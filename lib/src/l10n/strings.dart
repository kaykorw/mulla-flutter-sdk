import 'package:flutter/widgets.dart';

/// Every text the widgets show.
@immutable
class MullaStrings {
  const MullaStrings({
    required this.payWith,
    required this.chooseNetwork,
    required this.phoneNumber,
    required this.phoneHint,
    required this.invalidPhone,
    required this.wrongNetwork,
    required this.pay,
    required this.paying,
    required this.approveTitle,
    required this.approveBody,
    required this.dialHint,
    required this.successTitle,
    required this.successBody,
    required this.failedTitle,
    required this.failedBody,
    required this.expiredTitle,
    required this.expiredBody,
    required this.loadErrorTitle,
    required this.networkError,
    required this.unexpectedError,
    required this.tryAgain,
    required this.done,
    required this.cancel,
    required this.reference,
    required this.amountDue,
  });

  /// Heading above the network picker.
  final String payWith;
  final String chooseNetwork;
  final String phoneNumber;
  final String phoneHint;

  /// Shown when the number is not a Rwandan mobile number.
  final String invalidPhone;

  /// `{network}` is replaced with the network name.
  final String wrongNetwork;
  final String pay;
  final String paying;
  final String approveTitle;

  /// `{phone}` is replaced with the phone number.
  final String approveBody;

  /// Help shown while waiting, when no prompt arrives.
  final String dialHint;
  final String successTitle;
  final String successBody;
  final String failedTitle;
  final String failedBody;
  final String expiredTitle;
  final String expiredBody;
  final String loadErrorTitle;
  final String networkError;

  /// Shown when something unexpected went wrong (details are not shown to customers).
  final String unexpectedError;
  final String tryAgain;
  final String done;
  final String cancel;
  final String reference;
  final String amountDue;

  /// English.
  static const en = MullaStrings(
    payWith: 'Pay with mobile money',
    chooseNetwork: 'Network',
    phoneNumber: 'Phone number',
    phoneHint: '078 123 4567',
    invalidPhone: 'Enter a valid MTN or Airtel number',
    wrongNetwork: 'This number is not on {network}',
    pay: 'Pay',
    paying: 'Sending request…',
    approveTitle: 'Approve on your phone',
    approveBody: 'We sent a payment request to {phone}. Enter your PIN on your phone to confirm.',
    dialHint:
        'No prompt? Check that your phone is on and has signal, then open your mobile money menu to see pending approvals.',
    successTitle: 'Payment successful',
    successBody: 'Thank you. Your payment has been received.',
    failedTitle: 'Payment failed',
    failedBody: 'The payment was declined or cancelled. No money was taken.',
    expiredTitle: 'Payment expired',
    expiredBody: 'The request was not approved in time. Please start again.',
    loadErrorTitle: 'Could not load this payment',
    networkError: 'Check your internet connection and try again.',
    unexpectedError: 'Something went wrong. Please try again.',
    tryAgain: 'Try again',
    done: 'Done',
    cancel: 'Cancel',
    reference: 'Reference',
    amountDue: 'Amount due',
  );

  /// French.
  static const fr = MullaStrings(
    payWith: 'Payer par mobile money',
    chooseNetwork: 'Réseau',
    phoneNumber: 'Numéro de téléphone',
    phoneHint: '078 123 4567',
    invalidPhone: 'Saisissez un numéro MTN ou Airtel valide',
    wrongNetwork: "Ce numéro n'est pas sur {network}",
    pay: 'Payer',
    paying: 'Envoi de la demande…',
    approveTitle: 'Confirmez sur votre téléphone',
    approveBody: 'Une demande de paiement a été envoyée au {phone}. Saisissez votre code PIN pour confirmer.',
    dialHint:
        'Pas de message ? Vérifiez que votre téléphone est allumé et a du réseau, puis ouvrez le menu mobile money pour voir les demandes en attente.',
    successTitle: 'Paiement réussi',
    successBody: 'Merci. Votre paiement a bien été reçu.',
    failedTitle: 'Paiement échoué',
    failedBody: "Le paiement a été refusé ou annulé. Aucun montant n'a été débité.",
    expiredTitle: 'Paiement expiré',
    expiredBody: "La demande n'a pas été confirmée à temps. Veuillez recommencer.",
    loadErrorTitle: 'Impossible de charger ce paiement',
    networkError: 'Vérifiez votre connexion internet et réessayez.',
    unexpectedError: 'Une erreur est survenue. Veuillez réessayer.',
    tryAgain: 'Réessayer',
    done: 'Terminé',
    cancel: 'Annuler',
    reference: 'Référence',
    amountDue: 'Montant dû',
  );

