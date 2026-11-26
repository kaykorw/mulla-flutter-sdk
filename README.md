# Mulla for Flutter

<!-- x-release-please-start-version -->

> This guide applies to `mulla_flutter` **0.1.1** and the Mulla API **v1**.

<!-- x-release-please-end -->

Take **MTN Mobile Money** and **Airtel Money** payments in your Flutter app with [Mulla](https://mulla.app), the mobile money payment gateway for Rwanda. One function call opens a ready-made payment screen; your app never holds a secret key.

## What you can do

- **Open a payment screen in one call.** It shows the amount, asks for the network and phone number, sends the payment request to the customer's phone, waits for their approval and returns the result.
- **Keep your secret key safe.** Your server creates each payment; the app only receives a one-time pass for it.
- **Follow the payment live.** The status updates by itself, and is checked again as soon as the customer comes back from approving on their phone.
- **Match your app's look.** The screens use your app's theme. Texts come in English, French, Kinyarwanda and Swahili, and you can change any of them.
- **Build your own screens** with the same payment logic, if the ready-made ones don't fit.
- **Test without a network.** A fake Mulla server for your widget tests is included.

## How it works

A payment involves three parts: your app, your server, and Mulla.

```text
 Your app                        Your server                          Mulla
 ────────                        ───────────                          ─────
 Customer taps "Pay" ──────────► creates a payment page ───────────► returns id + token
                     ◄── id + token ──
 showMullaCheckout(id, token) ──────────────────────────────────────► sends a prompt to the phone
 customer approves on phone      ◄──────────────── live status ──────
 app shows the result            receives the "charge.success" ◄──── confirms the payment
                                 webhook, marks the order paid
```

1. **Your server** creates a payment page (a *checkout session*) with a Mulla server SDK and sends its `id` and `token` to the app.
2. **Your app** calls `showMullaCheckout`. The customer picks a network, enters their number and approves the prompt on their phone.
3. **Your server** marks the order paid when Mulla's `charge.success` webhook arrives.

> **Never put your secret key (`sk_…`) in the app.** Anyone can extract it from an app download and use it to move your money. This package doesn't need it.
>
> **Don't deliver an order because the app says it's paid.** The app's result is for showing the right screen. Your server confirms the payment with Mulla.

## Contents

- [Before you start](#before-you-start)
- [Install](#install)
- [Your first payment](#your-first-payment)
- [Guides](#guides)
  - [Open the payment screen](#open-the-payment-screen)
  - [Show the payment inside a page](#show-the-payment-inside-a-page)
  - [Pay an invoice](#pay-an-invoice)
  - [Handle the result](#handle-the-result)
  - [Build your own screen](#build-your-own-screen)
  - [Change colours and shapes](#change-colours-and-shapes)
  - [Change or translate texts](#change-or-translate-texts)
  - [Use a local or staging server](#use-a-local-or-staging-server)
  - [Test your app](#test-your-app)
  - [Go live](#go-live)
- [Reference](#reference)
- [Example app](#example-app)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Releasing](#releasing)
- [License](#license)

## Before you start

You need:

- **Flutter 3.27 or newer.** Android, iOS and web are supported.
- **A Mulla merchant account.**
- **A server that creates payment pages** with your secret key. Any Mulla server SDK works: [Dart](https://pub.dev/packages/mulla_dart), [Node](https://github.com/kaykorw/mulla-node-sdk), PHP or Laravel.
- **On Android, internet permission in release builds.** Flutter adds it to debug builds only. Add this line to `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:

  ```xml
  <uses-permission android:name="android.permission.INTERNET"/>
  ```

## Install

```bash
flutter pub add mulla_flutter
```

Then import it:

```dart
import 'package:mulla_flutter/mulla_flutter.dart';
```

## Your first payment

**1. Your server creates the payment page.** This example uses [`mulla_dart`](https://pub.dev/packages/mulla_dart) with shelf; every Mulla server SDK has the same `createCheckout` call.

```dart
final mulla = MullaClient(apiKey: Platform.environment['MULLA_SECRET_KEY']);

Future<Response> payOrder(Request request, String orderId) async {
  final order = await orders.find(orderId);
  final session = await mulla.charges.createCheckout(CreateCheckoutParams(
    amount: order.total, // RWF
    reason: 'Order #${order.id}',
    metadata: {'orderId': order.id},
    successUrl: 'https://shop.example/paid', // required by the API, used by the web checkout
    cancelUrl: 'https://shop.example/cart',
  ));
  return Response.ok(jsonEncode({'sessionId': session.id, 'token': session.token}));
}
```

**2. Your app opens the payment screen:**

```dart
final mulla = MullaPublicClient(environment: Environment.test); // Environment.production when live

Future<void> payOrder(BuildContext context, String orderId) async {
  final s = await myApi.post('/orders/$orderId/pay'); // your server from step 1

  final result = await showMullaCheckout(context, client: mulla, sessionId: s.sessionId, token: s.token);

  if (result.isSuccessful) {
    // Show a thank-you screen, then reload the order from your server.
  }
}
```

Create the `MullaPublicClient` once and reuse it. Its `environment` must match your server's key: `Environment.test` for `sk_test_` keys, `Environment.production` for `sk_live_` keys.

**3. Your server confirms the payment** when the `charge.success` webhook arrives, and marks the order paid. See [Get notified when a payment finishes](https://pub.dev/packages/mulla_dart#get-notified-when-a-payment-finishes) in the `mulla_dart` guide.

## Guides

### Open the payment screen

`showMullaCheckout` opens the payment in a bottom sheet and returns when it closes:

```dart
final result = await showMullaCheckout(context, client: mulla, sessionId: sessionId, token: token);
```

The customer goes through four steps:

```text
Amount and form ──► "Approve on your phone" ──► Payment successful
(network + number)                          └─► Payment failed / expired
```

The network is picked for them when the number shows it (078 and 079 are MTN, 072 and 073 are Airtel), and numbers can be typed in any common format.

### Show the payment inside a page

Use the `MullaCheckout` widget to place the payment in your own page instead of a sheet:

```dart
Scaffold(
  appBar: AppBar(title: const Text('Payment')),
  body: SingleChildScrollView(
    child: MullaCheckout(
      client: mulla,
      sessionId: sessionId,
      token: token,
      onFinished: (result) => Navigator.pop(context, result),
      onCancel: () => Navigator.pop(context),
    ),
  ),
);
```

`onFinished` runs when the customer taps **Done** on the result screen. Setting `onCancel` adds a cancel button to the form.

### Pay an invoice

An invoice needs no token: its id is enough. If an attempt fails, the invoice stays open and the customer can try again on the same screen.

```dart
final result = await showMullaInvoicePayment(context, client: mulla, invoiceId: invoiceId);
```

To place it in a page, use `MullaInvoicePayment(client: mulla, invoiceId: invoiceId)`.

### Handle the result

`showMullaCheckout` and `showMullaInvoicePayment` return a `MullaPaymentResult`:

| `result.outcome` | Meaning                                                     | What to do                                 |
| ---------------- | ----------------------------------------------------------- | ------------------------------------------ |
| `succeeded`      | The customer paid. `result.reference` is Mulla's reference  | Show a thank-you screen; reload the order  |
| `failed`         | Declined, wrong PIN or not enough money. No money was taken | Offer to try again                         |
| `expired`        | The customer didn't approve in time                         | Create a new payment page to try again     |
| `cancelled`      | The customer closed the screen before the end               | Ask your server; they may have paid anyway |

A customer can close the sheet while approving on their phone, and still pay. So treat `cancelled` as "unknown", and let your server, which gets Mulla's webhook, decide.

### Build your own screen

The controllers run the whole payment without any UI. They're `ChangeNotifier`s, so any widget can listen to them:

```dart
final controller = MullaCheckoutController(client: mulla, sessionId: id, token: token)..load();

ListenableBuilder(
  listenable: controller,
  builder: (context, _) => switch (controller.state) {
    MullaLoading() => const CircularProgressIndicator(),
    MullaLoadError(:final error) => Text('Could not load: $error'),
    MullaReady() || MullaPaying() => MyForm(
        provider: controller.provider,
        phone: controller.phoneNumber,
        error: controller.fieldError, // 'invalidPhone' or 'wrongNetwork'
        onNetwork: controller.selectProvider,
        onPhone: controller.setPhoneNumber,
        onPay: controller.canPay ? controller.pay : null,
      ),
    MullaAwaitingApproval(:final phoneNumber) => Text('Approve on $phoneNumber'),
    MullaSucceeded() => const Text('Paid'),
    MullaFailed() => const Text('Declined'),
    MullaExpired() => const Text('Expired'),
  },
);
```

Call `controller.dispose()` when your widget is removed. For invoices, use `MullaInvoicePaymentController(client: mulla, invoiceId: id)`.

You can also reuse the pieces of the ready-made screen: `MullaProviderPicker`, `MullaPhoneField`, `MullaPayButton`, `MullaPaymentStatusView`, or the whole flow as `MullaPaymentView(controller: controller)`.

To skip widgets and controllers entirely, `MullaPublicClient` has `checkout.retrieve`, `checkout.pay` and `checkout.watch`. See the [`mulla_dart`](https://pub.dev/packages/mulla_dart) guide.

### Change colours and shapes

The screens use your app's `ColorScheme` and text theme. To adjust them, add a `MullaCheckoutTheme` to your theme:

```dart
MaterialApp(
  theme: ThemeData(
    colorSchemeSeed: Colors.indigo,
    extensions: const [
      MullaCheckoutTheme(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        successColor: Color(0xFF1B873F),
      ),
    ],
  ),
);
```

All options are listed under [Theme options](#theme-options).

### Change or translate texts

Texts follow the app's language: English (`en`), French (`fr`), Kinyarwanda (`rw`) and Swahili (`sw`). Any other language falls back to English. To change some texts, or always use one language:

```dart
MullaCheckout(..., strings: MullaStrings.fr.copyWith(pay: 'Régler'));
showMullaCheckout(context, ..., strings: MullaStrings.rw);
```

> The Kinyarwanda and Swahili texts haven't been reviewed by a native speaker yet. Check them before you go live, and change any text with `copyWith`.

### Use a local or staging server

Pass `baseUrl` to the client:

```dart
final mulla = MullaPublicClient(
  environment: Environment.test,
  baseUrl: 'http://10.0.2.2:3000/gateway', // the Android emulator's address for your computer
);
```

Plain `http://` works only for local addresses (`localhost`, `10.0.2.2`). Every other server must use HTTPS.

### Test your app

`package:mulla_flutter/testing.dart` gives you a client backed by a fake Mulla server, so widget tests never touch the network. Queue the responses your test needs, in order:

```dart
import 'package:mulla_flutter/testing.dart';

testWidgets('pays an order', (tester) async {
  final (client, fake) = fakeMullaPublicClient();
  fake
    ..pushJson(MullaFixtures.checkoutSession(amount: 5000)) // loading the payment page
    ..pushJson(MullaFixtures.checkoutSession()) // sending the payment request
    ..pushEvents([{'checkout': 'cs_test_1', 'status': 'SUCCESSFUL'}]); // the live status

  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: MullaCheckout(client: client, sessionId: 'cs_test_1', token: 'tok')),
  ));
  // Enter a number, tap Pay, then expect 'Payment successful'.
});
```

### Go live

Before switching to real money:

- [ ] The app uses `Environment.production`, and your server uses a live key (`sk_live_…`).
- [ ] The secret key exists only on your server, never in the app or its source code.
- [ ] Your server marks orders paid only after Mulla's webhook or a status check, never because the app said so.
- [ ] Android release builds have the `INTERNET` permission.
- [ ] A native speaker has checked the Kinyarwanda and Swahili texts, if you use them.

## Reference

### Widgets and functions

| Name                                                                                 | What it does                                                        |
| ------------------------------------------------------------------------------------ | ------------------------------------------------------------------- |
| `showMullaCheckout(context, client:, sessionId:, token:)`                            | Opens the payment in a bottom sheet; returns a `MullaPaymentResult` |
| `showMullaInvoicePayment(context, client:, invoiceId:)`                              | Opens an invoice payment in a bottom sheet                          |
| `MullaCheckout`, `MullaInvoicePayment`                                               | The same payments as widgets for your own pages                     |
| `MullaCheckoutController`, `MullaInvoicePaymentController`                           | The payment logic without UI                                        |
| `MullaPaymentView`                                                                   | The full ready-made screen for any controller                       |
| `MullaProviderPicker`, `MullaPhoneField`, `MullaPayButton`, `MullaPaymentStatusView` | Pieces of the ready-made screen                                     |
| `MullaCheckoutTheme`, `MullaStrings`                                                 | Colours, shapes and texts                                           |
| `normalizePhoneNumber`, `providerForPhoneNumber`, `isRwandanMobileNumber`            | Phone number helpers (`0788 000 000` → `+250788000000`)             |

### Client options

`MullaPublicClient(...)` takes these named parameters:

| Option        | Default             | What it does                                                                      |
| ------------- | ------------------- | --------------------------------------------------------------------------------- |
| `environment` | Required            | `Environment.test` or `Environment.production`; must match your server's key.     |
| `baseUrl`     | Mulla's servers     | Another server, such as a local one.                                              |
| `lang`        | Mulla's default     | Language of Mulla's error messages: `Language.en`, `fr`, `rw` or `sw`.            |
| `timeout`     | 30 seconds          | Time limit for each request.                                                      |
| `maxRetries`  | `2`                 | Extra attempts for requests that are safe to repeat.                              |
| `deviceId`    | New for each client | A UUID v4 identifying the device; store one to keep it stable.                    |
| `appInfo`     | None                | Your app's name and version, such as `AppInfo(name: 'my-app', version: '2.1.0')`. |
| `httpClient`  | `http.Client()`     | Your own `package:http` client, such as `cronet_http` or `cupertino_http`.        |

### Controller

| Member                     | What it does                                                          |
| -------------------------- | --------------------------------------------------------------------- |
| `load()`                   | Loads the payment page or invoice. The ready-made widgets call it.    |
| `state`                    | The current step (see [States](#states)).                             |
| `summary`                  | Amount, currency, reason and merchant, once loaded.                   |
| `selectProvider(provider)` | Chooses the network.                                                  |
| `setPhoneNumber(text)`     | Updates the number, and picks the network when the number shows it.   |
| `fieldError`               | `'invalidPhone'` or `'wrongNetwork'` after a refused `pay()`.         |
| `canPay`                   | True when the form is complete and no payment is running.             |
| `pay()`                    | Sends the payment request to the phone.                               |
| `refresh()`                | Checks the status again. Also runs when the app returns to the front. |
| `retry()`                  | Tries loading again after `MullaLoadError`.                           |

### States

| State                   | Meaning                                                                               |
| ----------------------- | ------------------------------------------------------------------------------------- |
| `MullaLoading`          | Loading the payment page or invoice.                                                  |
| `MullaLoadError`        | Couldn't load it. `retryable` is true for network or server problems.                 |
| `MullaReady`            | Waiting for the network and number. `error` says why a previous attempt didn't start. |
| `MullaPaying`           | Sending the payment request.                                                          |
| `MullaAwaitingApproval` | The request reached the phone; waiting for the customer's PIN.                        |
| `MullaSucceeded`        | Paid. `reference` is Mulla's reference.                                               |
| `MullaFailed`           | Declined or cancelled. No money was taken.                                            |
| `MullaExpired`          | The customer didn't approve in time.                                                  |

If the connection drops just after **Pay** and the request may have reached Mulla, the controller moves to `MullaAwaitingApproval` and waits for the real outcome. It never lets the customer send a second request for the same payment.

### Theme options

| `MullaCheckoutTheme` option | Default                     | What it changes                 |
| --------------------------- | --------------------------- | ------------------------------- |
| `borderRadius`              | 12                          | Corners of cards and buttons    |
| `successColor`              | Green                       | The success screen              |
| `errorColor`                | Your `ColorScheme.error`    | Errors and the failure screen   |
| `selectedProviderColor`     | Your `ColorScheme.primary`  | The selected network            |
| `amountStyle`               | Your `headlineMedium`, bold | The amount                      |
| `padding`                   | 20 on every side            | Space around the payment screen |

## Example app

The [example](example) folder has a complete app with a **demo mode** that needs no account: a fake server inside the app approves MTN numbers and declines Airtel numbers. It also pays real sandbox payment pages created by your server.

```bash
cd example
flutter run
```

## Troubleshooting

| Problem                                              | Likely cause and fix                                                                                     |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| "Could not load this payment" right away             | A wrong id or token, or the app's `environment` doesn't match your server's key (test or live).          |
| Works in debug, fails in an Android release build    | Add the `INTERNET` permission to `AndroidManifest.xml`.                                                  |
| Can't reach a local server from the Android emulator | Use `http://10.0.2.2:<port>`, not `localhost`.                                                           |
| The status only changes every few seconds on the web | Expected: browsers can't keep the live connection open, so the package checks every 3 seconds instead.   |
| The customer approved, but the app still waits       | It checks again when the app comes back to the front. Your server's webhook is the reliable answer.      |
| The result is `cancelled`, but the order is paid     | The customer closed the screen while approving on their phone. Confirm payments on your server.          |
| The customer gets no prompt                          | The phone is off or has no signal. They can also open their mobile money menu to find pending approvals. |

## Contributing

```bash
flutter pub get          # pubspec_overrides.yaml points at ../mulla-dart while developing
dart format --set-exit-if-changed lib test example/lib
flutter analyze
flutter test
cd example && flutter run   # demo mode needs no account
```

CI uses the published `mulla_dart` from pub.dev, because `pubspec_overrides.yaml` isn't committed. A change that needs a new `mulla_dart` feature can only pass CI after that `mulla_dart` version is published.

Write commit messages as [Conventional Commits](https://www.conventionalcommits.org), because the changelog is built from them.

## Releasing

Releases are automated with [release-please](https://github.com/googleapis/release-please):

1. Every push to `main` updates a release pull request. It bumps the version in `pubspec.yaml` and this README, and adds the new entries to `CHANGELOG.md`.
2. Merging that pull request creates the `vX.Y.Z` tag and the GitHub release.
3. The tag runs `.github/workflows/publish.yml`, which tests the package and publishes it to pub.dev.

How the next version is chosen: release-please reads the commit messages on `main` since the last release.

| Commit message starts with                     | Next version (while below 1.0) | Shows in the changelog |
| ---------------------------------------------- | ------------------------------ | ---------------------- |
| `fix:`                                         | 0.1.0 → 0.1.1                  | Yes, under Bug Fixes   |
| `feat:`                                        | 0.1.0 → 0.2.0                  | Yes, under Features    |
| `feat!:` or a `BREAKING CHANGE:` footer        | 0.1.0 → 0.2.0                  | Yes, flagged breaking  |
| `docs:`, `test:`, `ci:`, `chore:`, `refactor:` | No release on its own          | No                     |

Pull requests are squash-merged, so the pull request title becomes the commit message. The `PR title` check rejects titles that don't follow this format.

This package requires `mulla_dart ^0.1.1`. When `mulla_dart` moves to a new minor version (0.1 → 0.2), update that line in `pubspec.yaml` by hand with a `fix:` or `feat:` commit; release-please can't do it across repositories.

One-time setup:

1. Create the public GitHub repository `kaykorw/mulla-flutter-sdk` and push this folder to it. pub.dev checks that the repository link works.
2. Publish the first version by hand, since pub.dev can only enable automated publishing for a package that already exists. Move `pubspec_overrides.yaml` aside first, so you test against the published `mulla_dart`, then run `flutter pub publish`. Then tag that commit so release-please knows where to start: `git tag v0.1.0 && git push origin v0.1.0`.
3. On pub.dev, open the package's **Admin** tab and enable **Automated publishing** from GitHub Actions for `kaykorw/mulla-flutter-sdk`, with the tag pattern `v{{version}}`.
4. In the GitHub repository, add a `RELEASE_PLEASE_TOKEN` secret: a token owned by `kaykorw` with read and write access to contents, pull requests, issues and workflows. Tags created with the default `GITHUB_TOKEN` don't start other workflows.

## License

MIT. See [LICENSE](LICENSE).
