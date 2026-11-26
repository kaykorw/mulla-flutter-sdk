# Changelog

## 0.1.1

- Builds cleanly on the latest Flutter, where `package:flutter/material.dart` is deprecated in favour of `material_ui`. The package keeps using `material.dart` so it still supports Flutter 3.27 and newer.
- CI now tests on the latest stable Flutter as well as the oldest supported version.

## 0.1.0

- First release: `showMullaCheckout` / `MullaCheckout`, `showMullaInvoicePayment` / `MullaInvoicePayment`, checkout and invoice controllers, building-block widgets, `MullaCheckoutTheme`, texts in English, French, Kinyarwanda and Swahili, and testing helpers.
- The controller never stays stuck on loading or paying: any failure returns to a retryable error or the form.
- Closing the sheet mid-payment stops all network work and timers.
- Customers see a plain `unexpectedError` text instead of technical error details.
- Requires `mulla_dart` 0.1.1 or newer.
- Documents every widget parameter, controller member and theme option.
- Re-exports `ApiServerException`, `InvalidArgumentException`, `RateLimitException` and `RequestCancelledException`.
