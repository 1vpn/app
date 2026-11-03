// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Burmese (`my`).
class OneVpnLocalizationsMy extends OneVpnLocalizations {
  OneVpnLocalizationsMy([String locale = 'my']) : super(locale);

  @override
  String get onevpnFaq => 'အမေးများသောမေးခွန်းများ';

  @override
  String get onevpnTermsOfService => 'ဝန်ဆောင်မှုစည်းမျဉ်းများ';

  @override
  String get onevpnMenu => 'မီနူး';

  @override
  String get onevpnUpgrade => 'အဆင့်မြှင့်တင်ရန်';

  @override
  String get onevpnUpgradeBannerTitle => 'ပရီမီယံသို့ အဆင့်မြှင့်တင်ရန်';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'ကြော်ငြာမရှိ၊ တည်နေရာအားလုံးနှင့် ပိုမြန်သော အမြန်နှုန်း';

  @override
  String get onevpnLogIn => 'လက်မှတ်ထိုးဝင်ရန်';

  @override
  String get onevpnLogOut => 'လက်မှတ်ထိုးထွက်ရန်';

  @override
  String get onevpnAccount => 'အကောင့်';

  @override
  String get onevpnContactUs => 'ဆက်သွယ်ရန်';

  @override
  String get onevpnRefundPolicy => 'ငွေပြန်အမ်းခြင်း မူဝါဒ';

  @override
  String get onevpnSupport => 'ပံ့ပိုးကူညီမှု';

  @override
  String get onevpnLanguage => 'ဘာသာစကား';

  @override
  String get onevpnLanguageSystem => 'စနစ်မူရင်း';

  @override
  String get onevpnPlanFree => 'အခမဲ့ အစီအစဉ်';

  @override
  String get onevpnPlanPremium => 'ပရီမီယံ အစီအစဉ်';

  @override
  String get onevpnSelectLocation => 'တည်နေရာ ရွေးရန်';

  @override
  String get onevpnDirectRegions => 'တိုက်ရိုက်ချိတ်ဆက်သည့် ဒေသများ';

  @override
  String get onevpnFree => 'အခမဲ့';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · အခမဲ့';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'အလိုအလျောက် · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'အလိုအလျောက်';

  @override
  String get onevpnStatusNoConnection => 'ချိတ်ဆက်မှု မရှိပါ';

  @override
  String get onevpnStatusConnectionFailed => 'ချိတ်ဆက်မှု မအောင်မြင်ပါ';

  @override
  String get onevpnStatusUpdating => 'အပ်ဒိတ်လုပ်နေသည်…';

  @override
  String get onevpnStatusMeasuring => 'ဆာဗာ အမြန်နှုန်း တိုင်းတာနေသည်…';

  @override
  String get onevpnAutomaticSubtitle => 'ရနိုင်သမျှထဲမှ အမြန်ဆုံး';

  @override
  String get onevpnLocationsLoadFailed => 'သင့်တည်နေရာများကို ရယူ၍ မရပါ။';

  @override
  String get onevpnLocationsUnavailable => 'ယခု တည်နေရာများ မရနိုင်ပါ။';

  @override
  String get onevpnDirectRegionsCardBody =>
      'အချို့ဝဘ်ဆိုက်များသည် ထိုဝဘ်ဆိုက်နှင့် နိုင်ငံတစ်ခုတည်းမှ ချိတ်ဆက်မှသာ အလုပ်လုပ်သည်။ ဒေသတစ်ခုကို ရွေးလိုက်ပါက ထိုဒေသမှ ဝဘ်ဆိုက်များသည် VPN ကို ကျော်၍ တိုက်ရိုက်ချိတ်ဆက်သည်။';

