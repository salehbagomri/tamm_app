import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/legal_urls.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../../core/widgets/tamm_button.dart';
import '../../../../core/widgets/tamm_theme_selector.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../../../../shared/providers/order_providers.dart';
import '../../../../shared/repositories/auth_repository.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGuest = ref.watch(isGuestProvider);
    if (isGuest) return const _GuestView();

    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: ResponsiveWrapper(
          child: profileAsync.when(
            data: (p) => _LoggedInView(profile: p),
            loading: () => const _ProfileSkeleton(),
            error: (e, _) => ErrorStateWidget(
              message: e is AppException
                  ? e.message
                  : 'حدث خطأ في تحميل بيانات الحساب',
              onRetry: () => ref.invalidate(userProfileProvider),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── حالة الزائر ──────────────────────────────────────────────────────────────

class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_outline,
                  size: 80,
                  color: context.colors.textFaint,
                ),
                AppSpacing.gapMd,
                Text(
                  'سجّل دخولك لإدارة حسابك',
                  style: AppTextStyles.body(context.colors.textPrimary),
                ),
                AppSpacing.gapLg,
                TammButton(
                  label: 'تسجيل الدخول',
                  onPressed: () => context.push('/login'),
                ),
                AppSpacing.gapSm2,
                TammButton(
                  label: 'إنشاء حساب',
                  type: TammButtonType.secondary,
                  onPressed: () => context.push('/register'),
                ),
                AppSpacing.gapXl,
                const TammThemeSelector(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── الشاشة الرئيسية للمستخدم المسجل ──────────────────────────────────────────

class _LoggedInView extends ConsumerWidget {
  final dynamic profile;
  const _LoggedInView({required this.profile});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(userProfileProvider);
    ref.invalidate(customerStatsProvider);
    await ref.read(userProfileProvider.future);
    await ref.read(customerStatsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.pagePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSpacing.gapMd,
            _ProfileHeader(profile: profile),
            AppSpacing.gapLg,

            const _SectionHeader(label: 'نشاطي'),
            AppSpacing.gapSm,
            const _StatsCard(),
            AppSpacing.gapMd,
            _QuickAction(
              icon: Icons.receipt_long_outlined,
              label: AppStrings.myOrders,
              onTap: () => context.push('/customer/orders'),
            ),
            const SizedBox(height: 8),
            _QuickAction(
              icon: Icons.devices_outlined,
              label: AppStrings.myDevices,
              onTap: () => context.push('/customer/devices'),
            ),
            const SizedBox(height: 8),
            _QuickAction(
              icon: Icons.location_on_outlined,
              label: 'عناويني المحفوظة',
              onTap: () => context.push('/customer/saved-addresses'),
            ),

            AppSpacing.gapLg,
            const _SectionHeader(label: 'الإعدادات'),
            AppSpacing.gapSm,
            const _SettingsCard(),

            AppSpacing.gapLg,
            const _SectionHeader(label: 'ساعدنا ننمو'),
            AppSpacing.gapSm,
            const _GrowthCard(),

            AppSpacing.gapLg,
            const _SectionHeader(label: 'الحساب والقانوني'),
            AppSpacing.gapSm,
            const _AccountLegalCard(),

            AppSpacing.gapLg,
            const _LogoutButton(),
            AppSpacing.gapSm2,
            const _DeleteAccountLink(),
            AppSpacing.gapMd,
          ],
        ),
      ),
    );
  }
}

// ─── عنوان قسم بسيط ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4, bottom: 4),
      child: Text(
        label,
        style: AppTextStyles.bodySmall(context.colors.textSecond).copyWith(
          fontWeight: AppTextStyles.semiBold,
        ),
      ),
    );
  }
}

// ─── بطاقة رأس الملف الشخصي ──────────────────────────────────────────────────

class _ProfileHeader extends ConsumerStatefulWidget {
  final dynamic profile;
  const _ProfileHeader({required this.profile});

