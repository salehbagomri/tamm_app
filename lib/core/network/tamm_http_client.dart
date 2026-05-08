import 'dart:async';
import 'package:http/http.dart' as http;

/// HTTP client مخصص يُضيف timeout ثابتاً على جميع طلبات Supabase.
///
/// عند قطع الإنترنت، يُلقي [TimeoutException] بعد [timeout] ثانية
/// بدلاً من أن يظل الطلب معلّقاً إلى الأبد.
class TammHttpClient extends http.BaseClient {
  final http.Client _inner;
  final Duration timeout;

  TammHttpClient({
    this.timeout = const Duration(seconds: 10),
    http.Client? inner,
  }) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'تعذر الاتصال بالخادم، تحقق من الشبكة',
        timeout,
      ),
    );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
