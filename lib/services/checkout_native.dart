import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

Future<void> openCheckout(Map<String, dynamic> options) async {
  if (defaultTargetPlatform != TargetPlatform.android &&
      defaultTargetPlatform != TargetPlatform.iOS) {
    throw Exception('Payments are supported on Android, iOS and web.');
  }
  final razorpay = Razorpay(), completion = Completer<void>();
  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
    PaymentSuccessResponse response,
  ) {
    if (!completion.isCompleted) completion.complete();
  });
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    if (!completion.isCompleted) {
      completion.completeError(
        Exception(response.message ?? 'Payment cancelled or failed.'),
      );
    }
  });
  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (
    ExternalWalletResponse response,
  ) {
    if (!completion.isCompleted) {
      completion.completeError(
        Exception(
          'Complete the payment in your wallet, then check payment history.',
        ),
      );
    }
  });
  try {
    razorpay.open(options);
    await completion.future;
  } finally {
    razorpay.clear();
  }
}
