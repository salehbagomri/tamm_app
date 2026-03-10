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
async function sendToUser(userId: string, title: string, body: string) {
  const { data: tokens } = await supabase
    .from("device_tokens")
    .select("fcm_token")
    .eq("user_id", userId);

  if (!tokens || tokens.length === 0) return;

  const accessToken = await getAccessToken();

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

  // Save in-app notification
  await supabase.from("notifications").insert({
    user_id: userId,
    title,
    body,
    type: "push",
    is_read: false,
  });
}

// === Send to all managers ===
async function sendToManagers(title: string, body: string) {
  const { data: managers } = await supabase
    .from("profiles")
    .select("id")
    .eq("role", "manager");

  if (!managers) return;
  for (const m of managers) {
    await sendToUser(m.id, title, body);
  }
}

// === Main handler ===
Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    const { type, table, record, old_record } = payload;

    // New order
    if (table === "orders" && type === "INSERT") {
      const orderNumber = record.order_number || "";
      await sendToManagers("🔔 طلب جديد", `طلب خدمة جديد #${orderNumber}`);
    }

    // Assignment created
    if (table === "assignments" && type === "INSERT") {
      const { data: order } = await supabase
        .from("orders")
        .select("customer_id, order_number")
        .eq("id", record.order_id)
        .single();

      const { data: tech } = await supabase
        .from("technicians")
        .select("profile_id")
        .eq("id", record.technician_id)
        .single();

      if (tech) {
        await sendToUser(tech.profile_id, "👷 مهمة جديدة", "تم تعيينك لمهمة جديدة");
      }
      if (order) {
        await sendToUser(order.customer_id, "🔧 تم التعيين", `تم تعيين فني لطلبك #${order.order_number}`);
      }
    }

    // Assignment status updated
    if (table === "assignments" && type === "UPDATE") {
      const newStatus = record.status;
      const oldStatus = old_record?.status;

      if (newStatus !== oldStatus) {
        const { data: order } = await supabase
          .from("orders")
          .select("customer_id, order_number")
          .eq("id", record.order_id)
          .single();

        if (newStatus === "started" && order) {
          await sendToUser(order.customer_id, "🚀 بدأ العمل", "الفني بدأ العمل على طلبك");
        }

        if (newStatus === "completed" && order) {
          await sendToUser(order.customer_id, "✅ تمّ الإنجاز", `تم إنجاز طلبك #${order.order_number}`);
          await sendToManagers("✅ مهمة مكتملة", `تم إنجاز الطلب #${order.order_number}`);
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
