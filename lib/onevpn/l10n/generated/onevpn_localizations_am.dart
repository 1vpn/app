// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class OneVpnLocalizationsAm extends OneVpnLocalizations {
  OneVpnLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get onevpnFaq => 'ተደጋግመው የሚጠየቁ ጥያቄዎች';

  @override
  String get onevpnTermsOfService => 'የአገልግሎት ውሎች';

  @override
  String get onevpnMenu => 'ምናሌ';

  @override
  String get onevpnUpgrade => 'ደረጃ አሻሽል';

  @override
  String get onevpnUpgradeBannerTitle => 'ወደ ፕሪሚየም ያሻሽሉ';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'ማስታወቂያ የለም፣ ሁሉም አካባቢዎች እና ፈጣን ፍጥነት';

  @override
  String get onevpnLogIn => 'በመለያ ይግቡ';

  @override
  String get onevpnLogOut => 'ዘግተው ይውጡ';

  @override
  String get onevpnAccount => 'መለያ';

  @override
  String get onevpnContactUs => 'ያግኙን';

  @override
  String get onevpnRefundPolicy => 'የተመላሽ ገንዘብ መመሪያ';

  @override
  String get onevpnSupport => 'ድጋፍ';

  @override
  String get onevpnLanguage => 'ቋንቋ';

  @override
  String get onevpnLanguageSystem => 'የሥርዓት ነባሪ';

  @override
  String get onevpnPlanFree => 'ነፃ ዕቅድ';

  @override
  String get onevpnPlanPremium => 'ፕሪሚየም ዕቅድ';

  @override
  String get onevpnSelectLocation => 'አካባቢ ይምረጡ';

  @override
  String get onevpnDirectRegions => 'ቀጥታ ክልሎች';

  @override
  String get onevpnFree => 'ነፃ';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · ነፃ';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'ራስ-ሰር · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'ራስ-ሰር';

  @override
  String get onevpnStatusNoConnection => 'ምንም ግንኙነት የለም';

  @override
  String get onevpnStatusConnectionFailed => 'ግንኙነት አልተሳካም';

  @override
  String get onevpnStatusUpdating => 'በማዘመን ላይ…';

  @override
  String get onevpnStatusMeasuring => 'አገልጋዮችን በመለካት ላይ…';

  @override
  String get onevpnAutomaticSubtitle => 'በጣም ፈጣኑ የሚገኝ አገልጋይ';

  @override
  String get onevpnLocationsLoadFailed => 'የእርስዎን አካባቢዎች መጫን አልተቻለም።';

  @override
  String get onevpnLocationsUnavailable => 'አካባቢዎች በአሁኑ ጊዜ አይገኙም።';

  @override
  String get onevpnDirectRegionsCardBody =>
      'አንዳንድ ድር ጣቢያዎች የሚሠሩት ድር ጣቢያው ካለበት አገር ሲገናኙ ብቻ ነው። አንድ ክልል ሲመርጡ ከዚያ ክልል የሆኑ ድር ጣቢያዎች በVPN በኩል አያልፉም።';

  @override
  String onevpnSelectionReset(String location) {
    return '$location አይገኝም፣ 1VPN ወደ «ራስ-ሰር» ቀይሯል።';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'የተመረጠው አካባቢ አይገኝም፣ 1VPN ወደ «ራስ-ሰር» ቀይሯል።';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'ወደ $location መቀየር አልተቻለም። አሁንም ከቀድሞው አካባቢዎ ጋር ተገናኝተዋል።';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'ለውጡን መተግበር አልተቻለም። አሁንም በቀድሞው ቅንብሮችዎ ተገናኝተዋል።';

  @override
  String get onevpnDirectRegionsOff => 'ጠፍቷል (ነባሪ)';

  @override
  String get onevpnAllViaVpnSubtitle => 'ሁሉም ትራፊክ በዋሻው በኩል ያልፋል';

  @override
  String get onevpnRegionChina => 'ቻይና';

  @override
  String get onevpnFirstConnectTitle => 'አንዳንድ ክልሎች በቀጥታ ሲገናኙ የተሻለ ይሠራሉ';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'እንደ ቻይና፣ ሩስያ እና ኢራን ባሉ ቦታዎች ሁሉንም ነገር በVPN በኩል መላክ የአገር ውስጥ የባንክ እና የክፍያ መተግበሪያዎች እንዳይሠሩ ሊያደርግ ይችላል።';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN ወደ መረጡት ክልል የሚሄደውን ትራፊክ ከዋሻው ውጭ፣ በእውነተኛው የIP አድራሻዎ በቀጥታ ማዞር ይችላል።';

  @override
  String get onevpnFirstConnectPointProtected =>
      'ሌላው ሁሉ እንደተጠበቀ ይቆያል። ይህን በማንኛውም ጊዜ መቀየር ይችላሉ።';

  @override
  String get onevpnFirstConnectChooseRegion => 'ቀጥታ ክልል ምረጥ';

  @override
  String get onevpnFirstConnectDismiss => 'አሁን አይደለም';

  @override
  String get onevpnCensorshipWarning =>
      'አንዳንድ ሰርቨሮች በመንግሥት ገደቦች ምክንያት በአካባቢዎ ሊታገዱ ይችላሉ። ይህንን ለመፍታት እየሠራን ነው። ስለ ግንዛቤዎ እናመሰግናለን።';

  @override
  String get onevpnAlwaysOnTitle => 'ሁልጊዜ የበራ VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      'መተግበሪያውን ሲዘጉ ዋሻው እንደተገናኘ ይቆያል። መሣሪያው ዳግም ከጀመረ ወይም መተግበሪያው ከተዘመነ በኋላ፣ «ሁልጊዜ የበራ VPN» ዋሻውን በራስ-ሰር እንደገና ያገናኛል።';

  @override
  String get onevpnAlwaysOnStep1 => 'ከታች ያለውን «የVPN ቅንብሮችን ክፈት» መታ ያድርጉ።';

  @override
  String get onevpnAlwaysOnStep2 =>
      'በዝርዝሩ ውስጥ 1VPNን ያግኙ። ከመጀመሪያው ግንኙነትዎ በኋላ ይታያል።';

  @override
  String get onevpnAlwaysOnStep3 => 'ከ1VPN አጠገብ ያለውን የማርሽ አዶ መታ ያድርጉ።';

  @override
  String get onevpnAlwaysOnStep4 => '«ሁልጊዜ የበራ VPN»ን ያብሩ።';

  @override
  String get onevpnAlwaysOnOpenSettings => 'የVPN ቅንብሮችን ክፈት';

  @override
  String get onevpnPaywallTitle => 'ዕቅድዎን ይምረጡ';

  @override
  String get onevpnPaywallBenefitLocations => 'ሁሉንም የአገልጋይ አካባቢዎች ይክፈቱ';

  @override
  String get onevpnPaywallBenefitNoAds => 'ማስታወቂያ የለም';

  @override
  String get onevpnPaywallBenefitSpeed => 'ፈጣን የአገልጋይ ፍጥነቶች';

  @override
  String get onevpnPaywallBenefitP2p => 'የBitTorrent (P2P) ድጋፍ';

  @override
  String get onevpnPaywallBenefitMoneyBack => 'የ10 ቀን ገንዘብ ተመላሽ ዋስትና';

  @override
  String get onevpnPaywallPlanYearly => 'ዓመታዊ';

  @override
  String get onevpnPaywallPlanMonthly => 'ወርሃዊ';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '$percent% ይቆጥቡ';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / ወር';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'ዋጋ አይገኝም';

  @override
  String get onevpnPaywallPlansLoadFailed => 'ዕቅዶችን መጫን አልተቻለም። ግንኙነትዎን ይፈትሹ።';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'ዕቅዶች በአሁኑ ጊዜ አይገኙም። እባክዎ ቆይተው እንደገና ይሞክሩ።';

  @override
  String get onevpnGetPremium => 'ፕሪሚየም ያግኙ';

  @override
  String get onevpnContinueFree => 'በነፃ ቀጥል';

  @override
  String get onevpnPaywallRetry => 'እንደገና ይሞክሩ';

  @override
  String get onevpnPaywallPurchaseError => 'የሆነ ስህተት ተከስቷል። እባክዎ እንደገና ይሞክሩ።';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'ይህ የGoogle መለያ ከሌላ የ1VPN መለያ ጋር የተገናኘ ንቁ ወይም በቅርቡ ያበቃ የ1VPN የደንበኝነት ምዝገባ አለው። በዚያ መለያ ይግቡ ወይም $supportን ያግኙ።';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'ይህ የGoogle መለያ አስቀድሞ የ1VPN የደንበኝነት ምዝገባ አለው። ፕሪሚየም ካልታየ $supportን ያግኙ።';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play የመጨረሻ ግዢዎን አላጠናቀቀም። ክፍት የሆኑ የGoogle Play ማያ ገጾችን ዘግተው እንደገና ይሞክሩ ወይም መተግበሪያውን እንደገና ያስጀምሩ።';

  @override
  String get onevpnPaywallSupportLink => 'የ1VPN ድጋፍ';

  @override
  String get onevpnSignUp => 'ይመዝገቡ';

  @override
  String get onevpnAuthEmailLabel => 'ኢሜይል';

  @override
  String get onevpnAuthPasswordLabel => 'የይለፍ ቃል';

  @override
  String get onevpnAuthTwoFactorLabel => 'የ2FA ኮድ';

  @override
  String get onevpnAuthForgotPassword => 'የእርስዎን የይለፍ ቃል ረሱት?';

  @override
  String get onevpnAuthSubmitting => 'በመጫን ላይ…';

  @override
  String get onevpnAuthCreateAccount => 'መለያ ፍጠር';

  @override
  String get onevpnAuthHaveAccount => 'መለያ አለዎት?';

  @override
  String get onevpnAuthLogInInstead => 'በምትኩ በመለያ ይግቡ';

  @override
  String get onevpnAuthFieldsRequired => 'ኢሜይል እና የይለፍ ቃል ያስገቡ';

  @override
  String get onevpnAuthInvalidEmail => 'የሚሠራ የኢሜይል አድራሻ ያስገቡ';

  @override
  String get onevpnAuthInvalidCredentials => 'ኢሜይል ወይም የይለፍ ቃል ትክክል አይደለም';

  @override
  String get onevpnAuthInvalidTwoFactor => 'ልክ ያልሆነ የ2FA ኮድ';

  @override
  String get onevpnAuthEmailInUse => 'ይህ ኢሜይል አስቀድሞ መለያ አለው';

  @override
  String get onevpnAuthRateLimited =>
      'ከልክ በላይ ብዙ ሙከራዎች። እባክዎ ትንሽ ቆይተው እንደገና ይሞክሩ';

  @override
  String get onevpnAuthUnreachable =>
      'አገልጋዩን ማግኘት አልተቻለም። ግንኙነትዎን ይፈትሹ እና እንደገና ይሞክሩ';

  @override
  String get onevpnAuthGenericError => 'የሆነ ስህተት ተከስቷል። እባክዎ እንደገና ይሞክሩ';

  @override
  String get onevpnAuthEmailLockedHint => 'ግዢዎ ከዚህ የኢሜይል አድራሻ ጋር ተገናኝቷል።';

  @override
  String get onevpnPaywallPurchasedTitle => 'ግዢው ተጠናቋል';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'ግዢዎ ከአድራሻው $email ጋር ተገናኝቷል። እሱን ለመጠቀም በዚያ አድራሻ መለያ ይፍጠሩ።';
  }

  @override
  String get onevpnPlanPremiumPending => 'ፕሪሚየም · ግዢው በመረጋገጥ ላይ';

  @override
  String get onevpnPremiumRecheck => 'የግዢዎን ሁኔታ በመፈተሽ ላይ…';

  @override
  String get onevpnButtonRetry => 'እንደገና ይሞክሩ';

  @override
  String get onevpnAppVersion => 'የመተግበሪያ ስሪት';

  @override
  String get onevpnPrivacyPolicy => 'የግላዊነት መመሪያ';

  @override
  String get onevpnConnect => 'አገናኝ';

  @override
  String get onevpnDisconnected => 'ግንኙነት ተቋርጧል';

  @override
  String get onevpnConnecting => 'በመገናኘት ላይ…';

  @override
  String get onevpnConnected => 'ተገናኝቷል';

  @override
  String get onevpnDisconnecting => 'ግንኙነትን በማቋረጥ ላይ…';

  @override
  String get onevpnConnectionFailed => 'ግንኙነት አልተሳካም';

  @override
  String get onevpnTemporarilyUnavailable => 'ለጊዜው አይገኝም';

  @override
  String get onevpnRetry => 'እንደገና ይሞክሩ';

  @override
  String get onevpnApplyChange => 'ይህ ለውጥ ይተግበር?';

  @override
  String get onevpnReconnectNotice =>
      'VPN ለአጭር ጊዜ ተቋርጦ እንደገና ይገናኛል። ይህ ብዙውን ጊዜ ጥቂት ሰከንዶችን ብቻ ይወስዳል።';

  @override
  String onevpnWillUseName(String name) {
    return 'ጥቅም ላይ የሚውለው፦ $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'ተግብር እና እንደገና አገናኝ';

  @override
  String get onevpnCancel => 'ይቅር';

  @override
  String get onevpnContinue => 'ቀጥል';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'ዋናው ዶሜን ታግዷል። ምትኬ በመጠቀም ላይ፦ $domain';
  }

  @override
  String get onevpnResultFailed => 'አልተሳካም';

  @override
  String get onevpnDownload => 'አውርድ';

  @override
  String get onevpnPermissionNotGranted => 'ፈቃድ አልተሰጠም';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action፦ $result';
  }

  @override
  String get onevpnDisconnect => 'ግንኙነት አቋርጥ';

  @override
  String get onevpnTimeout => 'ጊዜው አብቅቷል';

  @override
  String get onevpnNoAvailableEntries => 'ምንም የሚገኝ የመግቢያ አገልጋይ የለም';

  @override
  String get onevpnAddServers => 'አገልጋዮችን ያክሉ';

  @override
  String get onevpnNotEnoughServers => 'በቂ የሚገኙ አገልጋዮች የሉም';

  @override
  String get onevpnVpnFinalExit => 'የVPN የመጨረሻ መውጫ አገልጋይ';

  @override
  String get onevpnFinalExitEntryConflict =>
      'የመጨረሻው መውጫ አገልጋይ የመግቢያ አገልጋይም ሊሆን አይችልም';

  @override
  String get onevpnChooseNamedRoute => 'ስም ያለው አንድ መስመር ይምረጡ';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'በአካባቢያዊ አውታረ መረቡ ላይ ላሉ መሣሪያዎች እና አገልግሎቶች መዳረሻ ይፍቀዱ።';

  @override
  String get onevpnSystemApprovalRequired => 'የሥርዓት ማጽደቅ ያስፈልጋል';

  @override
  String get onevpnVpnPermissionRequired =>
      'የVPN ፈቃድ ያስፈልጋል። ለመቀጠል እባክዎ እንደገና ይሞክሩ።';

  @override
  String get onevpnChooseInterfaceNotice =>
      'አውታረ መረቡን ለመድረስ የሚያገለግለውን በይነገጽ ይምረጡ። በWindows / Linux ላይ ብቻ ያስፈልጋል።';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'አንዶራ',
      'AE': 'የተባበሩት ዓረብ ኤምሬትስ',
      'AF': 'አፍጋኒስታን',
      'AG': 'አንቲጓ እና ባርቡዳ',
      'AI': 'አንጉይላ',
      'AL': 'አልባኒያ',
      'AM': 'አርሜኒያ',
      'AO': 'አንጐላ',
      'AQ': 'አንታርክቲካ',
      'AR': 'አርጀንቲና',
      'AS': 'የአሜሪካ ሳሞአ',
      'AT': 'ኦስትሪያ',
      'AU': 'አውስትራልያ',
      'AW': 'አሩባ',
      'AX': 'የአላንድ ደሴቶች',
      'AZ': 'አዘርባጃን',
      'BA': 'ቦስኒያ እና ሄርዞጎቪኒያ',
      'BB': 'ባርቤዶስ',
      'BD': 'ባንግላዲሽ',
      'BE': 'ቤልጄም',
      'BF': 'ቡርኪና ፋሶ',
      'BG': 'ቡልጋሪያ',
      'BH': 'ባህሬን',
      'BI': 'ብሩንዲ',
      'BJ': 'ቤኒን',
      'BL': 'ሴንት ባርቴሌሚ',
      'BM': 'ቤርሙዳ',
      'BN': 'ብሩኒ',
      'BO': 'ቦሊቪያ',
      'BQ': 'የካሪቢያን ኔዘርላንድስ',
      'BR': 'ብራዚል',
      'BS': 'ባሃማስ',
      'BT': 'ቡህታን',
      'BV': 'ቡቬት ደሴት',
      'BW': 'ቦትስዋና',
      'BY': 'ቤላሩስ',
      'BZ': 'በሊዝ',
      'CA': 'ካናዳ',
      'CC': 'ኮኮስ (ኬሊንግ) ደሴቶች',
      'CD': 'ኮንጎ-ኪንሻሳ',
      'CF': 'ማዕከላዊ አፍሪካ ሪፑብሊክ',
      'CG': 'ኮንጎ ብራዛቪል',
      'CH': 'ስዊዘርላንድ',
      'CI': 'ኮትዲቯር',
      'CK': 'ኩክ ደሴቶች',
      'CL': 'ቺሊ',
      'CM': 'ካሜሩን',
      'CN': 'ቻይና',
      'CO': 'ኮሎምቢያ',
      'CR': 'ኮስታሪካ',
      'CU': 'ኩባ',
      'CV': 'ኬፕቨርዴ',
      'CW': 'ኩራሳዎ',
      'CX': 'ክሪስማስ ደሴት',
      'CY': 'ሳይፕረስ',
      'CZ': 'ቼቺያ',
      'DE': 'ጀርመን',
      'DJ': 'ጂቡቲ',
      'DK': 'ዴንማርክ',
      'DM': 'ዶሚኒካ',
      'DO': 'ዶመኒካን ሪፑብሊክ',
      'DZ': 'አልጄሪያ',
      'EC': 'ኢኳዶር',
      'EE': 'ኤስቶኒያ',
      'EG': 'ግብጽ',
      'EH': 'ምዕራባዊ ሳህራ',
      'ER': 'ኤርትራ',
      'ES': 'ስፔን',
      'ET': 'ኢትዮጵያ',
      'FI': 'ፊንላንድ',
      'FJ': 'ፊጂ',
      'FK': 'የፎክላንድ ደሴቶች',
      'FM': 'ማይክሮኔዢያ',
      'FO': 'የፋሮ ደሴቶች',
      'FR': 'ፈረንሳይ',
      'GA': 'ጋቦን',
      'GB': 'ዩናይትድ ኪንግደም',
      'GD': 'ግሬናዳ',
      'GE': 'ጆርጂያ',
      'GF': 'የፈረንሳይ ጉዊአና',
      'GG': 'ጉርነሲ',
      'GH': 'ጋና',
      'GI': 'ጂብራልተር',
      'GL': 'ግሪንላንድ',
      'GM': 'ጋምቢያ',
      'GN': 'ጊኒ',
      'GP': 'ጉዋደሉፕ',
      'GQ': 'ኢኳቶሪያል ጊኒ',
      'GR': 'ግሪክ',
      'GS': 'ደቡብ ጆርጂያ እና የደቡብ ሳንድዊች ደሴቶች',
      'GT': 'ጉዋቲማላ',
      'GU': 'ጉዋም',
      'GW': 'ጊኒ-ቢሳው',
      'GY': 'ጉያና',
      'HK': 'ሆንግ ኮንግ',
      'HM': 'ሄርድ እና ማክዶናልድ ደሴቶች',
      'HN': 'ሆንዱራስ',
      'HR': 'ክሮኤሽያ',
      'HT': 'ሀይቲ',
      'HU': 'ሀንጋሪ',
      'ID': 'ኢንዶኔዢያ',
      'IE': 'አየርላንድ',
      'IL': 'እስራኤል',
      'IM': 'አይል ኦፍ ማን',
      'IN': 'ህንድ',
      'IO': 'የብሪታኒያ ህንድ ውቂያኖስ ግዛት',
      'IQ': 'ኢራቅ',
      'IR': 'ኢራን',
      'IS': 'አይስላንድ',
      'IT': 'ጣሊያን',
      'JE': 'ጀርዚ',
      'JM': 'ጃማይካ',
      'JO': 'ጆርዳን',
      'JP': 'ጃፓን',
      'KE': 'ኬንያ',
      'KG': 'ኪርጊስታን',
      'KH': 'ካምቦዲያ',
      'KI': 'ኪሪባቲ',
      'KM': 'ኮሞሮስ',
      'KN': 'ቅዱስ ኪትስ እና ኔቪስ',
      'KP': 'ሰሜን ኮሪያ',
      'KR': 'ደቡብ ኮሪያ',
      'KW': 'ኩዌት',
      'KY': 'ካይማን ደሴቶች',
      'KZ': 'ካዛኪስታን',
      'LA': 'ላኦስ',
      'LB': 'ሊባኖስ',
      'LC': 'ሴንት ሉቺያ',
      'LI': 'ሊችተንስታይን',
      'LK': 'ሲሪላንካ',
      'LR': 'ላይቤሪያ',
      'LS': 'ሌሶቶ',
      'LT': 'ሊቱዌኒያ',
      'LU': 'ሉክሰምበርግ',
      'LV': 'ላትቪያ',
      'LY': 'ሊቢያ',
      'MA': 'ሞሮኮ',
      'MC': 'ሞናኮ',
      'MD': 'ሞልዶቫ',
      'ME': 'ሞንተኔግሮ',
      'MF': 'ሴንት ማርቲን',
      'MG': 'ማዳጋስካር',
      'MH': 'ማርሻል ደሴቶች',
      'MK': 'ሰሜን መቄዶንያ',
      'ML': 'ማሊ',
      'MM': 'ማይናማር (በርማ)',
      'MN': 'ሞንጎሊያ',
      'MO': 'ማካኡ',
      'MP': 'የሰሜናዊ ማሪያና ደሴቶች',
      'MQ': 'ማርቲኒክ',
      'MR': 'ሞሪቴኒያ',
      'MS': 'ሞንትሴራት',
      'MT': 'ማልታ',
      'MU': 'ሞሪሸስ',
      'MV': 'ማልዲቭስ',
      'MW': 'ማላዊ',
      'MX': 'ሜክሲኮ',
      'MY': 'ማሌዢያ',
      'MZ': 'ሞዛምቢክ',
      'NA': 'ናሚቢያ',
      'NC': 'ኒው ካሌዶኒያ',
      'NE': 'ኒጀር',
      'NF': 'ኖርፎልክ ደሴት',
      'NG': 'ናይጄሪያ',
      'NI': 'ኒካራጓ',
      'NL': 'ኔዘርላንድ',
      'NO': 'ኖርዌይ',
      'NP': 'ኔፓል',
      'NR': 'ናኡሩ',
      'NU': 'ኒዌ',
      'NZ': 'ኒው ዚላንድ',
      'OM': 'ኦማን',
      'PA': 'ፓናማ',
      'PE': 'ፔሩ',
      'PF': 'የፈረንሳይ ፖሊኔዢያ',
      'PG': 'ፓፑዋ ኒው ጊኒ',
      'PH': 'ፊሊፒንስ',
      'PK': 'ፓኪስታን',
      'PL': 'ፖላንድ',
      'PM': 'ሴንት ፒዬር እና ሚኩኤሎን',
      'PN': 'ፒትካኢርን ደሴቶች',
      'PR': 'ፑዌርቶ ሪኮ',
      'PS': 'የፍልስጤም ግዛት',
      'PT': 'ፖርቱጋል',
      'PW': 'ፓላው',
      'PY': 'ፓራጓይ',
      'QA': 'ኳታር',
      'RE': 'ሪዩኒየን',
      'RO': 'ሮሜኒያ',
      'RS': 'ሰርብያ',
      'RU': 'ሩስያ',
      'RW': 'ሩዋንዳ',
      'SA': 'ሳውድአረቢያ',
      'SB': 'ሰለሞን ደሴቶች',
      'SC': 'ሲሼልስ',
      'SD': 'ሱዳን',
      'SE': 'ስዊድን',
      'SG': 'ሲንጋፖር',
      'SH': 'ሴንት ሄለና',
      'SI': 'ስሎቬኒያ',
      'SJ': 'ስቫልባርድ እና ጃን ማየን',
      'SK': 'ስሎቫኪያ',
      'SL': 'ሴራሊዮን',
      'SM': 'ሳን ማሪኖ',
      'SN': 'ሴኔጋል',
      'SO': 'ሶማሊያ',
      'SR': 'ሱሪናም',
      'SS': 'ደቡብ ሱዳን',
      'ST': 'ሳኦ ቶሜ እና ፕሪንሲፔ',
      'SV': 'ኤል ሳልቫዶር',
      'SX': 'ሲንት ማርተን',
      'SY': 'ሶሪያ',
      'SZ': 'ኤስዋቲኒ',
      'TC': 'የቱርኮችና የካኢኮስ ደሴቶች',
      'TD': 'ቻድ',
      'TF': 'የፈረንሳይ ደቡባዊ ግዛቶች',
      'TG': 'ቶጐ',
      'TH': 'ታይላንድ',
      'TJ': 'ታጃኪስታን',
      'TK': 'ቶክላው',
      'TL': 'ቲሞር ሌስቴ',
      'TM': 'ቱርክሜኒስታን',
      'TN': 'ቱኒዚያ',
      'TO': 'ቶንጋ',
      'TR': 'ቱርክ',
      'TT': 'ትሪናዳድ እና ቶቤጎ',
      'TV': 'ቱቫሉ',
      'TW': 'ታይዋን',
      'TZ': 'ታንዛኒያ',
      'UA': 'ዩክሬን',
      'UG': 'ዩጋንዳ',
      'UM': 'የዩ ኤስ ጠረፍ ላይ ያሉ ደሴቶች',
      'US': 'ዩናይትድ ስቴትስ',
      'UY': 'ኡራጓይ',
      'UZ': 'ኡዝቤኪስታን',
      'VA': 'ቫቲካን ከተማ',
      'VC': 'ሴንት ቪንሴንት እና ግሬናዲንስ',
      'VE': 'ቬንዙዌላ',
      'VG': 'የእንግሊዝ ቨርጂን ደሴቶች',
      'VI': 'የአሜሪካ ቨርጂን ደሴቶች',
      'VN': 'ቬትናም',
      'VU': 'ቫኑአቱ',
      'WF': 'ዋሊስ እና ፉቱና ደሴቶች',
      'WS': 'ሳሞአ',
      'XK': 'ኮሶቮ',
      'YE': 'የመን',
      'YT': 'ሜይኦቴ',
      'ZA': 'ደቡብ አፍሪካ',
      'ZM': 'ዛምቢያ',
      'ZW': 'ዚምቧቤ',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'የግላዊነት ምርጫዎች';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'አምስተርዳም',
      'sgp': 'ሲንጋፖር',
      'lax': 'ሎስ አንጀለስ',
      'mel': 'ሜልቦርን',
      'syd': 'ሲድኒ',
      'sao': 'ሳኦ ፓውሎ',
      'yto': 'ቶሮንቶ',
      'scl': 'ሳንቲያጎ',
      'cdg': 'ፓሪስ',
      'fra': 'ፍራንክፈርት',
      'del': 'ዴሊ',
      'bom': 'ሙምባይ',
      'blr': 'ባንጋሎር',
      'tlv': 'ቴል አቪቭ',
      'itm': 'ኦሳካ',
      'nrt': 'ቶኪዮ',
      'mex': 'ሜክሲኮ ሲቲ',
      'waw': 'ዋርሳው',
      'jnb': 'ጆሃንስበርግ',
      'icn': 'ሴኡል',
      'mad': 'ማድሪድ',
      'sto': 'ስቶክሆልም',
      'lhr': 'ለንደን',
      'man': 'ማንቸስተር',
      'ord': 'ቺካጎ',
      'dfw': 'ዳላስ',
      'sea': 'ሲያትል',
      'sjc': 'ሳን ፍራንሲስኮ',
      'mia': 'ማያሚ',
      'hnl': 'ሆኖሉሉ',
      'ewr': 'ኒው ዮርክ',
      'atl': 'አትላንታ',
      'hkg': 'ሆንግ ኮንግ',
      'zrh': 'ዙሪክ',
      'gva': 'ጄኔቫ',
      'svo': 'ሞስኮ',
      'led': 'ሴንት ፒተርስበርግ',
      'hel': 'ሄልሲንኪ',
      'tpe': 'ታይፔ',
      'dxb': 'ዱባይ',
      'kbp': 'ኪየቭ',
      'ist': 'ኢስታንቡል',
      'otp': 'ቡካሬስት',
      'los': 'ሌጎስ',
      'pty': 'ፓናማ ሲቲ',
      'kef': 'ሬይክያቪክ',
      'ber': 'በርሊን',
      'ala': 'አልማቲ',
      'tbs': 'ትብሊሲ',
      'kul': 'ኩዋላ ላምፑር',
      'bkk': 'ባንኮክ',
      'cgk': 'ጃካርታ',
      'mnl': 'ማኒላ',
      'nbo': 'ናይሮቢ',
      'mxp': 'ሚላን',
      'dub': 'ደብሊን',
      'lis': 'ሊዝበን',
      'lux': 'ሉክሰምበርግ',
      'eze': 'ቦነስ አይረስ',
      'akl': 'ኦክላንድ',
      'yul': 'ሞንትሪያል',
      'yvr': 'ቫንኩቨር',
      'den': 'ዴንቨር',
      'phx': 'ፊኒክስ',
      'iad': 'ዋሽንግተን ዲሲ',
      'bos': 'ቦስተን',
      'edi': 'ኤድንበራ',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => '1VPNን እየወደዱት ነው?';

  @override
  String get onevpnYes => 'አዎ';

  @override
  String get onevpnNo => 'አይ';

  @override
  String get onevpnLocationLocked => 'ተቆልፏል፣ ፕሪሚየም ብቻ';

  @override
  String get onevpnManageSubscription => 'የደንበኝነት ምዝገባን ያስተዳድሩ';
}
