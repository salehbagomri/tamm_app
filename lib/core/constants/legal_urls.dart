/// روابط الوثائق القانونية والتواصل — مكان مركزي للتعديل.
class LegalUrls {
  LegalUrls._();

  /// سياسة الخصوصية (Google Play يتطلبها)
  static const String privacy =
      'https://github.com/salehbagomri/tamm-app-privacy';

  /// شروط الاستخدام — مؤقتاً تفتح صفحة الخصوصية حتى جاهزية المستودع المستقل.
  // TODO: استبدل بـ https://github.com/salehbagomri/tamm-app-terms عند إنشائه.
  static const String terms = privacy;

  /// رابط التطبيق على Google Play — يُستخدم للمشاركة والتقييم.
  static const String playStore =
      'https://play.google.com/store/apps/details?id=com.tamm.tamm_app';
}
