// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class OneVpnLocalizationsHi extends OneVpnLocalizations {
  OneVpnLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get onevpnFaq => 'अक्सर पूछे जाने वाले सवाल';

  @override
  String get onevpnTermsOfService => 'सेवा की शर्तें';

  @override
  String get onevpnMenu => 'मेन्यू';

  @override
  String get onevpnUpgrade => 'अपग्रेड करें';

  @override
  String get onevpnUpgradeBannerTitle => 'प्रीमियम पर अपग्रेड करें';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'कोई विज्ञापन नहीं, सभी जगहें और ज़्यादा तेज़ स्पीड';

  @override
  String get onevpnLogIn => 'लॉग इन करें';

  @override
  String get onevpnLogOut => 'लॉग आउट करें';

  @override
  String get onevpnAccount => 'खाता';

  @override
  String get onevpnContactUs => 'हमसे संपर्क करें';

  @override
  String get onevpnRefundPolicy => 'रिफ़ंड नीति';

  @override
  String get onevpnSupport => 'सहायता';

  @override
  String get onevpnLanguage => 'भाषा';

  @override
  String get onevpnLanguageSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get onevpnPlanFree => 'मुफ़्त प्लान';

  @override
  String get onevpnPlanPremium => 'प्रीमियम प्लान';

  @override
  String get onevpnSelectLocation => 'जगह चुनें';

  @override
  String get onevpnDirectRegions => 'सीधे कनेक्ट होने वाले क्षेत्र';

  @override
  String get onevpnFree => 'मुफ़्त';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · मुफ़्त';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'ऑटोमैटिक · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'ऑटोमैटिक';

  @override
  String get onevpnStatusNoConnection => 'कोई कनेक्शन नहीं';

  @override
  String get onevpnStatusConnectionFailed => 'कनेक्ट नहीं हो सका';

  @override
  String get onevpnStatusUpdating => 'अपडेट हो रहा है…';

  @override
  String get onevpnStatusMeasuring => 'सर्वर की स्पीड जांची जा रही है…';

  @override
  String get onevpnAutomaticSubtitle => 'सबसे तेज़ उपलब्ध सर्वर';

  @override
  String get onevpnLocationsLoadFailed => 'आपकी जगहें लोड नहीं हो सकीं.';

  @override
  String get onevpnLocationsUnavailable => 'फ़िलहाल कोई जगह उपलब्ध नहीं है.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'कुछ साइटें तभी काम करती हैं, जब आप उसी देश से कनेक्ट करते हैं जिस देश की वह साइट है. सीधे कनेक्ट होने वाला क्षेत्र चुनने पर, उस क्षेत्र की साइटें वीपीएन से होकर नहीं जातीं.';

  @override
  String onevpnSelectionReset(String location) {
    return '$location उपलब्ध नहीं है, इसलिए 1VPN ने \"ऑटोमैटिक\" पर स्विच कर दिया है.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'चुनी गई जगह उपलब्ध नहीं है, इसलिए 1VPN ने \"ऑटोमैटिक\" पर स्विच कर दिया है.';

  @override
  String onevpnReloadRolledBack(String location) {
    return '$location पर स्विच नहीं किया जा सका. आप अब भी अपनी पिछली जगह से कनेक्ट हैं.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'बदलाव लागू नहीं किया जा सका. आप अब भी अपनी पिछली सेटिंग के साथ कनेक्ट हैं.';

  @override
  String get onevpnDirectRegionsOff => 'बंद (डिफ़ॉल्ट)';

  @override
  String get onevpnAllViaVpnSubtitle => 'पूरा ट्रैफ़िक टनल से होकर जाता है';

  @override
  String get onevpnRegionChina => 'चीन';

  @override
  String get onevpnFirstConnectTitle =>
      'कुछ क्षेत्र सीधे कनेक्ट होने पर बेहतर काम करते हैं';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'चीन, रूस और ईरान जैसे देशों में, पूरा ट्रैफ़िक वीपीएन से भेजने पर स्थानीय बैंकिंग और पेमेंट ऐप काम करना बंद कर सकते हैं.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN आपके चुने हुए क्षेत्र को टनल के बाहर, आपके असली IP से सीधे कनेक्ट कर सकता है.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'बाकी सब कुछ सुरक्षित रहता है. आप इसे कभी भी बदल सकते हैं.';

  @override
  String get onevpnFirstConnectChooseRegion =>
      'सीधे कनेक्ट होने वाला क्षेत्र चुनें';

  @override
  String get onevpnFirstConnectDismiss => 'अभी नहीं';

  @override
  String get onevpnCensorshipWarning =>
      'सरकारी प्रतिबंधों के कारण आपके क्षेत्र में कुछ सर्वर ब्लॉक हो सकते हैं। हम इसे हल करने पर काम कर रहे हैं। आपकी समझ के लिए धन्यवाद।';

  @override
  String get onevpnAlwaysOnTitle => 'वीपीएन हमेशा चालू रखें';

  @override
  String get onevpnAlwaysOnIntro =>
      'ऐप बंद करने पर भी टनल चालू रहता है. डिवाइस रीस्टार्ट होने या ऐप अपडेट होने के बाद, \"वीपीएन हमेशा चालू रखें\" सेटिंग इसे अपने-आप फिर से कनेक्ट कर देती है.';

  @override
  String get onevpnAlwaysOnStep1 => 'नीचे \"वीपीएन सेटिंग खोलें\" पर टैप करें.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'सूची में 1VPN ढूंढें. आपके पहली बार कनेक्ट करने के बाद यह दिखता है.';

  @override
  String get onevpnAlwaysOnStep3 =>
      '1VPN के बगल में मौजूद सेटिंग (गियर) आइकॉन पर टैप करें.';

  @override
  String get onevpnAlwaysOnStep4 =>
      '\"वीपीएन हमेशा चालू रखें\" सेटिंग चालू करें.';

  @override
  String get onevpnAlwaysOnOpenSettings => 'वीपीएन सेटिंग खोलें';

  @override
  String get onevpnPaywallTitle => 'अपना प्लान चुनें';

  @override
  String get onevpnPaywallBenefitLocations => 'सर्वर की सभी जगहें अनलॉक करें';

  @override
  String get onevpnPaywallBenefitNoAds => 'कोई विज्ञापन नहीं';

  @override
  String get onevpnPaywallBenefitSpeed => 'सर्वर की ज़्यादा तेज़ स्पीड';

  @override
  String get onevpnPaywallBenefitP2p => 'BitTorrent (P2P) की सुविधा';

  @override
  String get onevpnPaywallBenefitMoneyBack => '10 दिन की मनी-बैक गारंटी';

  @override
  String get onevpnPaywallPlanYearly => 'सालाना';

  @override
  String get onevpnPaywallPlanMonthly => 'मासिक';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '$percent% बचाएं';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / महीना';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'कीमत उपलब्ध नहीं है';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'प्लान लोड नहीं हो सके. अपना कनेक्शन जांचें.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'फ़िलहाल कोई प्लान उपलब्ध नहीं है. कृपया बाद में फिर से कोशिश करें.';

  @override
  String get onevpnGetPremium => 'प्रीमियम पाएं';

  @override
  String get onevpnContinueFree => 'मुफ़्त में जारी रखें';

  @override
  String get onevpnPaywallRetry => 'फिर से कोशिश करें';

  @override
  String get onevpnPaywallPurchaseError =>
      'कोई गड़बड़ी हुई. कृपया फिर से कोशिश करें.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'इस Google खाते में एक चालू या हाल ही में ख़त्म हुई 1VPN सदस्यता है, जो किसी दूसरे 1VPN खाते से जुड़ी है. उस खाते में लॉग इन करें या $support से संपर्क करें.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'इस Google खाते में पहले से एक 1VPN सदस्यता है. अगर प्रीमियम नहीं दिखता, तो $support से संपर्क करें.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play ने आपकी पिछली खरीदारी पूरी नहीं की. खुली हुई Google Play स्क्रीन बंद करके फिर से कोशिश करें या ऐप रीस्टार्ट करें.';

  @override
  String get onevpnPaywallSupportLink => '1VPN सहायता';

  @override
  String get onevpnSignUp => 'साइन अप करें';

  @override
  String get onevpnAuthEmailLabel => 'ईमेल';

  @override
  String get onevpnAuthPasswordLabel => 'पासवर्ड';

  @override
  String get onevpnAuthTwoFactorLabel => '2FA टोकन';

  @override
  String get onevpnAuthForgotPassword => 'अपना पासवर्ड भूल गए हैं?';

  @override
  String get onevpnAuthSubmitting => 'लोड हो रहा है…';

  @override
  String get onevpnAuthCreateAccount => 'खाता बनाएं';

  @override
  String get onevpnAuthHaveAccount => 'क्या आपके पास पहले से खाता है?';

  @override
  String get onevpnAuthLogInInstead => 'इसके बजाय लॉग इन करें';

  @override
  String get onevpnAuthFieldsRequired => 'ईमेल और पासवर्ड डालें';

  @override
  String get onevpnAuthInvalidEmail => 'मान्य ईमेल पता डालें';

  @override
  String get onevpnAuthInvalidCredentials => 'क्रेडेंशियल गलत हैं';

  @override
  String get onevpnAuthInvalidTwoFactor => '2FA टोकन गलत है';

  @override
  String get onevpnAuthEmailInUse => 'इस ईमेल से पहले ही एक खाता बना हुआ है';

  @override
  String get onevpnAuthRateLimited =>
      'बहुत ज़्यादा कोशिशें की गईं. कृपया थोड़ी देर बाद फिर से कोशिश करें';

  @override
  String get onevpnAuthUnreachable =>
      'सर्वर से कनेक्ट नहीं हो सका. अपना कनेक्शन जांचें और फिर से कोशिश करें';

  @override
  String get onevpnAuthGenericError =>
      'कोई गड़बड़ी हुई. कृपया फिर से कोशिश करें';

  @override
  String get onevpnAuthEmailLockedHint =>
      'आपकी खरीदारी इस ईमेल पते से जुड़ी है.';

  @override
  String get onevpnPaywallPurchasedTitle => 'खरीदारी पूरी हुई';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'आपकी खरीदारी $email से जुड़ी है. इसका इस्तेमाल करने के लिए, उसी ईमेल पते से खाता बनाएं.';
  }

  @override
  String get onevpnPlanPremiumPending =>
      'प्रीमियम · खरीदारी की पुष्टि हो रही है';

  @override
  String get onevpnPremiumRecheck => 'आपकी खरीदारी की स्थिति जांची जा रही है…';

  @override
  String get onevpnButtonRetry => 'फिर से कोशिश करें';

  @override
  String get onevpnAppVersion => 'ऐप का वर्शन';

  @override
  String get onevpnPrivacyPolicy => 'निजता नीति';

  @override
  String get onevpnConnect => 'कनेक्ट करें';

  @override
  String get onevpnDisconnected => 'डिसकनेक्ट किया गया';

  @override
  String get onevpnConnecting => 'कनेक्ट हो रहा है…';

  @override
  String get onevpnConnected => 'कनेक्ट किया गया';

  @override
  String get onevpnDisconnecting => 'डिसकनेक्ट हो रहा है…';

  @override
  String get onevpnConnectionFailed => 'कनेक्ट नहीं हो सका';

  @override
  String get onevpnTemporarilyUnavailable => 'फ़िलहाल, उपलब्ध नहीं है';

  @override
  String get onevpnRetry => 'फिर से कोशिश करें';

  @override
  String get onevpnApplyChange => 'क्या यह बदलाव लागू करना है?';

  @override
  String get onevpnReconnectNotice =>
      'वीपीएन कुछ देर के लिए डिसकनेक्ट होकर फिर से कनेक्ट होगा. आम तौर पर इसमें बस कुछ सेकंड लगते हैं.';

  @override
  String onevpnWillUseName(String name) {
    return 'इस्तेमाल होगा: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'लागू करें और फिर से कनेक्ट करें';

  @override
  String get onevpnCancel => 'रद्द करें';

  @override
  String get onevpnContinue => 'जारी रखें';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'मुख्य डोमेन ब्लॉक है। बैकअप इस्तेमाल हो रहा है: $domain';
  }

  @override
  String get onevpnResultFailed => 'विफल';

  @override
  String get onevpnDownload => 'डाउनलोड करें';

  @override
  String get onevpnPermissionNotGranted => 'अनुमति नहीं मिली';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action: $result';
  }

  @override
  String get onevpnDisconnect => 'डिसकनेक्ट करें';

  @override
  String get onevpnTimeout => 'टाइम आउट';

  @override
  String get onevpnNoAvailableEntries => 'कोई एंट्री सर्वर उपलब्ध नहीं है';

  @override
  String get onevpnAddServers => 'सर्वर जोड़ें';

  @override
  String get onevpnNotEnoughServers => 'उपलब्ध सर्वर काफ़ी नहीं हैं';

  @override
  String get onevpnVpnFinalExit => 'वीपीएन का आखिरी एग्ज़िट सर्वर';

  @override
  String get onevpnFinalExitEntryConflict =>
      'आखिरी एग्ज़िट सर्वर और एंट्री सर्वर एक ही नहीं हो सकते';

  @override
  String get onevpnChooseNamedRoute => 'नाम वाला कोई एक रूट चुनें';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'लोकल नेटवर्क पर मौजूद डिवाइसों और सेवाओं को ऐक्सेस करने की अनुमति दें.';

  @override
  String get onevpnSystemApprovalRequired => 'सिस्टम की मंज़ूरी ज़रूरी है';

  @override
  String get onevpnVpnPermissionRequired =>
      'वीपीएन की अनुमति ज़रूरी है. जारी रखने के लिए कृपया फिर से कोशिश करें.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'नेटवर्क ऐक्सेस करने के लिए इस्तेमाल होने वाला इंटरफ़ेस चुनें. यह सिर्फ़ Windows / Linux पर ज़रूरी है.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'एंडोरा',
      'AE': 'संयुक्त अरब अमीरात',
      'AF': 'अफ़ग़ानिस्तान',
      'AG': 'एंटिगुआ और बरबुडा',
      'AI': 'एंग्विला',
      'AL': 'अल्बानिया',
      'AM': 'आर्मेनिया',
      'AO': 'अंगोला',
      'AQ': 'अंटार्कटिका',
      'AR': 'अर्जेंटीना',
      'AS': 'अमेरिकी समोआ',
      'AT': 'ऑस्ट्रिया',
      'AU': 'ऑस्ट्रेलिया',
      'AW': 'अरूबा',
      'AX': 'एलैंड द्वीपसमूह',
      'AZ': 'अज़रबैजान',
      'BA': 'बोस्निया और हर्ज़ेगोविना',
      'BB': 'बारबाडोस',
      'BD': 'बांग्लादेश',
      'BE': 'बेल्जियम',
      'BF': 'बुर्किना फ़ासो',
      'BG': 'बुल्गारिया',
      'BH': 'बहरीन',
      'BI': 'बुरुंडी',
      'BJ': 'बेनिन',
      'BL': 'सेंट बार्थेलेमी',
      'BM': 'बरमूडा',
      'BN': 'ब्रूनेई',
      'BO': 'बोलीविया',
      'BQ': 'कैरिबियन नीदरलैंड',
      'BR': 'ब्राज़ील',
      'BS': 'बहामास',
      'BT': 'भूटान',
      'BV': 'बोवेत द्वीप',
      'BW': 'बोत्स्वाना',
      'BY': 'बेलारूस',
      'BZ': 'बेलीज़',
      'CA': 'कनाडा',
      'CC': 'कोकोस (कीलिंग) द्वीपसमूह',
      'CD': 'कांगो - किंशासा',
      'CF': 'मध्य अफ़्रीकी गणराज्य',
      'CG': 'कांगो – ब्राज़ाविल',
      'CH': 'स्विट्ज़रलैंड',
      'CI': 'कोत दीवुआर',
      'CK': 'कुक द्वीपसमूह',
      'CL': 'चिली',
      'CM': 'कैमरून',
      'CN': 'चीन मुख्यभूमि',
      'CO': 'कोलंबिया',
      'CR': 'कोस्टा रीका',
      'CU': 'क्यूबा',
      'CV': 'केप वर्ड',
      'CW': 'कुरासाओ',
      'CX': 'क्रिसमस द्वीप',
      'CY': 'साइप्रस',
      'CZ': 'चेकिया',
      'DE': 'जर्मनी',
      'DJ': 'जिबूती',
      'DK': 'डेनमार्क',
      'DM': 'डोमिनिका',
      'DO': 'डोमिनिकन गणराज्य',
      'DZ': 'अल्जीरिया',
      'EC': 'इक्वाडोर',
      'EE': 'एस्टोनिया',
      'EG': 'मिस्र',
      'EH': 'पश्चिमी सहारा',
      'ER': 'इरिट्रिया',
      'ES': 'स्पेन',
      'ET': 'इथियोपिया',
      'FI': 'फ़िनलैंड',
      'FJ': 'फ़िजी',
      'FK': 'फ़ॉकलैंड द्वीपसमूह',
      'FM': 'माइक्रोनेशिया',
      'FO': 'फ़ेरो द्वीपसमूह',
      'FR': 'फ़्रांस',
      'GA': 'गैबॉन',
      'GB': 'यूनाइटेड किंगडम',
      'GD': 'ग्रेनाडा',
      'GE': 'जॉर्जिया',
      'GF': 'फ़्रेंच गुयाना',
      'GG': 'गर्नसी',
      'GH': 'घाना',
      'GI': 'जिब्राल्टर',
      'GL': 'ग्रीनलैंड',
      'GM': 'गाम्बिया',
      'GN': 'गिनी',
      'GP': 'ग्वाडेलूप',
      'GQ': 'इक्वेटोरियल गिनी',
      'GR': 'यूनान',
      'GS': 'दक्षिण जॉर्जिया और दक्षिण सैंडविच द्वीपसमूह',
      'GT': 'ग्वातेमाला',
      'GU': 'गुआम',
      'GW': 'गिनी-बिसाउ',
      'GY': 'गुयाना',
      'HK': 'हाँग काँग',
      'HM': 'हर्ड द्वीप और मैकडोनॉल्ड द्वीपसमूह',
      'HN': 'होंडूरास',
      'HR': 'क्रोएशिया',
      'HT': 'हाइती',
      'HU': 'हंगरी',
      'ID': 'इंडोनीशिया',
      'IE': 'आयरलैंड',
      'IL': 'इज़राइल',
      'IM': 'आइल ऑफ़ मैन',
      'IN': 'भारत',
      'IO': 'चागोस आर्किपेलगो',
      'IQ': 'इराक़',
      'IR': 'ईरान',
      'IS': 'आइसलैंड',
      'IT': 'इटली',
      'JE': 'जर्सी',
      'JM': 'जमैका',
      'JO': 'जॉर्डन',
      'JP': 'जापान',
      'KE': 'केन्या',
      'KG': 'किर्गिज़स्तान',
      'KH': 'कंबोडिया',
      'KI': 'किरिबाती',
      'KM': 'कोमोरोस',
      'KN': 'सेंट किट्स और नेविस',
      'KP': 'उत्तर कोरिया',
      'KR': 'दक्षिण कोरिया',
      'KW': 'कुवैत',
      'KY': 'कैमेन द्वीपसमूह',
      'KZ': 'क़ाज़ाक़स्तान',
      'LA': 'लाओस',
      'LB': 'लेबनान',
      'LC': 'सेंट लूसिया',
      'LI': 'लिक्टनस्टाइन',
      'LK': 'श्रीलंका',
      'LR': 'लाइबेरिया',
      'LS': 'लेसोथो',
      'LT': 'लिथुआनिया',
      'LU': 'लग्ज़मबर्ग',
      'LV': 'लातविया',
      'LY': 'लीबिया',
      'MA': 'मोरक्को',
      'MC': 'मोनाको',
      'MD': 'मॉल्डोवा',
      'ME': 'मोंटेनेग्रो',
      'MF': 'सेंट मार्टिन',
      'MG': 'मेडागास्कर',
      'MH': 'मार्शल द्वीपसमूह',
      'MK': 'उत्तरी मकदूनिया',
      'ML': 'माली',
      'MM': 'म्यांमार (बर्मा)',
      'MN': 'मंगोलिया',
      'MO': 'मकाओ',
      'MP': 'उत्तरी मारियाना द्वीपसमूह',
      'MQ': 'मार्टीनिक',
      'MR': 'मॉरिटानिया',
      'MS': 'मोंटसेरात',
      'MT': 'माल्टा',
      'MU': 'मॉरीशस',
      'MV': 'मालदीव',
      'MW': 'मलावी',
      'MX': 'मेक्सिको',
      'MY': 'मलेशिया',
      'MZ': 'मोज़ांबिक',
      'NA': 'नामीबिया',
      'NC': 'न्यू कैलेडोनिया',
      'NE': 'नाइजर',
      'NF': 'नॉरफ़ॉक द्वीप',
      'NG': 'नाइजीरिया',
      'NI': 'निकारागुआ',
      'NL': 'नीदरलैंड',
      'NO': 'नॉर्वे',
      'NP': 'नेपाल',
      'NR': 'नाउरु',
      'NU': 'नीयू',
      'NZ': 'न्यूज़ीलैंड',
      'OM': 'ओमान',
      'PA': 'पनामा',
      'PE': 'पेरू',
      'PF': 'फ़्रेंच पोलिनेशिया',
      'PG': 'पापुआ न्यू गिनी',
      'PH': 'फ़िलिपींस',
      'PK': 'पाकिस्तान',
      'PL': 'पोलैंड',
      'PM': 'सेंट पिएरे और मिक्वेलान',
      'PN': 'पिटकैर्न द्वीपसमूह',
      'PR': 'पोर्टो रिको',
      'PS': 'फ़िलिस्तीनी क्षेत्र',
      'PT': 'पुर्तगाल',
      'PW': 'पलाऊ',
      'PY': 'पराग्वे',
      'QA': 'क़तर',
      'RE': 'रियूनियन',
      'RO': 'रोमानिया',
      'RS': 'सर्बिया',
      'RU': 'रूस',
      'RW': 'रवांडा',
      'SA': 'सऊदी अरब',
      'SB': 'सोलोमन द्वीपसमूह',
      'SC': 'सेशेल्स',
      'SD': 'सूडान',
      'SE': 'स्वीडन',
      'SG': 'सिंगापुर',
      'SH': 'सेंट हेलेना',
      'SI': 'स्लोवेनिया',
      'SJ': 'स्वालबार्ड और जान मायेन',
      'SK': 'स्लोवाकिया',
      'SL': 'सिएरा लियोन',
      'SM': 'सैन मेरीनो',
      'SN': 'सेनेगल',
      'SO': 'सोमालिया',
      'SR': 'सूरीनाम',
      'SS': 'दक्षिण सूडान',
      'ST': 'साओ टोम और प्रिंसिपे',
      'SV': 'अल सल्वाडोर',
      'SX': 'सिंट मार्टिन',
      'SY': 'सीरिया',
      'SZ': 'एस्वाटिनी',
      'TC': 'तुर्क और कैकोज़ द्वीपसमूह',
      'TD': 'चाड',
      'TF': 'फ़्रांसीसी दक्षिणी क्षेत्र',
      'TG': 'टोगो',
      'TH': 'थाईलैंड',
      'TJ': 'ताजिकिस्तान',
      'TK': 'तोकेलाउ',
      'TL': 'तिमोर-लेस्त',
      'TM': 'तुर्कमेनिस्तान',
      'TN': 'ट्यूनीशिया',
      'TO': 'टोंगा',
      'TR': 'तुर्किये',
      'TT': 'त्रिनिदाद और टोबैगो',
      'TV': 'तुवालू',
      'TW': 'ताइवान',
      'TZ': 'तंज़ानिया',
      'UA': 'यूक्रेन',
      'UG': 'युगांडा',
      'UM': 'यू॰एस॰ दूरस्थ द्वीपसमूह',
      'US': 'संयुक्त राज्य अमेरिका',
      'UY': 'उरूग्वे',
      'UZ': 'उज़्बेकिस्तान',
      'VA': 'वेटिकन सिटी',
      'VC': 'सेंट विंसेंट और ग्रेनाडाइंस',
      'VE': 'वेनेज़ुएला',
      'VG': 'ब्रिटिश वर्जिन द्वीपसमूह',
      'VI': 'यू॰एस॰ वर्जिन द्वीपसमूह',
      'VN': 'वियतनाम',
      'VU': 'वनुआतू',
      'WF': 'वालिस और फ़्यूचूना',
      'WS': 'समोआ',
      'XK': 'कोसोवो',
      'YE': 'यमन',
      'YT': 'मायोते',
      'ZA': 'दक्षिण अफ़्रीका',
      'ZM': 'ज़ाम्बिया',
      'ZW': 'ज़िम्बाब्वे',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'गोपनीयता विकल्प';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'एम्स्टर्डम',
      'sgp': 'सिंगापुर',
      'lax': 'लॉस एंजेलिस',
      'mel': 'मेलबर्न',
      'syd': 'सिडनी',
      'sao': 'साओ पाउलो',
      'yto': 'टोरंटो',
      'scl': 'सैंटियागो',
      'cdg': 'पेरिस',
      'fra': 'फ़्रैंकफ़र्ट',
      'del': 'दिल्ली',
      'bom': 'मुंबई',
      'blr': 'बेंगलुरु',
      'tlv': 'तेल अवीव',
      'itm': 'ओसाका',
      'nrt': 'टोक्यो',
      'mex': 'मेक्सिको सिटी',
      'waw': 'वारसॉ',
      'jnb': 'जोहान्सबर्ग',
      'icn': 'सियोल',
      'mad': 'मैड्रिड',
      'sto': 'स्टॉकहोम',
      'lhr': 'लंदन',
      'man': 'मैनचेस्टर',
      'ord': 'शिकागो',
      'dfw': 'डैलस',
      'sea': 'सिएटल',
      'sjc': 'सैन फ़्रांसिस्को',
      'mia': 'मियामी',
      'hnl': 'होनोलूलू',
      'ewr': 'न्यूयॉर्क',
      'atl': 'अटलांटा',
      'hkg': 'हाँग काँग',
      'zrh': 'ज़्यूरिख़',
      'gva': 'जिनेवा',
      'svo': 'मॉस्को',
      'led': 'सेंट पीटर्सबर्ग',
      'hel': 'हेलसिंकी',
      'tpe': 'ताइपे',
      'dxb': 'दुबई',
      'kbp': 'कीव',
      'ist': 'इस्तांबुल',
      'otp': 'बुखारेस्ट',
      'los': 'लागोस',
      'pty': 'पनामा सिटी',
      'kef': 'रेक्जाविक',
      'ber': 'बर्लिन',
      'ala': 'अल्माटी',
      'tbs': 'त्बिलिसी',
      'kul': 'कुआलालंपुर',
      'bkk': 'बैंकॉक',
      'cgk': 'जकार्ता',
      'mnl': 'मनीला',
      'nbo': 'नैरोबी',
      'mxp': 'मिलान',
      'dub': 'डबलिन',
      'lis': 'लिस्बन',
      'lux': 'लग्ज़मबर्ग',
      'eze': 'ब्यूनस आयर्स',
      'akl': 'ऑकलैंड',
      'yul': 'मॉन्ट्रियल',
      'yvr': 'वैंकूवर',
      'den': 'डेनवर',
      'phx': 'फ़ीनिक्स',
      'iad': 'वॉशिंगटन डी॰सी॰',
      'bos': 'बॉस्टन',
      'edi': 'एडिनबर्ग',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'क्या आपको 1VPN पसंद आ रहा है?';

  @override
  String get onevpnYes => 'हाँ';

  @override
  String get onevpnNo => 'नहीं';

  @override
  String get onevpnLocationLocked => 'लॉक, केवल प्रीमियम';

  @override
  String get onevpnManageSubscription => 'सदस्यता प्रबंधित करें';
}
