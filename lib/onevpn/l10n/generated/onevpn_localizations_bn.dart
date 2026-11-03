// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class OneVpnLocalizationsBn extends OneVpnLocalizations {
  OneVpnLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get onevpnFaq => 'প্রায়শই জিজ্ঞাসিত প্রশ্ন';

  @override
  String get onevpnTermsOfService => 'পরিষেবার শর্তাবলী';

  @override
  String get onevpnMenu => 'মেনু';

  @override
  String get onevpnUpgrade => 'আপগ্রেড করুন';

  @override
  String get onevpnUpgradeBannerTitle => 'প্রিমিয়ামে আপগ্রেড করুন';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'কোনো বিজ্ঞাপন নেই, সব লোকেশন ও আরও বেশি স্পিড';

  @override
  String get onevpnLogIn => 'লগ-ইন করুন';

  @override
  String get onevpnLogOut => 'লগ-আউট করুন';

  @override
  String get onevpnAccount => 'অ্যাকাউন্ট';

  @override
  String get onevpnContactUs => 'আমাদের সাথে যোগাযোগ করুন';

  @override
  String get onevpnRefundPolicy => 'রিফান্ড নীতি';

  @override
  String get onevpnSupport => 'সহায়তা';

  @override
  String get onevpnLanguage => 'ভাষা';

  @override
  String get onevpnLanguageSystem => 'সিস্টেম ডিফল্ট';

  @override
  String get onevpnPlanFree => 'ফ্রি প্ল্যান';

  @override
  String get onevpnPlanPremium => 'প্রিমিয়াম প্ল্যান';

  @override
  String get onevpnSelectLocation => 'লোকেশন বেছে নিন';

  @override
  String get onevpnDirectRegions => 'সরাসরি অঞ্চল';

  @override
  String get onevpnFree => 'ফ্রি';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · ফ্রি';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'অটোমেটিক · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'অটোমেটিক';

  @override
  String get onevpnStatusNoConnection => 'কোনও কানেকশন নেই';

  @override
  String get onevpnStatusConnectionFailed => 'কানেক্ট করা যায়নি';

  @override
  String get onevpnStatusUpdating => 'আপডেট হচ্ছে…';

  @override
  String get onevpnStatusMeasuring => 'সার্ভার পরীক্ষা করা হচ্ছে…';

  @override
  String get onevpnAutomaticSubtitle => 'উপলভ্যগুলির মধ্যে দ্রুততম';

  @override
  String get onevpnLocationsLoadFailed => 'আপনার লোকেশনগুলি লোড করা যায়নি।';

  @override
  String get onevpnLocationsUnavailable =>
      'এই মুহূর্তে কোনও লোকেশন উপলভ্য নেই।';

  @override
  String get onevpnDirectRegionsCardBody =>
      'কিছু সাইট শুধুমাত্র তখনই কাজ করে, যখন আপনি সেই সাইটের দেশ থেকেই কানেক্ট করেন। কোনও অঞ্চল বেছে নিলে, সেই অঞ্চলের সাইটগুলি VPN এড়িয়ে সরাসরি কানেক্ট হয়।';

  @override
  String onevpnSelectionReset(String location) {
    return '$location উপলভ্য নেই, তাই 1VPN ‘অটোমেটিক’ বেছে নিয়েছে।';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'বেছে নেওয়া লোকেশনটি উপলভ্য নেই, তাই 1VPN ‘অটোমেটিক’ বেছে নিয়েছে।';

  @override
  String onevpnReloadRolledBack(String location) {
    return '$location লোকেশনে পরিবর্তন করা যায়নি। আপনি এখনও আগের লোকেশনেই কানেক্ট আছেন।';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'পরিবর্তনটি প্রয়োগ করা যায়নি। আপনি এখনও আগের সেটিংসেই কানেক্ট আছেন।';

  @override
  String get onevpnDirectRegionsOff => 'বন্ধ (ডিফল্ট)';

  @override
  String get onevpnAllViaVpnSubtitle => 'সব ট্রাফিক টানেলের মাধ্যমে';

  @override
  String get onevpnRegionChina => 'চীন';

  @override
  String get onevpnFirstConnectTitle =>
      'কিছু অঞ্চল সরাসরি কানেক্ট করলে ভালো কাজ করে';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'চীন, রাশিয়া ও ইরানের মতো জায়গায় সবকিছু VPN এর মাধ্যমে পাঠালে স্থানীয় ব্যাঙ্কিং ও পেমেন্ট অ্যাপ কাজ না-ও করতে পারে।';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN আপনার বেছে নেওয়া অঞ্চলকে টানেলের বাইরে, আপনার আসল IP থেকে সরাসরি রাউট করতে পারে।';

  @override
  String get onevpnFirstConnectPointProtected =>
      'বাকি সবকিছু সুরক্ষিত থাকে। আপনি যেকোনও সময় এটি পরিবর্তন করতে পারবেন।';

  @override
  String get onevpnFirstConnectChooseRegion => 'সরাসরি অঞ্চল বেছে নিন';

  @override
  String get onevpnFirstConnectDismiss => 'এখন নয়';

  @override
  String get onevpnCensorshipWarning =>
      'সরকারি বিধিনিষেধের কারণে আপনার অঞ্চলে কিছু সার্ভার ব্লক থাকতে পারে। আমরা এটি সমাধানের জন্য কাজ করছি। আপনার বোঝাপড়ার জন্য ধন্যবাদ।';

  @override
  String get onevpnAlwaysOnTitle => 'সর্বদা-চালু VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      'অ্যাপ বন্ধ করলেও টানেল চালু থাকে। ডিভাইস রিস্টার্ট বা অ্যাপ আপডেটের পরে ‘সর্বদা-চালু VPN’ টানেলটি অটোমেটিক আবার কানেক্ট করে।';

  @override
  String get onevpnAlwaysOnStep1 =>
      'নিচের ‘VPN সেটিংস খুলুন’ বোতামে ট্যাপ করুন।';

  @override
  String get onevpnAlwaysOnStep2 =>
      'তালিকায় 1VPN খুঁজুন। প্রথমবার কানেক্ট করার পরে এটি দেখা যায়।';

  @override
  String get onevpnAlwaysOnStep3 => '1VPN এর পাশের গিয়ার আইকনে ট্যাপ করুন।';

  @override
  String get onevpnAlwaysOnStep4 => '‘সর্বদা-চালু VPN’ চালু করুন।';

  @override
  String get onevpnAlwaysOnOpenSettings => 'VPN সেটিংস খুলুন';

  @override
  String get onevpnPaywallTitle => 'আপনার প্ল্যান বেছে নিন';

  @override
  String get onevpnPaywallBenefitLocations => 'সব সার্ভার লোকেশন আনলক করুন';

  @override
  String get onevpnPaywallBenefitNoAds => 'কোনো বিজ্ঞাপন নেই';

  @override
  String get onevpnPaywallBenefitSpeed => 'আরও দ্রুত সার্ভার স্পিড';

  @override
  String get onevpnPaywallBenefitP2p => 'BitTorrent (P2P) সাপোর্ট';

  @override
  String get onevpnPaywallBenefitMoneyBack => '১০ দিনের মানি-ব্যাক গ্যারান্টি';

  @override
  String get onevpnPaywallPlanYearly => 'বার্ষিক';

  @override
  String get onevpnPaywallPlanMonthly => 'মাসিক';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '$percent% সাশ্রয়';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / মাস';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'মূল্য উপলভ্য নয়';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'প্ল্যান লোড করা যায়নি। আপনার কানেকশন চেক করুন।';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'এই মুহূর্তে কোনও প্ল্যান উপলভ্য নেই। পরে আবার চেষ্টা করুন।';

  @override
  String get onevpnGetPremium => 'প্রিমিয়াম নিন';

  @override
  String get onevpnContinueFree => 'ফ্রিতে চালিয়ে যান';

  @override
  String get onevpnPaywallRetry => 'আবার চেষ্টা করুন';

  @override
  String get onevpnPaywallPurchaseError =>
      'কোনও সমস্যা হয়েছে। আবার চেষ্টা করুন।';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'এই Google অ্যাকাউন্টে একটি চালু বা সম্প্রতি শেষ হওয়া 1VPN সাবস্ক্রিপশন আছে, যা অন্য একটি 1VPN অ্যাকাউন্টের সাথে লিঙ্ক করা আছে। সেই অ্যাকাউন্টে লগ-ইন করুন বা $support টিমের সাথে যোগাযোগ করুন।';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'এই Google অ্যাকাউন্টে আগে থেকেই একটি 1VPN সাবস্ক্রিপশন আছে। প্রিমিয়াম দেখা না গেলে $support টিমের সাথে যোগাযোগ করুন।';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play আপনার শেষ কেনাকাটা সম্পূর্ণ করেনি। খোলা থাকা Google Play স্ক্রিন বন্ধ করে আবার চেষ্টা করুন, অথবা অ্যাপ রিস্টার্ট করুন।';

  @override
  String get onevpnPaywallSupportLink => '1VPN সহায়তা';

  @override
  String get onevpnSignUp => 'সাইন-আপ করুন';

  @override
  String get onevpnAuthEmailLabel => 'ইমেল';

  @override
  String get onevpnAuthPasswordLabel => 'পাসওয়ার্ড';

  @override
  String get onevpnAuthTwoFactorLabel => '2FA টোকেন';

  @override
  String get onevpnAuthForgotPassword => 'পাসওয়ার্ড ভুলে গেছেন?';

  @override
  String get onevpnAuthSubmitting => 'লোড হচ্ছে…';

  @override
  String get onevpnAuthCreateAccount => 'অ্যাকাউন্ট তৈরি করুন';

  @override
  String get onevpnAuthHaveAccount => 'আগে থেকেই অ্যাকাউন্ট আছে?';

  @override
  String get onevpnAuthLogInInstead => 'বরং লগ-ইন করুন';

  @override
  String get onevpnAuthFieldsRequired => 'ইমেল ও পাসওয়ার্ড লিখুন';

  @override
  String get onevpnAuthInvalidEmail => 'সঠিক ইমেল অ্যাড্রেস লিখুন';

  @override
  String get onevpnAuthInvalidCredentials => 'লগ-ইনের তথ্য সঠিক নয়';

  @override
  String get onevpnAuthInvalidTwoFactor => '2FA টোকেন সঠিক নয়';

  @override
  String get onevpnAuthEmailInUse => 'এই ইমেলে আগে থেকেই একটি অ্যাকাউন্ট আছে';

  @override
  String get onevpnAuthRateLimited =>
      'অনেকবার চেষ্টা করা হয়েছে। কিছুক্ষণ পরে আবার চেষ্টা করুন';

  @override
  String get onevpnAuthUnreachable =>
      'সার্ভারে কানেক্ট করা যায়নি। আপনার কানেকশন চেক করে আবার চেষ্টা করুন';

  @override
  String get onevpnAuthGenericError => 'কোনও সমস্যা হয়েছে। আবার চেষ্টা করুন';

  @override
  String get onevpnAuthEmailLockedHint =>
      'আপনার কেনাকাটা এই ইমেল অ্যাড্রেসের সাথে লিঙ্ক করা আছে।';

  @override
  String get onevpnPaywallPurchasedTitle => 'কেনাকাটা সম্পূর্ণ হয়েছে';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'আপনার কেনাকাটা $email অ্যাড্রেসের সাথে লিঙ্ক করা আছে। এটি ব্যবহার করতে সেই অ্যাড্রেসে একটি অ্যাকাউন্ট তৈরি করুন।';
  }

  @override
  String get onevpnPlanPremiumPending =>
      'প্রিমিয়াম · কেনাকাটা কনফার্ম করা হচ্ছে';

  @override
  String get onevpnPremiumRecheck => 'আপনার কেনাকাটার স্ট্যাটাস চেক করা হচ্ছে…';

  @override
  String get onevpnButtonRetry => 'আবার চেষ্টা করুন';

  @override
  String get onevpnAppVersion => 'অ্যাপ ভার্সন';

  @override
  String get onevpnPrivacyPolicy => 'গোপনীয়তা নীতি';

  @override
  String get onevpnConnect => 'কানেক্ট করুন';

  @override
  String get onevpnDisconnected => 'ডিসকানেক্ট করা আছে';

  @override
  String get onevpnConnecting => 'কানেক্ট হচ্ছে…';

  @override
  String get onevpnConnected => 'কানেক্ট আছে';

  @override
  String get onevpnDisconnecting => 'ডিসকানেক্ট হচ্ছে…';

  @override
  String get onevpnConnectionFailed => 'কানেক্ট করা যায়নি';

  @override
  String get onevpnTemporarilyUnavailable => 'সাময়িকভাবে উপলভ্য নেই';

  @override
  String get onevpnRetry => 'আবার চেষ্টা করুন';

  @override
  String get onevpnApplyChange => 'এই পরিবর্তন প্রয়োগ করবেন?';

  @override
  String get onevpnReconnectNotice =>
      'VPN কিছুক্ষণের জন্য ডিসকানেক্ট হয়ে আবার কানেক্ট হবে। সাধারণত এতে মাত্র কয়েক সেকেন্ড সময় লাগে।';

  @override
  String onevpnWillUseName(String name) {
    return 'ব্যবহার করা হবে: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'প্রয়োগ করে আবার কানেক্ট করুন';

  @override
  String get onevpnCancel => 'বাতিল';

  @override
  String get onevpnContinue => 'চালিয়ে যান';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'মূল ডোমেইন ব্লক করা হয়েছে। ব্যাকআপ ব্যবহার করা হচ্ছে: $domain';
  }

  @override
  String get onevpnResultFailed => 'ব্যর্থ হয়েছে';

  @override
  String get onevpnDownload => 'ডাউনলোড করুন';

  @override
  String get onevpnPermissionNotGranted => 'অনুমতি দেওয়া হয়নি';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action: $result';
  }

  @override
  String get onevpnDisconnect => 'ডিসকানেক্ট করুন';

  @override
  String get onevpnTimeout => 'সময়সীমা শেষ';

  @override
  String get onevpnNoAvailableEntries => 'কোনও এন্ট্রি সার্ভার উপলভ্য নেই';

  @override
  String get onevpnAddServers => 'সার্ভার যোগ করুন';

  @override
  String get onevpnNotEnoughServers => 'পর্যাপ্ত সার্ভার উপলভ্য নেই';

  @override
  String get onevpnVpnFinalExit => 'VPN এর শেষ এক্সিট';

  @override
  String get onevpnFinalExitEntryConflict =>
      'শেষ এক্সিট আর এন্ট্রি সার্ভার একই সার্ভার হতে পারবে না';

  @override
  String get onevpnChooseNamedRoute => 'নাম দেওয়া একটি রুট বেছে নিন';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'লোকাল নেটওয়ার্কের ডিভাইস ও পরিষেবা অ্যাক্সেস করার অনুমতি দিন।';

  @override
  String get onevpnSystemApprovalRequired => 'সিস্টেমের অনুমোদন প্রয়োজন';

  @override
  String get onevpnVpnPermissionRequired =>
      'VPN অনুমতি প্রয়োজন। চালিয়ে যেতে আবার চেষ্টা করুন।';

  @override
  String get onevpnChooseInterfaceNotice =>
      'নেটওয়ার্ক অ্যাক্সেস করার জন্য ব্যবহৃত ইন্টারফেস বেছে নিন। শুধুমাত্র Windows / Linux এ প্রয়োজন।';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'আন্ডোরা',
      'AE': 'সংযুক্ত আরব আমিরাত',
      'AF': 'আফগানিস্তান',
      'AG': 'অ্যান্টিগুয়া ও বারবুডা',
      'AI': 'অ্যাঙ্গুইলা',
      'AL': 'আলবেনিয়া',
      'AM': 'আর্মেনিয়া',
      'AO': 'অ্যাঙ্গোলা',
      'AQ': 'অ্যান্টার্কটিকা',
      'AR': 'আর্জেন্টিনা',
      'AS': 'আমেরিকান সামোয়া',
      'AT': 'অস্ট্রিয়া',
      'AU': 'অস্ট্রেলিয়া',
      'AW': 'আরুবা',
      'AX': 'অলান্ড দ্বীপপুঞ্জ',
      'AZ': 'আজারবাইজান',
      'BA': 'বসনিয়া ও হার্জেগোভিনা',
      'BB': 'বার্বাডোজ',
      'BD': 'বাংলাদেশ',
      'BE': 'বেলজিয়াম',
      'BF': 'বুরকিনা ফাসো',
      'BG': 'বুলগেরিয়া',
      'BH': 'বাহারিন',
      'BI': 'বুরুন্ডি',
      'BJ': 'বেনিন',
      'BL': 'সেন্ট বার্থেলেমি',
      'BM': 'বারমুডা',
      'BN': 'ব্রুনেই',
      'BO': 'বলিভিয়া',
      'BQ': 'ক্যারিবিয়ান নেদারল্যান্ডস',
      'BR': 'ব্রাজিল',
      'BS': 'বাহামা দ্বীপপুঞ্জ',
      'BT': 'ভুটান',
      'BV': 'বোভেট দ্বীপ',
      'BW': 'বতসোয়ানা',
      'BY': 'বেলারুশ',
      'BZ': 'বেলিজ',
      'CA': 'কানাডা',
      'CC': 'কোকোস (কিলিং) দ্বীপপুঞ্জ',
      'CD': 'কঙ্গো-কিনশাসা',
      'CF': 'মধ্য আফ্রিকান প্রজাতন্ত্র',
      'CG': 'কঙ্গো - ব্রাজাভিল',
      'CH': 'সুইজারল্যান্ড',
      'CI': 'কোট ডি‘আইভোর',
      'CK': 'কুক দ্বীপপুঞ্জ',
      'CL': 'চিলি',
      'CM': 'ক্যামেরুন',
      'CN': 'চীন',
      'CO': 'কলম্বিয়া',
      'CR': 'কোস্টারিকা',
      'CU': 'কিউবা',
      'CV': 'কেপ ভার্দে',
      'CW': 'কুরাসাও',
      'CX': 'ক্রিসমাস দ্বীপ',
      'CY': 'সাইপ্রাস',
      'CZ': 'চেকিয়া',
      'DE': 'জার্মানি',
      'DJ': 'জিবুতি',
      'DK': 'ডেনমার্ক',
      'DM': 'ডোমিনিকা',
      'DO': 'ডোমেনিকান প্রজাতন্ত্র',
      'DZ': 'আলজেরিয়া',
      'EC': 'ইকুয়েডর',
      'EE': 'এস্তোনিয়া',
      'EG': 'মিশর',
      'EH': 'পশ্চিম সাহারা',
      'ER': 'ইরিত্রিয়া',
      'ES': 'স্পেন',
      'ET': 'ইথিওপিয়া',
      'FI': 'ফিনল্যান্ড',
      'FJ': 'ফিজি',
      'FK': 'ফকল্যান্ড দ্বীপপুঞ্জ',
      'FM': 'মাইক্রোনেশিয়া',
      'FO': 'ফ্যারো দ্বীপপুঞ্জ',
      'FR': 'ফ্রান্স',
      'GA': 'গ্যাবন',
      'GB': 'যুক্তরাজ্য',
      'GD': 'গ্রেনাডা',
      'GE': 'জর্জিয়া',
      'GF': 'ফরাসী গায়ানা',
      'GG': 'গার্নসি',
      'GH': 'ঘানা',
      'GI': 'জিব্রাল্টার',
      'GL': 'গ্রীনল্যান্ড',
      'GM': 'গাম্বিয়া',
      'GN': 'গিনি',
      'GP': 'গুয়াদেলৌপ',
      'GQ': 'নিরক্ষীয় গিনি',
      'GR': 'গ্রীস',
      'GS': 'দক্ষিণ জর্জিয়া ও দক্ষিণ স্যান্ডউইচ দ্বীপপুঞ্জ',
      'GT': 'গুয়াতেমালা',
      'GU': 'গুয়াম',
      'GW': 'গিনি-বিসাউ',
      'GY': 'গিয়ানা',
      'HK': 'হংকং',
      'HM': 'হার্ড এবং ম্যাকডোনাল্ড দ্বীপপুঞ্জ',
      'HN': 'হন্ডুরাস',
      'HR': 'ক্রোয়েশিয়া',
      'HT': 'হাইতি',
      'HU': 'হাঙ্গেরি',
      'ID': 'ইন্দোনেশিয়া',
      'IE': 'আয়ারল্যান্ড',
      'IL': 'ইজরায়েল',
      'IM': 'আইল অফ ম্যান',
      'IN': 'ভারত',
      'IO': 'ব্রিটিশ ভারত মহাসাগরীয় অঞ্চল',
      'IQ': 'ইরাক',
      'IR': 'ইরান',
      'IS': 'আইসল্যান্ড',
      'IT': 'ইতালি',
      'JE': 'জার্সি',
      'JM': 'জামাইকা',
      'JO': 'জর্ডন',
      'JP': 'জাপান',
      'KE': 'কেনিয়া',
      'KG': 'কিরগিজিস্তান',
      'KH': 'কম্বোডিয়া',
      'KI': 'কিরিবাতি',
      'KM': 'কমোরোস',
      'KN': 'সেন্ট কিটস ও নেভিস',
      'KP': 'উত্তর কোরিয়া',
      'KR': 'দক্ষিণ কোরিয়া',
      'KW': 'কুয়েত',
      'KY': 'কেম্যান দ্বীপপুঞ্জ',
      'KZ': 'কাজাখস্তান',
      'LA': 'লাওস',
      'LB': 'লেবানন',
      'LC': 'সেন্ট লুসিয়া',
      'LI': 'লিচেনস্টেইন',
      'LK': 'শ্রীলঙ্কা',
      'LR': 'লাইবেরিয়া',
      'LS': 'লেসোথো',
      'LT': 'লিথুয়ানিয়া',
      'LU': 'লাক্সেমবার্গ',
      'LV': 'লাটভিয়া',
      'LY': 'লিবিয়া',
      'MA': 'মরক্কো',
      'MC': 'মোনাকো',
      'MD': 'মলডোভা',
      'ME': 'মন্টিনিগ্রো',
      'MF': 'সেন্ট মার্টিন',
      'MG': 'মাদাগাস্কার',
      'MH': 'মার্শাল দ্বীপপুঞ্জ',
      'MK': 'উত্তর ম্যাসেডোনিয়া',
      'ML': 'মালি',
      'MM': 'মায়ানমার (বার্মা)',
      'MN': 'মঙ্গোলিয়া',
      'MO': 'ম্যাকাও',
      'MP': 'উত্তরাঞ্চলীয় মারিয়ানা দ্বীপপুঞ্জ',
      'MQ': 'মার্টিনিক',
      'MR': 'মরিতানিয়া',
      'MS': 'মন্টসেরাট',
      'MT': 'মাল্টা',
      'MU': 'মরিশাস',
      'MV': 'মালদ্বীপ',
      'MW': 'মালাউই',
      'MX': 'মেক্সিকো',
      'MY': 'মালয়েশিয়া',
      'MZ': 'মোজাম্বিক',
      'NA': 'নামিবিয়া',
      'NC': 'নিউ ক্যালেডোনিয়া',
      'NE': 'নাইজার',
      'NF': 'নরফোক দ্বীপ',
      'NG': 'নাইজেরিয়া',
      'NI': 'নিকারাগুয়া',
      'NL': 'নেদারল্যান্ডস',
      'NO': 'নরওয়ে',
      'NP': 'নেপাল',
      'NR': 'নাউরু',
      'NU': 'নিউয়ে',
      'NZ': 'নিউজিল্যান্ড',
      'OM': 'ওমান',
      'PA': 'পানামা',
      'PE': 'পেরু',
      'PF': 'ফরাসী পলিনেশিয়া',
      'PG': 'পাপুয়া নিউ গিনি',
      'PH': 'ফিলিপাইন',
      'PK': 'পাকিস্তান',
      'PL': 'পোল্যান্ড',
      'PM': 'সেন্ট পিয়ের ও মিকুয়েলন',
      'PN': 'পিটকেয়ার্ন দ্বীপপুঞ্জ',
      'PR': 'পুয়ের্তো রিকো',
      'PS': 'প্যালেস্টাইন ভূখণ্ড',
      'PT': 'পর্তুগাল',
      'PW': 'পালাউ',
      'PY': 'প্যারাগুয়ে',
      'QA': 'কাতার',
      'RE': 'রিইউনিয়ন',
      'RO': 'রোমানিয়া',
      'RS': 'সার্বিয়া',
      'RU': 'রাশিয়া',
      'RW': 'রুয়ান্ডা',
      'SA': 'সৌদি আরব',
      'SB': 'সলোমন দ্বীপপুঞ্জ',
      'SC': 'সিসিলি',
      'SD': 'সুদান',
      'SE': 'সুইডেন',
      'SG': 'সিঙ্গাপুর',
      'SH': 'সেন্ট হেলেনা',
      'SI': 'স্লোভানিয়া',
      'SJ': 'স্বালবার্ড ও জান মেয়েন',
      'SK': 'স্লোভাকিয়া',
      'SL': 'সিয়েরা লিওন',
      'SM': 'সান মারিনো',
      'SN': 'সেনেগাল',
      'SO': 'সোমালিয়া',
      'SR': 'সুরিনাম',
      'SS': 'দক্ষিণ সুদান',
      'ST': 'সাওটোমা ও প্রিন্সিপি',
      'SV': 'এল সালভেদর',
      'SX': 'সিন্ট মার্টেন',
      'SY': 'সিরিয়া',
      'SZ': 'ইসওয়াতিনি',
      'TC': 'তুর্কস ও কাইকোস দ্বীপপুঞ্জ',
      'TD': 'চাদ',
      'TF': 'ফরাসী দক্ষিণাঞ্চল',
      'TG': 'টোগো',
      'TH': 'থাইল্যান্ড',
      'TJ': 'তাজিকিস্তান',
      'TK': 'টোকেলাউ',
      'TL': 'তিমুর-লেস্তে',
      'TM': 'তুর্কমেনিস্তান',
      'TN': 'তিউনিসিয়া',
      'TO': 'টোঙ্গা',
      'TR': 'তুরস্ক',
      'TT': 'ত্রিনিদাদ ও টোবাগো',
      'TV': 'টুভালু',
      'TW': 'তাইওয়ান',
      'TZ': 'তাঞ্জানিয়া',
      'UA': 'ইউক্রেন',
      'UG': 'উগান্ডা',
      'UM': 'যুক্তরাষ্ট্রের পার্শ্ববর্তী দ্বীপপুঞ্জ',
      'US': 'মার্কিন যুক্তরাষ্ট্র',
      'UY': 'উরুগুয়ে',
      'UZ': 'উজবেকিস্তান',
      'VA': 'ভ্যাটিকান সিটি',
      'VC': 'সেন্ট ভিনসেন্ট ও গ্রেনাডিনস',
      'VE': 'ভেনেজুয়েলা',
      'VG': 'ব্রিটিশ ভার্জিন দ্বীপপুঞ্জ',
      'VI': 'মার্কিন যুক্তরাষ্ট্রীয় ভার্জিন দ্বীপপুঞ্জ',
      'VN': 'ভিয়েতনাম',
      'VU': 'ভানুয়াটু',
      'WF': 'ওয়ালিস ও ফুটুনা',
      'WS': 'সামোয়া',
      'XK': 'কসোভো',
      'YE': 'ইয়েমেন',
      'YT': 'মায়োত্তে',
      'ZA': 'দক্ষিণ আফ্রিকা',
      'ZM': 'জাম্বিয়া',
      'ZW': 'জিম্বাবোয়ে',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'গোপনীয়তার পছন্দসমূহ';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'আমস্টারডাম',
      'sgp': 'সিঙ্গাপুর',
      'lax': 'লস অ্যাঞ্জেলেস',
      'mel': 'মেলবোর্ন',
      'syd': 'সিডনি',
      'sao': 'সাও পাওলো',
      'yto': 'টরন্টো',
      'scl': 'সান্তিয়াগো',
      'cdg': 'প্যারিস',
      'fra': 'ফ্রাঙ্কফুর্ট',
      'del': 'দিল্লি',
      'bom': 'মুম্বই',
      'blr': 'বেঙ্গালুরু',
      'tlv': 'তেল আবিব',
      'itm': 'ওসাকা',
      'nrt': 'টোকিও',
      'mex': 'মেক্সিকো সিটি',
      'waw': 'ওয়ারশ',
      'jnb': 'জোহানেসবার্গ',
      'icn': 'সিউল',
      'mad': 'মাদ্রিদ',
      'sto': 'স্টকহোম',
      'lhr': 'লন্ডন',
      'man': 'ম্যানচেস্টার',
      'ord': 'শিকাগো',
      'dfw': 'ডালাস',
      'sea': 'সিয়াটল',
      'sjc': 'সান ফ্রান্সিসকো',
      'mia': 'মায়ামি',
      'hnl': 'হনলুলু',
      'ewr': 'নিউ ইয়র্ক',
      'atl': 'আটলান্টা',
      'hkg': 'হংকং',
      'zrh': 'জুরিখ',
      'gva': 'জেনেভা',
      'svo': 'মস্কো',
      'led': 'সেন্ট পিটার্সবার্গ',
      'hel': 'হেলসিঙ্কি',
      'tpe': 'তাইপে',
      'dxb': 'দুবাই',
      'kbp': 'কিয়েভ',
      'ist': 'ইস্তাম্বুল',
      'otp': 'বুখারেস্ট',
      'los': 'লাগোস',
      'pty': 'পানামা সিটি',
      'kef': 'রেইকিয়াভিক',
      'ber': 'বার্লিন',
      'ala': 'আলমাটি',
      'tbs': 'তিবিলিসি',
      'kul': 'কুয়ালালামপুর',
      'bkk': 'ব্যাংকক',
      'cgk': 'জাকার্তা',
      'mnl': 'ম্যানিলা',
      'nbo': 'নাইরোবি',
      'mxp': 'মিলান',
      'dub': 'ডাবলিন',
      'lis': 'লিসবন',
      'lux': 'লাক্সেমবার্গ',
      'eze': 'বুয়েনোস আইরেস',
      'akl': 'অকল্যান্ড',
      'yul': 'মন্ট্রিয়ল',
      'yvr': 'ভ্যাঙ্কুভার',
      'den': 'ডেনভার',
      'phx': 'ফিনিক্স',
      'iad': 'ওয়াশিংটন ডি.সি.',
      'bos': 'বস্টন',
      'edi': 'এডিনবরা',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'আপনি কি 1VPN উপভোগ করছেন?';

  @override
  String get onevpnYes => 'হ্যাঁ';

  @override
  String get onevpnNo => 'না';

  @override
  String get onevpnLocationLocked => 'লক করা, শুধু প্রিমিয়াম';

  @override
  String get onevpnManageSubscription => 'সাবস্ক্রিপশন পরিচালনা করুন';
}
