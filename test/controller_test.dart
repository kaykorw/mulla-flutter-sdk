import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mulla_flutter/mulla_flutter.dart';
import 'package:mulla_flutter/testing.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MullaCheckoutController', () {
    test('load → pay → awaiting approval → succeeded over SSE', () async {
      final (client, fake) = fakeMullaPublicClient();
      fake
        ..pushJson(MullaFixtures.checkoutSession(amount: 5000))
        ..pushJson(MullaFixtures.checkoutSession(phoneNumber: '+250788000000', provider: 'MTN_RW'))
        ..pushEvents([
          {'checkout': 'cs_test_1', 'status': 'PENDING', 'reference': 'CHG-TEST-1'},
          {'checkout': 'cs_test_1', 'status': 'SUCCESSFUL', 'reference': 'CHG-TEST-1'},
        ], keepOpen: true);

      final c = MullaCheckoutController(client: client, sessionId: 'cs_test_1', token: 'tok_test');
      addTearDown(c.dispose);
      await c.load();
      expect(c.state, isA<MullaReady>());
      expect(c.summary!.amount, 5000);
      expect(c.summary!.merchantName, 'Test Shop');
      expect(fake.requests, hasLength(1), reason: 'load fetches the session once');

      c.setPhoneNumber('0788 000 000');
      expect(c.provider, Provider.mtnRw, reason: 'network detected from the number');
      await c.pay();
      expect(c.state, isA<MullaAwaitingApproval>());
      expect(fake.requests[1].url, endsWith('/checkout/cs_test_1/pay?token=tok_test'));

      await settle();
      expect(c.state, isA<MullaSucceeded>());
      expect((c.state as MullaSucceeded).reference, 'CHG-TEST-1');
      expect(MullaPaymentResult.fromState(c.state).isSuccessful, isTrue);
    });

    test('form errors never send a request', () async {
      final (client, fake) = fakeMullaPublicClient();
      fake.pushJson(MullaFixtures.checkoutSession());
      final c = MullaCheckoutController(client: client, sessionId: 'cs_test_1', token: 'tok_test');
      addTearDown(c.dispose);
      await c.load();

      c.selectProvider(Provider.mtnRw);
      c.setPhoneNumber('0700');
      await c.pay();
      expect(c.fieldError, 'invalidPhone');

      c.setPhoneNumber('0730000000');
      c.selectProvider(Provider.mtnRw);
      await c.pay();
      expect(c.fieldError, 'wrongNetwork');
      expect(c.state, isA<MullaReady>());
      fake.assertSentCount(1);
    });

    test('an API error while paying returns to the form with the error', () async {
      final (client, fake) = fakeMullaPublicClient();
      fake
        ..pushJson(MullaFixtures.checkoutSession())
        ..pushError(409, 'CHARGE_IN_PROGRESS', message: 'A payment is already in progress');
      final c = MullaCheckoutController(client: client, sessionId: 'cs_test_1', token: 'tok_test');
      addTearDown(c.dispose);
      await c.load();
      c.setPhoneNumber('0788000000');
      await c.pay();
      final state = c.state as MullaReady;
      expect(state.error, isA<ApiException>());
    });

    test('a cancelled or unexpected failure while paying returns to the form', () async {
      final (client, fake) = fakeMullaPublicClient();
      fake
        ..pushJson(MullaFixtures.checkoutSession())
        ..push(RequestCancelledException('cancelled'));
      final c = MullaCheckoutController(client: client, sessionId: 'cs_test_1', token: 'tok_test');
      addTearDown(c.dispose);
      await c.load();
      c.setPhoneNumber('0788000000');
      await c.pay();
      expect((c.state as MullaReady).error, isA<RequestCancelledException>());
    });

    test('an unexpected failure while loading shows a retryable error, not a spinner', () async {
      final (client, fake) = fakeMullaPublicClient();
      fake.push(Response(200, headers: const {'content-type': 'application/json'}, body: 'not json'));
      final c = MullaCheckoutController(client: client, sessionId: 'cs_test_1', token: 'tok_test');
      addTearDown(c.dispose);
      await c.load();
      expect(c.state, isA<MullaLoadError>());
      expect((c.state as MullaLoadError).retryable, isTrue);
    });

    test('closing the sheet while the prompt is being sent stops everything', () async {
      final (client, fake) = fakeMullaPublicClient();
      fake
        ..pushJson(MullaFixtures.checkoutSession())
        ..push((Request _) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));

          return Response(200,
              headers: const {'content-type': 'application/json'}, body: '{"id":"cs_test_1","status":"PENDING"}');
        });
      final c = MullaCheckoutController(client: client, sessionId: 'cs_test_1', token: 'tok_test');
      await c.load();
      c.setPhoneNumber('0788000000');
      final paying = c.pay();
      c.dispose();
      await paying;
      await settle();
      fake.assertSentCount(2); // No watch stream was opened after dispose.
    });

    test('a request that may have been sent waits for the outcome instead of failing', () async {
      final (client, fake) = fakeMullaPublicClient();
      fake
        ..pushJson(MullaFixtures.checkoutSession())
        ..pushConnectionError(requestMayHaveBeenSent: true)
        ..pushEvents([
          {'checkout': 'cs_test_1', 'status': 'FAILED'},
        ]);
      final c = MullaCheckoutController(client: client, sessionId: 'cs_test_1', token: 'tok_test');
      addTearDown(c.dispose);
      await c.load();
      c.setPhoneNumber('0788000000');
      await c.pay();
      expect(c.state, isA<MullaAwaitingApproval>());
      await settle();
      expect(c.state, isA<MullaFailed>());
    });

    test('a wrong token is a non-retryable load error', () async {
      final (client, fake) = fakeMullaPublicClient();
      fake.pushError(404, 'CHECKOUT_NOT_FOUND');
      final c = MullaCheckoutController(client: client, sessionId: 'cs_x', token: 'bad');
      addTearDown(c.dispose);
      await c.load();
      expect(c.state, isA<MullaLoadError>().having((s) => s.retryable, 'retryable', isFalse));
    });

    test('an already paid session opens on the success screen', () async {
      final (client, fake) = fakeMullaPublicClient();
      fake.pushJson(MullaFixtures.checkoutSession(status: 'SUCCESSFUL'));
      final c = MullaCheckoutController(client: client, sessionId: 'cs_test_1', token: 'tok_test');
      addTearDown(c.dispose);
      await c.load();
      expect(c.state, isA<MullaSucceeded>());
    });

    test('coming back to the app re-checks the session', () async {
      final (client, fake) = fakeMullaPublicClient();
      fake
        ..pushJson(MullaFixtures.checkoutSession())
        ..pushJson(MullaFixtures.checkoutSession())
        ..pushEvents([
          {'checkout': 'cs_test_1', 'status': 'PENDING'},
        ], keepOpen: true)
        ..pushJson(MullaFixtures.checkoutSession(status: 'SUCCESSFUL'));
      final c = MullaCheckoutController(client: client, sessionId: 'cs_test_1', token: 'tok_test');
      addTearDown(c.dispose);
      await c.load();
      c.setPhoneNumber('0788000000');
      await c.pay();
      await settle();
      expect(c.state, isA<MullaAwaitingApproval>());

      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await settle();
      expect(c.state, isA<MullaSucceeded>());
    });

    test('an expired session moves to Expired on its own', () async {
      final (client, fake) = fakeMullaPublicClient();
      fake
        ..pushJson(MullaFixtures.checkoutSession(expiresAt: DateTime.now().subtract(const Duration(seconds: 5))))
        ..pushJson(MullaFixtures.checkoutSession(status: 'EXPIRED'));
      final c = MullaCheckoutController(client: client, sessionId: 'cs_test_1', token: 'tok_test');
      addTearDown(c.dispose);
      await c.load();
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      expect(c.state, isA<MullaExpired>());
    });
  });

  group('MullaInvoicePaymentController', () {
    test('a failed attempt lets the customer try again, then the invoice is paid', () async {
      final (client, fake) = fakeMullaPublicClient();
      fake
        ..pushJson(MullaFixtures.invoice(total: 12000))
        ..pushJson({
          'payment': {'id': 'p1', 'transaction_id': 'tx1', 'status': 'PENDING'},
        })
        ..pushEvents([
          {'invoice': 'inv_test_1', 'status': 'ISSUED', 'payment_status': 'PENDING', 'transaction_id': 'tx1'},
          {'invoice': 'inv_test_1', 'status': 'ISSUED', 'payment_status': 'FAILED', 'transaction_id': 'tx1'},
        ], keepOpen: true)
        ..pushJson({
          'payment': {'id': 'p2', 'transaction_id': 'tx2', 'status': 'PENDING'},
        })
        ..pushEvents([
          {'invoice': 'inv_test_1', 'status': 'ISSUED', 'payment_status': 'FAILED', 'transaction_id': 'tx1'},
          {'invoice': 'inv_test_1', 'status': 'PAID', 'payment_status': 'SUCCESSFUL', 'transaction_id': 'tx2'},
        ]);

      final c = MullaInvoicePaymentController(client: client, invoiceId: 'inv_test_1');
      addTearDown(c.dispose);
      await c.load();
      expect(c.summary!.amount, 12000);

      c.setPhoneNumber('0788000000');
      await c.pay();
      await settle();
      expect(c.state, isA<MullaReady>().having((s) => s.previousAttemptFailed, 'failed', isTrue));

      await c.pay();
      await settle();
      expect(c.state, isA<MullaSucceeded>());
      expect(fake.requests.where((r) => r.url.endsWith('/invoice/inv_test_1/pay')), hasLength(2));
    });
  });

  test('formatAmount', () {
    expect(formatAmount(25000, 'RWF'), 'RWF 25,000');
    expect(formatAmount(1234567.5, null), 'RWF 1,234,567.50');
    expect(formatAmount(null, 'RWF'), '');
  });
}
