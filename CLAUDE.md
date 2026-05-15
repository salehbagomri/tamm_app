# CLAUDE.md — Tamm App Standing Instructions

## 1. Project Context
This is tamm_app — Flutter 3.x mobile + web app for Tamm platform (AC & solar energy services, Yemen).
Version: 1.1.0+3 | Target: Android + Web.
It shares the same Supabase database with tamm_web (Next.js).
Three roles: customer, manager, technician.

## 2. Git — Auto Push After Every Change
After completing ANY task that modifies files:
1. git add -A
2. git commit -m "descriptive message in English"
3. git push origin main
Always confirm push succeeded before reporting task complete.

## 3. Cross-Project Sync Warning
Before finishing any task, check if the change affects tamm_web (Next.js).
If YES — stop and tell the user exactly:
- What was changed
- Which file(s) in tamm_web need the same change
- Whether it is a database change (affects both projects immediately)

Changes that ALWAYS affect both projects:
- Supabase table schema changes
- kIsWeb where mobile and web logic differ
- FCM notifications: mobile only — always guard with kIsWeb == false

## 4. Database Changes
- Always write a SQL migration file in supabase/migrations/
- Never modify the database directly without a migration file
- After schema changes, update Dart models in lib/shared/models/
- Notify the user to apply the same type changes in tamm_web/lib/types/

## 5. Code Quality Rules — Flutter
- Use context.colors.xxx — never raw Colors or hardcoded hex
- Use AppSpacing constants — never hardcoded EdgeInsets values
- Use AppTextStyles — never raw fontSize numbers
- Font: Alexandria (Google Fonts) — never override globally
- All new screens must support responsive layout (mobile/tablet/desktop) via ResponsiveWrapper
- Never use dart:io — use Uint8List and PlatformUtils for web compatibility
- State management: Riverpod only — no setState for business logic
- Navigation: go_router only — no Navigator.push
- Platform separation: use kIsWeb where mobile and web logic differ
- FCM notifications: mobile only — always guard with kIsWeb == false
- Icons: always use Outline variants — never filled icons
  Examples: Icons.home_outlined NOT Icons.home
            Icons.shopping_cart_outlined NOT Icons.shopping_cart
            Icons.person_outlined NOT Icons.person
            Icons.notifications_outlined NOT Icons.notifications
            Icons.settings_outlined NOT Icons.settings
  When adding any new icon, always search for the _outlined suffix first.
  If no outline variant exists, use the _rounded suffix as fallback.

## 6. Architecture Rules
- Layer order: Screen → Provider → Repository → Supabase
- Error handling: always throw AppException — never raw exceptions
- New features go in: lib/features/[role]/[module]/presentation/
- Shared models: lib/shared/models/
- Shared providers: lib/shared/providers/
- Shared repositories: lib/shared/repositories/

## 7. Before Reporting Any Task Complete
- [ ] flutter analyze passes with no errors
- [ ] Git pushed to main successfully
- [ ] Cross-project impact checked and reported to user
- [ ] No hardcoded colors, spacing, or font sizes
- [ ] Responsive layout implemented for all new screens
- [ ] kIsWeb used correctly where needed
- [ ] All UI text is in Arabic
