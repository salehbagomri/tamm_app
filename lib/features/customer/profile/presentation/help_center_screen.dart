import 'package:flutter/material.dart';
import 'package:tamm_app/core/theme/tamm_colors.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../widgets/support_dialog.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgPrimary,
      appBar: AppBar(
        backgroundColor: context.colors.bgPrimary,
        elevation: 0,
        title: Text(
          'مركز المساعدة',
          style: AppTextStyles.cardTitle(context.colors.textPrimary),
        ),
        iconTheme: IconThemeData(color: context.colors.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.pagePadding,
          children: [
            _IntroCard(),
            AppSpacing.gapLg,
            const _FaqSection(
              title: 'الطلبات',
              icon: Icons.receipt_long_outlined,
              items: [
                _FaqItem(
                  question: 'كيف أتابع حالة طلبي؟',
                  answer:
                      'من تبويب "حسابي" → "طلباتي" تجد جميع طلباتك. اضغط على '
                      'الطلب لرؤية شريط حالته المباشر (تم استلامه — تم تعيين '
                      'الفني — في الطريق — جاري التنفيذ — مكتمل).',
                ),
                _FaqItem(
                  question: 'هل يمكنني إلغاء الطلب؟',
                  answer:
                      'نعم، يمكنك الإلغاء قبل أن يتم تأكيد الطلب أو خلال مرحلة '
                      '"بانتظار التأكيد". بعد أن يبدأ الفني التنفيذ، تواصل '
                      'معنا مباشرة لمناقشة الإلغاء.',
                ),
                _FaqItem(
                  question: 'كم يستغرق الفني للوصول؟',
                  answer:
                      'يتم تعيين الفني المناسب بأقرب وقت بعد تأكيد الطلب. '
                      'عند تحرّكه ستصلك رسالة "الفني في الطريق".',
                ),
              ],
            ),
            AppSpacing.gapMd,
            const _FaqSection(
              title: 'الدفع',
              icon: Icons.payments_outlined,
              items: [
                _FaqItem(
                  question: 'ما هي طرق الدفع المتاحة؟',
                  answer:
                      'الدفع نقداً عند الاستلام (كاش)، تحويل بنكي، أو محفظة '
                      'إلكترونية. تختار طريقتك عند إتمام الطلب.',
                ),
                _FaqItem(
                  question: 'كيف أرسل سند التحويل البنكي؟',
                  answer:
                      'بعد الطلب، افتحه من "طلباتي" وستجد قسماً لرفع صورة '
                      'السند. اضغط رفع → اختر الصورة → سيتم استلامها مباشرة.',
                ),
                _FaqItem(
                  question: 'هل علي تأكيد استلام الفني للمبلغ النقدي؟',
                  answer:
                      'نعم، عند اكتمال الطلب وكان الدفع نقدياً، ستظهر لك '
                      'بطاقة "تأكيد استلام الطلب" مع زرين. ضغطك يساعدنا على '
                      'حماية حقك وحق الفني.',
                ),
              ],
            ),
            AppSpacing.gapMd,
            const _FaqSection(
              title: 'المنتجات والتركيب',
              icon: Icons.build_outlined,
              items: [
                _FaqItem(
                  question: 'هل التركيب مشمول مع المنتج؟',
                  answer:
                      'يعتمد على نوع المنتج. عند إضافة المنتج للسلة سيُسألك '
                      'إذا كنت تريد إضافة التركيب (برسم منفصل). يمكنك الشراء '
                      'بدونه إن أردت التركيب بنفسك.',
                ),
                _FaqItem(
                  question: 'كيف يتم توصيل المنتجات؟',
                  answer:
                      'إذا اخترت "منتج بدون تركيب" يصلك المنتج عن طريق موصل '
                      'الشركة المورّدة. أما إذا اخترت "مع التركيب" فيأتيك '
                      'الفني المختص ويركبه في موقعك.',
                ),
                _FaqItem(
                  question: 'هل يمكنني طلب عرض سعر مخصص؟',
                  answer:
                      'نعم، من قسم الخدمات اختر "طلب عرض سعر" وقم بوصف '
                      'احتياجك. سيتواصل فريقنا معك بأقرب وقت لإرسال عرض مكتوب.',
                ),
              ],
            ),
            AppSpacing.gapMd,
            const _FaqSection(
              title: 'الحساب والخصوصية',
              icon: Icons.shield_outlined,
              items: [
                _FaqItem(
                  question: 'كيف أعدّل بياناتي الشخصية؟',
                  answer:
                      'من "حسابي" اضغط زر "تعديل الحساب" أو اضغط على صورتك '
                      'لتغييرها مباشرة من الكاميرا أو المعرض.',
                ),
                _FaqItem(
                  question: 'كيف أحذف حسابي نهائياً؟',
                  answer:
                      'من "حسابي" اضغط "حذف الحساب نهائياً" في الأسفل. سيتم '
                      'مسح كافة بياناتك بشكل لا رجعة فيه.',
                ),
                _FaqItem(
                  question: 'هل بياناتي آمنة؟',
                  answer:
                      'نعم. نتبع أعلى معايير الأمان ولا نشارك بياناتك مع أي '
                      'طرف ثالث. راجع سياسة الخصوصية للتفاصيل.',
                ),
              ],
            ),
            AppSpacing.gapLg,
            const _ContactPromptCard(),
            AppSpacing.gapLg,
          ],
        ),
      ),
    );
  }
}

