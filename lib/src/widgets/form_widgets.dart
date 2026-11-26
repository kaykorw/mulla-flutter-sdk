// material_ui needs Flutter 3.47+; this package supports 3.27+. Switch once the minimum is 3.47.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mulla_dart/mulla_dart.dart';

import '../theme.dart';

/// Lets the customer pick MTN Mobile Money or Airtel Money.
class MullaProviderPicker extends StatelessWidget {
  const MullaProviderPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.providers = Provider.values,
    this.enabled = true,
  });

  /// The selected network.
  final Provider? value;

  /// Called with the network the customer taps.
  final ValueChanged<Provider> onChanged;

  /// The networks to offer.
  final List<Provider> providers;

  /// False to show the picker greyed out.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = MullaCheckoutTheme.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        for (final (i, provider) in providers.indexed) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              selected: provider == value,
              button: true,
              child: InkWell(
                key: ValueKey('mulla-provider-${provider.value}'),
                borderRadius: theme.borderRadius,
                onTap: enabled ? () => onChanged(provider) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: theme.borderRadius,
                    border: Border.all(
                      color: provider == value ? theme.selectedProviderColor : scheme.outlineVariant,
                      width: provider == value ? 2 : 1,
                    ),
                    color: provider == value ? theme.selectedProviderColor.withValues(alpha: 0.08) : null,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        provider == value ? Icons.radio_button_checked : Icons.radio_button_off,
                        size: 20,
                        color: provider == value ? theme.selectedProviderColor : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(provider.label, style: Theme.of(context).textTheme.bodyMedium),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class MullaPhoneField extends StatefulWidget {
  const MullaPhoneField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    required this.hint,
    this.errorText,
    this.enabled = true,
    this.onSubmitted,
  });

  /// The number to show.
  final String value;

  /// Called on every change.
  final ValueChanged<String> onChanged;

  /// The field label.
  final String label;

  /// Example number shown while empty.
  final String hint;

  /// Message shown under the field.
  final String? errorText;

  /// False to disable input.
  final bool enabled;

  /// Called when the keyboard's done key is pressed.
  final VoidCallback? onSubmitted;

  @override
  State<MullaPhoneField> createState() => _MullaPhoneFieldState();
}

class _MullaPhoneFieldState extends State<MullaPhoneField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(MullaPhoneField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        key: const ValueKey('mulla-phone'),
        controller: _controller,
        enabled: widget.enabled,
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumber],
        textInputAction: TextInputAction.done,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')), LengthLimitingTextInputFormatter(16)],
        onChanged: widget.onChanged,
        onSubmitted: (_) => widget.onSubmitted?.call(),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          errorText: widget.errorText,
          prefixIcon: const Icon(Icons.phone_iphone),
          border: OutlineInputBorder(borderRadius: MullaCheckoutTheme.of(context).borderRadius),
        ),
      );
}

class MullaPayButton extends StatelessWidget {
  const MullaPayButton({super.key, required this.label, required this.onPressed, this.loading = false});

  /// The button text.
  final String label;

  /// Called on tap; the button is disabled when null.
  final VoidCallback? onPressed;

  /// Shows a progress indicator instead of the label.
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          key: const ValueKey('mulla-pay'),
          onPressed: loading ? null : onPressed,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: MullaCheckoutTheme.of(context).borderRadius),
          ),
          child: loading
              ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
              : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      );
}
