// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class OneVpnLocalizationsUr extends OneVpnLocalizations {
  OneVpnLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get onevpnFaq => 'اکثر پوچھے گئے سوالات';

  @override
  String get onevpnTermsOfService => 'سروس کی شرائط';

  @override
  String get onevpnMenu => 'مینو';

  @override
  String get onevpnUpgrade => 'اپ گریڈ کریں';

  @override
  String get onevpnUpgradeBannerTitle => 'پریمیم میں اپ گریڈ کریں';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'کوئی اشتہار نہیں، تمام مقامات اور تیز تر رفتار';

  @override
  String get onevpnLogIn => 'لاگ ان کریں';

  @override
  String get onevpnLogOut => 'لاگ آؤٹ کریں';

  @override
  String get onevpnAccount => 'اکاؤنٹ';

  @override
  String get onevpnContactUs => 'ہم سے رابطہ کریں';

  @override
  String get onevpnRefundPolicy => 'رقم کی واپسی کی پالیسی';

  @override
  String get onevpnSupport => 'سپورٹ';

  @override
  String get onevpnLanguage => 'زبان';

  @override
  String get onevpnLanguageSystem => 'سسٹم ڈیفالٹ';

  @override
  String get onevpnPlanFree => 'مفت پلان';

  @override
  String get onevpnPlanPremium => 'پریمیم پلان';

  @override
  String get onevpnSelectLocation => 'مقام منتخب کریں';

  @override
  String get onevpnDirectRegions => 'براہ راست علاقے';

  @override
  String get onevpnFree => 'مفت';

  @override
  String onevpnFreeSubtitle(String country) {
    return '⁦$country‎⁩ · مفت';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'خودکار · ⁦$node‎⁩';
  }

  @override
  String get onevpnAutomaticSelection => 'خودکار';

  @override
  String get onevpnStatusNoConnection => 'کوئی کنکشن نہیں';

  @override
  String get onevpnStatusConnectionFailed => 'کنکشن ناکام ہو گیا';

  @override
  String get onevpnStatusUpdating => 'اپ ڈیٹ ہو رہا ہے…';

  @override
  String get onevpnStatusMeasuring => 'سرورز کی پیمائش ہو رہی ہے…';

  @override
  String get onevpnAutomaticSubtitle => 'تیز ترین دستیاب سرور';

  @override
  String get onevpnLocationsLoadFailed => 'آپ کے مقامات لوڈ نہیں ہو سکے۔';

  @override
  String get onevpnLocationsUnavailable => 'مقامات اس وقت دستیاب نہیں ہیں۔';

  @override
  String get onevpnDirectRegionsCardBody =>
      'کچھ سائٹس صرف اسی وقت کام کرتی ہیں جب آپ اسی ملک سے منسلک ہوں جہاں وہ سائٹ ہے۔ کوئی علاقہ منتخب کرنے پر، اس علاقے کی سائٹس VPN کو بائی پاس کرتی ہیں۔';

  @override
  String onevpnSelectionReset(String location) {
    return '⁦$location‎⁩ دستیاب نہیں ہے، اس لیے 1VPN نے \'خودکار\' پر سوئچ کر دیا۔';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'منتخب کردہ مقام دستیاب نہیں ہے، اس لیے 1VPN نے \'خودکار\' پر سوئچ کر دیا۔';

  @override
  String onevpnReloadRolledBack(String location) {
    return '⁦$location‎⁩ پر سوئچ نہیں ہو سکا۔ آپ اب بھی اپنے پچھلے مقام سے منسلک ہیں۔';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'تبدیلی لاگو نہیں ہو سکی۔ آپ اب بھی اپنی پچھلی ترتیبات کے ساتھ منسلک ہیں۔';

  @override
  String get onevpnDirectRegionsOff => 'آف (ڈیفالٹ)';

  @override
  String get onevpnAllViaVpnSubtitle => 'تمام ٹریفک ٹنل کے ذریعے';

  @override
  String get onevpnRegionChina => 'چین';

  @override
  String get onevpnFirstConnectTitle => 'کچھ علاقے براہ راست بہتر کام کرتے ہیں';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'چین، روس اور ایران جیسی جگہوں پر، سب کچھ VPN کے ذریعے بھیجنے سے مقامی بینکنگ اور ادائیگی کی ایپس کام کرنا بند کر سکتی ہیں۔';

  @override
  String get onevpnFirstConnectPointDirect =>
      '‏1VPN آپ کے منتخب کردہ علاقے کو ٹنل سے باہر، آپ کے اصل IP سے براہ راست روٹ کر سکتا ہے۔';

  @override
  String get onevpnFirstConnectPointProtected =>
      'باقی سب کچھ محفوظ رہتا ہے۔ آپ اسے کسی بھی وقت تبدیل کر سکتے ہیں۔';

  @override
  String get onevpnFirstConnectChooseRegion => 'براہ راست علاقہ منتخب کریں';

  @override
  String get onevpnFirstConnectDismiss => 'ابھی نہیں';

  @override
  String get onevpnCensorshipWarning =>
      'حکومتی پابندیوں کی وجہ سے آپ کے علاقے میں کچھ سرورز بلاک ہو سکتے ہیں۔ ہم اسے حل کرنے پر کام کر رہے ہیں۔ آپ کی سمجھ بوجھ کا شکریہ۔';

  @override
  String get onevpnAlwaysOnTitle => '‏ہمیشہ آن VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      'ایپ بند کرنے پر بھی ٹنل منسلک رہتا ہے۔ ری سٹارٹ یا ایپ اپ ڈیٹ کے بعد، \'‏ہمیشہ آن VPN\' اسے خودکار طور پر دوبارہ منسلک کر دیتا ہے۔';

  @override
  String get onevpnAlwaysOnStep1 =>
      'نیچے \'VPN کی ترتیبات کھولیں\' پر تھپتھپائیں۔';

  @override
  String get onevpnAlwaysOnStep2 =>
      'فہرست میں 1VPN تلاش کریں۔ یہ آپ کے پہلی بار منسلک ہونے کے بعد ظاہر ہوتا ہے۔';

  @override
  String get onevpnAlwaysOnStep3 =>
      '‏1VPN کے ساتھ والے گیئر آئیکن پر تھپتھپائیں۔';

  @override
  String get onevpnAlwaysOnStep4 => '\'‏ہمیشہ آن VPN\' کو آن کریں۔';

  @override
  String get onevpnAlwaysOnOpenSettings => 'VPN کی ترتیبات کھولیں';

  @override
  String get onevpnPaywallTitle => 'اپنا پلان منتخب کریں';

  @override
  String get onevpnPaywallBenefitLocations => 'سرور کے تمام مقامات تک رسائی';

  @override
  String get onevpnPaywallBenefitNoAds => 'کوئی اشتہار نہیں';

  @override
  String get onevpnPaywallBenefitSpeed => 'سرور کی تیز تر رفتار';

  @override
  String get onevpnPaywallBenefitP2p => 'BitTorrent (P2P) کی سپورٹ';

  @override
  String get onevpnPaywallBenefitMoneyBack => 'رقم کی واپسی کی 10 دن کی گارنٹی';

  @override
  String get onevpnPaywallPlanYearly => 'سالانہ';

  @override
  String get onevpnPaywallPlanMonthly => 'ماہانہ';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '⁦$percent%‎⁩ بچائیں';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '⁦$amount $currency‎⁩ / ماہ';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'قیمت دستیاب نہیں';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'پلانز لوڈ نہیں ہو سکے۔ اپنا کنکشن چیک کریں۔';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'پلانز اس وقت دستیاب نہیں ہیں۔ براہ کرم بعد میں دوبارہ کوشش کریں۔';

  @override
  String get onevpnGetPremium => 'پریمیم حاصل کریں';

  @override
  String get onevpnContinueFree => 'مفت جاری رکھیں';

  @override
  String get onevpnPaywallRetry => 'دوبارہ کوشش کریں';

  @override
  String get onevpnPaywallPurchaseError =>
      'کچھ غلط ہو گیا۔ براہ کرم دوبارہ کوشش کریں۔';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'اس Google اکاؤنٹ میں ایک فعال یا حال ہی میں ختم ہونے والی 1VPN سبسکرپشن ہے جو کسی دوسرے 1VPN اکاؤنٹ سے وابستہ ہے۔ اس اکاؤنٹ میں لاگ ان کریں یا $support سے رابطہ کریں۔';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'اس Google اکاؤنٹ میں پہلے سے 1VPN سبسکرپشن موجود ہے۔ اگر پریمیم ظاہر نہ ہو تو $support سے رابطہ کریں۔';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'آپ کی پچھلی خریداری Google Play میں مکمل نہیں ہوئی۔ کھلی ہوئی Google Play اسکرینیں بند کر کے دوبارہ کوشش کریں، یا ایپ ری سٹارٹ کریں۔';

  @override
  String get onevpnPaywallSupportLink => '1VPN سپورٹ';

  @override
  String get onevpnSignUp => 'سائن اپ کریں';

  @override
  String get onevpnAuthEmailLabel => 'ای میل';

  @override
  String get onevpnAuthPasswordLabel => 'پاس ورڈ';

  @override
  String get onevpnAuthTwoFactorLabel => '2FA ٹوکن';

  @override
  String get onevpnAuthForgotPassword => 'اپنا پاس ورڈ بھول گئے؟';

  @override
  String get onevpnAuthSubmitting => 'لوڈ ہو رہا ہے…';

  @override
  String get onevpnAuthCreateAccount => 'اکاؤنٹ بنائیں';

  @override
  String get onevpnAuthHaveAccount => 'کیا آپ کے پاس اکاؤنٹ ہے؟';

  @override
  String get onevpnAuthLogInInstead => 'اس کے بجائے لاگ ان کریں';

  @override
  String get onevpnAuthFieldsRequired => 'ای میل اور پاس ورڈ درج کریں';

  @override
  String get onevpnAuthInvalidEmail => 'درست ای میل پتہ درج کریں';

  @override
  String get onevpnAuthInvalidCredentials => 'لاگ ان کی تفصیلات غلط ہیں';

  @override
  String get onevpnAuthInvalidTwoFactor => 'غلط 2FA ٹوکن';

  @override
  String get onevpnAuthEmailInUse => 'اس ای میل کا پہلے سے ایک اکاؤنٹ ہے';

  @override
  String get onevpnAuthRateLimited =>
      'بہت زیادہ کوششیں۔ براہ کرم تھوڑی دیر بعد دوبارہ کوشش کریں';

  @override
  String get onevpnAuthUnreachable =>
      'سرور تک رسائی نہیں ہو سکی۔ اپنا کنکشن چیک کریں اور دوبارہ کوشش کریں';

  @override
  String get onevpnAuthGenericError =>
      'کچھ غلط ہو گیا۔ براہ کرم دوبارہ کوشش کریں';

  @override
  String get onevpnAuthEmailLockedHint =>
      'آپ کی خریداری اس ای میل پتے سے وابستہ ہے۔';

  @override
  String get onevpnPaywallPurchasedTitle => 'خریداری مکمل ہو گئی';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'آپ کی خریداری ⁦$email‎⁩ سے وابستہ ہے۔ اسے استعمال کرنے کے لیے اسی پتے پر ایک اکاؤنٹ بنائیں۔';
  }

  @override
  String get onevpnPlanPremiumPending => 'پریمیم · خریداری کی تصدیق ہو رہی ہے';

  @override
  String get onevpnPremiumRecheck =>
      'آپ کی خریداری کی صورتحال چیک کی جا رہی ہے…';

  @override
  String get onevpnButtonRetry => 'پھر کوشش کریں';

  @override
  String get onevpnAppVersion => 'ایپ ورژن';

  @override
  String get onevpnPrivacyPolicy => 'رازداری کی پالیسی';

  @override
  String get onevpnConnect => 'منسلک کریں';

  @override
  String get onevpnDisconnected => 'غیر منسلک';

  @override
  String get onevpnConnecting => 'منسلک ہو رہا ہے…';

  @override
  String get onevpnConnected => 'منسلک';

  @override
  String get onevpnDisconnecting => 'غیر منسلک ہو رہا ہے…';

  @override
  String get onevpnConnectionFailed => 'کنکشن ناکام ہو گیا';

  @override
  String get onevpnTemporarilyUnavailable => 'عارضی طور پر دستیاب نہیں';

  @override
  String get onevpnRetry => 'پھر کوشش کریں';

  @override
  String get onevpnApplyChange => 'یہ تبدیلی لاگو کریں؟';

  @override
  String get onevpnReconnectNotice =>
      'VPN مختصر وقت کے لیے غیر منسلک ہو کر دوبارہ منسلک ہوگا۔ اس میں عام طور پر صرف چند سیکنڈ لگتے ہیں۔';

  @override
  String onevpnWillUseName(String name) {
    return 'استعمال ہوگا: ⁦$name‎⁩';
  }

  @override
  String get onevpnApplyAndReconnect => 'لاگو کریں اور دوبارہ منسلک کریں';

  @override
  String get onevpnCancel => 'منسوخ کریں';

  @override
  String get onevpnContinue => 'جاری رکھیں';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'مرکزی ڈومین بلاک ہے۔ بیک اپ استعمال ہو رہا ہے: ⁦$domain‎⁩';
  }

  @override
  String get onevpnResultFailed => 'ناکام';

  @override
  String get onevpnDownload => 'ڈاؤن لوڈ کریں';

  @override
  String get onevpnPermissionNotGranted => 'اجازت نہیں دی گئی';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action: $result';
  }

  @override
  String get onevpnDisconnect => 'غیر منسلک کریں';

  @override
  String get onevpnTimeout => 'ٹائم آؤٹ';

  @override
  String get onevpnNoAvailableEntries => 'کوئی انٹری سرور دستیاب نہیں';

  @override
  String get onevpnAddServers => 'سرورز شامل کریں';

  @override
  String get onevpnNotEnoughServers => 'کافی سرورز دستیاب نہیں';

  @override
  String get onevpnVpnFinalExit => 'VPN کا آخری ایگزٹ';

  @override
  String get onevpnFinalExitEntryConflict =>
      'آخری ایگزٹ انٹری سرور بھی نہیں ہو سکتا';

  @override
  String get onevpnChooseNamedRoute => 'ایک نام والا روٹ منتخب کریں';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'مقامی نیٹ ورک پر آلات اور سروسز تک رسائی کی اجازت دیں۔';

  @override
  String get onevpnSystemApprovalRequired => 'سسٹم کی منظوری درکار ہے';

  @override
  String get onevpnVpnPermissionRequired =>
      'VPN کی اجازت درکار ہے۔ جاری رکھنے کے لیے براہ کرم پھر کوشش کریں۔';

  @override
  String get onevpnChooseInterfaceNotice =>
      'نیٹ ورک تک رسائی کے لیے استعمال ہونے والا انٹرفیس منتخب کریں۔ صرف Windows / Linux پر درکار ہے۔';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'انڈورا',
      'AE': 'متحدہ عرب امارات',
      'AF': 'افغانستان',
      'AG': 'انٹیگوا اور باربودا',
      'AI': 'انگوئیلا',
      'AL': 'البانیہ',
      'AM': 'آرمینیا',
      'AO': 'انگولا',
      'AQ': 'انٹارکٹیکا',
      'AR': 'ارجنٹینا',
      'AS': 'امریکی ساموآ',
      'AT': 'آسٹریا',
      'AU': 'آسٹریلیا',
      'AW': 'اروبا',
      'AX': 'آلینڈ آئلینڈز',
      'AZ': 'آذربائیجان',
      'BA': 'بوسنیا اور ہرزیگووینا',
      'BB': 'بارباڈوس',
      'BD': 'بنگلہ دیش',
      'BE': 'بیلجیم',
      'BF': 'برکینا فاسو',
      'BG': 'بلغاریہ',
      'BH': 'بحرین',
      'BI': 'برونڈی',
      'BJ': 'بینن',
      'BL': 'سینٹ برتھلیمی',
      'BM': 'برمودا',
      'BN': 'برونائی',
      'BO': 'بولیویا',
      'BQ': 'کریبیائی نیدرلینڈز',
      'BR': 'برازیل',
      'BS': 'بہاماس',
      'BT': 'بھوٹان',
      'BV': 'بؤویٹ آئلینڈ',
      'BW': 'بوتسوانا',
      'BY': 'بیلاروس',
      'BZ': 'بیلائز',
      'CA': 'کینیڈا',
      'CC': 'کوکوس (کیلنگ) جزائر',
      'CD': 'کانگو - کنشاسا',
      'CF': 'وسط افریقی جمہوریہ',
      'CG': 'کانگو - برازاویلے',
      'CH': 'سوئٹزر لینڈ',
      'CI': 'کوٹ ڈی آئیوری',
      'CK': 'کک آئلینڈز',
      'CL': 'چلی',
      'CM': 'کیمرون',
      'CN': 'چین',
      'CO': 'کولمبیا',
      'CR': 'کوسٹا ریکا',
      'CU': 'کیوبا',
      'CV': 'کیپ ورڈی',
      'CW': 'کیوراکاؤ',
      'CX': 'جزیرہ کرسمس',
      'CY': 'قبرص',
      'CZ': 'چیکیا',
      'DE': 'جرمنی',
      'DJ': 'جبوتی',
      'DK': 'ڈنمارک',
      'DM': 'ڈومنیکا',
      'DO': 'جمہوریہ ڈومینیکن',
      'DZ': 'الجیریا',
      'EC': 'ایکواڈور',
      'EE': 'اسٹونیا',
      'EG': 'مصر',
      'EH': 'مغربی صحارا',
      'ER': 'اریٹیریا',
      'ES': 'ہسپانیہ',
      'ET': 'ایتھوپیا',
      'FI': 'فن لینڈ',
      'FJ': 'فجی',
      'FK': 'فاکلینڈ جزائر',
      'FM': 'مائکرونیشیا',
      'FO': 'جزائر فارو',
      'FR': 'فرانس',
      'GA': 'گیبون',
      'GB': 'سلطنت متحدہ',
      'GD': 'گریناڈا',
      'GE': 'جارجیا',
      'GF': 'فرینچ گیانا',
      'GG': 'گوئرنسی',
      'GH': 'گھانا',
      'GI': 'جبل الطارق',
      'GL': 'گرین لینڈ',
      'GM': 'گیمبیا',
      'GN': 'گنی',
      'GP': 'گواڈیلوپ',
      'GQ': 'استوائی گیانا',
      'GR': 'یونان',
      'GS': 'جنوبی جارجیا اور جنوبی سینڈوچ جزائر',
      'GT': 'گواٹے مالا',
      'GU': 'گوام',
      'GW': 'گنی بساؤ',
      'GY': 'گیانا',
      'HK': 'ہانگ کانگ',
      'HM': 'ہیرڈ جزیرہ و میکڈونلڈ جزائر',
      'HN': 'ہونڈاروس',
      'HR': 'کروشیا',
      'HT': 'ہیٹی',
      'HU': 'ہنگری',
      'ID': 'انڈونیشیا',
      'IE': 'آئرلینڈ',
      'IL': 'اسرائیل',
      'IM': 'آئل آف مین',
      'IN': 'بھارت',
      'IO': 'برطانوی بحر ہند کا علاقہ',
      'IQ': 'عراق',
      'IR': 'ایران',
      'IS': 'آئس لینڈ',
      'IT': 'اٹلی',
      'JE': 'جرسی',
      'JM': 'جمائیکا',
      'JO': 'اردن',
      'JP': 'جاپان',
      'KE': 'کینیا',
      'KG': 'کرغزستان',
      'KH': 'کمبوڈیا',
      'KI': 'کریباتی',
      'KM': 'کوموروس',
      'KN': 'سینٹ کٹس اور نیویس',
      'KP': 'شمالی کوریا',
      'KR': 'جنوبی کوریا',
      'KW': 'کویت',
      'KY': 'کیمین آئلینڈز',
      'KZ': 'قزاخستان',
      'LA': 'لاؤس',
      'LB': 'لبنان',
      'LC': 'سینٹ لوسیا',
      'LI': 'لیشٹنسٹائن',
      'LK': 'سری لنکا',
      'LR': 'لائبیریا',
      'LS': 'لیسوتھو',
      'LT': 'لیتھونیا',
      'LU': 'لکسمبرگ',
      'LV': 'لٹویا',
      'LY': 'لیبیا',
      'MA': 'مراکش',
      'MC': 'موناکو',
      'MD': 'مالدووا',
      'ME': 'مونٹے نیگرو',
      'MF': 'سینٹ مارٹن',
      'MG': 'مڈغاسکر',
      'MH': 'مارشل آئلینڈز',
      'MK': 'شمالی مقدونیہ',
      'ML': 'مالی',
      'MM': 'میانمار (برما)',
      'MN': 'منگولیا',
      'MO': 'مکاؤ',
      'MP': 'شمالی ماریانا آئلینڈز',
      'MQ': 'مارٹینک',
      'MR': 'موریطانیہ',
      'MS': 'مونٹسیراٹ',
      'MT': 'مالٹا',
      'MU': 'ماریشس',
      'MV': 'مالدیپ',
      'MW': 'ملاوی',
      'MX': 'میکسیکو',
      'MY': 'ملائشیا',
      'MZ': 'موزمبیق',
      'NA': 'نامیبیا',
      'NC': 'نیو کلیڈونیا',
      'NE': 'نائجر',
      'NF': 'نارفوک آئلینڈ',
      'NG': 'نائجیریا',
      'NI': 'نکاراگووا',
      'NL': 'نیدر لینڈز',
      'NO': 'ناروے',
      'NP': 'نیپال',
      'NR': 'نؤرو',
      'NU': 'نیئو',
      'NZ': 'نیوزی لینڈ',
      'OM': 'عمان',
      'PA': 'پانامہ',
      'PE': 'پیرو',
      'PF': 'فرانسیسی پولینیشیا',
      'PG': 'پاپوآ نیو گنی',
      'PH': 'فلپائن',
      'PK': 'پاکستان',
      'PL': 'پولینڈ',
      'PM': 'سینٹ پیئر اور میکلیئون',
      'PN': 'پٹکائرن جزائر',
      'PR': 'پیورٹو ریکو',
      'PS': 'فلسطینی خطے',
      'PT': 'پرتگال',
      'PW': 'پلاؤ',
      'PY': 'پیراگوئے',
      'QA': 'قطر',
      'RE': 'ری یونین',
      'RO': 'رومانیہ',
      'RS': 'سربیا',
      'RU': 'روس',
      'RW': 'روانڈا',
      'SA': 'سعودی عرب',
      'SB': 'سولومن آئلینڈز',
      'SC': 'سشلیز',
      'SD': 'سوڈان',
      'SE': 'سویڈن',
      'SG': 'سنگاپور',
      'SH': 'سینٹ ہیلینا',
      'SI': 'سلووینیا',
      'SJ': 'سوالبرڈ اور جان ماین',
      'SK': 'سلوواکیہ',
      'SL': 'سیرالیون',
      'SM': 'سان مارینو',
      'SN': 'سینیگل',
      'SO': 'صومالیہ',
      'SR': 'سورینام',
      'SS': 'جنوبی سوڈان',
      'ST': 'ساؤ ٹومے اور پرنسپے',
      'SV': 'ال سلواڈور',
      'SX': 'سنٹ مارٹن',
      'SY': 'شام',
      'SZ': 'سواتنی',
      'TC': 'ٹرکس اور کیکوس جزائر',
      'TD': 'چاڈ',
      'TF': 'فرانسیسی جنوبی خطے',
      'TG': 'ٹوگو',
      'TH': 'تھائی لینڈ',
      'TJ': 'تاجکستان',
      'TK': 'ٹوکیلاؤ',
      'TL': 'تیمور لیسٹ',
      'TM': 'ترکمانستان',
      'TN': 'تونس',
      'TO': 'ٹونگا',
      'TR': 'ترکیہ',
      'TT': 'ترینیداد اور ٹوباگو',
      'TV': 'ٹووالو',
      'TW': 'تائیوان',
      'TZ': 'تنزانیہ',
      'UA': 'یوکرین',
      'UG': 'یوگنڈا',
      'UM': 'امریکہ سے باہر کے چھوٹے جزائر',
      'US': 'ریاست ہائے متحدہ امریکہ',
      'UY': 'یوروگوئے',
      'UZ': 'ازبکستان',
      'VA': 'ویٹیکن سٹی',
      'VC': 'سینٹ ونسنٹ اور گرینیڈائنز',
      'VE': 'وینزوئیلا',
      'VG': 'برٹش ورجن آئلینڈز',
      'VI': 'امریکی ورجن آئلینڈز',
      'VN': 'ویتنام',
      'VU': 'وینوآٹو',
      'WF': 'ویلیز اور فیوٹیونا',
      'WS': 'ساموآ',
      'XK': 'کوسووو',
      'YE': 'یمن',
      'YT': 'مایوٹ',
      'ZA': 'جنوبی افریقہ',
      'ZM': 'زامبیا',
      'ZW': 'زمبابوے',
      'other': '⁦$code‎⁩',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'رازداری کے انتخابات';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'ایمسٹرڈیم',
      'sgp': 'سنگاپور',
      'lax': 'لاس اینجلس',
      'mel': 'میلبورن',
      'syd': 'سڈنی',
      'sao': 'ساؤ پاؤلو',
      'yto': 'ٹورنٹو',
      'scl': 'سانتیاگو',
      'cdg': 'پیرس',
      'fra': 'فرینکفرٹ',
      'del': 'دہلی',
      'bom': 'ممبئی',
      'blr': 'بنگلور',
      'tlv': 'تل ابیب',
      'itm': 'اوساکا',
      'nrt': 'ٹوکیو',
      'mex': 'میکسیکو شہر',
      'waw': 'وارسا',
      'jnb': 'جوہانسبرگ',
      'icn': 'سیول',
      'mad': 'میڈرڈ',
      'sto': 'اسٹاک ہوم',
      'lhr': 'لندن',
      'man': 'مانچسٹر',
      'ord': 'شکاگو',
      'dfw': 'ڈیلس',
      'sea': 'سیئٹل',
      'sjc': 'سان فرانسسکو',
      'mia': 'میامی',
      'hnl': 'ہونولولو',
      'ewr': 'نیو یارک',
      'atl': 'اٹلانٹا',
      'hkg': 'ہانگ کانگ',
      'zrh': 'زیورخ',
      'gva': 'جنیوا',
      'svo': 'ماسکو',
      'led': 'سینٹ پیٹرزبرگ',
      'hel': 'ہیلسنکی',
      'tpe': 'تائپے',
      'dxb': 'دبئی',
      'kbp': 'کیف',
      'ist': 'استنبول',
      'otp': 'بخارسٹ',
      'los': 'لاگوس',
      'pty': 'پانامہ شہر',
      'kef': 'ریکیاوک',
      'ber': 'برلن',
      'ala': 'الماتی',
      'tbs': 'تبلیسی',
      'kul': 'کوالالمپور',
      'bkk': 'بینکاک',
      'cgk': 'جکارتہ',
      'mnl': 'منیلا',
      'nbo': 'نیروبی',
      'mxp': 'میلان',
      'dub': 'ڈبلن',
      'lis': 'لزبن',
      'lux': 'لکسمبرگ',
      'eze': 'بیونس آئرس',
      'akl': 'آکلینڈ',
      'yul': 'مونٹریال',
      'yvr': 'وینکوور',
      'den': 'ڈینور',
      'phx': 'فینکس',
      'iad': 'واشنگٹن ڈی سی',
      'bos': 'بوسٹن',
      'edi': 'ایڈنبرا',
      'other': '⁦$name‎⁩',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'کیا آپ کو 1VPN پسند آ رہا ہے؟';

  @override
  String get onevpnYes => 'ہاں';

  @override
  String get onevpnNo => 'نہیں';

  @override
  String get onevpnLocationLocked => 'مقفل، صرف پریمیم';

  @override
  String get onevpnManageSubscription => 'سبسکرپشن کا انتظام کریں';
}