// ─── مقدمة الشاشة ─────────────────────────────────────────────────────────────

class _IntroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.colors.bluePrimary.withValues(alpha: 0.12),
            context.colors.bluePrimary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(
          color: context.colors.bluePrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.bluePrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.support_agent_outlined,
              color: context.colors.bluePrimary,
              size: AppSpacing.iconMd,
            ),
          ),
          AppSpacing.hGapSm2,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'كيف يمكننا مساعدتك؟',
                  style: AppTextStyles.cardTitle(context.colors.textPrimary),
                ),
                AppSpacing.gapXs,
                Text(
                  'إجابات الأسئلة الشائعة، وإن لم تجد ما تبحث عنه — تواصل معنا.',
                  style: AppTextStyles.bodySmall(context.colors.textSecond),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── قسم FAQ ──────────────────────────────────────────────────────────────────

class _FaqSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_FaqItem> items;
  const _FaqSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(icon, color: context.colors.bluePrimary, size: 20),
                AppSpacing.hGapSm,
                Text(
                  title,
                  style: AppTextStyles.body(
                    context.colors.textPrimary,
                  ).copyWith(fontWeight: AppTextStyles.bold),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.colors.border),
          ...items.asMap().entries.map((entry) {
            final isLast = entry.key == items.length - 1;
            return Column(
              children: [
                entry.value,
                if (!isLast) Divider(height: 1, color: context.colors.border),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm2,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: AppTextStyles.body(
                        context.colors.textPrimary,
                      ).copyWith(fontWeight: AppTextStyles.semiBold),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.colors.textSecond,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(
                    widget.answer,
                    style: AppTextStyles.bodySmall(
                      context.colors.textSecond,
                    ).copyWith(height: 1.6),
                  ),
                ),
                crossFadeState: _open
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── بطاقة "تواصل معنا" ───────────────────────────────────────────────────────

class _ContactPromptCard extends StatelessWidget {
  const _ContactPromptCard();

  Future<void> _whatsapp(BuildContext context) async {
    // رقم WhatsApp يمكن تخصيصه لاحقاً في constants
    final uri = Uri.parse('https://wa.me/967770727055');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) showSupportDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.colors.bgSurface,
        borderRadius: AppSpacing.radiusLg,
        border: Border.all(color: context.colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.headset_mic_outlined,
            color: context.colors.bluePrimary,
            size: 36,
          ),
          AppSpacing.gapSm,
          Text(
            'لم تجد إجابتك؟',
            style: AppTextStyles.cardTitle(context.colors.textPrimary),
          ),
          AppSpacing.gapXs,
          Text(
            'فريقنا جاهز للرد على أي استفسار',
            style: AppTextStyles.bodySmall(context.colors.textSecond),
            textAlign: TextAlign.center,
          ),
          AppSpacing.gapMd,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => showSupportDialog(context),
                  icon: Icon(
                    Icons.phone_outlined,
                    color: context.colors.bluePrimary,
                    size: 18,
                  ),
                  label: Text(
                    'اتصل بنا',
                    style: AppTextStyles.bodySmall(context.colors.bluePrimary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.colors.bluePrimary),
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.radiusLg,
                    ),
                  ),
                ),
              ),
              AppSpacing.hGapSm,
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _whatsapp(context),
                  icon: const Icon(
                    Icons.chat_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    'واتساب',
                    style: AppTextStyles.button(Colors.white),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.colors.success,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppSpacing.radiusLg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
