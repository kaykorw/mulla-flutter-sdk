# Changelog

## 0.1.0

- First release: `showMullaCheckout` / `MullaCheckout`, `showMullaInvoicePayment` / `MullaInvoicePayment`, checkout and invoice controllers, building-block widgets, `MullaCheckoutTheme`, texts in English, French, Kinyarwanda and Swahili, and testing helpers.
- The controller never stays stuck on loading or paying: any failure returns to a retryable error or the form.
- Closing the sheet mid-payment stops all network work and timers.
- Customers see a plain `unexpectedError` text instead of technical error details.
- Re-exports `ApiServerException`, `InvalidArgumentException`, `RateLimitException` and `RequestCancelledException`.