  static const rw = MullaStrings(
    payWith: 'Kwishyura na mobile money',
    chooseNetwork: 'Umuyoboro',
    phoneNumber: 'Nimero ya telefoni',
    phoneHint: '078 123 4567',
    invalidPhone: 'Andika nimero ya MTN cyangwa Airtel yemewe',
    wrongNetwork: 'Iyi nimero ntabwo ari iya {network}',
    pay: 'Ishyura',
    paying: 'Kohereza ubusabe…',
    approveTitle: 'Emeza kuri telefoni yawe',
    approveBody:
        'Twohereje ubusabe bwo kwishyura kuri {phone}. Andika umubare w\'ibanga kuri telefoni yawe kugira ngo wemeze.',
    dialHint:
        'Nta butumwa wabonye? Reba ko telefoni yawe ifunguye kandi ifite rezo, hanyuma ufungure menu ya mobile money urebe ibyo utaremeza.',
    successTitle: 'Kwishyura byagenze neza',
    successBody: 'Murakoze. Ubwishyu bwanyu bwakiriwe.',
    failedTitle: 'Kwishyura byanze',
    failedBody: 'Ubwishyu bwanzwe cyangwa bwahagaritswe. Nta mafaranga yakuweho.',
    expiredTitle: 'Igihe cyarangiye',
    expiredBody: 'Ubusabe ntibwemejwe ku gihe. Ongera utangire.',
    loadErrorTitle: 'Ntibyashobotse gufungura ubu bwishyu',
    networkError: 'Reba interineti yawe hanyuma wongere ugerageze.',
    unexpectedError: 'Habaye ikibazo. Ongera ugerageze.',
    tryAgain: 'Ongera ugerageze',
    done: 'Byarangiye',
    cancel: 'Hagarika',
    reference: 'Indango',
    amountDue: 'Amafaranga yo kwishyura',
  );

  static const sw = MullaStrings(
    payWith: 'Lipa kwa pesa ya simu',
    chooseNetwork: 'Mtandao',
    phoneNumber: 'Namba ya simu',
    phoneHint: '078 123 4567',
    invalidPhone: 'Weka namba sahihi ya MTN au Airtel',
    wrongNetwork: 'Namba hii si ya {network}',
    pay: 'Lipa',
    paying: 'Inatuma ombi…',
    approveTitle: 'Thibitisha kwenye simu yako',
    approveBody: 'Tumetuma ombi la malipo kwa {phone}. Weka PIN yako kwenye simu ili kuthibitisha.',
    dialHint:
        'Hukupata ujumbe? Hakikisha simu yako imewashwa na ina mtandao, kisha fungua menyu ya pesa ya simu kuona maombi yanayosubiri.',
    successTitle: 'Malipo yamefanikiwa',
    successBody: 'Asante. Malipo yako yamepokelewa.',
    failedTitle: 'Malipo yameshindikana',
    failedBody: 'Malipo yamekataliwa au kusitishwa. Hakuna pesa iliyokatwa.',
    expiredTitle: 'Muda umeisha',
    expiredBody: 'Ombi halikuthibitishwa kwa wakati. Tafadhali anza tena.',
    loadErrorTitle: 'Imeshindwa kupakia malipo haya',
    networkError: 'Angalia muunganisho wa intaneti kisha ujaribu tena.',
    unexpectedError: 'Hitilafu imetokea. Tafadhali jaribu tena.',
    tryAgain: 'Jaribu tena',
    done: 'Imekamilika',
    cancel: 'Ghairi',
    reference: 'Kumbukumbu',
    amountDue: 'Kiasi cha kulipa',
  );

  /// The texts for a language code, English when it is not supported.
  static MullaStrings forLanguageCode(String code) => switch (code) {
        'fr' => fr,
        'rw' => rw,
        'sw' => sw,
        _ => en,
      };

  /// Strings for the app's current locale (English when it is not supported).
  static MullaStrings of(BuildContext context) =>
      forLanguageCode(Localizations.maybeLocaleOf(context)?.languageCode ?? 'en');

  MullaStrings copyWith({
    String? payWith,
    String? chooseNetwork,
    String? phoneNumber,
    String? phoneHint,
    String? invalidPhone,
    String? wrongNetwork,
    String? pay,
    String? paying,
    String? approveTitle,
    String? approveBody,
    String? dialHint,
    String? successTitle,
    String? successBody,
    String? failedTitle,
    String? failedBody,
    String? expiredTitle,
    String? expiredBody,
    String? loadErrorTitle,
    String? networkError,
    String? unexpectedError,
    String? tryAgain,
    String? done,
    String? cancel,
    String? reference,
    String? amountDue,
  }) =>
      MullaStrings(
        payWith: payWith ?? this.payWith,
        chooseNetwork: chooseNetwork ?? this.chooseNetwork,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        phoneHint: phoneHint ?? this.phoneHint,
        invalidPhone: invalidPhone ?? this.invalidPhone,
        wrongNetwork: wrongNetwork ?? this.wrongNetwork,
        pay: pay ?? this.pay,
        paying: paying ?? this.paying,
        approveTitle: approveTitle ?? this.approveTitle,
        approveBody: approveBody ?? this.approveBody,
        dialHint: dialHint ?? this.dialHint,
        successTitle: successTitle ?? this.successTitle,
        successBody: successBody ?? this.successBody,
        failedTitle: failedTitle ?? this.failedTitle,
        failedBody: failedBody ?? this.failedBody,
        expiredTitle: expiredTitle ?? this.expiredTitle,
        expiredBody: expiredBody ?? this.expiredBody,
        loadErrorTitle: loadErrorTitle ?? this.loadErrorTitle,
        networkError: networkError ?? this.networkError,
        unexpectedError: unexpectedError ?? this.unexpectedError,
        tryAgain: tryAgain ?? this.tryAgain,
        done: done ?? this.done,
        cancel: cancel ?? this.cancel,
        reference: reference ?? this.reference,
        amountDue: amountDue ?? this.amountDue,
      );
}
