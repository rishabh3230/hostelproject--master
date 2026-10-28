import 'dart:convert';
import 'dart:js_interop';

@JS('hmsCheckout')
external JSPromise<JSAny?> _checkout(JSString options);

Future<void> openCheckout(Map<String, dynamic> options) async {
  try {
    await _checkout(jsonEncode(options).toJS).toDart;
  } catch (_) {
    throw Exception(
      'Payment cancelled or unavailable. Check payment history before retrying.',
    );
  }
}
