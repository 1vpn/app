// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class OneVpnLocalizationsFa extends OneVpnLocalizations {
  OneVpnLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get onevpnFaq => 'پرسش‌های متداول';

  @override
  String get onevpnTermsOfService => 'شرایط استفاده از خدمات';

  @override
  String get onevpnMenu => 'منو';

  @override
  String get onevpnUpgrade => 'ارتقاء';

  @override
  String get onevpnUpgradeBannerTitle => 'ارتقاء به پریمیوم';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'بدون تبلیغات، همهٔ مکان‌ها و سرعت بالاتر';

  @override
  String get onevpnLogIn => 'ورود';

  @override
  String get onevpnLogOut => 'خروج';

  @override
  String get onevpnAccount => 'حساب';

  @override
  String get onevpnContactUs => 'تماس با ما';

  @override
  String get onevpnRefundPolicy => 'سیاست بازگشت وجه';

  @override
  String get onevpnSupport => 'پشتیبانی';

  @override
  String get onevpnLanguage => 'زبان';

  @override
  String get onevpnLanguageSystem => 'پیروی از سیستم';

  @override
  String get onevpnPlanFree => 'طرح رایگان';

  @override
  String get onevpnPlanPremium => 'طرح پریمیوم';

  @override
  String get onevpnSelectLocation => 'انتخاب مکان';

  @override
  String get onevpnDirectRegions => 'مناطق اتصال مستقیم';

  @override
  String get onevpnFree => 'رایگان';

  @override
  String onevpnFreeSubtitle(String country) {
    return '⁦$country‎⁩ · رایگان';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'خودکار · ⁦$node‎⁩';
  }

  @override
  String get onevpnAutomaticSelection => 'خودکار';

  @override
  String get onevpnStatusNoConnection => 'بدون اتصال';

  @override
  String get onevpnStatusConnectionFailed => 'اتصال ناموفق بود';

  @override
  String get onevpnStatusUpdating => 'در حال به‌روزرسانی…';

  @override
  String get onevpnStatusMeasuring => 'در حال سنجش سرورها…';

  @override
  String get onevpnAutomaticSubtitle => 'سریع‌ترین سرور در دسترس';

  @override
  String get onevpnLocationsLoadFailed => 'بارگذاری مکان‌های شما ناموفق بود.';

  @override
  String get onevpnLocationsUnavailable =>
      'مکان‌ها در حال حاضر در دسترس نیستند.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'برخی سایت‌ها فقط وقتی کار می‌کنند که از همان کشوری متصل شوید که سایت در آن است. با انتخاب یک منطقه، اتصال به سایت‌های آن منطقه بدون VPN برقرار می‌شود.';

  @override
  String onevpnSelectionReset(String location) {
    return '⁦$location‎⁩ در دسترس نیست و 1VPN گزینهٔ «خودکار» را انتخاب کرد.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'مکان انتخاب‌شده در دسترس نیست و 1VPN گزینهٔ «خودکار» را انتخاب کرد.';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'تغییر به ⁦$location‎⁩ ممکن نشد. همچنان به مکان قبلی خود متصل هستید.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'اعمال تغییر ممکن نشد. همچنان با تنظیمات قبلی خود متصل هستید.';

  @override
  String get onevpnDirectRegionsOff => 'خاموش (پیش‌فرض)';

  @override
  String get onevpnAllViaVpnSubtitle => 'همهٔ ترافیک از تونل عبور می‌کند';

  @override
  String get onevpnRegionChina => 'چین';

  @override
  String get onevpnFirstConnectTitle =>
      'برخی مناطق با اتصال مستقیم بهتر کار می‌کنند';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'در جاهایی مانند چین، روسیه و ایران، عبور همهٔ ترافیک از VPN ممکن است برنامه‌های بانکی و پرداخت محلی را از کار بیندازد.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '‏1VPN می‌تواند ترافیک منطقهٔ انتخابی شما را مستقیم و خارج از تونل، با IP واقعی‌تان عبور دهد.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'بقیهٔ ترافیک همچنان محافظت می‌شود. هر زمان بخواهید می‌توانید این تنظیم را تغییر دهید.';

  @override
  String get onevpnFirstConnectChooseRegion => 'انتخاب منطقهٔ اتصال مستقیم';

  @override
  String get onevpnFirstConnectDismiss => 'اکنون نه';

  @override
  String get onevpnCensorshipWarning =>
      'برخی از سرورها ممکن است به دلیل محدودیت‌های دولتی در ایران مسدود شده باشند. ما در حال رفع این مشکل هستیم. از درک شما سپاسگزاریم.';

  @override
  String get onevpnAlwaysOnTitle => '‏VPN همیشه روشن';

  @override
  String get onevpnAlwaysOnIntro =>
      'وقتی برنامه را می‌بندید، تونل متصل می‌ماند. پس از راه‌اندازی مجدد یا به‌روزرسانی برنامه، «‏VPN همیشه روشن» آن را به‌طور خودکار دوباره متصل می‌کند.';

  @override
  String get onevpnAlwaysOnStep1 =>
      'در پایین، روی «باز کردن تنظیمات VPN» ضربه بزنید.';

  @override
  String get onevpnAlwaysOnStep2 =>
      '‏1VPN را در فهرست پیدا کنید. این مورد پس از نخستین اتصال نمایش داده می‌شود.';

  @override
  String get onevpnAlwaysOnStep3 => 'روی نماد چرخ‌دنده کنار 1VPN ضربه بزنید.';

  @override
  String get onevpnAlwaysOnStep4 => '«‏VPN همیشه روشن» را فعال کنید.';

  @override
  String get onevpnAlwaysOnOpenSettings => 'باز کردن تنظیمات VPN';

  @override
  String get onevpnPaywallTitle => 'طرح خود را انتخاب کنید';

  @override
  String get onevpnPaywallBenefitLocations => 'دسترسی به همهٔ مکان‌های سرور';

  @override
  String get onevpnPaywallBenefitNoAds => 'بدون تبلیغات';

  @override
  String get onevpnPaywallBenefitSpeed => 'سرعت بالاتر سرورها';

  @override
  String get onevpnPaywallBenefitP2p => 'پشتیبانی از BitTorrent (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack => 'ضمانت بازگشت وجه ۱۰ روزه';

  @override
  String get onevpnPaywallPlanYearly => 'سالانه';

  @override
  String get onevpnPaywallPlanMonthly => 'ماهانه';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'صرفه‌جویی ⁦$percent٪‎⁩';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '⁦$amount $currency‎⁩ / ماه';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'قیمت در دسترس نیست';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'بارگذاری طرح‌ها ناموفق بود. اتصال خود را بررسی کنید.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'طرح‌ها در حال حاضر در دسترس نیستند. لطفاً بعداً دوباره تلاش کنید.';

  @override
  String get onevpnGetPremium => 'دریافت پریمیوم';

  @override
  String get onevpnContinueFree => 'ادامه رایگان';

  @override
  String get onevpnPaywallRetry => 'تلاش دوباره';

  @override
  String get onevpnPaywallPurchaseError =>
      'مشکلی پیش آمد. لطفاً دوباره تلاش کنید.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'این حساب Google یک اشتراک فعال یا اخیراً پایان‌یافتهٔ 1VPN دارد که به حساب 1VPN دیگری مرتبط است. وارد آن حساب شوید یا با $support تماس بگیرید.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'این حساب Google از قبل اشتراک 1VPN دارد. اگر پریمیوم نمایش داده نشد، با $support تماس بگیرید.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'خرید قبلی شما در Google Play کامل نشد. صفحه‌های باز Google Play را ببندید و دوباره تلاش کنید، یا برنامه را مجدداً راه‌اندازی کنید.';

  @override
  String get onevpnPaywallSupportLink => 'پشتیبانی 1VPN';

  @override
  String get onevpnSignUp => 'ثبت‌نام';

  @override
  String get onevpnAuthEmailLabel => 'ایمیل';

  @override
  String get onevpnAuthPasswordLabel => 'رمز عبور';

  @override
  String get onevpnAuthTwoFactorLabel => 'توکن احراز هویت دو مرحله‌ای';

  @override
  String get onevpnAuthForgotPassword => 'رمز عبور را فراموش کرده‌اید؟';

  @override
  String get onevpnAuthSubmitting => 'در حال بارگذاری…';

  @override
  String get onevpnAuthCreateAccount => 'ایجاد حساب کاربری';

  @override
  String get onevpnAuthHaveAccount => 'حساب کاربری دارید؟';

  @override
  String get onevpnAuthLogInInstead => 'ورود به‌جای ثبت‌نام';

  @override
  String get onevpnAuthFieldsRequired => 'ایمیل و رمز عبور را وارد کنید';

  @override
  String get onevpnAuthInvalidEmail => 'یک نشانی ایمیل معتبر وارد کنید';

  @override
  String get onevpnAuthInvalidCredentials => 'اطلاعات ورود نامعتبر است';

  @override
  String get onevpnAuthInvalidTwoFactor =>
      'توکن احراز هویت دو مرحله‌ای نامعتبر است';

  @override
  String get onevpnAuthEmailInUse =>
      'برای این ایمیل قبلاً حساب کاربری ساخته شده است';

  @override
  String get onevpnAuthRateLimited =>
      'تعداد تلاش‌ها بیش از حد است. لطفاً کمی بعد دوباره تلاش کنید';

  @override
  String get onevpnAuthUnreachable =>
      'دسترسی به سرور ممکن نشد. اتصال خود را بررسی کرده و دوباره تلاش کنید';

  @override
  String get onevpnAuthGenericError => 'مشکلی پیش آمد. لطفاً دوباره تلاش کنید';

  @override
  String get onevpnAuthEmailLockedHint =>
      'خرید شما به این نشانی ایمیل مرتبط است.';

  @override
  String get onevpnPaywallPurchasedTitle => 'خرید انجام شد';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'خرید شما به ⁦$email‎⁩ مرتبط است. برای استفاده از آن، با همین نشانی حساب کاربری ایجاد کنید.';
  }

  @override
  String get onevpnPlanPremiumPending => 'پریمیوم · در حال تأیید خرید';

  @override
  String get onevpnPremiumRecheck => 'در حال بررسی وضعیت خرید شما…';

  @override
  String get onevpnButtonRetry => 'تلاش دوباره';

  @override
  String get onevpnAppVersion => 'نسخهٔ برنامه';

  @override
  String get onevpnPrivacyPolicy => 'سیاست حریم خصوصی';

  @override
  String get onevpnConnect => 'اتصال';

  @override
  String get onevpnDisconnected => 'قطع است';

  @override
  String get onevpnConnecting => 'در حال اتصال…';

  @override
  String get onevpnConnected => 'متصل';

  @override
  String get onevpnDisconnecting => 'در حال قطع اتصال…';

  @override
  String get onevpnConnectionFailed => 'اتصال ناموفق بود';

  @override
  String get onevpnTemporarilyUnavailable => 'موقتاً در دسترس نیست';

  @override
  String get onevpnRetry => 'تلاش دوباره';

  @override
  String get onevpnApplyChange => 'این تغییر اعمال شود؟';

  @override
  String get onevpnReconnectNotice =>
      'VPN برای لحظه‌ای قطع و دوباره متصل می‌شود. این کار معمولاً فقط چند ثانیه طول می‌کشد.';

  @override
  String onevpnWillUseName(String name) {
    return 'استفاده خواهد شد: ⁦$name‎⁩';
  }

  @override
  String get onevpnApplyAndReconnect => 'اعمال و اتصال دوباره';

  @override
  String get onevpnCancel => 'لغو';

  @override
  String get onevpnContinue => 'ادامه';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'دامنه اصلی مسدود است. در حال استفاده از دامنه پشتیبان: ⁦$domain‎⁩';
  }

  @override
  String get onevpnResultFailed => 'ناموفق';

  @override
  String get onevpnDownload => 'دانلود';

  @override
  String get onevpnPermissionNotGranted => 'مجوز داده نشده';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action $result';
  }

  @override
  String get onevpnDisconnect => 'قطع اتصال';

  @override
  String get onevpnTimeout => 'مهلت';

  @override
  String get onevpnNoAvailableEntries => 'هیچ سرور ورودی در دسترس نیست';

  @override
  String get onevpnAddServers => 'افزودن سرورها';

  @override
  String get onevpnNotEnoughServers => 'سرور در دسترس کافی نیست';

  @override
  String get onevpnVpnFinalExit => 'خروجی نهایی VPN';

  @override
  String get onevpnFinalExitEntryConflict =>
      'خروجی نهایی نمی‌تواند هم‌زمان سرور ورودی باشد';

  @override
  String get onevpnChooseNamedRoute =>
      'یک طرح مسیریابی نام‌گذاری‌شده انتخاب کنید';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'اجازهٔ دسترسی به دستگاه‌ها و سرویس‌های شبکهٔ محلی.';

  @override
  String get onevpnSystemApprovalRequired => 'نیازمند تأیید سیستم';

  @override
  String get onevpnVpnPermissionRequired =>
      'مجوز VPN لازم است. برای ادامه دوباره امتحان کنید.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'رابط مورد استفاده برای دسترسی به شبکه را انتخاب کنید. فقط در Windows / Linux لازم است.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'آندورا',
      'AE': 'امارات متحدهٔ عربی',
      'AF': 'افغانستان',
      'AG': 'آنتیگوا و باربودا',
      'AI': 'آنگویلا',
      'AL': 'آلبانی',
      'AM': 'ارمنستان',
      'AO': 'آنگولا',
      'AQ': 'جنوبگان',
      'AR': 'آرژانتین',
      'AS': 'ساموآی امریکا',
      'AT': 'اتریش',
      'AU': 'استرالیا',
      'AW': 'آروبا',
      'AX': 'جزایر آلاند',
      'AZ': 'جمهوری آذربایجان',
      'BA': 'بوسنی و هرزگوین',
      'BB': 'باربادوس',
      'BD': 'بنگلادش',
      'BE': 'بلژیک',
      'BF': 'بورکینافاسو',
      'BG': 'بلغارستان',
      'BH': 'بحرین',
      'BI': 'بوروندی',
      'BJ': 'بنین',
      'BL': 'سن بارتلمی',
      'BM': 'برمودا',
      'BN': 'برونئی',
      'BO': 'بولیوی',
      'BQ': 'جزایر کارائیب هلند',
      'BR': 'برزیل',
      'BS': 'باهاما',
      'BT': 'بوتان',
      'BV': 'جزیرهٔ بووه',
      'BW': 'بوتسوانا',
      'BY': 'بلاروس',
      'BZ': 'بلیز',
      'CA': 'کانادا',
      'CC': 'جزایر کوکوس',
      'CD': 'کنگو - کینشاسا',
      'CF': 'جمهوری افریقای مرکزی',
      'CG': 'کنگو - برازویل',
      'CH': 'سوئیس',
      'CI': 'ساحل عاج',
      'CK': 'جزایر کوک',
      'CL': 'شیلی',
      'CM': 'کامرون',
      'CN': 'سرزمین اصلی چین',
      'CO': 'کلمبیا',
      'CR': 'کاستاریکا',
      'CU': 'کوبا',
      'CV': 'کیپ‌ورد',
      'CW': 'کوراسائو',
      'CX': 'جزیرهٔ کریسمس',
      'CY': 'قبرس',
      'CZ': 'چک',
      'DE': 'آلمان',
      'DJ': 'جیبوتی',
      'DK': 'دانمارک',
      'DM': 'دومینیکا',
      'DO': 'جمهوری دومینیکن',
      'DZ': 'الجزایر',
      'EC': 'اکوادور',
      'EE': 'استونی',
      'EG': 'مصر',
      'EH': 'صحرای غربی',
      'ER': 'اریتره',
      'ES': 'اسپانیا',
      'ET': 'اتیوپی',
      'FI': 'فنلاند',
      'FJ': 'فیجی',
      'FK': 'جزایر فالکلند',
      'FM': 'میکرونزی',
      'FO': 'جزایر فارو',
      'FR': 'فرانسه',
      'GA': 'گابن',
      'GB': 'بریتانیا',
      'GD': 'گرنادا',
      'GE': 'گرجستان',
      'GF': 'گویان فرانسه',
      'GG': 'گرنزی',
      'GH': 'غنا',
      'GI': 'جبل‌الطارق',
      'GL': 'گرینلند',
      'GM': 'گامبیا',
      'GN': 'گینه',
      'GP': 'گوادلوپ',
      'GQ': 'گینهٔ استوایی',
      'GR': 'یونان',
      'GS': 'جورجیای جنوبی و جزایر ساندویچ جنوبی',
      'GT': 'گواتمالا',
      'GU': 'گوام',
      'GW': 'گینهٔ بیسائو',
      'GY': 'گویان',
      'HK': 'هنگ‌کنگ',
      'HM': 'هرد و جزایر مک‌دونالد',
      'HN': 'هندوراس',
      'HR': 'کرواسی',
      'HT': 'هائیتی',
      'HU': 'مجارستان',
      'ID': 'اندونزی',
      'IE': 'ایرلند',
      'IL': 'اسرائیل',
      'IM': 'جزیرهٔ من',
      'IN': 'هند',
      'IO': 'قلمرو بریتانیا در اقیانوس هند',
      'IQ': 'عراق',
      'IR': 'ایران',
      'IS': 'ایسلند',
      'IT': 'ایتالیا',
      'JE': 'جرزی',
      'JM': 'جامائیکا',
      'JO': 'اردن',
      'JP': 'ژاپن',
      'KE': 'کنیا',
      'KG': 'قرقیزستان',
      'KH': 'کامبوج',
      'KI': 'کیریباتی',
      'KM': 'کومور',
      'KN': 'سنت کیتس و نویس',
      'KP': 'کرهٔ شمالی',
      'KR': 'کرهٔ جنوبی',
      'KW': 'کویت',
      'KY': 'جزایر کِیمن',
      'KZ': 'قزاقستان',
      'LA': 'لائوس',
      'LB': 'لبنان',
      'LC': 'سنت لوسیا',
      'LI': 'لیختن‌اشتاین',
      'LK': 'سری‌لانکا',
      'LR': 'لیبریا',
      'LS': 'لسوتو',
      'LT': 'لیتوانی',
      'LU': 'لوکزامبورگ',
      'LV': 'لتونی',
      'LY': 'لیبی',
      'MA': 'مراکش',
      'MC': 'موناکو',
      'MD': 'مولداوی',
      'ME': 'مونته‌نگرو',
      'MF': 'سنت مارتین',
      'MG': 'ماداگاسکار',
      'MH': 'جزایر مارشال',
      'MK': 'مقدونیهٔ شمالی',
      'ML': 'مالی',
      'MM': 'میانمار (برمه)',
      'MN': 'مغولستان',
      'MO': 'ماکائو',
      'MP': 'جزایر ماریانای شمالی',
      'MQ': 'مارتینیک',
      'MR': 'موریتانی',
      'MS': 'مونت‌سرات',
      'MT': 'مالت',
      'MU': 'موریس',
      'MV': 'مالدیو',
      'MW': 'مالاوی',
      'MX': 'مکزیک',
      'MY': 'مالزی',
      'MZ': 'موزامبیک',
      'NA': 'نامیبیا',
      'NC': 'کالدونیای جدید',
      'NE': 'نیجر',
      'NF': 'جزیرهٔ نورفولک',
      'NG': 'نیجریه',
      'NI': 'نیکاراگوئه',
      'NL': 'هلند',
      'NO': 'نروژ',
      'NP': 'نپال',
      'NR': 'نائورو',
      'NU': 'نیوئه',
      'NZ': 'نیوزیلند',
      'OM': 'عمان',
      'PA': 'پاناما',
      'PE': 'پرو',
      'PF': 'پلی‌نزی فرانسه',
      'PG': 'پاپوا گینهٔ نو',
      'PH': 'فیلیپین',
      'PK': 'پاکستان',
      'PL': 'لهستان',
      'PM': 'سن پیر و میکلن',
      'PN': 'جزایر پیت‌کرن',
      'PR': 'پورتوریکو',
      'PS': 'سرزمین‌های فلسطینی',
      'PT': 'پرتغال',
      'PW': 'پالائو',
      'PY': 'پاراگوئه',
      'QA': 'قطر',
      'RE': 'رئونیون',
      'RO': 'رومانی',
      'RS': 'صربستان',
      'RU': 'روسیه',
      'RW': 'رواندا',
      'SA': 'عربستان سعودی',
      'SB': 'جزایر سلیمان',
      'SC': 'سیشل',
      'SD': 'سودان',
      'SE': 'سوئد',
      'SG': 'سنگاپور',
      'SH': 'سنت هلن',
      'SI': 'اسلوونی',
      'SJ': 'سوالبارد و یان ماین',
      'SK': 'اسلواکی',
      'SL': 'سیرالئون',
      'SM': 'سان‌مارینو',
      'SN': 'سنگال',
      'SO': 'سومالی',
      'SR': 'سورینام',
      'SS': 'سودان جنوبی',
      'ST': 'سائوتومه و پرینسیپ',
      'SV': 'السالوادور',
      'SX': 'سنت مارتن',
      'SY': 'سوریه',
      'SZ': 'اسواتینی',
      'TC': 'جزایر تورکس و کایکوس',
      'TD': 'چاد',
      'TF': 'سرزمین‌های جنوبی فرانسه',
      'TG': 'توگو',
      'TH': 'تایلند',
      'TJ': 'تاجیکستان',
      'TK': 'توکلائو',
      'TL': 'تیمور-لسته',
      'TM': 'ترکمنستان',
      'TN': 'تونس',
      'TO': 'تونگا',
      'TR': 'ترکیه',
      'TT': 'ترینیداد و توباگو',
      'TV': 'تووالو',
      'TW': 'تایوان',
      'TZ': 'تانزانیا',
      'UA': 'اوکراین',
      'UG': 'اوگاندا',
      'UM': 'جزایر دورافتادهٔ ایالات متحده',
      'US': 'ایالات متحده',
      'UY': 'اروگوئه',
      'UZ': 'ازبکستان',
      'VA': 'واتیکان',
      'VC': 'سنت وینسنت و گرنادین',
      'VE': 'ونزوئلا',
      'VG': 'جزایر ویرجین بریتانیا',
      'VI': 'جزایر ویرجین ایالات متحده',
      'VN': 'ویتنام',
      'VU': 'وانواتو',
      'WF': 'والیس و فوتونا',
      'WS': 'ساموآ',
      'XK': 'کوزوو',
      'YE': 'یمن',
      'YT': 'مایوت',
      'ZA': 'افریقای جنوبی',
      'ZM': 'زامبیا',
      'ZW': 'زیمبابوه',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'انتخاب‌های حریم خصوصی';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'آمستردام',
      'sgp': 'سنگاپور',
      'lax': 'لوس‌آنجلس',
      'mel': 'ملبورن',
      'syd': 'سیدنی',
      'sao': 'سائوپائولو',
      'yto': 'تورنتو',
      'scl': 'سانتیاگو',
      'cdg': 'پاریس',
      'fra': 'فرانکفورت',
      'del': 'دهلی',
      'bom': 'مومبای',
      'blr': 'بنگالور',
      'tlv': 'تل‌آویو',
      'itm': 'اوساکا',
      'nrt': 'توکیو',
      'mex': 'مکزیکو سیتی',
      'waw': 'ورشو',
      'jnb': 'ژوهانسبورگ',
      'icn': 'سئول',
      'mad': 'مادرید',
      'sto': 'استکهلم',
      'lhr': 'لندن',
      'man': 'منچستر',
      'ord': 'شیکاگو',
      'dfw': 'دالاس',
      'sea': 'سیاتل',
      'sjc': 'سان‌فرانسیسکو',
      'mia': 'میامی',
      'hnl': 'هونولولو',
      'ewr': 'نیویورک',
      'atl': 'آتلانتا',
      'hkg': 'هنگ کنگ',
      'zrh': 'زوریخ',
      'gva': 'ژنو',
      'svo': 'مسکو',
      'led': 'سن‌پترزبورگ',
      'hel': 'هلسینکی',
      'tpe': 'تایپه',
      'dxb': 'دبی',
      'kbp': 'کی‌یف',
      'ist': 'استانبول',
      'otp': 'بخارست',
      'los': 'لاگوس',
      'pty': 'شهر پاناما',
      'kef': 'ریکیاویک',
      'ber': 'برلین',
      'ala': 'آلماتی',
      'tbs': 'تفلیس',
      'kul': 'کوالالامپور',
      'bkk': 'بانکوک',
      'cgk': 'جاکارتا',
      'mnl': 'مانیل',
      'nbo': 'نایروبی',
      'mxp': 'میلان',
      'dub': 'دوبلین',
      'lis': 'لیسبون',
      'lux': 'لوکزامبورگ',
      'eze': 'بوئنوس آیرس',
      'akl': 'اوکلند',
      'yul': 'مونترال',
      'yvr': 'ونکوور',
      'den': 'دنور',
      'phx': 'فینیکس',
      'iad': 'واشینگتن دی.سی.',
      'bos': 'بوستون',
      'edi': 'ادینبرو',
      'other': '⁦$name‎⁩',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'از 1VPN راضی هستید؟';

  @override
  String get onevpnYes => 'بله';

  @override
  String get onevpnNo => 'خیر';

  @override
  String get onevpnLocationLocked => 'قفل‌شده، فقط پریمیوم';

  @override
  String get onevpnManageSubscription => 'مدیریت اشتراک';
}
