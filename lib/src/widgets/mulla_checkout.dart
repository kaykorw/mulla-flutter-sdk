// material_ui needs Flutter 3.47+; this package supports 3.27+. Switch once the minimum is 3.47.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:mulla_dart/mulla_dart.dart';

import '../controller/checkout_controller.dart';
import '../controller/invoice_controller.dart';
import '../controller/payment_controller.dart';
import '../controller/payment_state.dart';
import '../l10n/strings.dart';
import 'payment_view.dart';

/// Drop-in checkout for a session created by your backend.
class MullaCheckout extends StatelessWidget {
  const MullaCheckout({
    super.key,
    required this.client,
    required this.sessionId,
    required this.token,
    this.strings,
    this.onFinished,
    this.onCancel,
  });

  /// The key-less client used for every request.
  final MullaPublicClient client;

  /// The checkout session id from your backend.
  final String sessionId;

  /// The session's token from your backend.
  final String token;

  /// Texts to show; defaults to the app's language.
  final MullaStrings? strings;

  /// Called when the customer taps "Done" on the result screen.
  final ValueChanged<MullaPaymentResult>? onFinished;

  /// Shows a cancel button on the form when set.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => _OwnedController(
        key: ValueKey('checkout:$sessionId'),
        create: () => MullaCheckoutController(client: client, sessionId: sessionId, token: token),
        builder: (controller) => MullaPaymentView(
          controller: controller,
          strings: strings,
          onFinished: onFinished,
          onCancel: onCancel,
        ),
      );
}

/// Drop-in payment for an invoice (public endpoints, no token needed).
class MullaInvoicePayment extends StatelessWidget {
  const MullaInvoicePayment({
    super.key,
    required this.client,
    required this.invoiceId,
    this.notes,
    this.strings,
    this.onFinished,
    this.onCancel,
  });

  /// The key-less client used for every request.
  final MullaPublicClient client;

  /// The invoice to pay.
  final String invoiceId;

  /// Optional note sent with each payment attempt.
  final String? notes;

  /// Texts to show; defaults to the app's language.
  final MullaStrings? strings;

  /// Called when the customer taps "Done" on the result screen.
  final ValueChanged<MullaPaymentResult>? onFinished;

  /// Shows a cancel button on the form when set.
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) => _OwnedController(
        key: ValueKey('invoice:$invoiceId'),
        create: () => MullaInvoicePaymentController(client: client, invoiceId: invoiceId, notes: notes),
        builder: (controller) => MullaPaymentView(
          controller: controller,
          strings: strings,
          onFinished: onFinished,
          onCancel: onCancel,
        ),
      );
}

class _OwnedController extends StatefulWidget {
  const _OwnedController({super.key, required this.create, required this.builder});

  final MullaPaymentController Function() create;
  final Widget Function(MullaPaymentController controller) builder;

  @override
  State<_OwnedController> createState() => _OwnedControllerState();
}

class _OwnedControllerState extends State<_OwnedController> {
  late final MullaPaymentController _controller = widget.create();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

/// Opens the checkout in a bottom sheet and returns how it ended.
Future<MullaPaymentResult> showMullaCheckout(
  BuildContext context, {
  required MullaPublicClient client,
  required String sessionId,
  required String token,
  MullaStrings? strings,
}) =>
    _showSheet(
      context,
      (onFinished, onCancel) => MullaCheckout(
        client: client,
        sessionId: sessionId,
        token: token,
        strings: strings,
        onFinished: onFinished,
        onCancel: onCancel,
      ),
    );

/// Opens an invoice payment in a bottom sheet and returns how it ended.
Future<MullaPaymentResult> showMullaInvoicePayment(
  BuildContext context, {
  required MullaPublicClient client,
  required String invoiceId,
  String? notes,
  MullaStrings? strings,
}) =>
    _showSheet(
      context,
      (onFinished, onCancel) => MullaInvoicePayment(
        client: client,
        invoiceId: invoiceId,
        notes: notes,
        strings: strings,
        onFinished: onFinished,
        onCancel: onCancel,
      ),
    );

Future<MullaPaymentResult> _showSheet(
  BuildContext context,
  Widget Function(ValueChanged<MullaPaymentResult> onFinished, VoidCallback onCancel) build,
) async {
  final result = await showModalBottomSheet<MullaPaymentResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: SingleChildScrollView(
        child: build(
          (result) => Navigator.of(sheetContext).pop(result),
          () => Navigator.of(sheetContext).pop(const MullaPaymentResult(MullaPaymentOutcome.cancelled)),
        ),
      ),
    ),
  );

  return result ?? const MullaPaymentResult(MullaPaymentOutcome.cancelled);
}