  @override
  String onevpnSelectionReset(String location) {
    return '$location တည်နေရာကို မရနိုင်သဖြင့် 1VPN က ‘အလိုအလျောက်’ သို့ ပြောင်းလိုက်ပါပြီ။';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'ရွေးထားသော တည်နေရာကို မရနိုင်သဖြင့် 1VPN က ‘အလိုအလျောက်’ သို့ ပြောင်းလိုက်ပါပြီ။';

  @override
  String onevpnReloadRolledBack(String location) {
    return '$location တည်နေရာသို့ ပြောင်း၍ မရပါ။ သင်သည် ယခင်တည်နေရာနှင့် ချိတ်ဆက်ထားဆဲ ဖြစ်သည်။';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'အပြောင်းအလဲကို အသုံးပြု၍ မရပါ။ သင်သည် ယခင်ဆက်တင်များဖြင့် ချိတ်ဆက်ထားဆဲ ဖြစ်သည်။';

  @override
  String get onevpnDirectRegionsOff => 'ပိတ် (မူရင်း)';

  @override
  String get onevpnAllViaVpnSubtitle => 'ကွန်ရက်အသွားအလာ အားလုံး ဥမင်မှတစ်ဆင့်';

  @override
  String get onevpnRegionChina => 'တရုတ်';

  @override
  String get onevpnFirstConnectTitle =>
      'အချို့ဒေသများသည် တိုက်ရိုက်ချိတ်ဆက်လျှင် ပိုအဆင်ပြေသည်';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'တရုတ်၊ ရုရှားနှင့် အီရန်ကဲ့သို့သော နေရာများတွင် အရာအားလုံးကို VPN မှတစ်ဆင့် ပို့ပါက ပြည်တွင်း ဘဏ်နှင့် ငွေပေးချေရေး အက်ပ်များ အလုပ်မလုပ်ဖြစ်နိုင်သည်။';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN သည် သင်ရွေးသည့် ဒေသကို ဥမင်ပြင်ပတွင် သင်၏ IP အစစ်ဖြင့် တိုက်ရိုက်ချိတ်ဆက်ပေးနိုင်သည်။';

  @override
  String get onevpnFirstConnectPointProtected =>
      'အခြားအရာအားလုံးကို ဆက်လက် ကာကွယ်ထားသည်။ ဤဆက်တင်ကို အချိန်မရွေး ပြောင်းနိုင်သည်။';

  @override
  String get onevpnFirstConnectChooseRegion =>
      'တိုက်ရိုက်ချိတ်ဆက်သည့် ဒေသ ရွေးရန်';

  @override
  String get onevpnFirstConnectDismiss => 'ယခုမလုပ်ပါ';

  @override
  String get onevpnCensorshipWarning =>
      'အစိုးရ၏ ကန့်သတ်ချက်များကြောင့် သင့်ဒေသတွင် အချို့ဆာဗာများကို ပိတ်ဆို့ထားနိုင်ပါသည်။ ဤပြဿနာကို ဖြေရှင်းရန် ကျွန်ုပ်တို့ ကြိုးစားဆောင်ရွက်နေပါသည်။ နားလည်ပေးမှုအတွက် ကျေးဇူးတင်ပါသည်။';

  @override
  String get onevpnAlwaysOnTitle => 'VPN အမြဲတမ်းဖွင့်ထားရန်';

  @override
  String get onevpnAlwaysOnIntro =>
      'အက်ပ်ကို ပိတ်လိုက်သော်လည်း ဥမင်သည် ဆက်လက် ချိတ်ဆက်ထားမည်။ စက်ကို ပြန်စပြီးနောက် (သို့) အက်ပ်ကို အပ်ဒိတ်လုပ်ပြီးနောက် ‘VPN အမြဲတမ်းဖွင့်ထားရန်’ က ဥမင်ကို အလိုအလျောက် ပြန်ချိတ်ဆက်ပေးသည်။';

  @override
  String get onevpnAlwaysOnStep1 =>
      'အောက်ရှိ ‘VPN ဆက်တင်များ ဖွင့်ရန်’ ကို တို့ပါ။';

  @override
  String get onevpnAlwaysOnStep2 =>
      'စာရင်းထဲတွင် 1VPN ကို ရှာပါ။ ပထမဆုံးအကြိမ် ချိတ်ဆက်ပြီးနောက် ၎င်း ပေါ်လာပါမည်။';

  @override
  String get onevpnAlwaysOnStep3 => '1VPN ဘေးရှိ ဂီယာသင်္ကေတကို တို့ပါ။';

  @override
  String get onevpnAlwaysOnStep4 => '‘VPN အမြဲတမ်းဖွင့်ထားရန်’ ကို ဖွင့်ပါ။';

  @override
  String get onevpnAlwaysOnOpenSettings => 'VPN ဆက်တင်များ ဖွင့်ရန်';

  @override
  String get onevpnPaywallTitle => 'သင့်အစီအစဉ်ကို ရွေးပါ';

  @override
  String get onevpnPaywallBenefitLocations =>
      'ဆာဗာတည်နေရာ အားလုံး အသုံးပြုနိုင်ခြင်း';

  @override
  String get onevpnPaywallBenefitNoAds => 'ကြော်ငြာ မရှိခြင်း';

  @override
  String get onevpnPaywallBenefitSpeed => 'ပိုမြန်သော ဆာဗာ အမြန်နှုန်း';

  @override
  String get onevpnPaywallBenefitP2p => 'BitTorrent (P2P) ပံ့ပိုးမှု';

  @override
  String get onevpnPaywallBenefitMoneyBack =>
      '၁၀ ရက်အတွင်း ငွေပြန်အမ်းမည့် အာမခံချက်';

  @override
  String get onevpnPaywallPlanYearly => 'နှစ်စဉ်';

  @override
  String get onevpnPaywallPlanMonthly => 'လစဉ်';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '$percent% သက်သာ';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / လ';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'စျေးနှုန်း မရနိုင်ပါ';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'အစီအစဉ်များကို ရယူ၍ မရပါ။ သင့်ချိတ်ဆက်မှုကို စစ်ဆေးပါ။';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'ယခု အစီအစဉ်များ မရနိုင်ပါ။ ကျေးဇူးပြု၍ နောက်မှ ထပ်စမ်းကြည့်ပါ။';

  @override
  String get onevpnGetPremium => 'ပရီမီယံ ရယူရန်';

  @override
  String get onevpnContinueFree => 'အခမဲ့ ဆက်သုံးရန်';

  @override
  String get onevpnPaywallRetry => 'ထပ်စမ်းကြည့်ရန်';

  @override
  String get onevpnPaywallPurchaseError =>
      'တစ်ခုခုမှားသွားသည်။ ထပ်စမ်းကြည့်ပါ။';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'ဤ Google အကောင့်တွင် အခြား 1VPN အကောင့်တစ်ခုနှင့် ချိတ်ထားသော လက်ရှိ သို့မဟုတ် မကြာသေးမီက ကုန်ဆုံးသွားသည့် 1VPN စာရင်းသွင်းမှု ရှိသည်။ ထိုအကောင့်သို့ လက်မှတ်ထိုးဝင်ပါ သို့မဟုတ် $support ကို ဆက်သွယ်ပါ။';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'ဤ Google အကောင့်တွင် 1VPN စာရင်းသွင်းမှု ရှိပြီးဖြစ်သည်။ ပရီမီယံ မပေါ်လာပါက $support ကို ဆက်သွယ်ပါ။';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play သည် သင်၏ နောက်ဆုံးဝယ်ယူမှုကို မပြီးဆုံးခဲ့ပါ။ ဖွင့်ထားသော Google Play မျက်နှာပြင်များကို ပိတ်ပြီး ထပ်စမ်းကြည့်ပါ သို့မဟုတ် အက်ပ်ကို ပြန်စတင်ပါ။';

  @override
  String get onevpnPaywallSupportLink => '1VPN ပံ့ပိုးကူညီရေးအဖွဲ့';

  @override
  String get onevpnSignUp => 'စာရင်းသွင်းရန်';

  @override
  String get onevpnAuthEmailLabel => 'အီးမေးလ်';

  @override
  String get onevpnAuthPasswordLabel => 'စကားဝှက်';

  @override
  String get onevpnAuthTwoFactorLabel => '2FA ကုဒ်';

  @override
  String get onevpnAuthForgotPassword => 'စကားဝှက် မေ့နေပါလား။';

  @override
  String get onevpnAuthSubmitting => 'ဖွင့်နေသည်…';

  @override
  String get onevpnAuthCreateAccount => 'အကောင့် ပြုလုပ်ရန်';

  @override
  String get onevpnAuthHaveAccount => 'အကောင့် ရှိပြီးသားလား။';

  @override
  String get onevpnAuthLogInInstead => 'လက်မှတ်ထိုးဝင်ရန်';

  @override
  String get onevpnAuthFieldsRequired => 'အီးမေးလ်နှင့် စကားဝှက် ထည့်ပါ';

  @override
  String get onevpnAuthInvalidEmail => 'မှန်ကန်သော အီးမေးလ်လိပ်စာ ထည့်ပါ';

  @override
  String get onevpnAuthInvalidCredentials =>
      'လက်မှတ်ထိုးဝင်သည့် အချက်အလက် မမှန်ကန်ပါ';

  @override
  String get onevpnAuthInvalidTwoFactor => '2FA ကုဒ် မမှန်ကန်ပါ';

  @override
  String get onevpnAuthEmailInUse => 'ဤအီးမေးလ်တွင် အကောင့် ရှိပြီးသား ဖြစ်သည်';

  @override
  String get onevpnAuthRateLimited =>
      'ကြိုးစားမှု များလွန်းနေပါသည်။ ခဏနေမှ ထပ်စမ်းကြည့်ပါ';

  @override
  String get onevpnAuthUnreachable =>
      'ဆာဗာသို့ ချိတ်ဆက်၍ မရပါ။ သင့်ချိတ်ဆက်မှုကို စစ်ဆေးပြီး ထပ်စမ်းကြည့်ပါ';

  @override
  String get onevpnAuthGenericError => 'တစ်ခုခုမှားသွားသည်။ ထပ်စမ်းကြည့်ပါ';

  @override
  String get onevpnAuthEmailLockedHint =>
      'သင်၏ ဝယ်ယူမှုကို ဤအီးမေးလ်လိပ်စာနှင့် ချိတ်ထားသည်။';

  @override
  String get onevpnPaywallPurchasedTitle => 'ဝယ်ယူမှု ပြီးပါပြီ';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'သင်၏ ဝယ်ယူမှုကို $email လိပ်စာနှင့် ချိတ်ထားသည်။ ၎င်းကို အသုံးပြုရန် ထိုလိပ်စာဖြင့် အကောင့်တစ်ခု ပြုလုပ်ပါ။';
  }

  @override
  String get onevpnPlanPremiumPending => 'ပရီမီယံ · ဝယ်ယူမှုကို အတည်ပြုနေသည်';

  @override
  String get onevpnPremiumRecheck => 'သင်၏ ဝယ်ယူမှု အခြေအနေကို စစ်ဆေးနေသည်…';

  @override
  String get onevpnButtonRetry => 'ထပ်စမ်းကြည့်ရန်';

  @override
  String get onevpnAppVersion => 'အက်ပ်ဗားရှင်း';

  @override
  String get onevpnPrivacyPolicy => 'ကိုယ်ရေးအချက်အလက်ဆိုင်ရာ မူဝါဒ';

  @override
  String get onevpnConnect => 'ချိတ်ဆက်ရန်';

  @override
  String get onevpnDisconnected => 'ချိတ်ဆက်မထားပါ';

  @override
  String get onevpnConnecting => 'ချိတ်ဆက်နေသည်…';

  @override
  String get onevpnConnected => 'ချိတ်ဆက်ထားသည်';

  @override
  String get onevpnDisconnecting => 'ချိတ်ဆက်မှု ဖြုတ်နေသည်…';

  @override
  String get onevpnConnectionFailed => 'ချိတ်ဆက်မှု မအောင်မြင်ပါ';

  @override
  String get onevpnTemporarilyUnavailable => 'လောလောဆယ် မရနိုင်သေးပါ';

  @override
  String get onevpnRetry => 'ထပ်စမ်းကြည့်ရန်';

  @override
  String get onevpnApplyChange => 'ဤအပြောင်းအလဲကို အသုံးပြုမလား။';

  @override
  String get onevpnReconnectNotice =>
      'VPN သည် ခဏတာ ချိတ်ဆက်မှု ပြတ်ပြီး ပြန်ချိတ်ဆက်ပါမည်။ ပုံမှန်အားဖြင့် စက္ကန့်အနည်းငယ်သာ ကြာသည်။';

  @override
  String onevpnWillUseName(String name) {
    return 'အသုံးပြုမည်- $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'အသုံးပြုပြီး ပြန်ချိတ်ဆက်ရန်';

  @override
  String get onevpnCancel => 'မလုပ်တော့';

  @override
  String get onevpnContinue => 'ရှေ့ဆက်ရန်';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'ပင်မဒိုမိန်းကို ပိတ်ဆို့ထားသည်။ အရန်ကို အသုံးပြုနေသည်: $domain';
  }

  @override
  String get onevpnResultFailed => 'မအောင်မြင်ပါ';

  @override
  String get onevpnDownload => 'ဒေါင်းလုဒ်လုပ်ရန်';

  @override
  String get onevpnPermissionNotGranted => 'ခွင့်ပြုချက် မရပါ';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action $result';
  }

