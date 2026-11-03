// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkmen (`tk`).
class OneVpnLocalizationsTk extends OneVpnLocalizations {
  OneVpnLocalizationsTk([String locale = 'tk']) : super(locale);

  @override
  String get onevpnFaq => 'Ýygy berilýän soraglar';

  @override
  String get onevpnTermsOfService => 'Hyzmat şertleri';

  @override
  String get onevpnMenu => 'Menýu';

  @override
  String get onevpnUpgrade => 'Premium tarifine geç';

  @override
  String get onevpnUpgradeBannerTitle => 'Premium tarifine geçiň';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Mahabatsyz, ähli ýerleşişler we has ýokary tizlik';

  @override
  String get onevpnLogIn => 'Ulgama gir';

  @override
  String get onevpnLogOut => 'Ulgamdan çyk';

  @override
  String get onevpnAccount => 'Hasap';

  @override
  String get onevpnContactUs => 'Biz bilen habarlaşyň';

  @override
  String get onevpnRefundPolicy => 'Pul gaýtarmak syýasaty';

  @override
  String get onevpnSupport => 'Goldaw';

  @override
  String get onevpnLanguage => 'Dil';

  @override
  String get onevpnLanguageSystem => 'Ulgamyň dili';

  @override
  String get onevpnPlanFree => 'Mugt tarif';

  @override
  String get onevpnPlanPremium => 'Premium tarif';

  @override
  String get onevpnSelectLocation => 'Ýerleşişi saýlaň';

  @override
  String get onevpnDirectRegions => 'Göni birikme sebitleri';

  @override
  String get onevpnFree => 'Mugt';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Mugt';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Awtomatik · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Awtomatik';

  @override
  String get onevpnStatusNoConnection => 'Birikme ýok';

  @override
  String get onevpnStatusConnectionFailed => 'Birikip bolmady';

  @override
  String get onevpnStatusUpdating => 'Täzelenýär…';

  @override
  String get onevpnStatusMeasuring => 'Serwerler barlanýar…';

  @override
  String get onevpnAutomaticSubtitle => 'Iň çalt elýeterli serwer';

  @override
  String get onevpnLocationsLoadFailed => 'Ýerleşişleriňizi ýükläp bolmady.';

  @override
  String get onevpnLocationsUnavailable =>
      'Ýerleşişler häzirki wagtda elýeterli däl.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Käbir saýtlar diňe siz saýt bilen bir ýurtdan birikeniňizde işleýär. Göni birikme sebitini saýlanyňyzda, şol sebitiň saýtlary VPN-den geçmeýär.';

