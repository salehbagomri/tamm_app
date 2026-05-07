import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const FCM_PROJECT_ID = Deno.env.get("FCM_PROJECT_ID")!;
const FCM_SERVICE_ACCOUNT = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT")!);

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// === Google OAuth2 JWT for FCM V1 API ===
function pemToArrayBuffer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s/g, "");
  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

function base64url(data: ArrayBuffer | string): string {
  const str = typeof data === "string"
    ? btoa(data)
    : btoa(String.fromCharCode(...new Uint8Array(data)));
  return str.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getAccessToken(): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = base64url(JSON.stringify({
    iss: FCM_SERVICE_ACCOUNT.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToArrayBuffer(FCM_SERVICE_ACCOUNT.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${payload}`),
  );

  const jwt = `${header}.${payload}.${base64url(signature)}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const data = await res.json();
  return data.access_token;
}

// === Send FCM to a user ===
// notificationType: the notification category (e.g. 'on_the_way', 'quote_sent')
// referenceId: order_id for customer/manager, assignment_id for technician
async function sendToUser(
  userId: string,
  title: string,
  body: string,
  notificationType: string = "general",
  referenceId: string | null = null,
) {
  const { data: tokens } = await supabase
    .from("device_tokens")
    .select("fcm_token")
    .eq("user_id", userId);

  if (!tokens || tokens.length === 0) return;

  const accessToken = await getAccessToken();

  // Build data payload for deep linking
  const dataPayload: Record<string, string> = {
    notification_type: notificationType,
  };
  if (referenceId) dataPayload.order_id = referenceId;

  for (const { fcm_token } of tokens) {
    try {
      await fetch(
        `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: fcm_token,
              notification: { title, body },
              data: dataPayload,
              android: {
                priority: "high",
                notification: { sound: "default", channel_id: "tamm_notifications" },
              },
            },
          }),
        },
      );
    } catch (_e) {
      // Skip failed tokens
    }
  }

  // Save in-app notification with routing fields
  await supabase.from("notifications").insert({
    user_id: userId,
    title,
    body,
    is_read: false,
    notification_type: notificationType,
    order_id: referenceId,
  });
}

// === Send to all managers ===
async function sendToManagers(
  title: string,
  body: string,
  notificationType: string = "general",
  referenceId: string | null = null,
) {
  const { data: managers } = await supabase
    .from("profiles")
    .select("id")
    .eq("role", "manager");

  if (!managers) return;
  for (const m of managers) {
    await sendToUser(m.id, title, body, notificationType, referenceId);
  }
}

// === Main handler ===
Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const { type, table, record, old_record } = payload;

    // ─── NEW ORDER ─────────────────────────────────────────────────────
    if (table === "orders" && type === "INSERT") {
      const orderNumber = record.order_number || "";
      await sendToManagers(
        "🔔 طلب جديد",
        `طلب خدمة جديد #${orderNumber}`,
        "new_order",
        record.id,
      );
    }

    // ─── ORDER STATUS / QUOTE STATUS UPDATED ───────────────────────────
    if (table === "orders" && type === "UPDATE") {
      const newStatus = record.status;
      const oldStatus = old_record?.status;
      const newQuoteStatus = record.quote_status;
      const oldQuoteStatus = old_record?.quote_status;
      const orderId = record.id;
      const orderNumber = record.order_number || "";
      const customerId = record.user_id || record.customer_id;

      // ── Status changes ──
      if (newStatus !== oldStatus && customerId) {
        if (newStatus === "on_the_way") {
          await sendToUser(
            customerId,
            "🚗 الفني في الطريق",
            "سيصل الفني إليك قريباً، كن جاهزاً",
            "on_the_way",
            orderId,
          );
        }

        if (newStatus === "in_progress") {
          await sendToUser(
            customerId,
            "🔧 بدأ الفني العمل",
            "يعمل الفني الآن على طلبك",
            "in_progress",
            orderId,
          );
        }

        if (newStatus === "completed") {
          await sendToUser(
            customerId,
            "✅ اكتمل طلبك",
            "تم إنجاز طلبك بنجاح. شاركنا تقييمك",
            "completed",
            orderId,
          );
          await sendToManagers(
            "📋 طلب مكتمل",
            `تم إنجاز الطلب #${orderNumber}`,
            "completed",
            orderId,
          );
        }
      }

      // ── Quote status changes ──
      if (newQuoteStatus !== oldQuoteStatus) {
        // quote sent to customer
        if (newQuoteStatus === "sent" && customerId) {
          await sendToUser(
            customerId,
            "📋 عرض سعر جديد",
            "لديك عرض سعر بانتظارك، اضغط للمراجعة",
            "quote_sent",
            orderId,
          );
        }

        // Customer responded (accepted or rejected) → notify managers
        if (newQuoteStatus === "accepted" || newQuoteStatus === "rejected") {
          const decision = newQuoteStatus === "accepted" ? "قَبِل ✅" : "رفض ❌";
          await sendToManagers(
            `العميل ${decision} العرض`,
            `قرار العميل بشأن عرض الطلب #${orderNumber}`,
            "quote_responded",
            orderId,
          );
        }
      }
    }

    // ─── ASSIGNMENT CREATED ────────────────────────────────────────────
    if (table === "assignments" && type === "INSERT") {
      const { data: order } = await supabase
        .from("orders")
        .select("user_id, customer_id, order_number")
        .eq("id", record.order_id)
        .single();

      const { data: tech } = await supabase
        .from("technicians")
        .select("profile_id")
        .eq("id", record.technician_id)
        .single();

      // Notify technician — referenceId = assignment_id (used for deep link)
      if (tech) {
        await sendToUser(
          tech.profile_id,
          "👷 مهمة جديدة",
          "تم تعيينك لمهمة جديدة",
          "new_assignment",
          record.id, // assignment_id for deep linking to /technician/task/:id
        );
      }

      // Notify customer — referenceId = order_id
      if (order) {
        const customerId = order.user_id || order.customer_id;
        await sendToUser(
          customerId,
          "🔧 تم التعيين",
          `تم تعيين فني لطلبك #${order.order_number}`,
          "assigned",
          record.order_id,
        );
      }
    }

    // ─── ASSIGNMENT STATUS UPDATED ─────────────────────────────────────
    if (table === "assignments" && type === "UPDATE") {
      const newStatus = record.status;
      const oldStatus = old_record?.status;

      if (newStatus !== oldStatus) {
        const { data: order } = await supabase
          .from("orders")
          .select("user_id, customer_id, order_number")
          .eq("id", record.order_id)
          .single();

        if (newStatus === "started" && order) {
          const customerId = order.user_id || order.customer_id;
          await sendToUser(
            customerId,
            "🚀 بدأ العمل",
            "الفني بدأ العمل على طلبك",
            "in_progress",
            record.order_id,
          );
        }

        if (newStatus === "completed" && order) {
          const customerId = order.user_id || order.customer_id;
          await sendToUser(
            customerId,
            "✅ تمّ الإنجاز",
            `تم إنجاز طلبك #${order.order_number}`,
            "completed",
            record.order_id,
          );
          await sendToManagers(
            "✅ مهمة مكتملة",
            `تم إنجاز الطلب #${order.order_number}`,
            "completed",
            record.order_id,
          );
        }
      }
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
