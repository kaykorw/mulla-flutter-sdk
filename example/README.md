# mulla_flutter example

A small app that shows the Mulla checkout in action. It runs on Android, iOS and the web.

## Run it

```bash
cd example
flutter run
```

## What you can try

**Demo (no account needed).** Tap **Open demo checkout**. The app uses a fake Mulla server that runs inside the app, so nothing goes over the network:

- Enter any MTN number (078 or 079): the fake customer approves after 3 seconds, and you see the success screen.
- Enter an Airtel number (072 or 073): the payment is declined, and you see the failure screen.

**Sandbox (real test payment).** Create a checkout session on your backend with a test key (`sk_test_…`), then paste its id and token into the app and tap **Pay sandbox session**. To use a local Mulla server, fill in its address. From the Android emulator, use `http://10.0.2.2:<port>/gateway`.

## Where to look

Everything is in [lib/main.dart](lib/main.dart):

- `_demo()` and `_sandbox()` open the checkout with `showMullaCheckout`.
- `demoClient()` builds the fake server with `fakeMullaPublicClient()` from `package:mulla_flutter/testing.dart`. Your own tests can use it the same way.

See the [package README](../README.md) for the full guide.