  @override
  String onevpnSelectionReset(String location) {
    return '$location ýerleşişi elýeterli däl, 1VPN “Awtomatik” saýlawyna geçdi.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'Saýlanan ýerleşiş elýeterli däl, 1VPN “Awtomatik” saýlawyna geçdi.';

  @override
  String onevpnReloadRolledBack(String location) {
    return '$location ýerleşişine geçip bolmady. Birikme öňki ýerleşişiňizde dowam edýär.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Üýtgetmäni ulanyp bolmady. Birikme öňki sazlamalaryňyz bilen dowam edýär.';

  @override
  String get onevpnDirectRegionsOff => 'Öçük (Deslapky)';

  @override
  String get onevpnAllViaVpnSubtitle => 'Ähli trafik tunelden geçýär';

  @override
  String get onevpnRegionChina => 'Hytaý';

  @override
  String get onevpnFirstConnectTitle =>
      'Käbir sebitler göni birikmede has gowy işleýär';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'Hytaý, Russiýa we Eýran ýaly ýerlerde ähli trafigi VPN arkaly ibermek ýerli bank we töleg programmalarynyň işini bozup biler.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN siziň saýlan sebitiňizi tuneliň daşyndan, hakyky IP salgyňyzdan göni ugrukdyryp biler.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Galan ähli zat goragly bolup galýar. Muny islän wagtyňyz üýtgedip bilersiňiz.';

  @override
  String get onevpnFirstConnectChooseRegion => 'Göni birikme sebitini saýla';

  @override
  String get onevpnFirstConnectDismiss => 'Häzir däl';

  @override
  String get onevpnCensorshipWarning =>
      'Hökümet çäklendirmeleri sebäpli käbir serwerler siziň sebitiňizde petiklenen bolup biler. Biz bu meseläni çözmegiň üstünde işleýäris. Düşüneniňiz üçin sag boluň.';

  @override
  String get onevpnAlwaysOnTitle => 'Hemişe açyk VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      'Programmany ýapanyňyzda tunel açyk galýar. Enjam täzeden işledilenden ýa-da programma täzelenenden soň, “Hemişe açyk VPN” tuneli awtomatik usulda täzeden birikdirýär.';

  @override
  String get onevpnAlwaysOnStep1 =>
      'Aşakdaky “VPN sazlamalaryny aç” düwmesine basyň.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Sanawda 1VPN programmasyny tapyň. Ol ilkinji birikmeňizden soň peýda bolýar.';

  @override
  String get onevpnAlwaysOnStep3 =>
      '1VPN programmasynyň ýanyndaky dişli çarh nyşanyna basyň.';

  @override
  String get onevpnAlwaysOnStep4 => '“Hemişe açyk VPN” sazlamasyny açyň.';

  @override
  String get onevpnAlwaysOnOpenSettings => 'VPN sazlamalaryny aç';

  @override
  String get onevpnPaywallTitle => 'Tarifiňizi saýlaň';

  @override
  String get onevpnPaywallBenefitLocations =>
      'Ähli serwer ýerleşişlerine elýeterlilik';

  @override
  String get onevpnPaywallBenefitNoAds => 'Mahabatsyz';

  @override
  String get onevpnPaywallBenefitSpeed => 'Has ýokary serwer tizligi';

  @override
  String get onevpnPaywallBenefitP2p => 'BitTorrent (P2P) goldawy';

  @override
  String get onevpnPaywallBenefitMoneyBack =>
      '10 günlük pul gaýtarma kepilligi';

  @override
  String get onevpnPaywallPlanYearly => 'Bir ýyllyk';

  @override
  String get onevpnPaywallPlanMonthly => 'Bir aýlyk';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '$percent% tygşytlaň';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / aý';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Bahany alyp bolmady';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Tarifleri ýükläp bolmady. Internet baglanyşygyňyzy barlaň.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Tarifler häzirki wagtda elýeterli däl. Soňrak gaýtadan synanyşyň.';

  @override
  String get onevpnGetPremium => 'Premium tarifini al';

  @override
  String get onevpnContinueFree => 'Mugt dowam et';

  @override
  String get onevpnPaywallRetry => 'Gaýtadan synanyş';

  @override
  String get onevpnPaywallPurchaseError =>
      'Näsazlyk ýüze çykdy. Gaýtadan synanyşyň.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'Bu Google hasabynda başga bir 1VPN hasabyna baglanan işjeň ýa-da ýakynda tamamlanan 1VPN abunalygy bar. Şol hasap bilen ulgama giriň ýa-da $support bilen habarlaşyň.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'Bu Google hasabynda eýýäm 1VPN abunalygy bar. Premium görünmese, $support bilen habarlaşyň.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play soňky satyn alşyňyzy tamamlamady. Açyk Google Play ekranlaryny ýapyp, gaýtadan synanyşyň ýa-da programmany täzeden işlediň.';

  @override
  String get onevpnPaywallSupportLink => '1VPN goldaw gullugy';

  @override
  String get onevpnSignUp => 'Hasaba dur';

  @override
  String get onevpnAuthEmailLabel => 'E-poçta';

  @override
  String get onevpnAuthPasswordLabel => 'Açar söz';

  @override
  String get onevpnAuthTwoFactorLabel => '2FA kody';

  @override
  String get onevpnAuthForgotPassword => 'Açar sözümi unutdym';

  @override
  String get onevpnAuthSubmitting => 'Ýüklenýär…';

  @override
  String get onevpnAuthCreateAccount => 'Hasap döret';

  @override
  String get onevpnAuthHaveAccount => 'Hasabyňyz barmy?';

  @override
  String get onevpnAuthLogInInstead => 'Onuň ýerine ulgama gir';

  @override
  String get onevpnAuthFieldsRequired =>
      'E-poçta salgyňyzy we açar sözüňizi giriziň';

  @override
  String get onevpnAuthInvalidEmail => 'Dogry e-poçta salgysyny giriziň';

  @override
  String get onevpnAuthInvalidCredentials => 'E-poçta ýa-da açar söz nädogry';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Nädogry 2FA kody';

  @override
  String get onevpnAuthEmailInUse => 'Bu e-poçta salgysy bilen hasap eýýäm bar';

  @override
  String get onevpnAuthRateLimited =>
      'Synanyşyk sany gaty köp. Birazdan gaýtadan synanyşyň';

  @override
  String get onevpnAuthUnreachable =>
      'Serwer bilen baglanyşyp bolmady. Internet baglanyşygyňyzy barlaň we gaýtadan synanyşyň';

  @override
  String get onevpnAuthGenericError =>
      'Näsazlyk ýüze çykdy. Gaýtadan synanyşyň';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Satyn alşyňyz şu e-poçta salgysyna baglanan.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Satyn alyş tamamlandy';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Satyn alşyňyz $email salgysyna baglanan. Ony ulanmak üçin şol salgy bilen hasap dörediň.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Premium · satyn alyş tassyklanýar';

  @override
  String get onevpnPremiumRecheck => 'Satyn alşyňyzyň ýagdaýy barlanýar…';

  @override
  String get onevpnButtonRetry => 'Gaýtadan synanyş';

  @override
  String get onevpnAppVersion => 'Programmanyň wersiýasy';

  @override
  String get onevpnPrivacyPolicy => 'Gizlinlik syýasaty';

  @override
  String get onevpnConnect => 'Birik';

  @override
  String get onevpnDisconnected => 'Birikme kesildi';

  @override
  String get onevpnConnecting => 'Birikýär…';

  @override
  String get onevpnConnected => 'Birikdi';

  @override
  String get onevpnDisconnecting => 'Birikme kesilýär…';

  @override
  String get onevpnConnectionFailed => 'Birikip bolmady';

  @override
  String get onevpnTemporarilyUnavailable => 'Wagtlaýyn elýeterli däl';

  @override
  String get onevpnRetry => 'Gaýtadan synanyş';

  @override
  String get onevpnApplyChange => 'Bu üýtgetme ulanylsynmy?';

  @override
  String get onevpnReconnectNotice =>
      'VPN birikmesi gysga wagtlyk kesilip, täzeden birikdiriler. Bu adatça diňe birnäçe sekunt alýar.';

  @override
  String onevpnWillUseName(String name) {
    return 'Ulanylar: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Ulan we täzeden birik';

  @override
  String get onevpnCancel => 'Ýatyr';

  @override
  String get onevpnContinue => 'Dowam et';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'Esasy domen petiklendi. Ätiýaçlyk ulanylýar: $domain';
  }

  @override
  String get onevpnResultFailed => 'şowsuz';

  @override
  String get onevpnDownload => 'Ýükle';

  @override
  String get onevpnPermissionNotGranted => 'Rugsat berilmedi';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action: $result';
  }

  @override
  String get onevpnDisconnect => 'Birikmäni kes';

  @override
  String get onevpnTimeout => 'Wagt gutardy';

  @override
  String get onevpnNoAvailableEntries => 'Elýeterli giriş serweri ýok';

  @override
  String get onevpnAddServers => 'Serwer goşuň';

  @override
  String get onevpnNotEnoughServers => 'Elýeterli serwer sany ýeterlik däl';

  @override
  String get onevpnVpnFinalExit => 'VPN soňky çykyş serweri';

  @override
  String get onevpnFinalExitEntryConflict =>
      'Soňky çykyş serweri şol bir wagtda giriş serweri bolup bilmez';

  @override
  String get onevpnChooseNamedRoute => 'Atlandyrylan bir marşruty saýlaň';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Ýerli tordaky enjamlara we hyzmatlara girmäge rugsat beriň.';

  @override
  String get onevpnSystemApprovalRequired => 'Ulgamyň tassyklamasy gerek';

  @override
  String get onevpnVpnPermissionRequired =>
      'VPN rugsady gerek. Dowam etmek üçin gaýtadan synanyşyň.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Tora girmek üçin ulanylýan interfeýsi saýlaň. Diňe Windows / Linux ulgamlarynda gerek.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Andorra',
      'AE': 'Birleşen Arap Emirlikleri',
      'AF': 'Owganystan',
      'AG': 'Antigua we Barbuda',
      'AI': 'Angilýa',
      'AL': 'Albaniýa',
      'AM': 'Ermenistan',
      'AO': 'Angola',
      'AQ': 'Antarktika',
      'AR': 'Argentina',
      'AS': 'Amerikan Samoasy',
      'AT': 'Awstriýa',
      'AU': 'Awstraliýa',
      'AW': 'Aruba',
      'AX': 'Aland adalary',
      'AZ': 'Azerbaýjan',
      'BA': 'Bosniýa we Gersegowina',
      'BB': 'Barbados',
      'BD': 'Bangladeş',
      'BE': 'Belgiýa',
      'BF': 'Burkina-Faso',
      'BG': 'Bolgariýa',
      'BH': 'Bahreýn',
      'BI': 'Burundi',
      'BJ': 'Benin',
      'BL': 'Sen-Bartelemi',
      'BM': 'Bermuda',
      'BN': 'Bruneý',
      'BO': 'Boliwiýa',
      'BQ': 'Karib Niderlandlary',
      'BR': 'Braziliýa',
      'BS': 'Bagama adalary',
      'BT': 'Butan',
      'BV': 'Buwe adasy',
      'BW': 'Botswana',
      'BY': 'Belarus',
      'BZ': 'Beliz',
      'CA': 'Kanada',
      'CC': 'Kokos (Kiling) adalary',
      'CD': 'Kongo - Kinşasa',
      'CF': 'Merkezi Afrika Respublikasy',
      'CG': 'Kongo - Brazzawil',
      'CH': 'Şweýsariýa',
      'CI': 'Kot-d’Iwuar',
      'CK': 'Kuk adalary',
      'CL': 'Çili',
      'CM': 'Kamerun',
      'CN': 'Hytaý',
      'CO': 'Kolumbiýa',
      'CR': 'Kosta-Rika',
      'CU': 'Kuba',
      'CV': 'Kabo-Werde',
      'CW': 'Kýurasao',
      'CX': 'Roždestwo adasy',
      'CY': 'Kipr',
      'CZ': 'Çehiýa',
      'DE': 'Germaniýa',
      'DJ': 'Jibuti',
      'DK': 'Daniýa',
      'DM': 'Dominika',
      'DO': 'Dominikan Respublikasy',
      'DZ': 'Alžir',
      'EC': 'Ekwador',
      'EE': 'Estoniýa',
      'EG': 'Müsür',
      'EH': 'Günbatar Sahara',
      'ER': 'Eritreýa',
      'ES': 'Ispaniýa',
      'ET': 'Efiopiýa',
      'FI': 'Finlýandiýa',
      'FJ': 'Fiji',
      'FK': 'Folklend adalary',
      'FM': 'Mikroneziýa',
      'FO': 'Farer adalary',
      'FR': 'Fransiýa',
      'GA': 'Gabon',
      'GB': 'Birleşen Patyşalyk',
      'GD': 'Grenada',
      'GE': 'Gruziýa',
      'GF': 'Fransuz Gwianasy',
      'GG': 'Gernsi',
      'GH': 'Gana',
      'GI': 'Gibraltar',
      'GL': 'Grenlandiýa',
      'GM': 'Gambiýa',
      'GN': 'Gwineýa',
      'GP': 'Gwadelupa',
      'GQ': 'Ekwatorial Gwineýa',
      'GR': 'Gresiýa',
      'GS': 'Günorta Georgiýa we Günorta Sendwiç adasy',
      'GT': 'Gwatemala',
      'GU': 'Guam',
      'GW': 'Gwineýa-Bisau',
      'GY': 'Gaýana',
      'HK': 'Gonkong',
      'HM': 'Herd we Makdonald adalary',
      'HN': 'Gonduras',
      'HR': 'Horwatiýa',
      'HT': 'Gaiti',
      'HU': 'Wengriýa',
      'ID': 'Indoneziýa',
      'IE': 'Irlandiýa',
      'IL': 'Ysraýyl',
      'IM': 'Men adasy',
      'IN': 'Hindistan',
      'IO': 'Britaniýanyň Hindi okeanyndaky territoriýalary',
      'IQ': 'Yrak',
      'IR': 'Eýran',
      'IS': 'Islandiýa',
      'IT': 'Italiýa',
      'JE': 'Jersi',
      'JM': 'Ýamaýka',
      'JO': 'Iordaniýa',
      'JP': 'Ýaponiýa',
      'KE': 'Keniýa',
      'KG': 'Gyrgyzystan',
      'KH': 'Kamboja',
      'KI': 'Kiribati',
      'KM': 'Komor adalary',
      'KN': 'Sent-Kits we Newis',
      'KP': 'Demirgazyk Koreýa',
      'KR': 'Günorta Koreýa',
      'KW': 'Kuweýt',
      'KY': 'Kaýman adalary',
      'KZ': 'Gazagystan',
      'LA': 'Laos',
      'LB': 'Liwan',
      'LC': 'Sent-Lýusiýa',
      'LI': 'Lihtenşteýn',
      'LK': 'Şri-Lanka',
      'LR': 'Liberiýa',
      'LS': 'Lesoto',
      'LT': 'Litwa',
      'LU': 'Lýuksemburg',
      'LV': 'Latwiýa',
      'LY': 'Liwiýa',
      'MA': 'Marokko',
      'MC': 'Monako',
      'MD': 'Moldowa',
      'ME': 'Çernogoriýa',
      'MF': 'Sen-Marten',
      'MG': 'Madagaskar',
      'MH': 'Marşall adalary',
      'MK': 'Demirgazyk Makedoniýa',
      'ML': 'Mali',
      'MM': 'Mýanma (Birma)',
      'MN': 'Mongoliýa',
      'MO': 'Makao',
      'MP': 'Demirgazyk Mariana adalary',
      'MQ': 'Martinika',
      'MR': 'Mawritaniýa',
      'MS': 'Monserrat',
      'MT': 'Malta',
      'MU': 'Mawrikiý',
      'MV': 'Maldiwler',
      'MW': 'Malawi',
      'MX': 'Meksika',
      'MY': 'Malaýziýa',
      'MZ': 'Mozambik',
      'NA': 'Namibiýa',
      'NC': 'Täze Kaledoniýa',
      'NE': 'Niger',
      'NF': 'Norfolk adasy',
      'NG': 'Nigeriýa',
      'NI': 'Nikaragua',
      'NL': 'Niderlandlar',
      'NO': 'Norwegiýa',
      'NP': 'Nepal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'Täze Zelandiýa',
      'OM': 'Oman',
      'PA': 'Panama',
      'PE': 'Peru',
      'PF': 'Fransuz Polineziýasy',
      'PG': 'Papua - Täze Gwineýa',
      'PH': 'Filippinler',
      'PK': 'Pakistan',
      'PL': 'Polşa',
      'PM': 'Sen-Pýer we Mikelon',
      'PN': 'Pitkern adalary',
      'PR': 'Puerto-Riko',
      'PS': 'Palestina territoriýasy',
      'PT': 'Portugaliýa',
      'PW': 'Palau',
      'PY': 'Paragwaý',
      'QA': 'Katar',
      'RE': 'Reýunýon',
      'RO': 'Rumyniýa',
      'RS': 'Serbiýa',
      'RU': 'Russiýa',
      'RW': 'Ruanda',
      'SA': 'Saud Arabystany',
      'SB': 'Solomon adalary',
      'SC': 'Seýşel adalary',
      'SD': 'Sudan',
      'SE': 'Şwesiýa',
      'SG': 'Singapur',
      'SH': 'Keramatly Ýelena adasy',
      'SI': 'Sloweniýa',
      'SJ': 'Şpisbergen we Ýan-Maýen',
      'SK': 'Slowakiýa',
      'SL': 'Sýerra-Leone',
      'SM': 'San-Marino',
      'SN': 'Senegal',
      'SO': 'Somali',
      'SR': 'Surinam',
      'SS': 'Günorta Sudan',
      'ST': 'San-Tome we Prinsipi',
      'SV': 'Salwador',
      'SX': 'Sint-Marten',
      'SY': 'Siriýa',
      'SZ': 'Eswatini',
      'TC': 'Terks we Kaýkos adalary',
      'TD': 'Çad',
      'TF': 'Fransuz günorta territoriýalary',
      'TG': 'Togo',
      'TH': 'Taýland',
      'TJ': 'Täjigistan',
      'TK': 'Tokelau',
      'TL': 'Timor-Leste',
      'TM': 'Türkmenistan',
      'TN': 'Tunis',
      'TO': 'Tonga',
      'TR': 'Türkiýe',
      'TT': 'Trinidad we Tobago',
      'TV': 'Tuwalu',
      'TW': 'Taýwan',
      'TZ': 'Tanzaniýa',
      'UA': 'Ukraina',
      'UG': 'Uganda',
      'UM': 'ABŞ-nyň daşarky adalary',
      'US': 'Amerikanyň Birleşen Ştatlary',
      'UY': 'Urugwaý',
      'UZ': 'Özbegistan',
      'VA': 'Watikan',
      'VC': 'Sent-Winsent we Grenadinler',
      'VE': 'Wenesuela',
      'VG': 'Britan Wirgin adalary',
      'VI': 'ABŞ-nyň Wirgin adalary',
      'VN': 'Wýetnam',
      'VU': 'Wanuatu',
      'WF': 'Uollis we Futuna',
      'WS': 'Samoa',
      'XK': 'Kosowo',
      'YE': 'Ýemen',
      'YT': 'Maýotta',
      'ZA': 'Günorta Afrika',
      'ZM': 'Zambiýa',
      'ZW': 'Zimbabwe',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Gizlinlik saýlawlary';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Amsterdam',
      'sgp': 'Singapur',
      'lax': 'Los-Anjeles',
      'mel': 'Melburn',
      'syd': 'Sidneý',
      'sao': 'San-Paulu',
      'yto': 'Toronto',
      'scl': 'Santýago',
      'cdg': 'Pariž',
      'fra': 'Frankfurt',
      'del': 'Deli',
      'bom': 'Mumbaý',
      'blr': 'Bangalor',
      'tlv': 'Tel-Awiw',
      'itm': 'Osaka',
      'nrt': 'Tokio',
      'mex': 'Mehiko',
      'waw': 'Warşawa',
      'jnb': 'Ýohannesburg',
      'icn': 'Seul',
      'mad': 'Madrid',
      'sto': 'Stokgolm',
      'lhr': 'London',
      'man': 'Mançester',
      'ord': 'Çikago',
      'dfw': 'Dallas',
      'sea': 'Sietl',
      'sjc': 'San-Fransisko',
      'mia': 'Maýami',
      'hnl': 'Gonolulu',
      'ewr': 'Nýu-Ýork',
      'atl': 'Atlanta',
      'hkg': 'Gonkong',
      'zrh': 'Sýurih',
      'gva': 'Ženewa',
      'svo': 'Moskwa',
      'led': 'Sankt-Peterburg',
      'hel': 'Helsinki',
      'tpe': 'Taýbeý',
      'dxb': 'Dubaý',
      'kbp': 'Kiýew',
      'ist': 'Stambul',
      'otp': 'Buharest',
      'los': 'Lagos',
      'pty': 'Panama',
      'kef': 'Reýkýawik',
      'ber': 'Berlin',
      'ala': 'Almaty',
      'tbs': 'Tbilisi',
      'kul': 'Kuala-Lumpur',
      'bkk': 'Bangkok',
      'cgk': 'Jakarta',
      'mnl': 'Manila',
      'nbo': 'Naýrobi',
      'mxp': 'Milan',
      'dub': 'Dublin',
      'lis': 'Lissabon',
      'lux': 'Lýuksemburg',
      'eze': 'Buenos-Aýres',
      'akl': 'Oklend',
      'yul': 'Monreal',
      'yvr': 'Wankuwer',
      'den': 'Denwer',
      'phx': 'Finiks',
      'iad': 'Waşington',
      'bos': 'Boston',
      'edi': 'Edinburg',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => '1VPN size halanýarmy?';

  @override
  String get onevpnYes => 'Hawa';

  @override
  String get onevpnNo => 'Ýok';

  @override
  String get onevpnLocationLocked => 'Gulply, diňe Premium';

  @override
  String get onevpnManageSubscription => 'Abunalygy dolandyr';
}