  @override
  String get onevpnDisconnect => 'ချိတ်ဆက်မှု ဖြုတ်ရန်';

  @override
  String get onevpnTimeout => 'အချိန်ကုန်သွားသည်';

  @override
  String get onevpnNoAvailableEntries => 'အသုံးပြုနိုင်သော ဝင်ပေါက်ဆာဗာ မရှိပါ';

  @override
  String get onevpnAddServers => 'ဆာဗာများ ထည့်ရန်';

  @override
  String get onevpnNotEnoughServers => 'အသုံးပြုနိုင်သော ဆာဗာ မလုံလောက်ပါ';

  @override
  String get onevpnVpnFinalExit => 'VPN နောက်ဆုံး ထွက်ပေါက်';

  @override
  String get onevpnFinalExitEntryConflict =>
      'နောက်ဆုံး ထွက်ပေါက်သည် ဝင်ပေါက်ဆာဗာနှင့် တူညီသော ဆာဗာ မဖြစ်ရပါ';

  @override
  String get onevpnChooseNamedRoute =>
      'အမည်ပေးထားသော လမ်းကြောင်း တစ်ခုကို ရွေးပါ';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'ဒေသတွင်း ကွန်ရက်ပေါ်ရှိ စက်များနှင့် ဝန်ဆောင်မှုများကို သုံးခွင့်ပြုပါ။';

