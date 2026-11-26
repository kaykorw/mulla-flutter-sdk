import 'package:mulla_dart/mulla_dart.dart';

import 'payment_controller.dart';
import 'payment_state.dart';

/// Drives the payment of a checkout session your backend created.
class MullaCheckoutController extends MullaPaymentController {
  MullaCheckoutController({required this.client, required this.sessionId, required this.token});

  /// The key-less client used for every request.
  final MullaPublicClient client;

  /// The checkout session id from your backend.
  final String sessionId;

  /// The session's token from your backend; it only allows paying this session.
  final String token;

  CheckoutSession? _session;

  CheckoutSession? get session => _session;

  @override
  Future<MullaPaymentSummary> fetchSummary() async {
    final s = await client.checkout.retrieve(sessionId, token);
    _session = s;

    return MullaPaymentSummary(
      amount: s.amount,
      currency: s.currency,
      reason: s.reason,
      merchantName: s.merchantName,
      reference: s.reference,
      expiresAt: s.expiresAt,
      provider: s.provider,
      phoneNumber: s.phoneNumber,
    );
  }

  @override
  Future<MullaPaymentState?> fetchFinalState() async {
    final s = _session != null && state is MullaLoading ? _session! : await client.checkout.retrieve(sessionId, token);
    _session = s;

    return _fromStatus(s.status, s.reference);
  }

  @override
  Future<void> startPayment(Provider provider, String phoneNumber) async {
    _session = await client.checkout.pay(sessionId, token, PayParams(provider: provider, phoneNumber: phoneNumber));
  }

  @override
  Stream<MullaPaymentState?> watchStates() =>
      client.checkout.watch(sessionId, token).map((u) => _fromStatus(u.status, u.reference ?? _session?.reference));

  MullaPaymentState? _fromStatus(ChargeStatus? status, String? reference) => switch (status) {
        ChargeStatus.successful => MullaSucceeded(reference: reference),
        ChargeStatus.failed => MullaFailed(reason: _session?.raw['failure_message']?.toString()),
        ChargeStatus.expired => const MullaExpired(),
        _ => null,
      };
}