  @override
  ConsumerState<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends ConsumerState<_ProfileHeader> {
  bool _uploading = false;

  Future<void> _changeAvatar() async {
    if (_uploading) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.colors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'صورة الحساب',
                style: AppTextStyles.cardTitle(context.colors.textPrimary),
              ),
              AppSpacing.gapMd,
              _SourceTile(
                icon: Icons.photo_camera_outlined,
                label: 'الكاميرا',
                color: context.colors.bluePrimary,
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              AppSpacing.gapSm,
              _SourceTile(
                icon: Icons.photo_library_outlined,
                label: 'المعرض',
                color: context.colors.success,
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              AppSpacing.gapSm,
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'إلغاء',
                  style: AppTextStyles.body(context.colors.textSecond),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
      maxHeight: 800,
    );
    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.name.contains('.')
          ? picked.name.split('.').last.toLowerCase()
          : 'jpg';
      await ref.read(authRepositoryProvider).uploadAvatar(
            bytes: bytes,
            extension: ext == 'jpeg' ? 'jpg' : ext,
          );
      if (!mounted) return;
      ref.invalidate(userProfileProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم تحديث الصورة',
            style: AppTextStyles.body(Colors.white),
          ),
          backgroundColor: context.colors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is AppException ? e.message : 'تعذّر رفع الصورة',
            style: AppTextStyles.body(Colors.white),
          ),
          backgroundColor: context.colors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final fullName = profile?.fullName?.toString() ?? '';
    final phone = profile?.phone?.toString() ?? '';
    final avatarUrl = profile?.avatarUrl?.toString();
    final initial = fullName.isNotEmpty ? fullName[0] : '?';

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _changeAvatar,
            child: Stack(
              children: [
                if (avatarUrl != null && avatarUrl.isNotEmpty)
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: context.colors.blueDark,
                    backgroundImage: CachedNetworkImageProvider(avatarUrl),
                  )
                else
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: context.colors.blueDark,
                    child: Text(
                      initial,
                      style: AppTextStyles.cardTitle(Colors.white).copyWith(
                        fontSize: 22,
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: context.colors.bluePrimary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colors.bgSurface,
                        width: 2,
                      ),
                    ),
                    child: _uploading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.camera_alt_outlined,
                            color: Colors.white,
                            size: 14,
                          ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGapSm2,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullName.isEmpty ? 'حسابك' : fullName,
                  style: AppTextStyles.cardTitle(context.colors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (phone.isNotEmpty) ...[
                  AppSpacing.gapXs,
                  Text(
                    phone,
                    style: AppTextStyles.bodySmall(context.colors.textSecond),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.push('/profile/edit'),
            icon: Icon(
              Icons.edit_outlined,
              color: context.colors.bluePrimary,
              size: AppSpacing.iconSm,
            ),
            tooltip: 'تعديل الحساب',
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppSpacing.radiusLg,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: AppSpacing.cardPadding,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: AppSpacing.radiusLg,
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: AppSpacing.iconMd),
              ),
              AppSpacing.hGapSm2,
              Text(
                label,
                style: AppTextStyles.body(context.colors.textPrimary)
                    .copyWith(fontWeight: AppTextStyles.semiBold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── بطاقة الإحصاءات ──────────────────────────────────────────────────────────

class _StatsCard extends ConsumerWidget {
  const _StatsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(customerStatsProvider);

    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: statsAsync.when(
        loading: () => const SizedBox(
          height: 64,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (_, __) => Text(
          'تعذّر تحميل الإحصاءات',
          style: AppTextStyles.bodySmall(context.colors.textFaint),
        ),
        data: (s) => Row(
          children: [
            Expanded(
              child: _StatCell(
                label: 'نشطة',
                value: s.active.toString(),
                color: context.colors.bluePrimary,
                icon: Icons.local_shipping_outlined,
              ),
            ),
            _VerticalDivider(),
            Expanded(
              child: _StatCell(
                label: 'مكتملة',
                value: s.completed.toString(),
                color: context.colors.success,
                icon: Icons.check_circle_outlined,
              ),
            ),
            _VerticalDivider(),
            Expanded(
              child: _StatCell(
                label: 'مجموع المصروف',
                value: _formatAmount(s.totalSpent),
                color: context.colors.warning,
                icon: Icons.payments_outlined,
                isAmount: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    if (v == v.truncateToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(0);
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isAmount;
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.isAmount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: AppSpacing.iconSm),
        AppSpacing.gapXs,
        Text(
          isAmount ? '$value ر.س' : value,
          style: AppTextStyles.sectionTitle(color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.caption(context.colors.textSecond),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        color: context.colors.border,
      );
}

// ─── إجراء سريع (بطاقة قابلة للضغط) ──────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.bgSurface,
      borderRadius: AppSpacing.radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppSpacing.radius,
        child: Container(
          padding: AppSpacing.cardPaddingSm,
          decoration: BoxDecoration(
            border: Border.all(color: context.colors.border),
            borderRadius: AppSpacing.radius,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.bluePrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: context.colors.bluePrimary,
                  size: 20,
                ),
              ),
              AppSpacing.hGapSm2,
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body(context.colors.textPrimary),
                ),
              ),
              Icon(
                Icons.chevron_left_outlined,
                color: context.colors.textFaint,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── بطاقة الإعدادات (يحتوي على الثيم واللغة) ────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radius,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.md,
              ),
              leading: Icon(
                Icons.palette_outlined,
                color: context.colors.bluePrimary,
                size: 20,
              ),
              title: Text(
                'مظهر التطبيق',
                style: AppTextStyles.body(context.colors.textPrimary),
              ),
              children: const [TammThemeSelector()],
            ),
          ),
          Divider(height: 1, color: context.colors.border),
          ListTile(
            leading: Icon(
              Icons.language_outlined,
              color: context.colors.textFaint,
              size: 20,
            ),
            title: Text(
              'اللغة',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: context.colors.bgPrimary,
                borderRadius: AppSpacing.radiusFull,
                border: Border.all(color: context.colors.border),
              ),
              child: Text(
                'العربية — قريباً',
                style: AppTextStyles.caption(context.colors.textFaint),
              ),
            ),
            enabled: false,
          ),
        ],
      ),
    );
  }
}

// ─── بطاقة "ساعدنا ننمو" (تقييم + مشاركة) ────────────────────────────────────

class _GrowthCard extends StatelessWidget {
  const _GrowthCard();

  Future<void> _rate(BuildContext context) async {
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(
          appStoreId: null,
          microsoftStoreId: null,
        );
      }
    } catch (_) {
      if (context.mounted) {
        final uri = Uri.parse(LegalUrls.playStore);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _share() async {
    await Share.share(
      'جرّب تطبيق تَمّ — لخدمات التكييف والطاقة الشمسية في اليمن.\n'
      '${LegalUrls.playStore}',
      subject: 'تطبيق تَمّ',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radius,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          ListTile(
            onTap: () => _rate(context),
            leading: Icon(
              Icons.star_outline_rounded,
              color: context.colors.warning,
              size: 22,
            ),
            title: Text(
              'قيّم التطبيق',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
            subtitle: Text(
              'دقيقة واحدة تساعدنا كثيراً',
              style: AppTextStyles.caption(context.colors.textSecond),
            ),
            trailing: Icon(
              Icons.chevron_left_outlined,
              color: context.colors.textFaint,
              size: 20,
            ),
          ),
          Divider(height: 1, color: context.colors.border),
          ListTile(
            onTap: _share,
            leading: Icon(
              Icons.share_outlined,
              color: context.colors.bluePrimary,
              size: 20,
            ),
            title: Text(
              'شارك التطبيق',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
            subtitle: Text(
              'انشر فائدة "تَمّ" بين معارفك',
              style: AppTextStyles.caption(context.colors.textSecond),
            ),
            trailing: Icon(
              Icons.chevron_left_outlined,
              color: context.colors.textFaint,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── بطاقة الحساب والقانوني ───────────────────────────────────────────────────

class _AccountLegalCard extends StatelessWidget {
  const _AccountLegalCard();

  Future<void> _open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final ok =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تعذّر فتح الرابط',
              style: AppTextStyles.body(Colors.white),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radius,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          _LegalRow(
            icon: Icons.privacy_tip_outlined,
            label: 'سياسة الخصوصية',
            onTap: () => _open(context, LegalUrls.privacy),
          ),
          Divider(height: 1, color: context.colors.border),
          _LegalRow(
            icon: Icons.description_outlined,
            label: 'شروط الاستخدام',
            onTap: () => _open(context, LegalUrls.terms),
          ),
          Divider(height: 1, color: context.colors.border),
          ListTile(
            onTap: () => context.push('/customer/help-center'),
            leading: Icon(
              Icons.support_agent_outlined,
              color: context.colors.bluePrimary,
              size: 20,
            ),
            title: Text(
              'مركز المساعدة',
              style: AppTextStyles.body(context.colors.textPrimary),
            ),
            trailing: Icon(
              Icons.chevron_left_outlined,
              color: context.colors.textFaint,
              size: 20,
            ),
          ),
          Divider(height: 1, color: context.colors.border),
          const _AboutRow(),
        ],
      ),
    );
  }
}

class _LegalRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _LegalRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: context.colors.bluePrimary, size: 20),
      title: Text(
        label,
        style: AppTextStyles.body(context.colors.textPrimary),
      ),
      trailing: Icon(
        Icons.open_in_new_outlined,
        color: context.colors.textFaint,
        size: 16,
      ),
    );
  }
}

class _AboutRow extends StatefulWidget {
  const _AboutRow();

  @override
  State<_AboutRow> createState() => _AboutRowState();
}

class _AboutRowState extends State<_AboutRow> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(
          () => _version = '${info.version} (${info.buildNumber})',
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.info_outline_rounded,
        color: context.colors.bluePrimary,
        size: 20,
      ),
      title: Text(
        'حول التطبيق',
        style: AppTextStyles.body(context.colors.textPrimary),
      ),
      trailing: Text(
        _version.isEmpty ? '...' : _version,
        style: AppTextStyles.caption(context.colors.textFaint),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

// ─── زر تسجيل الخروج ──────────────────────────────────────────────────────────

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TammButton(
      label: 'تسجيل الخروج',
      type: TammButtonType.secondary,
      icon: Icons.logout_outlined,
      onPressed: () => AuthRepository.confirmSignOut(context, ref),
    );
  }
}

// ─── رابط حذف الحساب (أقل بروزاً لكن متاح كما يتطلب Play Store) ─────────────

class _DeleteAccountLink extends ConsumerWidget {
  const _DeleteAccountLink();

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.bgSurface,
        shape: const RoundedRectangleBorder(
          borderRadius: AppSpacing.radiusLg,
        ),
        title: Text(
          'حذف الحساب نهائياً',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        content: Text(
          'هل أنت متأكد أنك تريد حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء '
          'وسيتم مسح كافة البيانات المرتبطة بك.',
          style: AppTextStyles.body(context.colors.textSecond),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'إلغاء',
              style: AppTextStyles.body(context.colors.textSecond),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'حذف حسابي',
              style: AppTextStyles.body(context.colors.error)
                  .copyWith(fontWeight: AppTextStyles.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم حذف حسابك',
              style: AppTextStyles.body(Colors.white),
            ),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/customer/home');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException ? e.message : 'حدث خطأ أثناء الحذف',
              style: AppTextStyles.body(Colors.white),
            ),
            backgroundColor: context.colors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _confirmDelete(context, ref),
        icon: Icon(
          Icons.delete_outline_rounded,
          color: context.colors.error,
          size: 18,
        ),
        label: Text(
          'حذف الحساب نهائياً',
          style: AppTextStyles.bodySmall(context.colors.error),
        ),
      ),
    );
  }
}

// ─── Skeleton أثناء التحميل ───────────────────────────────────────────────────

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSpacing.gapMd,
          _SkeletonBox(height: 92, radius: AppSpacing.radiusLgValue),
          AppSpacing.gapLg,
          _SkeletonBox(height: 84, radius: AppSpacing.radiusLgValue),
          AppSpacing.gapMd,
          _SkeletonBox(height: 52, radius: AppSpacing.radiusValue),
          AppSpacing.gapSm,
          _SkeletonBox(height: 52, radius: AppSpacing.radiusValue),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double height;
  final double radius;
  const _SkeletonBox({required this.height, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.bgSurface2,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
