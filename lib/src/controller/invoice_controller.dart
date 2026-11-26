import 'package:mulla_dart/mulla_dart.dart';

import 'payment_controller.dart';
import 'payment_state.dart';

/// Drives the payment of an invoice.
class MullaInvoicePaymentController extends MullaPaymentController {
  MullaInvoicePaymentController({required this.client, required this.invoiceId, this.notes});

  /// The key-less client used for every request.
  final MullaPublicClient client;

  /// The invoice to pay.
  final String invoiceId;

  /// Optional note sent with each payment attempt.
  final String? notes;

  Invoice? _invoice;
  String? _transactionId;

  Invoice? get invoice => _invoice;

  @override
  Future<MullaPaymentSummary> fetchSummary() async {
    final i = await client.invoices.retrievePublic(invoiceId);
    _invoice = i;

    return MullaPaymentSummary(
      amount: i.amountDue ?? i.totalAmount,
      currency: i.currency,
      reason: i.invoiceNumber,
      merchantName: i.merchant == null ? null : (i.merchant!['name'] ?? i.merchant!['business_name'])?.toString(),
      reference: i.invoiceNumber,
      phoneNumber: i.customerPhone,
    );
  }

  @override
  Future<MullaPaymentState?> fetchFinalState() async {
    final i = state is MullaLoading && _invoice != null ? _invoice! : await client.invoices.retrievePublic(invoiceId);
    _invoice = i;

    return switch (i.status) {
      InvoiceStatus.paid => MullaSucceeded(reference: i.invoiceNumber),
      InvoiceStatus.cancelled => const MullaFailed(),
      _ => null,
    };
  }

  @override
  Future<void> startPayment(Provider provider, String phoneNumber) async {
    final started = await client.invoices
        .pay(invoiceId, PayInvoiceParams(provider: provider, phoneNumber: phoneNumber, notes: notes));
    _transactionId = started.payment?.transactionId;
  }

  @override
  Stream<MullaPaymentState?> watchStates() => client.invoices.watch(invoiceId).map(_fromUpdate);

  MullaPaymentState? _fromUpdate(InvoiceUpdate u) {
    if (u.isPaid) return MullaSucceeded(reference: u.invoiceNumber ?? _invoice?.invoiceNumber);
    if (u.status == InvoiceStatus.cancelled) return const MullaFailed();

    final mine = _transactionId == null || u.transactionId == null || u.transactionId == _transactionId;
    final failed =
        const [PaymentStatus.failed, PaymentStatus.cancelled, PaymentStatus.expired].contains(u.paymentStatus);
    if (mine && failed) {
      return const MullaReady(previousAttemptFailed: true);
    }

    return null;
  }
}
