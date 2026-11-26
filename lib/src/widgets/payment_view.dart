// material_ui needs Flutter 3.47+; this package supports 3.27+. Switch once the minimum is 3.47.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:mulla_dart/mulla_dart.dart';

import '../controller/payment_controller.dart';
import '../controller/payment_state.dart';
import '../l10n/strings.dart';
import '../theme.dart';
import 'form_widgets.dart';

/// The full payment flow, from the form to the result screen.
class MullaPaymentView extends StatefulWidget {
  const MullaPaymentView({
    super.key,
    required this.controller,
    this.strings,
    this.onFinished,
    this.onCancel,
    this.showSummary = true,
  });

  /// The controller that runs the payment.
  final MullaPaymentController controller;

  /// Defaults to [MullaStrings.of] the app's locale.
  final MullaStrings? strings;

  /// Called when the customer taps "Done" on a final screen.
  final ValueChanged<MullaPaymentResult>? onFinished;

  /// Shows a cancel button on the form when set.
  final VoidCallback? onCancel;

  /// Shows the amount and merchant above the form.
  final bool showSummary;

  @override
  State<MullaPaymentView> createState() => _MullaPaymentViewState();
}

class _MullaPaymentViewState extends State<MullaPaymentView> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.state is MullaLoading && widget.controller.summary == null) {
      widget.controller.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings ?? MullaStrings.of(context);
    final theme = MullaCheckoutTheme.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        final state = c.state;

        return Padding(
          padding: theme.padding,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: KeyedSubtree(
              key: ValueKey(state.runtimeType),
              child: switch (state) {
                MullaLoading() => const Center(
                    child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()),
                  ),
                MullaLoadError(:final error, :final retryable) => MullaPaymentStatusView(
                    icon: Icons.error_outline,
                    color: theme.errorColor,
                    title: strings.loadErrorTitle,
                    body: _message(error, strings),
                    actionLabel: retryable ? strings.tryAgain : strings.done,
                    onAction: retryable
                        ? c.retry
                        : () => widget.onFinished?.call(const MullaPaymentResult(MullaPaymentOutcome.cancelled)),
                  ),
                MullaReady() || MullaPaying() => _Form(controller: c, strings: strings, view: widget),
                MullaAwaitingApproval(:final phoneNumber) => MullaPaymentStatusView(
                    icon: Icons.phonelink_ring,
                    color: theme.selectedProviderColor,
                    title: strings.approveTitle,
                    body: strings.approveBody.replaceAll('{phone}', phoneNumber),
                    footnote: strings.dialHint,
                    busy: true,
                  ),
                MullaSucceeded(:final reference) => MullaPaymentStatusView(
                    icon: Icons.check_circle,
                    color: theme.successColor,
                    title: strings.successTitle,
                    body: strings.successBody,
                    footnote: reference == null ? null : '${strings.reference}: $reference',
                    actionLabel: strings.done,
                    onAction: () => widget.onFinished?.call(MullaPaymentResult.fromState(state)),
                  ),
                MullaFailed(:final reason) => MullaPaymentStatusView(
                    icon: Icons.cancel,
                    color: theme.errorColor,
                    title: strings.failedTitle,
                    body: reason ?? strings.failedBody,
                    actionLabel: strings.done,
                    onAction: () => widget.onFinished?.call(MullaPaymentResult.fromState(state)),
                  ),
                MullaExpired() => MullaPaymentStatusView(
                    icon: Icons.timer_off_outlined,
                    color: theme.errorColor,
                    title: strings.expiredTitle,
                    body: strings.expiredBody,
                    actionLabel: strings.done,
                    onAction: () => widget.onFinished?.call(MullaPaymentResult.fromState(state)),
                  ),
              },
            ),
          ),
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({required this.controller, required this.strings, required this.view});

  final MullaPaymentController controller;
  final MullaStrings strings;
  final MullaPaymentView view;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final theme = MullaCheckoutTheme.of(context);
    final textTheme = Theme.of(context).textTheme;
    final summary = c.summary;
    final paying = c.state is MullaPaying;
    final ready = c.state;
    final amount = formatAmount(summary?.amount, summary?.currency);

    String? fieldError;
    if (c.fieldError == 'invalidPhone') fieldError = strings.invalidPhone;
    if (c.fieldError == 'wrongNetwork') {
      fieldError = strings.wrongNetwork.replaceAll('{network}', c.provider?.label ?? '');
    }

    String? banner;
    if (ready is MullaReady && ready.previousAttemptFailed) banner = strings.failedBody;
    if (ready is MullaReady && ready.error != null) {
      banner = _message(ready.error!, strings);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (view.showSummary && summary != null) ...[
          if (summary.merchantName != null)
            Text(summary.merchantName!, style: textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(amount, style: theme.amountStyle, textAlign: TextAlign.center, key: const ValueKey('mulla-amount')),
          if (summary.reason != null) ...[
            const SizedBox(height: 4),
            Text(summary.reason!, style: textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
          const SizedBox(height: 24),
        ],
        if (banner != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.errorColor.withValues(alpha: 0.08),
              borderRadius: theme.borderRadius,
            ),
            child: Text(banner, style: textTheme.bodyMedium?.copyWith(color: theme.errorColor)),
          ),
          const SizedBox(height: 16),
        ],
        Text(strings.chooseNetwork, style: textTheme.labelLarge),
        const SizedBox(height: 8),
        MullaProviderPicker(value: c.provider, onChanged: c.selectProvider, enabled: !paying),
        const SizedBox(height: 16),
        MullaPhoneField(
          value: c.phoneNumber,
          onChanged: c.setPhoneNumber,
          label: strings.phoneNumber,
          hint: strings.phoneHint,
          errorText: fieldError,
          enabled: !paying,
          onSubmitted: c.canPay ? c.pay : null,
        ),
        const SizedBox(height: 24),
        MullaPayButton(
          label: amount.isEmpty ? strings.pay : '${strings.pay} $amount',
          loading: paying,
          onPressed: c.canPay ? c.pay : null,
        ),
        if (view.onCancel != null) ...[
          const SizedBox(height: 8),
          TextButton(onPressed: paying ? null : view.onCancel, child: Text(strings.cancel)),
        ],
      ],
    );
  }
}

