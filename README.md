# Mulla for Flutter

<!-- x-release-please-start-version -->

> This guide applies to `mulla_flutter` **0.1.0** and the Mulla API **v1**.

<!-- x-release-please-end -->

Accept **MTN Mobile Money** and **Airtel Money** in your Flutter app with Mulla, the mobile money payment gateway for Rwanda.

- **Ready-made checkout:** one call opens a sheet that shows the amount and asks for the network and phone number. It sends the payment prompt, waits for the customer to approve on their phone, and returns the result.
- **No secret in your app.** Your backend creates the payment; the app only gets a one-session token.
- **Live status:** updates arrive over server-sent events. If streaming isn't available (web) the SDK polls instead, and it re-checks when the customer returns from approving on their phone.
- **Yours to style:** it follows your `ThemeData`. Texts come in English, French, Kinyarwanda and Swahili, or you can supply your own. To build a fully custom UI, use the controllers on their own.

<p align="center"><i>Amount → network + phone → "Approve on your phone" → Payment successful</i></p>

## Contents

- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Guides](#guides): [Embed the checkout](#embed-the-checkout-in-a-page) · [Invoices](#pay-an-invoice) · [Custom UI](#build-your-own-ui) · [Theme and texts](#theme-and-texts) · [Testing](#test-your-app)
- [Reference](#reference)
- [Troubleshooting](#troubleshooting)

## How it works

```text
 Flutter app                    Your backend                         Mulla
 ───────────                    ────────────                         ─────
 "Pay" tapped ───────────────►  charges.createCheckout(...)  ──────► session
              ◄── id + token ─  (secret key, sk_...)         ◄────── id, token
 showMullaCheckout(id, token)  ─────────────────────────────────────► pay → prompt on phone
 waits for approval            ◄──────────────────── live status ────
 result to UI                   webhook "charge.success" ◄────────── confirms
                                marks the order paid
```

1. **Your backend** creates a checkout session with any Mulla server SDK ([Node](https://github.com/kaykorw/mulla-node-sdk), PHP, Laravel or [Dart](https://pub.dev/packages/mulla_dart)) and returns `session.id` and `session.token` to the app.
2. **The app** calls `showMullaCheckout`. The customer picks a network, enters a number and approves the prompt on their phone.
3. **Your backend** marks the order paid when the `charge.success` webhook arrives, or after checking with `charges.retrieve`.

> **Never put your secret key (`sk_...`) in the app.** Anyone can extract it from an app bundle, and it can move money. This package doesn't need it.
>
> **Don't fulfil orders based on the app result alone.** The result is for the UI. Your backend confirms the payment.

## Requirements

- Flutter 3.27 or newer (Dart 3.6). Android, iOS and web are supported.
- A Mulla merchant account, and a backend that can create checkout sessions.
- **Android:** the app needs internet permission. Flutter adds it to debug builds only, so add `<uses-permission android:name="android.permission.INTERNET"/>` to `android/app/src/main/AndroidManifest.xml` for release builds.

## Installation

```bash
flutter pub add mulla_flutter
```

## Quick start

**1. Backend** (Node shown here; every Mulla server SDK has `createCheckout`):

```ts
app.post('/orders/:id/pay', async (req, res) => {
  const order = await db.orders.find(req.params.id);
  const session = await mulla.charges.createCheckout({
    amount: order.total,
    reason: `Order #${order.id}`,
    metadata: { orderId: order.id },
    successUrl: 'https://shop.example/paid', // used by the web checkout; required by the API
    cancelUrl: 'https://shop.example/cart',
  });
  await db.orders.update(order.id, { mullaChargeId: session.charge });
  res.json({ sessionId: session.id, token: session.token });
});
```

**2. App:**

```dart
import 'package:mulla_flutter/mulla_flutter.dart';

final mulla = MullaPublicClient(environment: Environment.test); // Environment.production when live

Future<void> payOrder(BuildContext context, String orderId) async {
  final s = await myApi.post('/orders/$orderId/pay'); // your backend from step 1

  final result = await showMullaCheckout(context, client: mulla, sessionId: s.sessionId, token: s.token);

  if (result.isSuccessful) {
    // Show "thank you", then reload the order from your backend; it confirms via the webhook.
  }
}
```

`result.outcome` is `succeeded`, `failed`, `expired` or `cancelled` (the customer closed the sheet).

**3. Backend:** handle the `charge.success` webhook (see your server SDK's README) and mark the order paid.

## Guides

### Embed the checkout in a page

Use `MullaCheckout` instead of the bottom sheet:

```dart
Scaffold(
  appBar: AppBar(title: const Text('Payment')),
  body: SingleChildScrollView(
    child: MullaCheckout(
      client: mulla,
      sessionId: sessionId,
      token: token,
      onFinished: (result) => Navigator.pop(context, result),
    ),
  ),
);
```

### Pay an invoice

Invoices need no token: the invoice id is enough. A failed attempt leaves the invoice open, so the customer can try again.

```dart
final result = await showMullaInvoicePayment(context, client: mulla, invoiceId: invoiceId);
```

Or embed `MullaInvoicePayment(client: mulla, invoiceId: invoiceId)`.

### Build your own UI

The controllers hold the whole flow. They are `ChangeNotifier`s, so you can drive any UI with them:

```dart
final controller = MullaCheckoutController(client: mulla, sessionId: id, token: token)..load();

ListenableBuilder(
  listenable: controller,
  builder: (context, _) => switch (controller.state) {
    MullaLoading() => const CircularProgressIndicator(),
    MullaLoadError(:final error) => Text('Could not load: $error'),
    MullaReady() || MullaPaying() => MyForm(
        provider: controller.provider,            // controller.selectProvider(Provider.mtnRw)
        phone: controller.phoneNumber,            // controller.setPhoneNumber(text): detects the network
        error: controller.fieldError,             // 'invalidPhone' | 'wrongNetwork'
        onPay: controller.canPay ? controller.pay : null,
      ),
    MullaAwaitingApproval(:final phoneNumber) => Text('Approve on $phoneNumber'),
    MullaSucceeded() => const Text('Paid'),
    MullaFailed() => const Text('Declined'),
    MullaExpired() => const Text('Expired'),
  },
);

// Dispose it with your widget: controller.dispose();
```

The building blocks used by the drop-in widgets are exported too: `MullaProviderPicker`, `MullaPhoneField`, `MullaPayButton`, `MullaPaymentStatusView` and `MullaPaymentView`.

If you'd rather skip widgets entirely, `MullaPublicClient` gives you `checkout.retrieve`, `checkout.pay` and `checkout.watch` (a `Stream` of status updates). See [`mulla_dart`](https://pub.dev/packages/mulla_dart).

### Theme and texts

The widgets use your `ColorScheme` and text theme. To adjust them, add a `MullaCheckoutTheme`:

```dart
ThemeData(
  colorSchemeSeed: Colors.indigo,
  extensions: const [
    MullaCheckoutTheme(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      successColor: Color(0xFF1B873F),
    ),
  ],
)
```

Texts follow the app locale (`en`, `fr`, `rw`, `sw`; anything else falls back to English). To change a text, or to force a language:

```dart
MullaCheckout(..., strings: MullaStrings.fr.copyWith(pay: 'Régler'));
showMullaCheckout(context, ..., strings: MullaStrings.rw);
```

> The Kinyarwanda and Swahili texts need review by a native speaker before production use. Override any string with `copyWith`.

### Test your app

`package:mulla_flutter/testing.dart` gives you a client that never touches the network:

```dart
import 'package:mulla_flutter/testing.dart';

testWidgets('pays an order', (tester) async {
  final (client, fake) = fakeMullaPublicClient();
  fake
    ..pushJson(MullaFixtures.checkoutSession(amount: 5000)) // load
    ..pushJson(MullaFixtures.checkoutSession())             // pay
    ..pushEvents([{'checkout': 'cs_test_1', 'status': 'SUCCESSFUL'}]); // live status

  await tester.pumpWidget(MaterialApp(home: Scaffold(body: MullaCheckout(client: client, sessionId: 'cs_test_1', token: 'tok'))));
  // ...enter a number, tap pay, expect 'Payment successful'
});
```

The example app (`example/`) has a **demo mode** with a fake API, so you can try the whole flow without an account.

## Reference

### Widgets and functions

| API                                                      | What it does                                                     |
| -------------------------------------------------------- | ---------------------------------------------------------------- |
| `showMullaCheckout(context, client:, sessionId:, token:)` | Bottom-sheet checkout; returns `MullaPaymentResult`.            |
| `showMullaInvoicePayment(context, client:, invoiceId:)`  | Bottom-sheet invoice payment.                                    |
| `MullaCheckout`, `MullaInvoicePayment`                   | The same flows as embeddable widgets (`onFinished`, `onCancel`). |
| `MullaCheckoutController`, `MullaInvoicePaymentController` | The flow without UI: `load`, `selectProvider`, `setPhoneNumber`, `pay`, `refresh`, `retry`. |
| `MullaPaymentView`                                       | Renders any controller.                                          |
| `MullaProviderPicker`, `MullaPhoneField`, `MullaPayButton`, `MullaPaymentStatusView` | Building blocks. |
| `MullaCheckoutTheme`, `MullaStrings`                     | Styling and texts.                                               |
| `normalizePhoneNumber`, `providerForPhoneNumber`, `isRwandanMobileNumber` | Phone helpers (`0788 000 000` → `+250788000000`). |

### `MullaPublicClient` options

| Option        | Default         | Description                                                                         |
| ------------- | --------------- | ----------------------------------------------------------------------------------- |
| `environment` | — (required)    | `Environment.test` (sandbox) or `Environment.production`. Must match the backend key. |
| `baseUrl`     | Official server | For a local gateway, e.g. `http://10.0.2.2:3000/gateway` from the Android emulator. |
| `lang`        | API default     | Language of API error messages.                                                     |
| `deviceId`    | Random per client | A UUID v4 you persist, sent as `x-device-id`.                                     |
| `appInfo`     | —               | `AppInfo(name: 'my-app', version: '2.1.0')`.                                        |
| `httpClient`  | `http.Client()` | E.g. `cronet_http` / `cupertino_http` clients.                                      |
| `timeout`, `maxRetries` | 30 s, 2 | As in `mulla_dart`.                                                             |

### States

| State                   | Meaning                                                        |
| ----------------------- | -------------------------------------------------------------- |
| `MullaLoading`          | Fetching the session or invoice.                               |
| `MullaLoadError`        | Bad id or token (`retryable: false`), or a network problem.    |
| `MullaReady`            | Waiting for network + phone; `error` explains a refused attempt. |
| `MullaPaying`           | Sending the request.                                           |
| `MullaAwaitingApproval` | Prompt sent; waiting for the customer's PIN.                   |
| `MullaSucceeded`        | Paid (`reference`).                                            |
| `MullaFailed`           | Declined or cancelled. No money was taken.                     |
| `MullaExpired`          | Not approved in time.                                          |

If the network fails just after "Pay" and the request may have reached Mulla, the controller goes to `MullaAwaitingApproval` and lets the live status settle the outcome. It doesn't let the customer send a second request.

## Troubleshooting

| Problem                                           | Likely cause and fix                                                                                    |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| "Could not load this payment" right away          | Wrong session id or token, or `environment` doesn't match the key your backend used (test vs live).     |
| Works in debug, not in a release Android build    | Add the `INTERNET` permission to `AndroidManifest.xml`.                                                  |
| Can't reach a local gateway from the emulator     | Use `http://10.0.2.2:<port>`, not `localhost`. Plain http is allowed only for local hosts.              |
| Status updates arrive every few seconds on web    | Expected: browsers buffer streamed responses, so the SDK polls every 3 s.                               |
| Customer approved but the app still waits         | It re-checks when the app returns to the foreground; your backend's webhook is the source of truth.     |
| `showMullaCheckout` returned `cancelled`, but the order is paid | The customer closed the sheet while approving on their phone. The app result is only for the UI: confirm on your backend. |

## Contributing

```bash
flutter pub get          # pubspec_overrides.yaml points at ../mulla-dart during development
dart format --set-exit-if-changed .
flutter analyze
flutter test
cd example && flutter run   # demo mode needs no account
```

Commits follow [Conventional Commits](https://www.conventionalcommits.org).

CI resolves `mulla_dart` from pub.dev (`pubspec_overrides.yaml` is gitignored), so the `mulla_dart` version in `pubspec.yaml` must be published before CI can pass.

## Releasing

Releases are automated with [release-please](https://github.com/googleapis/release-please):

1. Every push to `main` updates a release pull request. It bumps the version in `pubspec.yaml` and this README, and adds the new entries to `CHANGELOG.md`.
2. Merging that pull request creates the `vX.Y.Z` tag and the GitHub release.
3. The tag runs `.github/workflows/publish.yml`, which tests the package and publishes it to pub.dev.

How the next version is chosen: release-please reads the commit messages on `main` since the last release.

| Commit message starts with                      | Next version (while below 1.0) | Shows in the changelog |
| ----------------------------------------------- | ------------------------------ | ---------------------- |
| `fix:`                                          | 0.1.0 → 0.1.1                  | Yes, under Bug Fixes   |
| `feat:`                                         | 0.1.0 → 0.2.0                  | Yes, under Features    |
| `feat!:` or a `BREAKING CHANGE:` footer         | 0.1.0 → 0.2.0                  | Yes, flagged breaking  |
| `docs:`, `test:`, `ci:`, `chore:`, `refactor:`  | No release on its own          | No                     |

Pull requests are squash-merged, so the pull request title becomes the commit message. The `PR title` check rejects titles that don't follow this format.

When `mulla_dart` releases a new minor version (0.1 → 0.2), update the `mulla_dart` constraint in `pubspec.yaml` with a `fix:` or `feat:` commit; release-please can't do that across repositories.

One-time setup:

1. Publish [`mulla_dart`](https://pub.dev/packages/mulla_dart) first: this package depends on its released version.
2. Publish the first version of this package by hand, since pub.dev can only enable automated publishing for an existing package. Move `pubspec_overrides.yaml` aside first, so you test against the published `mulla_dart`, then run `flutter pub publish`. Then tag that commit so release-please knows where to start: `git tag v0.1.0 && git push origin v0.1.0`.
3. On pub.dev, open the package's **Admin** tab, enable **Automated publishing** from GitHub Actions for `kaykorw/mulla-flutter-sdk`, with the tag pattern `v{{version}}`.
4. In the GitHub repository, add a `RELEASE_PLEASE_TOKEN` secret (a personal access token with `contents` and `pull-requests` write access). Tags pushed with the default `GITHUB_TOKEN` don't start other workflows.

## License

MIT. See [LICENSE](LICENSE).
