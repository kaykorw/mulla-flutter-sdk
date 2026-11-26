import 'package:flutter/foundation.dart';
import 'package:mulla_dart/mulla_dart.dart';

/// What the customer is paying for, shown above the form.
@immutable
class MullaPaymentSummary {
  const MullaPaymentSummary({
    required this.amount,
    this.currency,
    this.reason,
    this.merchantName,
    this.reference,
    this.expiresAt,
    this.provider,
    this.phoneNumber,
  });

  /// Amount to pay, in whole francs.
  final num? amount;

  /// Currency code, such as `RWF`.
  final String? currency;

  /// What the payment is for, as your backend described it.
  final String? reason;

  /// The business being paid.
  final String? merchantName;

  /// Mulla's reference for this payment.
  final String? reference;

  /// When the session stops accepting payment.
  final DateTime? expiresAt;

  /// Prefilled network, when the session already has one.
  final Provider? provider;

  /// Prefilled phone number, when the session already has one.
  final String? phoneNumber;
}

/// The step the payment is at.
@immutable
sealed class MullaPaymentState {
  const MullaPaymentState();

  /// True once nothing more can happen (success, failure, expiry).
  bool get isFinal => false;
}

final class MullaLoading extends MullaPaymentState {
  const MullaLoading();
}

/// Could not load the session or invoice (bad token, network...).
final class MullaLoadError extends MullaPaymentState {
  const MullaLoadError(this.error, {required this.retryable});

  /// The exception that stopped loading.
  final Object error;

  /// True when trying again may work (network or server problem).
  final bool retryable;
}

/// Waiting for the customer to choose a network and enter a phone number.
final class MullaReady extends MullaPaymentState {
  const MullaReady({this.error, this.previousAttemptFailed = false});

  /// Why the previous attempt did not start, if there was one.
  final Object? error;

  /// True for an invoice whose last payment attempt failed (the customer may try again).
  final bool previousAttemptFailed;
}

final class MullaPaying extends MullaPaymentState {
  const MullaPaying();
}

/// The prompt was sent; waiting for the customer to approve it on their phone.
final class MullaAwaitingApproval extends MullaPaymentState {
  const MullaAwaitingApproval({required this.phoneNumber, required this.provider});

  /// The number the prompt was sent to.
  final String phoneNumber;

  /// The network the prompt was sent through.
  final Provider provider;
}

/// Paid. Confirm on your backend before fulfilling the order.
final class MullaSucceeded extends MullaPaymentState {
  const MullaSucceeded({this.reference});

  /// Mulla's reference for the payment.
  final String? reference;

  @override
  bool get isFinal => true;
}

/// Declined, cancelled or failed.
final class MullaFailed extends MullaPaymentState {
  const MullaFailed({this.reason});

  /// Mulla's explanation, when it gave one.
  final String? reason;

  @override
  bool get isFinal => true;
}

/// The customer did not approve in time.
final class MullaExpired extends MullaPaymentState {
  const MullaExpired();

  @override
  bool get isFinal => true;
}

enum MullaPaymentOutcome { succeeded, failed, expired, cancelled }

/// How a payment sheet ended. Confirm on your backend before fulfilling the order.
@immutable
class MullaPaymentResult {
  const MullaPaymentResult(this.outcome, {this.reference});

  /// How the sheet ended.
  final MullaPaymentOutcome outcome;

  /// Mulla's reference, for a successful payment.
  final String? reference;

  /// True when the customer paid.
  bool get isSuccessful => outcome == MullaPaymentOutcome.succeeded;

  /// The result matching a final [MullaPaymentState].
  static MullaPaymentResult fromState(MullaPaymentState state) => switch (state) {
        MullaSucceeded(:final reference) => MullaPaymentResult(MullaPaymentOutcome.succeeded, reference: reference),
        MullaFailed() => const MullaPaymentResult(MullaPaymentOutcome.failed),
        MullaExpired() => const MullaPaymentResult(MullaPaymentOutcome.expired),
        _ => const MullaPaymentResult(MullaPaymentOutcome.cancelled),
      };

  @override
  String toString() => 'MullaPaymentResult(${outcome.name}, reference: $reference)';
}
