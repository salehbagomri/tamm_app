---
trigger: always_on
---

# Tamm App — Flutter Android Agent Rules

## Project Architecture

This project (Flutter Android) is part of a two-app ecosystem:
- **Flutter Android** → Customer + Technician (this project)
- **Next.js Web**     → Customer + Admin (separate project)
- **Supabase**        → Shared database and auth between both

Both projects are independent codebases sharing the same
Supabase instance. Any change affecting shared logic must
be reflected in both projects.

---

## Tech Stack

- Flutter + Dart (null-safe)
- State Management: Riverpod
- Routing: go_router
- Backend: Supabase (PostgreSQL + Auth + Storage + Realtime)
- Notifications: Firebase Cloud Messaging (FCM) — mobile only
- Fonts: Google Fonts (Harmattan for Arabic)
- Theme: Dark Mode only (AppColors system)
- Language: Arabic (RTL) — UI text in Arabic, code in English

---

## Code Rules

- All code in English, all comments and UI text in Arabic
- Never use dart:io — use Uint8List and PlatformUtils instead
- Always check kIsWeb when separating mobile/web logic
- Never add new packages without explicit approval
- Follow existing project structure:
  features/[role]/[module]/presentation/
- Never modify database schema without writing a SQL migration
- Always use existing models: Order, Product, ServiceType, UserProfile
- Never modify model structure without explicit approval

---

## Git Rules

After every successful change or fix, always:

1. Stage all modified files
   git add .

2. Commit with a clear descriptive message in this format:
   git commit -m "feat: [what was added]"
   git commit -m "fix: [what was fixed]"
   git commit -m "refactor: [what was refactored]"
   git commit -m "chore: [dependency or config change]"

3. Push to main branch immediately
   git push origin main

Never leave changes uncommitted after a completed task.
Always push before ending the session.

---

## Cross-Project Sync Rule

After any change or fix, evaluate whether it falls under
any of these categories and notify me immediately if so:

### Triggers that affect Next.js Web:

1. **Supabase changes**
   - Added, modified, or deleted table or column
   - Changed RLS policies
   - Modified Edge Functions
   - Added SQL Migration

2. **Data model changes**
   - Modified Order, Product, UserProfile, or ServiceType
   - Added new field or changed existing field type

3. **Customer business logic changes**
   - Changed order flow or status transitions
   - Changed pricing calculation logic
   - Changed validation rules

4. **Customer UX changes**
   - Changed flow of any customer-facing screen
   - Added new step to any customer process

### Notification format:

When any trigger above is detected, append this to your response:

⚠️ Next.js Web Impact:
- What changed exactly
- Which file or table
- What needs to be updated in the Next.js project

If the change is UI-only and does not affect any of the above,
no notification needed — continue normally.

---

## Before Every Response

Ask yourself:
- Does this change affect Supabase? → notify
- Does this change affect a shared data model? → notify
- Does this change affect customer-facing logic or flow? → notify
- Is this UI-only? → no notification needed
- Did I commit and push after completing the task? → always yes