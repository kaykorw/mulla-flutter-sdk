import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mulla_dart/mulla_dart.dart';

import 'payment_state.dart';

/// Shared payment state machine; subclasses say how to load, pay and watch.
abstract class MullaPaymentController extends ChangeNotifier with WidgetsBindingObserver {
  /// Starts watching the app lifecycle, so the status is re-checked when the customer returns.
  MullaPaymentController() {
    WidgetsBinding.instance.addObserver(this);
  }

  MullaPaymentState _state = const MullaLoading();
  MullaPaymentSummary? _summary;
  Provider? _provider;
  String _phoneNumber = '';
  String? _fieldError;
  StreamSubscription<Object?>? _watch;
  Timer? _expiryTimer;
  bool _disposed = false;

  /// The current step; listen to the controller to rebuild when it changes.
  MullaPaymentState get state => _state;

  /// What the customer pays for, once loaded.
  MullaPaymentSummary? get summary => _summary;

  Provider? get provider => _provider;

  /// The phone number as typed so far.
  String get phoneNumber => _phoneNumber;

  /// Validation problem with the form (`invalidPhone` or `wrongNetwork`), shown under the field.
  String? get fieldError => _fieldError;

  /// True when a network and a phone number are filled in and no payment is running.
  bool get canPay => _state is MullaReady && _provider != null && _phoneNumber.trim().isNotEmpty;

  @protected
  Future<MullaPaymentSummary> fetchSummary();

  /// The current state from the server, or null while still payable and pending.
  @protected
  Future<MullaPaymentState?> fetchFinalState();

  /// Asks Mulla to send the payment prompt.
  @protected
  Future<void> startPayment(Provider provider, String phoneNumber);

  /// Live updates mapped to states; null entries mean "nothing changed yet".
  @protected
  Stream<MullaPaymentState?> watchStates();

  Future<void> load() async {
    _set(const MullaLoading());
    try {
      final summary = await fetchSummary();
      _summary = summary;
      _provider ??= summary.provider;
      if (_phoneNumber.isEmpty && summary.phoneNumber != null) {
        _phoneNumber = summary.phoneNumber!;
      }
      final finalState = await fetchFinalState();
      if (_disposed) return;
      _set(finalState ?? const MullaReady());
      if (finalState == null) _scheduleExpiry();
    } on ApiException catch (e) {
      _set(MullaLoadError(e, retryable: e is ApiServerException || e is RateLimitException));
    } on ConnectionException catch (e) {
      _set(MullaLoadError(e, retryable: true));
    } on InvalidArgumentException catch (e) {
      _set(MullaLoadError(e, retryable: false));
    } on Object catch (e) {
      _set(MullaLoadError(e, retryable: true));
    }
  }

  /// Chooses the network.
  void selectProvider(Provider provider) {
    _provider = provider;
    _fieldError = null;
    _notify();
  }

  /// Updates the phone number; the network is picked automatically when the number reveals it.
  void setPhoneNumber(String value) {
    _phoneNumber = value;
    _fieldError = null;
    final detected = providerForPhoneNumber(value);
    if (detected != null) {
      _provider = detected;
    }
    _notify();
  }

  Future<void> pay() async {
    if (_state is! MullaReady) return;
    final provider = _provider;
    final phone = normalizePhoneNumber(_phoneNumber);
    if (!isRwandanMobileNumber(phone)) {
      _fieldError = 'invalidPhone';
      _notify();

      return;
    }
    final detected = providerForPhoneNumber(phone);
    if (provider == null || (detected != null && detected != provider)) {
      _fieldError = 'wrongNetwork';
      _notify();

      return;
    }

    _set(const MullaPaying());
    try {
      await startPayment(provider, phone);
    } on ConnectionException catch (e) {
      if (!e.requestMayHaveBeenSent) {
        _set(MullaReady(error: e));

        return;
      }
    } on ApiException catch (e) {
      _set(MullaReady(error: e));

      return;
    } on Object catch (e) {
      _set(MullaReady(error: e));

      return;
    }
    if (_disposed) return;
    _set(MullaAwaitingApproval(phoneNumber: phone, provider: provider));
    _startWatching();
  }

  /// Checks the server again (also done when the app comes back to the foreground).
  Future<void> refresh() async {
    if (_state is! MullaAwaitingApproval) return;
    try {
      final latest = await fetchFinalState();
      if (latest != null) _apply(latest);
    } on Object {
      // Keep waiting: the stream or the next refresh will catch up.
    }
  }

  Future<void> retry() async {
    if (_state is MullaLoadError) await load();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refresh());
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_watch?.cancel());
    _expiryTimer?.cancel();
    super.dispose();
  }

  /// Moves to a new state reported by the server.
  @protected

  /// Moves to a new state reported by the server.
  void apply(MullaPaymentState state) => _apply(state);

  void _apply(MullaPaymentState next) {
    if (_disposed || _state.isFinal) return;
    if (next is MullaReady && _state is MullaAwaitingApproval) {
      unawaited(_watch?.cancel());
      _watch = null;
    }
    _set(next);
    if (next.isFinal) {
      unawaited(_watch?.cancel());
      _watch = null;
      _expiryTimer?.cancel();
    }
  }

  void _startWatching() {
    if (_disposed) return;
    unawaited(_watch?.cancel());
    _watch = watchStates().listen(
      (state) {
        if (state != null) _apply(state);
      },
      onError: (Object _) {
        // The SDK already falls back to polling; app-resume refreshes cover the rest.
      },
    );
  }

  void _scheduleExpiry() {
    final expiresAt = _summary?.expiresAt;
    if (expiresAt == null || _disposed) return;
    _expiryTimer?.cancel();
    final left = expiresAt.difference(DateTime.now());
    _expiryTimer = Timer(left.isNegative ? Duration.zero : left + const Duration(seconds: 2), () async {
      if (_state.isFinal) return;
      try {
        final latest = await fetchFinalState();
        _apply(latest ?? const MullaExpired());
      } on Object {
        _apply(const MullaExpired());
      }
    });
  }

  void _set(MullaPaymentState state) {
    _state = state;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }
}