  @override
  String get onevpnSystemApprovalRequired => 'စနစ်၏ အတည်ပြုချက် လိုအပ်သည်';

  @override
  String get onevpnVpnPermissionRequired =>
      'VPN ခွင့်ပြုချက် လိုအပ်သည်။ ရှေ့ဆက်ရန် ထပ်စမ်းကြည့်ပါ။';

  @override
  String get onevpnChooseInterfaceNotice =>
      'ကွန်ရက်သို့ ဝင်ရောက်ရန် အသုံးပြုသည့် အင်တာဖေ့စ်ကို ရွေးပါ။ Windows / Linux တွင်သာ လိုအပ်သည်။';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'အန်ဒိုရာ',
      'AE': 'ယူအေအီး',
      'AF': 'အာဖဂန်နစ္စတန်',
      'AG': 'အန်တီဂွါနှင့် ဘာဘူဒါ',
      'AI': 'အန်ဂီလာ',
      'AL': 'အယ်လ်ဘေးနီးယား',
      'AM': 'အာမေးနီးယား',
      'AO': 'အန်ဂိုလာ',
      'AQ': 'အန်တာတိက',
      'AR': 'အာဂျင်တီးနား',
      'AS': 'အမေရိကန် ဆမိုးအား',
      'AT': 'ဩစတြီးယား',
      'AU': 'ဩစတြေးလျ',
      'AW': 'အာရူးဗား',
      'AX': 'အာလန်ကျွန်း',
      'AZ': 'အဇာဘိုင်ဂျန်',
      'BA': 'ဘော့စနီးယားနှင့် ဟာဇီဂိုဗီနား',
      'BB': 'ဘာဘေးဒိုးစ်',
      'BD': 'ဘင်္ဂလားဒေ့ရှ်',
      'BE': 'ဘယ်လ်ဂျီယမ်',
      'BF': 'ဘာကီးနား ဖားဆို',
      'BG': 'ဘူလ်ဂေးရီးယား',
      'BH': 'ဘာရိန်း',
      'BI': 'ဘူရွန်ဒီ',
      'BJ': 'ဘီနင်',
      'BL': 'စိန့်ဘာသယ်လ်မီ',
      'BM': 'ဘာမြူဒါ',
      'BN': 'ဘရူနိုင်း',
      'BO': 'ဘိုလီးဗီးယား',
      'BQ': 'ကာရစ်ဘီယံ နယ်သာလန်',
      'BR': 'ဘရာဇီး',
      'BS': 'ဘဟားမား',
      'BT': 'ဘူတန်',
      'BV': 'ဘူဗက်ကျွန်း',
      'BW': 'ဘော့ဆွာနာ',
      'BY': 'ဘီလာရုစ်',
      'BZ': 'ဘလိဇ်',
      'CA': 'ကနေဒါ',
      'CC': 'ကိုကိုးကျွန်း',
      'CD': 'ကွန်ဂို',
      'CF': 'ဗဟို အာဖရိက ပြည်ထောင်စု',
      'CG': 'ကွန်ဂို-ဘရာဇာဗီးလ်',
      'CH': 'ဆွစ်ဇာလန်',
      'CI': 'ကို့တ် ဒီဗွာ',
      'CK': 'ကွတ် ကျွန်းစု',
      'CL': 'ချီလီ',
      'CM': 'ကင်မရွန်း',
      'CN': 'တရုတ်',
      'CO': 'ကိုလံဘီယာ',
      'CR': 'ကို့စ်တာရီကာ',
      'CU': 'ကျူးဘား',
      'CV': 'ကိတ်ဗာဒီ',
      'CW': 'ကျူရေးကိုးစ်',
      'CX': 'ခရစ်စမတ် ကျွန်း',
      'CY': 'ဆိုက်ပရပ်စ်',
      'CZ': 'ချက်ကီယား',
      'DE': 'ဂျာမနီ',
      'DJ': 'ဂျီဘူတီ',
      'DK': 'ဒိန်းမတ်',
      'DM': 'ဒိုမီနီကာ',
      'DO': 'ဒိုမီနီကန်',
      'DZ': 'အယ်လ်ဂျီးရီးယား',
      'EC': 'အီကွေဒေါ',
      'EE': 'အက်စတိုးနီးယား',
      'EG': 'အီဂျစ်',
      'EH': 'အနောက် ဆာဟာရ',
      'ER': 'အီရီထရီးယား',
      'ES': 'စပိန်',
      'ET': 'အီသီယိုးပီးယား',
      'FI': 'ဖင်လန်',
      'FJ': 'ဖီဂျီ',
      'FK': 'ဖော့ကလန် ကျွန်းစု',
      'FM': 'မိုင်ခရိုနီရှား',
      'FO': 'ဖာရိုး ကျွန်းစုများ',
      'FR': 'ပြင်သစ်',
      'GA': 'ဂါဘွန်',
      'GB': 'ယူနိုက်တက်ကင်းဒမ်း',
      'GD': 'ဂရီနေဒါ',
      'GE': 'ဂျော်ဂျီယာ',
      'GF': 'ပြင်သစ် ဂီယာနာ',
      'GG': 'ဂွန်းဇီ',
      'GH': 'ဂါနာ',
      'GI': 'ဂျီဘရော်လ်တာ',
      'GL': 'ဂရင်းလန်း',
      'GM': 'ဂမ်ဘီရာ',
      'GN': 'ဂီနီ',
      'GP': 'ဂွါဒီလု',
      'GQ': 'အီကွေတာ ဂီနီ',
      'GR': 'ဂရိ',
      'GS': 'တောင် ဂျော်ဂျီယာ နှင့် တောင် ဆင်းဒဝစ်ဂျ် ကျွန်းစုများ',
      'GT': 'ဂွါတီမာလာ',
      'GU': 'ဂူအမ်',
      'GW': 'ဂီနီ-ဘီစော',
      'GY': 'ဂိုင်ယာနာ',
      'HK': 'ဟောင်ကောင်',
      'HM': 'ဟတ်ကျွန်းနှင့်မက်ဒေါနယ်ကျွန်းစု',
      'HN': 'ဟွန်ဒူးရပ်စ်',
      'HR': 'ခရိုအေးရှား',
      'HT': 'ဟေတီ',
      'HU': 'ဟန်ဂေရီ',
      'ID': 'အင်ဒိုနီးရှား',
      'IE': 'အိုင်ယာလန်',
      'IL': 'အစ္စရေး',
      'IM': 'မန်ကျွန်း',
      'IN': 'အိန္ဒိယ',
      'IO': 'ဗြိတိသျှပိုင် အိန္ဒိယသမုဒ္ဒရာကျွန်းများ',
      'IQ': 'အီရတ်',
      'IR': 'အီရန်',
      'IS': 'အိုက်စလန်',
      'IT': 'အီတလီ',
      'JE': 'ဂျာစီ',
      'JM': 'ဂျမေကာ',
      'JO': 'ဂျော်ဒန်',
      'JP': 'ဂျပန်',
      'KE': 'ကင်ညာ',
      'KG': 'ကာဂျစ္စတန်',
      'KH': 'ကမ္ဘောဒီးယား',
      'KI': 'ခီရီဘာတီ',
      'KM': 'ကိုမိုရိုစ်',
      'KN': 'စိန့်ကစ်နှင့်နီဗီစ်',
      'KP': 'မြောက်ကိုရီးယား',
      'KR': 'တောင်ကိုရီးယား',
      'KW': 'ကူဝိတ်',
      'KY': 'ကေမန် ကျွန်းစု',
      'KZ': 'ကာဇက်စတန်',
      'LA': 'လာအို',
      'LB': 'လက်ဘနွန်',
      'LC': 'စိန့်လူစီယာ',
      'LI': 'လစ်တန်စတိန်း',
      'LK': 'သီရိလင်္ကာ',
      'LR': 'လိုက်ဘေးရီးယား',
      'LS': 'လီဆိုသို',
      'LT': 'လစ်သူဝေးနီးယား',
      'LU': 'လူဇင်ဘတ်',
      'LV': 'လတ်ဗီးယား',
      'LY': 'လစ်ဗျား',
      'MA': 'မော်ရိုကို',
      'MC': 'မိုနာကို',
      'MD': 'မောလ်ဒိုဗာ',
      'ME': 'မွန်တီနိဂရိုး',
      'MF': 'စိန့်မာတင်',
      'MG': 'မဒါဂတ်စကား',
      'MH': 'မာရှယ် ကျွန်းစု',
      'MK': 'မြောက် မက်ဆီဒိုးနီးယား',
      'ML': 'မာလီ',
      'MM': 'မြန်မာ',
      'MN': 'မွန်ဂိုးလီးယား',
      'MO': 'မကာအို',
      'MP': 'မြောက်ပိုင်းမာရီအာနာကျွန်းစု',
      'MQ': 'မာတီနိခ်',
      'MR': 'မော်ရီတေးနီးယား',
      'MS': 'မောင့်စဲရက်',
      'MT': 'မောလ်တာ',
      'MU': 'မောရစ်ရှ',
      'MV': 'မော်လ်ဒိုက်',
      'MW': 'မာလာဝီ',
      'MX': 'မက်ကဆီကို',
      'MY': 'မလေးရှား',
      'MZ': 'မိုဇမ်ဘစ်',
      'NA': 'နမီးဘီးယား',
      'NC': 'နယူး ကယ်လီဒိုနီးယား',
      'NE': 'နိုင်ဂျာ',
      'NF': 'နောဖုတ်ကျွန်း',
      'NG': 'နိုင်ဂျီးရီးယား',
      'NI': 'နီကာရာဂွါ',
      'NL': 'နယ်သာလန်',
      'NO': 'နော်ဝေ',
      'NP': 'နီပေါ',
      'NR': 'နော်ရူး',
      'NU': 'နီဥူအေ',
      'NZ': 'နယူးဇီလန်',
      'OM': 'အိုမန်',
      'PA': 'ပနားမား',
      'PE': 'ပီရူး',
      'PF': 'ပြင်သစ် ပေါ်လီနီးရှား',
      'PG': 'ပါပူအာ နယူးဂီနီ',
      'PH': 'ဖိလစ်ပိုင်',
      'PK': 'ပါကစ္စတန်',
      'PL': 'ပိုလန်',
      'PM': 'စိန့်ပီအဲရ်နှင့် မီကွီလွန်',
      'PN': 'ပစ်တ်ကိန်းကျွန်းစု',
      'PR': 'ပေါ်တိုရီကို',
      'PS': 'ပါလက်စတိုင်း ပိုင်နက်',
      'PT': 'ပေါ်တူဂီ',
      'PW': 'ပလာအို',
      'PY': 'ပါရာဂွေး',
      'QA': 'ကာတာ',
      'RE': 'ရီယူနီယန်',
      'RO': 'ရိုမေးနီးယား',
      'RS': 'ဆားဘီးယား',
      'RU': 'ရုရှား',
      'RW': 'ရဝန်ဒါ',
      'SA': 'ဆော်ဒီအာရေးဘီးယား',
      'SB': 'ဆော်လမွန်ကျွန်းစု',
      'SC': 'ဆေးရှဲ',
      'SD': 'ဆူဒန်',
      'SE': 'ဆွီဒင်',
      'SG': 'စင်္ကာပူ',
      'SH': 'စိန့်ဟယ်လယ်နာ',
      'SI': 'ဆလိုဗေးနီးယား',
      'SJ': 'စဗိုလ်ဘတ်နှင့်ဂျန်မေရန်',
      'SK': 'ဆလိုဗက်ကီးယား',
      'SL': 'ဆီယာရာ လီယွန်း',
      'SM': 'ဆန်မာရီနို',
      'SN': 'ဆီနီဂေါ',
      'SO': 'ဆိုမာလီယာ',
      'SR': 'ဆူရာနမ်',
      'SS': 'တောင် ဆူဒန်',
      'ST': 'ဆောင်တူမေးနှင့် ပရင်စီပီ',
      'SV': 'အယ်လ်ဆာဗေးဒိုး',
      'SX': 'စင့်မာတင်',
      'SY': 'ဆီးရီးယား',
      'SZ': 'ဆွာဇီလန်',
      'TC': 'တခ်စ်နှင့်ကာအီကိုစ်ကျွန်းစု',
      'TD': 'ချဒ်',
      'TF': 'ပြင်သစ် တောင်ပိုင်း ပိုင်နက်များ',
      'TG': 'တိုဂို',
      'TH': 'ထိုင်း',
      'TJ': 'တာဂျီကစ္စတန်',
      'TK': 'တိုကလောင်',
      'TL': 'အရှေ့တီမော',
      'TM': 'တာ့ခ်မင်နစ္စတန်',
      'TN': 'တူနီးရှား',
      'TO': 'တွန်ဂါ',
      'TR': 'တူရကီ',
      'TT': 'ထရီနီဒတ်နှင့် တိုဘက်ဂို',
      'TV': 'တူဗားလူ',
      'TW': 'ထိုင်ဝမ်',
      'TZ': 'တန်ဇန်းနီးယား',
      'UA': 'ယူကရိန်း',
      'UG': 'ယူဂန်းဒါး',
      'UM': 'ယူနိုက်တက်စတိတ် ကျွန်းနိုင်ငံများ',
      'US': 'အမေရိကန် ပြည်ထောင်စု',
      'UY': 'ဥရုဂွေး',
      'UZ': 'ဥဇဘက်ကစ္စတန်',
      'VA': 'ဗာတီကန်စီးတီး',
      'VC': 'စိန့်ဗင်းဆင့်နှင့် ဂရိနေဒိုင်',
      'VE': 'ဗင်နီဇွဲလား',
      'VG': 'ဗြိတိသျှ ဗာဂျင်း ကျွန်းစု',
      'VI': 'ယူအက်စ် ဗာဂျင်း ကျွန်းစု',
      'VN': 'ဗီယက်နမ်',
      'VU': 'ဗနွားတူ',
      'WF': 'ဝေါလစ်နှင့် ဖူကျူးနား',
      'WS': 'ဆမိုးအား',
      'XK': 'ကိုဆိုဗို',
      'YE': 'ယီမင်',
      'YT': 'မေယော့',
      'ZA': 'တောင်အာဖရိက',
      'ZM': 'ဇမ်ဘီယာ',
      'ZW': 'ဇင်ဘာဘွေ',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'ကိုယ်ရေးအချက်အလက် ရွေးချယ်မှုများ';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'အမ်စတာဒမ်',
      'sgp': 'စင်္ကာပူ',
      'lax': 'လော့စ်အိန်ဂျယ်လိစ်',
      'mel': 'မဲလ်ဘုန်း',
      'syd': 'ဆစ်ဒနီ',
      'sao': 'ဆောပိုလို',
      'yto': 'တိုရန်တို',
      'scl': 'ဆန်တီယာဂို',
      'cdg': 'ပါရီ',
      'fra': 'ဖရန့်ဖတ်',
      'del': 'ဒေလီ',
      'bom': 'မွမ်ဘိုင်း',
      'blr': 'ဘန်ဂလိုး',
      'tlv': 'တဲလ်အဗစ်',
      'itm': 'အိုဆာကာ',
      'nrt': 'တိုကျို',
      'mex': 'မက်ကဆီကိုစီးတီး',
      'waw': 'ဝါဆော',
      'jnb': 'ဂျိုဟန်နက်စဘတ်',
      'icn': 'ဆိုးလ်',
      'mad': 'မက်ဒရစ်',
      'sto': 'စတော့ဟုမ်း',
      'lhr': 'လန်ဒန်',
      'man': 'မန်ချက်စတာ',
      'ord': 'ချီကာဂို',
      'dfw': 'ဒါလပ်စ်',
      'sea': 'ဆီယက်တဲလ်',
      'sjc': 'ဆန်ဖရန်စစ္စကို',
      'mia': 'မိုင်ယာမီ',
      'hnl': 'ဟိုနိုလူလူ',
      'ewr': 'နယူးယောက်',
      'atl': 'အတ္တလန်တာ',
      'hkg': 'ဟောင်ကောင်',
      'zrh': 'ဇူးရစ်',
      'gva': 'ဂျနီဗာ',
      'svo': 'မော်စကို',
      'led': 'စိန့်ပီတာစဘတ်',
      'hel': 'ဟယ်လ်ဆင်ကီ',
      'tpe': 'ထိုင်ပေ',
      'dxb': 'ဒူဘိုင်း',
      'kbp': 'ကိဗ်',
      'ist': 'အစ္စတန်ဘူလ်',
      'otp': 'ဘူခါရက်စ်',
      'los': 'လာဂို့စ်',
      'pty': 'ပနားမားစီးတီး',
      'kef': 'ရေကျာဗစ်',
      'ber': 'ဘာလင်',
      'ala': 'အယ်လ်မာတီ',
      'tbs': 'တဘီလီစီ',
      'kul': 'ကွာလာလမ်ပူ',
      'bkk': 'ဘန်ကောက်',
      'cgk': 'ဂျကာတာ',
      'mnl': 'မနီလာ',
      'nbo': 'နိုင်ရိုဘီ',
      'mxp': 'မီလန်',
      'dub': 'ဒပ်ဗလင်',
      'lis': 'လစ္စဘွန်း',
      'lux': 'လူဇင်ဘတ်',
      'eze': 'ဗျူနိုအေးရိစ်',
      'akl': 'အော့ကလန်',
      'yul': 'မွန်ထရီအယ်',
      'yvr': 'ဗန်ကူးဗား',
      'den': 'ဒင်ဗာ',
      'phx': 'ဖီးနစ်',
      'iad': 'ဝါရှင်တန်ဒီစီ',
      'bos': 'ဘော့စတွန်',
      'edi': 'အက်ဒင်ဘရာ',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => '1VPN ကို နှစ်သက်ပါသလား။';

  @override
  String get onevpnYes => 'ဟုတ်ကဲ့';

  @override
  String get onevpnNo => 'မဟုတ်ပါ';

  @override
  String get onevpnLocationLocked => 'သော့ခတ်ထားသည်၊ ပရီမီယံ သီးသန့်';

  @override
  String get onevpnManageSubscription => 'စာရင်းသွင်းမှုကို စီမံရန်';
}
