// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class OneVpnLocalizationsAr extends OneVpnLocalizations {
  OneVpnLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get onevpnFaq => 'الأسئلة الشائعة';

  @override
  String get onevpnTermsOfService => 'شروط الخدمة';

  @override
  String get onevpnMenu => 'القائمة';

  @override
  String get onevpnUpgrade => 'ترقية';

  @override
  String get onevpnUpgradeBannerTitle => 'الترقية إلى بريميوم';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'بدون إعلانات، جميع المواقع وسرعات أعلى';

  @override
  String get onevpnLogIn => 'تسجيل الدخول';

  @override
  String get onevpnLogOut => 'تسجيل الخروج';

  @override
  String get onevpnAccount => 'الحساب';

  @override
  String get onevpnContactUs => 'اتصل بنا';

  @override
  String get onevpnRefundPolicy => 'سياسة استرداد الأموال';

  @override
  String get onevpnSupport => 'الدعم';

  @override
  String get onevpnLanguage => 'اللغة';

  @override
  String get onevpnLanguageSystem => 'الإعداد التلقائي للنظام';

  @override
  String get onevpnPlanFree => 'الخطة المجانية';

  @override
  String get onevpnPlanPremium => 'خطة بريميوم';

  @override
  String get onevpnSelectLocation => 'اختر الموقع';

  @override
  String get onevpnDirectRegions => 'مناطق الاتصال المباشر';

  @override
  String get onevpnFree => 'مجاني';

  @override
  String onevpnFreeSubtitle(String country) {
    return '⁦$country‎⁩ · مجاني';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'تلقائي · ⁦$node‎⁩';
  }

  @override
  String get onevpnAutomaticSelection => 'تلقائي';

  @override
  String get onevpnStatusNoConnection => 'لا يوجد اتصال';

  @override
  String get onevpnStatusConnectionFailed => 'فشل الاتصال';

  @override
  String get onevpnStatusUpdating => 'جارٍ التحديث…';

  @override
  String get onevpnStatusMeasuring => 'جارٍ قياس الخوادم…';

  @override
  String get onevpnAutomaticSubtitle => 'أسرع خادم متاح';

  @override
  String get onevpnLocationsLoadFailed => 'تعذّر تحميل مواقعك.';

  @override
  String get onevpnLocationsUnavailable => 'المواقع غير متاحة حاليًا.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'لا تعمل بعض مواقع الويب إلا عند الاتصال من البلد الذي توجد فيه. عند اختيار منطقة، يتم الوصول إلى مواقع الويب في تلك المنطقة دون المرور عبر شبكة ⁦VPN‎⁩.';

  @override
  String onevpnSelectionReset(String location) {
    return '⁦$location‎⁩ غير متاح، لذا انتقل ⁦1VPN‎⁩ إلى «تلقائي».';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'الموقع المحدد غير متاح، لذا انتقل ⁦1VPN‎⁩ إلى «تلقائي».';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'تعذّر التبديل إلى ⁦$location‎⁩. ما زلت متصلًا بموقعك السابق.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'تعذّر تطبيق التغيير. ما زلت متصلًا بإعداداتك السابقة.';

  @override
  String get onevpnDirectRegionsOff => 'إيقاف (افتراضي)';

  @override
  String get onevpnAllViaVpnSubtitle => 'جميع حركة البيانات عبر النفق';

  @override
  String get onevpnRegionChina => 'الصين';

  @override
  String get onevpnFirstConnectTitle =>
      'بعض المناطق تعمل بشكل أفضل باتصال مباشر';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'في أماكن مثل الصين وروسيا وإيران، قد يؤدي تمرير جميع حركة البيانات عبر شبكة ⁦VPN‎⁩ إلى تعطّل تطبيقات البنوك والدفع المحلية.';

  @override
  String get onevpnFirstConnectPointDirect =>
      'يمكن لتطبيق ⁦1VPN‎⁩ توجيه حركة بيانات منطقة تختارها مباشرةً، خارج النفق، باستخدام عنوان ⁦IP‎⁩ الحقيقي الخاص بك.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'تبقى حركة البيانات الأخرى محمية. ويمكنك تغيير ذلك في أي وقت.';

  @override
  String get onevpnFirstConnectChooseRegion => 'اختر منطقة الاتصال المباشر';

  @override
  String get onevpnFirstConnectDismiss => 'ليس الآن';

  @override
  String get onevpnCensorshipWarning =>
      'قد تكون بعض الخوادم محجوبة في منطقتك بسبب قيود حكومية. نحن نعمل على حل هذه المشكلة. شكراً لتفهمك.';

  @override
  String get onevpnAlwaysOnTitle => '‏شبكة VPN قيد التشغيل دائمًا';

  @override
  String get onevpnAlwaysOnIntro =>
      'يظل النفق متصلًا عند إغلاق التطبيق. بعد إعادة تشغيل الجهاز أو تحديث التطبيق، تعيد ميزة «‏شبكة VPN قيد التشغيل دائمًا» توصيله تلقائيًا.';

  @override
  String get onevpnAlwaysOnStep1 => 'انقر على «فتح إعدادات ‏شبكة VPN» أدناه.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'ابحث عن ⁦1VPN‎⁩ في قائمة الشبكات. يظهر بعد أول اتصال لك.';

  @override
  String get onevpnAlwaysOnStep3 => 'انقر على رمز الترس بجانب ⁦1VPN‎⁩.';

  @override
  String get onevpnAlwaysOnStep4 => 'فعّل «‏شبكة VPN قيد التشغيل دائمًا».';

  @override
  String get onevpnAlwaysOnOpenSettings => 'فتح إعدادات ‏شبكة VPN';

  @override
  String get onevpnPaywallTitle => 'اختر خطتك';

  @override
  String get onevpnPaywallBenefitLocations => 'افتح جميع مواقع الخوادم';

  @override
  String get onevpnPaywallBenefitNoAds => 'بدون إعلانات';

  @override
  String get onevpnPaywallBenefitSpeed => 'سرعات خوادم أسرع';

  @override
  String get onevpnPaywallBenefitP2p => 'دعم BitTorrent (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack =>
      'ضمان استرداد الأموال لمدة 10 أيام';

  @override
  String get onevpnPaywallPlanYearly => 'سنوي';

  @override
  String get onevpnPaywallPlanMonthly => 'شهري';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'وفّر ⁦$percent%‎⁩';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '⁦$amount $currency‎⁩ / شهر';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'السعر غير متاح';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'تعذّر تحميل الخطط. تحقق من اتصالك.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'الخطط غير متاحة حاليًا. يُرجى المحاولة مرة أخرى لاحقًا.';

  @override
  String get onevpnGetPremium => 'احصل على بريميوم';

  @override
  String get onevpnContinueFree => 'استمر مجاناً';

  @override
  String get onevpnPaywallRetry => 'إعادة المحاولة';

  @override
  String get onevpnPaywallPurchaseError =>
      'حدث خطأ ما. يُرجى المحاولة مرة أخرى.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'لدى حساب ⁦Google‎⁩ هذا اشتراك ⁦1VPN‎⁩ نشط أو منتهٍ مؤخرًا ومرتبط بحساب ⁦1VPN‎⁩ آخر. سجّل الدخول إلى ذلك الحساب أو تواصل مع $support.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'لدى حساب ⁦Google‎⁩ هذا اشتراك ⁦1VPN‎⁩ بالفعل. إذا لم يظهر بريميوم، فتواصل مع $support.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'لم يُكمل ⁦Google Play‎⁩ عملية الشراء الأخيرة. أغلق أي شاشة مفتوحة من ⁦Google Play‎⁩ وحاول مرة أخرى، أو أعد تشغيل التطبيق.';

  @override
  String get onevpnPaywallSupportLink => 'دعم ⁦1VPN‎⁩';

  @override
  String get onevpnSignUp => 'تسجيل';

  @override
  String get onevpnAuthEmailLabel => 'البريد الإلكتروني';

  @override
  String get onevpnAuthPasswordLabel => 'كلمة المرور';

  @override
  String get onevpnAuthTwoFactorLabel => 'رمز التحقق الثنائي';

  @override
  String get onevpnAuthForgotPassword => 'هل نسيت كلمة المرور؟';

  @override
  String get onevpnAuthSubmitting => 'جارٍ التحميل…';

  @override
  String get onevpnAuthCreateAccount => 'إنشاء حساب';

  @override
  String get onevpnAuthHaveAccount => 'هل لديك حساب؟';

  @override
  String get onevpnAuthLogInInstead => 'تسجيل الدخول بدلًا من ذلك';

  @override
  String get onevpnAuthFieldsRequired => 'أدخل البريد الإلكتروني وكلمة المرور';

  @override
  String get onevpnAuthInvalidEmail => 'أدخل عنوان بريد إلكتروني صالحًا';

  @override
  String get onevpnAuthInvalidCredentials => 'بيانات تسجيل الدخول غير صحيحة';

  @override
  String get onevpnAuthInvalidTwoFactor => 'رمز التحقق الثنائي غير صالح';

  @override
  String get onevpnAuthEmailInUse => 'يوجد حساب بالفعل لهذا البريد الإلكتروني';

  @override
  String get onevpnAuthRateLimited =>
      'محاولات كثيرة جدًا. يُرجى المحاولة مرة أخرى بعد قليل';

  @override
  String get onevpnAuthUnreachable =>
      'تعذّر الوصول إلى الخادم. تحقق من اتصالك وأعد المحاولة';

  @override
  String get onevpnAuthGenericError => 'حدث خطأ ما. يُرجى المحاولة مرة أخرى';

  @override
  String get onevpnAuthEmailLockedHint =>
      'تم ربط عملية الشراء بعنوان البريد الإلكتروني هذا.';

  @override
  String get onevpnPaywallPurchasedTitle => 'اكتملت عملية الشراء';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'تم ربط عملية الشراء بالعنوان ⁦$email‎⁩. أنشئ حسابًا بهذا العنوان لاستخدامها.';
  }

  @override
  String get onevpnPlanPremiumPending => 'بريميوم · جارٍ تأكيد الشراء';

  @override
  String get onevpnPremiumRecheck => 'جارٍ التحقق من حالة الشراء…';

  @override
  String get onevpnButtonRetry => 'إعادة المحاولة';

  @override
  String get onevpnAppVersion => 'إصدار التطبيق';

  @override
  String get onevpnPrivacyPolicy => 'سياسة الخصوصية';

  @override
  String get onevpnConnect => 'اتصال';

  @override
  String get onevpnDisconnected => 'غير متصل';

  @override
  String get onevpnConnecting => 'جارٍ الاتصال…';

  @override
  String get onevpnConnected => 'متصل';

  @override
  String get onevpnDisconnecting => 'جارٍ قطع الاتصال…';

  @override
  String get onevpnConnectionFailed => 'فشل الاتصال';

  @override
  String get onevpnTemporarilyUnavailable => 'غير متاح مؤقتًا';

  @override
  String get onevpnRetry => 'إعادة المحاولة';

  @override
  String get onevpnApplyChange => 'هل تريد تطبيق هذا التغيير؟';

  @override
  String get onevpnReconnectNotice =>
      'سيتم قطع اتصال شبكة ⁦VPN‎⁩ لفترة وجيزة ثم إعادة الاتصال. يستغرق ذلك عادةً بضع ثوانٍ فقط.';

  @override
  String onevpnWillUseName(String name) {
    return 'سيتم استخدام: ⁦$name‎⁩';
  }

  @override
  String get onevpnApplyAndReconnect => 'تطبيق وإعادة الاتصال';

  @override
  String get onevpnCancel => 'إلغاء';

  @override
  String get onevpnContinue => 'متابعة';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'النطاق الرئيسي محظور. يتم استخدام النطاق الاحتياطي: ⁦$domain‎⁩';
  }

  @override
  String get onevpnResultFailed => 'فشل';

  @override
  String get onevpnDownload => 'تنزيل';

  @override
  String get onevpnPermissionNotGranted => 'لم يتم منح الإذن';

  @override
  String onevpnActionResult(String action, String result) {
    return '⁦$result‎⁩ ⁦$action‎⁩';
  }

  @override
  String get onevpnDisconnect => 'قطع الاتصال';

  @override
  String get onevpnTimeout => 'انتهت المهلة';

  @override
  String get onevpnNoAvailableEntries => 'لا توجد خوادم دخول متاحة';

  @override
  String get onevpnAddServers => 'أضف خوادم';

  @override
  String get onevpnNotEnoughServers => 'لا تتوفر خوادم كافية';

  @override
  String get onevpnVpnFinalExit => 'المخرج النهائي لشبكة ⁦VPN‎⁩';

  @override
  String get onevpnFinalExitEntryConflict =>
      'لا يمكن أن يكون المخرج النهائي هو خادم الدخول أيضًا';

  @override
  String get onevpnChooseNamedRoute => 'اختر مسارًا واحدًا مُسمّى';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'اسمح بالوصول إلى الأجهزة والخدمات على الشبكة المحلية.';

  @override
  String get onevpnSystemApprovalRequired => 'يلزم الحصول على موافقة النظام';

  @override
  String get onevpnVpnPermissionRequired =>
      'يلزم منح إذن شبكة ⁦VPN‎⁩. يُرجى إعادة المحاولة للمتابعة.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'اختر الواجهة المستخدمة للوصول إلى الشبكة. مطلوب على ⁦Windows / Linux‎⁩ فقط.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'أندورا',
      'AE': 'الإمارات العربية المتحدة',
      'AF': 'أفغانستان',
      'AG': 'أنتيغوا وبربودا',
      'AI': 'أنغويلا',
      'AL': 'ألبانيا',
      'AM': 'أرمينيا',
      'AO': 'أنغولا',
      'AQ': 'أنتاركتيكا',
      'AR': 'الأرجنتين',
      'AS': 'ساموا الأمريكية',
      'AT': 'النمسا',
      'AU': 'أستراليا',
      'AW': 'أروبا',
      'AX': 'جزر آلاند',
      'AZ': 'أذربيجان',
      'BA': 'البوسنة والهرسك',
      'BB': 'بربادوس',
      'BD': 'بنغلاديش',
      'BE': 'بلجيكا',
      'BF': 'بوركينا فاسو',
      'BG': 'بلغاريا',
      'BH': 'البحرين',
      'BI': 'بوروندي',
      'BJ': 'بنين',
      'BL': 'سان بارتليمي',
      'BM': 'برمودا',
      'BN': 'بروناي',
      'BO': 'بوليفيا',
      'BQ': 'هولندا الكاريبية',
      'BR': 'البرازيل',
      'BS': 'جزر البهاما',
      'BT': 'بوتان',
      'BV': 'جزيرة بوفيه',
      'BW': 'بوتسوانا',
      'BY': 'بيلاروس',
      'BZ': 'بليز',
      'CA': 'كندا',
      'CC': 'جزر كوكوس (كيلينغ)',
      'CD': 'الكونغو - كينشاسا',
      'CF': 'جمهورية أفريقيا الوسطى',
      'CG': 'الكونغو - برازافيل',
      'CH': 'سويسرا',
      'CI': 'ساحل العاج',
      'CK': 'جزر كوك',
      'CL': 'تشيلي',
      'CM': 'الكاميرون',
      'CN': 'بر الصين الرئيسي',
      'CO': 'كولومبيا',
      'CR': 'كوستاريكا',
      'CU': 'كوبا',
      'CV': 'الرأس الأخضر',
      'CW': 'كوراساو',
      'CX': 'جزيرة كريسماس',
      'CY': 'قبرص',
      'CZ': 'التشيك',
      'DE': 'ألمانيا',
      'DJ': 'جيبوتي',
      'DK': 'الدانمرك',
      'DM': 'دومينيكا',
      'DO': 'جمهورية الدومينيكان',
      'DZ': 'الجزائر',
      'EC': 'الإكوادور',
      'EE': 'إستونيا',
      'EG': 'مصر',
      'EH': 'الصحراء الغربية',
      'ER': 'إريتريا',
      'ES': 'إسبانيا',
      'ET': 'إثيوبيا',
      'FI': 'فنلندا',
      'FJ': 'فيجي',
      'FK': 'جزر فوكلاند',
      'FM': 'ميكرونيزيا',
      'FO': 'جزر فارو',
      'FR': 'فرنسا',
      'GA': 'الغابون',
      'GB': 'المملكة المتحدة',
      'GD': 'غرينادا',
      'GE': 'جورجيا',
      'GF': 'غويانا الفرنسية',
      'GG': 'غيرنزي',
      'GH': 'غانا',
      'GI': 'جبل طارق',
      'GL': 'غرينلاند',
      'GM': 'غامبيا',
      'GN': 'غينيا',
      'GP': 'غوادلوب',
      'GQ': 'غينيا الاستوائية',
      'GR': 'اليونان',
      'GS': 'جورجيا الجنوبية وجزر ساندويتش الجنوبية',
      'GT': 'غواتيمالا',
      'GU': 'غوام',
      'GW': 'غينيا بيساو',
      'GY': 'غيانا',
      'HK': 'هونغ كونغ',
      'HM': 'جزيرة هيرد وجزر ماكدونالد',
      'HN': 'هندوراس',
      'HR': 'كرواتيا',
      'HT': 'هايتي',
      'HU': 'هنغاريا',
      'ID': 'إندونيسيا',
      'IE': 'أيرلندا',
      'IL': 'إسرائيل',
      'IM': 'جزيرة مان',
      'IN': 'الهند',
      'IO': 'أرخببيل تشاغوس',
      'IQ': 'العراق',
      'IR': 'إيران',
      'IS': 'آيسلندا',
      'IT': 'إيطاليا',
      'JE': 'جيرسي',
      'JM': 'جامايكا',
      'JO': 'الأردن',
      'JP': 'اليابان',
      'KE': 'كينيا',
      'KG': 'قيرغيزستان',
      'KH': 'كمبوديا',
      'KI': 'كيريباتي',
      'KM': 'جزر القمر',
      'KN': 'سانت كيتس ونيفيس',
      'KP': 'كوريا الشمالية',
      'KR': 'كوريا الجنوبية',
      'KW': 'الكويت',
      'KY': 'جزر كايمان',
      'KZ': 'كازاخستان',
      'LA': 'لاوس',
      'LB': 'لبنان',
      'LC': 'سانت لوسيا',
      'LI': 'ليختنشتاين',
      'LK': 'سريلانكا',
      'LR': 'ليبيريا',
      'LS': 'ليسوتو',
      'LT': 'ليتوانيا',
      'LU': 'لوكسمبورغ',
      'LV': 'لاتفيا',
      'LY': 'ليبيا',
      'MA': 'المغرب',
      'MC': 'موناكو',
      'MD': 'مولدوفا',
      'ME': 'الجبل الأسود',
      'MF': 'سان مارتن',
      'MG': 'مدغشقر',
      'MH': 'جزر مارشال',
      'MK': 'مقدونيا الشمالية',
      'ML': 'مالي',
      'MM': 'ميانمار (بورما)',
      'MN': 'منغوليا',
      'MO': 'ماكاو',
      'MP': 'جزر ماريانا الشمالية',
      'MQ': 'جزر المارتينيك',
      'MR': 'موريتانيا',
      'MS': 'مونتسرات',
      'MT': 'مالطا',
      'MU': 'موريشيوس',
      'MV': 'جزر المالديف',
      'MW': 'ملاوي',
      'MX': 'المكسيك',
      'MY': 'ماليزيا',
      'MZ': 'موزمبيق',
      'NA': 'ناميبيا',
      'NC': 'كاليدونيا الجديدة',
      'NE': 'النيجر',
      'NF': 'جزيرة نورفولك',
      'NG': 'نيجيريا',
      'NI': 'نيكاراغوا',
      'NL': 'هولندا',
      'NO': 'النرويج',
      'NP': 'نيبال',
      'NR': 'ناورو',
      'NU': 'نيوي',
      'NZ': 'نيوزيلندا',
      'OM': 'عُمان',
      'PA': 'بنما',
      'PE': 'بيرو',
      'PF': 'بولينيزيا الفرنسية',
      'PG': 'بابوا غينيا الجديدة',
      'PH': 'الفلبين',
      'PK': 'باكستان',
      'PL': 'بولندا',
      'PM': 'سان بيير ومكويلون',
      'PN': 'جزر بيتكيرن',
      'PR': 'بورتوريكو',
      'PS': 'الأراضي الفلسطينية',
      'PT': 'البرتغال',
      'PW': 'بالاو',
      'PY': 'باراغواي',
      'QA': 'قطر',
      'RE': 'روينيون',
      'RO': 'رومانيا',
      'RS': 'صربيا',
      'RU': 'روسيا',
      'RW': 'رواندا',
      'SA': 'المملكة العربية السعودية',
      'SB': 'جزر سليمان',
      'SC': 'سيشل',
      'SD': 'السودان',
      'SE': 'السويد',
      'SG': 'سنغافورة',
      'SH': 'سانت هيلينا',
      'SI': 'سلوفينيا',
      'SJ': 'سفالبارد وجان ماين',
      'SK': 'سلوفاكيا',
      'SL': 'سيراليون',
      'SM': 'سان مارينو',
      'SN': 'السنغال',
      'SO': 'الصومال',
      'SR': 'سورينام',
      'SS': 'جنوب السودان',
      'ST': 'ساو تومي وبرينسيبي',
      'SV': 'السلفادور',
      'SX': 'سانت مارتن',
      'SY': 'سوريا',
      'SZ': 'إسواتيني',
      'TC': 'جزر توركس وكايكوس',
      'TD': 'تشاد',
      'TF': 'الأقاليم الجنوبية الفرنسية',
      'TG': 'توغو',
      'TH': 'تايلاند',
      'TJ': 'طاجيكستان',
      'TK': 'توكيلاو',
      'TL': 'تيمور - ليشتي',
      'TM': 'تركمانستان',
      'TN': 'تونس',
      'TO': 'تونغا',
      'TR': 'تركيا',
      'TT': 'ترينيداد وتوباغو',
      'TV': 'توفالو',
      'TW': 'تايوان',
      'TZ': 'تنزانيا',
      'UA': 'أوكرانيا',
      'UG': 'أوغندا',
      'UM': 'جزر الولايات المتحدة النائية',
      'US': 'الولايات المتحدة',
      'UY': 'أورغواي',
      'UZ': 'أوزبكستان',
      'VA': 'الفاتيكان',
      'VC': 'سانت فنسنت وجزر غرينادين',
      'VE': 'فنزويلا',
      'VG': 'جزر فيرجن البريطانية',
      'VI': 'جزر فيرجن الأمريكية',
      'VN': 'فيتنام',
      'VU': 'فانواتو',
      'WF': 'جزر والس وفوتونا',
      'WS': 'ساموا',
      'XK': 'كوسوفو',
      'YE': 'اليمن',
      'YT': 'مايوت',
      'ZA': 'جنوب أفريقيا',
      'ZM': 'زامبيا',
      'ZW': 'زيمبابوي',
      'other': '⁦$code‎⁩',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'خيارات الخصوصية';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'أمستردام',
      'sgp': 'سنغافورة',
      'lax': 'لوس أنجلوس',
      'mel': 'ملبورن',
      'syd': 'سيدني',
      'sao': 'ساو باولو',
      'yto': 'تورنتو',
      'scl': 'سانتياغو',
      'cdg': 'باريس',
      'fra': 'فرانكفورت',
      'del': 'دلهي',
      'bom': 'مومباي',
      'blr': 'بنغالور',
      'tlv': 'تل أبيب',
      'itm': 'أوساكا',
      'nrt': 'طوكيو',
      'mex': 'مكسيكو سيتي',
      'waw': 'وارسو',
      'jnb': 'جوهانسبرغ',
      'icn': 'سيول',
      'mad': 'مدريد',
      'sto': 'ستوكهولم',
      'lhr': 'لندن',
      'man': 'مانشستر',
      'ord': 'شيكاغو',
      'dfw': 'دالاس',
      'sea': 'سياتل',
      'sjc': 'سان فرانسيسكو',
      'mia': 'ميامي',
      'hnl': 'هونولولو',
      'ewr': 'نيويورك',
      'atl': 'أتلانتا',
      'hkg': 'هونغ كونغ',
      'zrh': 'زيورخ',
      'gva': 'جنيف',
      'svo': 'موسكو',
      'led': 'سانت بطرسبرغ',
      'hel': 'هلسنكي',
      'tpe': 'تايبيه',
      'dxb': 'دبي',
      'kbp': 'كييف',
      'ist': 'إسطنبول',
      'otp': 'بوخارست',
      'los': 'لاغوس',
      'pty': 'مدينة بنما',
      'kef': 'ريكيافيك',
      'ber': 'برلين',
      'ala': 'ألماتي',
      'tbs': 'تبليسي',
      'kul': 'كوالالمبور',
      'bkk': 'بانكوك',
      'cgk': 'جاكرتا',
      'mnl': 'مانيلا',
      'nbo': 'نيروبي',
      'mxp': 'ميلانو',
      'dub': 'دبلن',
      'lis': 'لشبونة',
      'lux': 'لوكسمبورغ',
      'eze': 'بوينس آيرس',
      'akl': 'أوكلاند',
      'yul': 'مونتريال',
      'yvr': 'فانكوفر',
      'den': 'دنفر',
      'phx': 'فينيكس',
      'iad': 'واشنطن العاصمة',
      'bos': 'بوسطن',
      'edi': 'إدنبرة',
      'other': '⁦$name‎⁩',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'هل تستمتع باستخدام 1VPN؟';

  @override
  String get onevpnYes => 'نعم';

  @override
  String get onevpnNo => 'لا';

  @override
  String get onevpnLocationLocked => 'مقفل، بريميوم فقط';

  @override
  String get onevpnManageSubscription => 'إدارة الاشتراك';
}
