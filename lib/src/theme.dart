// material_ui needs Flutter 3.47+; this package supports 3.27+. Switch once the minimum is 3.47.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';

/// Visual settings for the Mulla widgets.
@immutable
class MullaCheckoutTheme extends ThemeExtension<MullaCheckoutTheme> {
  const MullaCheckoutTheme({
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.successColor,
    this.errorColor,
    this.selectedProviderColor,
    this.amountStyle,
    this.padding = const EdgeInsets.all(20),
  });

  /// Corner radius of cards and buttons.
  final BorderRadius borderRadius;

  /// Colour of the success screen.
  final Color? successColor;

  /// Colour of errors and the failure screen.
  final Color? errorColor;

  /// Highlight of the selected network.
  final Color? selectedProviderColor;

  /// Text style of the amount.
  final TextStyle? amountStyle;

  /// Space around the payment view.
  final EdgeInsets padding;

  /// The theme from context, with defaults filled in.
  static ResolvedMullaTheme of(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<MullaCheckoutTheme>() ?? const MullaCheckoutTheme();
    final scheme = theme.colorScheme;

    return ResolvedMullaTheme(
      borderRadius: ext.borderRadius,
      successColor: ext.successColor ?? Colors.green.shade600,
      errorColor: ext.errorColor ?? scheme.error,
      selectedProviderColor: ext.selectedProviderColor ?? scheme.primary,
      amountStyle: ext.amountStyle ??
          theme.textTheme.headlineMedium!.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      padding: ext.padding,
    );
  }

  @override
  MullaCheckoutTheme copyWith({
    BorderRadius? borderRadius,
    Color? successColor,
    Color? errorColor,
    Color? selectedProviderColor,
    TextStyle? amountStyle,
    EdgeInsets? padding,
  }) =>
      MullaCheckoutTheme(
        borderRadius: borderRadius ?? this.borderRadius,
        successColor: successColor ?? this.successColor,
        errorColor: errorColor ?? this.errorColor,
        selectedProviderColor: selectedProviderColor ?? this.selectedProviderColor,
        amountStyle: amountStyle ?? this.amountStyle,
        padding: padding ?? this.padding,
      );

  @override
  MullaCheckoutTheme lerp(MullaCheckoutTheme? other, double t) {
    if (other == null) return this;

    return MullaCheckoutTheme(
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t)!,
      successColor: Color.lerp(successColor, other.successColor, t),
      errorColor: Color.lerp(errorColor, other.errorColor, t),
      selectedProviderColor: Color.lerp(selectedProviderColor, other.selectedProviderColor, t),
      amountStyle: TextStyle.lerp(amountStyle, other.amountStyle, t),
      padding: EdgeInsets.lerp(padding, other.padding, t)!,
    );
  }
}

/// [MullaCheckoutTheme] with every value resolved.
@immutable
class ResolvedMullaTheme {
  const ResolvedMullaTheme({
    required this.borderRadius,
    required this.successColor,
    required this.errorColor,
    required this.selectedProviderColor,
    required this.amountStyle,
    required this.padding,
  });

  final BorderRadius borderRadius;
  final Color successColor;
  final Color errorColor;
  final Color selectedProviderColor;
  final TextStyle amountStyle;
  final EdgeInsets padding;
}

/// `RWF 25,000` (whole francs, thousands separated).
String formatAmount(num? amount, String? currency) {
  if (amount == null) return '';
  final whole = amount == amount.truncate();
  final text = whole ? amount.truncate().toString() : amount.toStringAsFixed(2);
  final parts = text.split('.');
  final digits = parts.first.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

  return '${currency ?? 'RWF'} ${parts.length > 1 ? '$digits.${parts[1]}' : digits}';
}
