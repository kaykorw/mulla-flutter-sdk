// material_ui needs Flutter 3.47+; this package supports 3.27+. Switch once the minimum is 3.47.
// ignore: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mulla_flutter/mulla_flutter.dart';
import 'package:mulla_flutter/testing.dart';

Widget app(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('fr')],
      // ignore: deprecated_member_use
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('full checkout flow: amount, phone, pay, approve, success, done', (tester) async {
    final (client, fake) = fakeMullaPublicClient();
    fake
      ..pushJson(MullaFixtures.checkoutSession(amount: 25000))
      ..pushJson(MullaFixtures.checkoutSession(amount: 25000))
      ..pushEvents([
        {'checkout': 'cs_test_1', 'status': 'PENDING'},
      ], keepOpen: true);

    MullaPaymentResult? result;
    await tester.pumpWidget(app(MullaCheckout(
      client: client,
      sessionId: 'cs_test_1',
      token: 'tok_test',
      onFinished: (r) => result = r,
    )));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('RWF 25,000'), findsOneWidget);
    expect(find.text('Test Shop'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byKey(const ValueKey('mulla-pay'))).onPressed, isNull,
        reason: 'pay is disabled until a number is entered');

    await tester.enterText(find.byKey(const ValueKey('mulla-phone')), '0788 000 000');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('mulla-pay')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Approve on your phone'), findsOneWidget);
    expect(find.textContaining('+250788000000'), findsOneWidget);

    fake.pushJson(MullaFixtures.checkoutSession(status: 'SUCCESSFUL'));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Payment successful'), findsOneWidget);
    await tester.tap(find.text('Done'));
    expect(result?.outcome, MullaPaymentOutcome.succeeded);
    expect(result?.reference, 'CHG-TEST-1');
  });

  testWidgets('shows the invalid-number message under the field', (tester) async {
    final (client, fake) = fakeMullaPublicClient();
    fake.pushJson(MullaFixtures.checkoutSession());
    await tester.pumpWidget(app(MullaCheckout(client: client, sessionId: 'cs_test_1', token: 'tok_test')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const ValueKey('mulla-provider-MTN_RW')));
    await tester.enterText(find.byKey(const ValueKey('mulla-phone')), '0700');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('mulla-pay')));
    await tester.pump();

    expect(find.text('Enter a valid MTN or Airtel number'), findsOneWidget);
    fake.assertSentCount(1);
  });

  testWidgets('uses the app locale (French)', (tester) async {
    final (client, fake) = fakeMullaPublicClient();
    fake.pushError(404, 'CHECKOUT_NOT_FOUND', message: 'Checkout not found');
    await tester
        .pumpWidget(app(MullaCheckout(client: client, sessionId: 'cs_x', token: 'bad'), locale: const Locale('fr')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Impossible de charger ce paiement'), findsOneWidget);
    expect(find.text('Checkout not found'), findsOneWidget);
  });

  testWidgets('showMullaCheckout returns cancelled when the sheet is cancelled', (tester) async {
    final (client, fake) = fakeMullaPublicClient();
    fake.pushJson(MullaFixtures.checkoutSession());
    MullaPaymentResult? result;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async =>
              result = await showMullaCheckout(context, client: client, sessionId: 'cs_test_1', token: 'tok_test'),
          child: const Text('Checkout'),
        ),
      ),
    ));
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(result?.outcome, MullaPaymentOutcome.cancelled);
  });
}