/// A centred icon, title, text and optional action: used for every result screen.
class MullaPaymentStatusView extends StatelessWidget {
  const MullaPaymentStatusView({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.footnote,
    this.actionLabel,
    this.onAction,
    this.busy = false,
  });

  /// The large icon at the top.
  final IconData icon;

  /// Colour of the icon.
  final Color color;

  /// The heading.
  final String title;

  /// The explanation under the heading.
  final String body;

  /// Small print under the body.
  final String? footnote;

  /// Text of the button.
  final String? actionLabel;

  /// Called when the button is tapped; no button when null.
  final VoidCallback? onAction;

  /// Shows a progress indicator instead of the button.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 16),
          Text(title, style: textTheme.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(body, style: textTheme.bodyMedium, textAlign: TextAlign.center),
          if (busy) ...[
            const SizedBox(height: 24),
            const LinearProgressIndicator(),
          ],
          if (footnote != null) ...[
            const SizedBox(height: 16),
            Text(footnote!, style: textTheme.bodySmall, textAlign: TextAlign.center),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            MullaPayButton(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

String _message(Object error, MullaStrings strings) {
  if (error is ConnectionException) return strings.networkError;
  if (error is ApiServerException) return strings.unexpectedError;
  if (error is ApiException) {
    final text = error.message.replaceFirst(RegExp(r'^\[[A-Z_]+\]\s*'), '');
    final dash = text.indexOf(' — ');

    return dash == -1 ? text : text.substring(0, dash);
  }

  return strings.unexpectedError;
}
