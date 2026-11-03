// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class OneVpnLocalizationsAz extends OneVpnLocalizations {
  OneVpnLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get onevpnFaq => 'Tez-tez verilən suallar';

  @override
  String get onevpnTermsOfService => 'Xidmət şərtləri';

  @override
  String get onevpnMenu => 'Menyu';

  @override
  String get onevpnUpgrade => 'Təkmilləşdirin';

  @override
  String get onevpnUpgradeBannerTitle => 'Premium\'a keçin';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Reklamsız, bütün məkanlar və daha yüksək sürət';

  @override
  String get onevpnLogIn => 'Daxil olun';

  @override
  String get onevpnLogOut => 'Hesabdan çıxın';

  @override
  String get onevpnAccount => 'Hesab';

  @override
  String get onevpnContactUs => 'Bizimlə əlaqə';

  @override
  String get onevpnRefundPolicy => 'Geri ödəniş siyasəti';

  @override
  String get onevpnSupport => 'Dəstək';

  @override
  String get onevpnLanguage => 'Dil';

  @override
  String get onevpnLanguageSystem => 'Sistem defoltu';

  @override
  String get onevpnPlanFree => 'Pulsuz plan';

  @override
  String get onevpnPlanPremium => 'Premium plan';

  @override
  String get onevpnSelectLocation => 'Məkan seçin';

  @override
  String get onevpnDirectRegions => 'Birbaşa regionlar';

  @override
  String get onevpnFree => 'Pulsuz';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Pulsuz';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Avtomatik · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Avtomatik';

  @override
  String get onevpnStatusNoConnection => 'Bağlantı yoxdur';

  @override
  String get onevpnStatusConnectionFailed => 'Qoşulmaq alınmadı';

  @override
  String get onevpnStatusUpdating => 'Yenilənir…';

  @override
  String get onevpnStatusMeasuring => 'Serverlər yoxlanılır…';

  @override
  String get onevpnAutomaticSubtitle => 'Ən sürətli əlçatan server';

  @override
  String get onevpnLocationsLoadFailed => 'Məkanlarınızı yükləmək alınmadı.';

  @override
  String get onevpnLocationsUnavailable => 'Məkanlar hazırda əlçatan deyil.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Bəzi saytlar yalnız saytın yerləşdiyi ölkədən qoşulduqda işləyir. Region seçdikdə həmin regionun saytları VPN\'i yan keçir.';

  @override
  String onevpnSelectionReset(String location) {
    return '$location məkanı əlçatan deyil, 1VPN “Avtomatik” seçiminə keçdi.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'Seçilmiş məkan əlçatan deyil, 1VPN “Avtomatik” seçiminə keçdi.';

  @override
  String onevpnReloadRolledBack(String location) {
    return '$location məkanına keçmək alınmadı. Hələ də əvvəlki məkanınıza qoşulusunuz.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Dəyişikliyi tətbiq etmək alınmadı. Hələ də əvvəlki ayarlarınızla qoşulusunuz.';

  @override
  String get onevpnDirectRegionsOff => 'Deaktiv (Defolt)';

  @override
  String get onevpnAllViaVpnSubtitle => 'Bütün trafik tuneldən keçir';

  @override
  String get onevpnRegionChina => 'Çin';

  @override
  String get onevpnFirstConnectTitle =>
      'Bəzi regionlar birbaşa daha yaxşı işləyir';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'Çin, Rusiya və İran kimi yerlərdə bütün trafiki VPN üzərindən göndərmək yerli bank və ödəniş tətbiqlərinin işini poza bilər.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN seçdiyiniz regionun trafikini tuneldən kənarda, real IP ünvanınızdan birbaşa yönləndirə bilər.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Qalan hər şey qorunmaqda davam edir. Bunu istənilən vaxt dəyişə bilərsiniz.';

  @override
  String get onevpnFirstConnectChooseRegion => 'Birbaşa region seçin';

  @override
  String get onevpnFirstConnectDismiss => 'İndi yox';

  @override
  String get onevpnCensorshipWarning =>
      'Hökumət məhdudiyyətləri səbəbindən bəzi serverlər regionunuzda bloklanmış ola bilər. Bu problemin həlli üzərində işləyirik. Anlayışınız üçün təşəkkür edirik.';

  @override
  String get onevpnAlwaysOnTitle => 'VPN həmişə aktiv';

  @override
  String get onevpnAlwaysOnIntro =>
      'Tətbiqi bağladıqda tunel qoşulu qalır. Cihaz yenidən başladıqdan və ya tətbiq güncəlləndikdən sonra “VPN həmişə aktiv” onu avtomatik olaraq yenidən qoşur.';

  @override
  String get onevpnAlwaysOnStep1 =>
      'Aşağıdakı “VPN ayarlarını açın” düyməsinə toxunun.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Siyahıda 1VPN tətbiqini tapın. O, ilk qoşulmanızdan sonra görünür.';

  @override
  String get onevpnAlwaysOnStep3 =>
      '1VPN tətbiqinin yanındakı dişli ikonasına toxunun.';

  @override
  String get onevpnAlwaysOnStep4 => '“VPN həmişə aktiv” seçimini aktiv edin.';

  @override
  String get onevpnAlwaysOnOpenSettings => 'VPN ayarlarını açın';

  @override
  String get onevpnPaywallTitle => 'Planınızı seçin';

  @override
  String get onevpnPaywallBenefitLocations => 'Bütün server məkanlarına giriş';

  @override
  String get onevpnPaywallBenefitNoAds => 'Reklamsız';

  @override
  String get onevpnPaywallBenefitSpeed => 'Daha yüksək server sürəti';

  @override
  String get onevpnPaywallBenefitP2p => 'BitTorrent (P2P) dəstəyi';

  @override
  String get onevpnPaywallBenefitMoneyBack => '10 günlük pul qaytarma zəmanəti';

  @override
  String get onevpnPaywallPlanYearly => 'İllik';

  @override
  String get onevpnPaywallPlanMonthly => 'Aylıq';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '$percent% qənaət';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / ay';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Qiymət əlçatan deyil';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Planları yükləmək alınmadı. Bağlantınızı yoxlayın.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Planlar hazırda əlçatan deyil. Bir az sonra yenidən cəhd edin.';

  @override
  String get onevpnGetPremium => 'Premium əldə edin';

  @override
  String get onevpnContinueFree => 'Pulsuz davam edin';

  @override
  String get onevpnPaywallRetry => 'Yenidən cəhd edin';

  @override
  String get onevpnPaywallPurchaseError => 'Xəta baş verdi. Yenidən cəhd edin.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'Bu Google hesabında başqa 1VPN hesabı ilə əlaqələndirilmiş aktiv və ya bu yaxınlarda bitmiş 1VPN abunəliyi var. Həmin hesaba daxil olun və ya $support ilə əlaqə saxlayın.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'Bu Google hesabında artıq 1VPN abunəliyi var. Premium görünməsə, $support ilə əlaqə saxlayın.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play son alışınızı tamamlamadı. Açıq olan Google Play ekranlarını bağlayıb yenidən cəhd edin və ya tətbiqi yenidən başladın.';

  @override
  String get onevpnPaywallSupportLink => '1VPN dəstək xidməti';

  @override
  String get onevpnSignUp => 'Qeydiyyatdan keçin';

  @override
  String get onevpnAuthEmailLabel => 'E-poçt';

  @override
  String get onevpnAuthPasswordLabel => 'Parol';

  @override
  String get onevpnAuthTwoFactorLabel => '2FA kodu';

  @override
  String get onevpnAuthForgotPassword => 'Parolu unutmusunuz?';

  @override
  String get onevpnAuthSubmitting => 'Yüklənir…';

  @override
  String get onevpnAuthCreateAccount => 'Hesab yaradın';

  @override
  String get onevpnAuthHaveAccount => 'Artıq hesabınız var?';

  @override
  String get onevpnAuthLogInInstead => 'Bunun əvəzinə daxil olun';

  @override
  String get onevpnAuthFieldsRequired => 'E-poçt və parolu daxil edin';

  @override
  String get onevpnAuthInvalidEmail => 'Düzgün e-poçt ünvanı daxil edin';

  @override
  String get onevpnAuthInvalidCredentials => 'E-poçt və ya parol yanlışdır';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Yanlış 2FA kodu';

  @override
  String get onevpnAuthEmailInUse => 'Bu e-poçt ünvanı ilə artıq hesab var';

  @override
  String get onevpnAuthRateLimited =>
      'Həddən çox cəhd edildi. Bir az sonra yenidən cəhd edin';

  @override
  String get onevpnAuthUnreachable =>
      'Serverə qoşulmaq alınmadı. Bağlantınızı yoxlayıb yenidən cəhd edin';

  @override
  String get onevpnAuthGenericError => 'Xəta baş verdi. Yenidən cəhd edin';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Alışınız bu e-poçt ünvanı ilə əlaqələndirilib.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Alış tamamlandı';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Alışınız $email ünvanı ilə əlaqələndirilib. Ondan istifadə etmək üçün həmin ünvanla hesab yaradın.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Premium · alış təsdiqlənir';

  @override
  String get onevpnPremiumRecheck => 'Alış statusunuz yoxlanılır…';

  @override
  String get onevpnButtonRetry => 'Yenidən cəhd edin';

  @override
  String get onevpnAppVersion => 'Tətbiq versiyası';

  @override
  String get onevpnPrivacyPolicy => 'Məxfilik siyasəti';

  @override
  String get onevpnConnect => 'Qoşulun';

  @override
  String get onevpnDisconnected => 'Bağlantı kəsildi';

  @override
  String get onevpnConnecting => 'Qoşulur…';

  @override
  String get onevpnConnected => 'Qoşuldu';

  @override
  String get onevpnDisconnecting => 'Bağlantı kəsilir…';

  @override
  String get onevpnConnectionFailed => 'Qoşulmaq alınmadı';

  @override
  String get onevpnTemporarilyUnavailable => 'Müvəqqəti əlçatan deyil';

  @override
  String get onevpnRetry => 'Yenidən cəhd edin';

  @override
  String get onevpnApplyChange => 'Bu dəyişiklik tətbiq edilsin?';

  @override
  String get onevpnReconnectNotice =>
      'VPN bağlantısı qısa müddətə kəsilib yenidən qurulacaq. Bu, adətən cəmi bir neçə saniyə çəkir.';

  @override
  String onevpnWillUseName(String name) {
    return 'İstifadə ediləcək: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Tətbiq edin və yenidən qoşulun';

  @override
  String get onevpnCancel => 'Ləğv edin';

  @override
  String get onevpnContinue => 'Davam edin';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'Əsas domen bloklanıb. Ehtiyat domen istifadə olunur: $domain';
  }

  @override
  String get onevpnResultFailed => 'alınmadı';

  @override
  String get onevpnDownload => 'Endirin';

  @override
  String get onevpnPermissionNotGranted => 'İcazə verilməyib';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action: $result';
  }

  @override
  String get onevpnDisconnect => 'Bağlantını kəsin';

  @override
  String get onevpnTimeout => 'Vaxt bitdi';

  @override
  String get onevpnNoAvailableEntries => 'Əlçatan giriş serveri yoxdur';

  @override
  String get onevpnAddServers => 'Server əlavə edin';

  @override
  String get onevpnNotEnoughServers => 'Kifayət qədər əlçatan server yoxdur';

  @override
  String get onevpnVpnFinalExit => 'VPN son çıxış serveri';

  @override
  String get onevpnFinalExitEntryConflict =>
      'Son çıxış serveri eyni zamanda giriş serveri ola bilməz';

  @override
  String get onevpnChooseNamedRoute => 'Adlandırılmış bir marşrut seçin';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Lokal şəbəkədəki cihaz və xidmətlərə girişə icazə verin.';

  @override
  String get onevpnSystemApprovalRequired => 'Sistem təsdiqi tələb olunur';

  @override
  String get onevpnVpnPermissionRequired =>
      'VPN icazəsi tələb olunur. Davam etmək üçün yenidən cəhd edin.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Şəbəkəyə giriş üçün istifadə olunan interfeysi seçin. Yalnız Windows / Linux\'da tələb olunur.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Andorra',
      'AE': 'Birləşmiş Ərəb Əmirlikləri',
      'AF': 'Əfqanıstan',
      'AG': 'Antiqua və Barbuda',
      'AI': 'Angilya',
      'AL': 'Albaniya',
      'AM': 'Ermənistan',
      'AO': 'Anqola',
      'AQ': 'Antarktika',
      'AR': 'Argentina',
      'AS': 'Amerika Samoası',
      'AT': 'Avstriya',
      'AU': 'Avstraliya',
      'AW': 'Aruba',
      'AX': 'Aland adaları',
      'AZ': 'Azərbaycan',
      'BA': 'Bosniya və Herseqovina',
      'BB': 'Barbados',
      'BD': 'Banqladeş',
      'BE': 'Belçika',
      'BF': 'Burkina Faso',
      'BG': 'Bolqarıstan',
      'BH': 'Bəhreyn',
      'BI': 'Burundi',
      'BJ': 'Benin',
      'BL': 'Sent-Bartelemi',
      'BM': 'Bermud adaları',
      'BN': 'Bruney',
      'BO': 'Boliviya',
      'BQ': 'Karib Niderlandı',
      'BR': 'Braziliya',
      'BS': 'Baham adaları',
      'BT': 'Butan',
      'BV': 'Buve adası',
      'BW': 'Botsvana',
      'BY': 'Belarus',
      'BZ': 'Beliz',
      'CA': 'Kanada',
      'CC': 'Kokos (Kilinq) adaları',
      'CD': 'Konqo - Kinşasa',
      'CF': 'Mərkəzi Afrika Respublikası',
      'CG': 'Konqo - Brazzavil',
      'CH': 'İsveçrə',
      'CI': 'Kotd’ivuar',
      'CK': 'Kuk adaları',
      'CL': 'Çili',
      'CM': 'Kamerun',
      'CN': 'Çin',
      'CO': 'Kolumbiya',
      'CR': 'Kosta Rika',
      'CU': 'Kuba',
      'CV': 'Kabo-Verde',
      'CW': 'Kurasao',
      'CX': 'Milad adası',
      'CY': 'Kipr',
      'CZ': 'Çexiya',
      'DE': 'Almaniya',
      'DJ': 'Cibuti',
      'DK': 'Danimarka',
      'DM': 'Dominika',
      'DO': 'Dominikan Respublikası',
      'DZ': 'Əlcəzair',
      'EC': 'Ekvador',
      'EE': 'Estoniya',
      'EG': 'Misir',
      'EH': 'Qərbi Saxara',
      'ER': 'Eritreya',
      'ES': 'İspaniya',
      'ET': 'Efiopiya',
      'FI': 'Finlandiya',
      'FJ': 'Fici',
      'FK': 'Folklend adaları',
      'FM': 'Mikroneziya',
      'FO': 'Farer adaları',
      'FR': 'Fransa',
      'GA': 'Qabon',
      'GB': 'Birləşmiş Krallıq',
      'GD': 'Qrenada',
      'GE': 'Gürcüstan',
      'GF': 'Fransa Qvianası',
      'GG': 'Gernsi',
      'GH': 'Qana',
      'GI': 'Cəbəllütariq',
      'GL': 'Qrenlandiya',
      'GM': 'Qambiya',
      'GN': 'Qvineya',
      'GP': 'Qvadelupa',
      'GQ': 'Ekvatorial Qvineya',
      'GR': 'Yunanıstan',
      'GS': 'Cənubi Corciya və Cənubi Sendviç adaları',
      'GT': 'Qvatemala',
      'GU': 'Quam',
      'GW': 'Qvineya-Bisau',
      'GY': 'Qayana',
      'HK': 'Honq Konq',
      'HM': 'Herd və Makdonald adaları',
      'HN': 'Honduras',
      'HR': 'Xorvatiya',
      'HT': 'Haiti',
      'HU': 'Macarıstan',
      'ID': 'İndoneziya',
      'IE': 'İrlandiya',
      'IL': 'İsrail',
      'IM': 'Men adası',
      'IN': 'Hindistan',
      'IO': 'Britaniyanın Hind Okeanı Ərazisi',
      'IQ': 'İraq',
      'IR': 'İran',
      'IS': 'İslandiya',
      'IT': 'İtaliya',
      'JE': 'Cersi',
      'JM': 'Yamayka',
      'JO': 'İordaniya',
      'JP': 'Yaponiya',
      'KE': 'Keniya',
      'KG': 'Qırğızıstan',
      'KH': 'Kamboca',
      'KI': 'Kiribati',
      'KM': 'Komor adaları',
      'KN': 'Sent-Kits və Nevis',
      'KP': 'Şimali Koreya',
      'KR': 'Cənubi Koreya',
      'KW': 'Küveyt',
      'KY': 'Kayman adaları',
      'KZ': 'Qazaxıstan',
      'LA': 'Laos',
      'LB': 'Livan',
      'LC': 'Sent-Lusiya',
      'LI': 'Lixtenşteyn',
      'LK': 'Şri-Lanka',
      'LR': 'Liberiya',
      'LS': 'Lesoto',
      'LT': 'Litva',
      'LU': 'Lüksemburq',
      'LV': 'Latviya',
      'LY': 'Liviya',
      'MA': 'Mərakeş',
      'MC': 'Monako',
      'MD': 'Moldova',
      'ME': 'Monteneqro',
      'MF': 'Sent Martin',
      'MG': 'Madaqaskar',
      'MH': 'Marşal adaları',
      'MK': 'Şimali Makedoniya',
      'ML': 'Mali',
      'MM': 'Myanma',
      'MN': 'Monqolustan',
      'MO': 'Makao',
      'MP': 'Şimali Marian adaları',
      'MQ': 'Martinik',
      'MR': 'Mavritaniya',
      'MS': 'Monserat',
      'MT': 'Malta',
      'MU': 'Mavriki',
      'MV': 'Maldiv adaları',
      'MW': 'Malavi',
      'MX': 'Meksika',
      'MY': 'Malayziya',
      'MZ': 'Mozambik',
      'NA': 'Namibiya',
      'NC': 'Yeni Kaledoniya',
      'NE': 'Niger',
      'NF': 'Norfolk adası',
      'NG': 'Nigeriya',
      'NI': 'Nikaraqua',
      'NL': 'Niderland',
      'NO': 'Norveç',
      'NP': 'Nepal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'Yeni Zelandiya',
      'OM': 'Oman',
      'PA': 'Panama',
      'PE': 'Peru',
      'PF': 'Fransa Polineziyası',
      'PG': 'Papua-Yeni Qvineya',
      'PH': 'Filippin',
      'PK': 'Pakistan',
      'PL': 'Polşa',
      'PM': 'Müqəddəs Pyer və Mikelon',
      'PN': 'Pitkern adaları',
      'PR': 'Puerto Riko',
      'PS': 'Fələstin Əraziləri',
      'PT': 'Portuqaliya',
      'PW': 'Palau',
      'PY': 'Paraqvay',
      'QA': 'Qətər',
      'RE': 'Reyunyon',
      'RO': 'Rumıniya',
      'RS': 'Serbiya',
      'RU': 'Rusiya',
      'RW': 'Ruanda',
      'SA': 'Səudiyyə Ərəbistanı',
      'SB': 'Solomon adaları',
      'SC': 'Seyşel adaları',
      'SD': 'Sudan',
      'SE': 'İsveç',
      'SG': 'Sinqapur',
      'SH': 'Müqəddəs Yelena',
      'SI': 'Sloveniya',
      'SJ': 'Svalbard və Yan-Mayen',
      'SK': 'Slovakiya',
      'SL': 'Syerra-Leone',
      'SM': 'San-Marino',
      'SN': 'Seneqal',
      'SO': 'Somali',
      'SR': 'Surinam',
      'SS': 'Cənubi Sudan',
      'ST': 'San-Tome və Prinsipi',
      'SV': 'Salvador',
      'SX': 'Sint-Marten',
      'SY': 'Suriya',
      'SZ': 'Esvatini',
      'TC': 'Törks və Kaykos adaları',
      'TD': 'Çad',
      'TF': 'Fransanın Cənub Əraziləri',
      'TG': 'Toqo',
      'TH': 'Tailand',
      'TJ': 'Tacikistan',
      'TK': 'Tokelau',
      'TL': 'Şərqi Timor',
      'TM': 'Türkmənistan',
      'TN': 'Tunis',
      'TO': 'Tonqa',
      'TR': 'Türkiyə',
      'TT': 'Trinidad və Tobaqo',
      'TV': 'Tuvalu',
      'TW': 'Tayvan',
      'TZ': 'Tanzaniya',
      'UA': 'Ukrayna',
      'UG': 'Uqanda',
      'UM': 'ABŞ-a bağlı kiçik adacıqlar',
      'US': 'Amerika Birləşmiş Ştatları',
      'UY': 'Uruqvay',
      'UZ': 'Özbəkistan',
      'VA': 'Vatikan',
      'VC': 'Sent-Vinsent və Qrenadinlər',
      'VE': 'Venesuela',
      'VG': 'Britaniyanın Virgin adaları',
      'VI': 'ABŞ Virgin adaları',
      'VN': 'Vyetnam',
      'VU': 'Vanuatu',
      'WF': 'Uollis və Futuna',
      'WS': 'Samoa',
      'XK': 'Kosovo',
      'YE': 'Yəmən',
      'YT': 'Mayot',
      'ZA': 'Cənub Afrika',
      'ZM': 'Zambiya',
      'ZW': 'Zimbabve',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Məxfilik seçimləri';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Amsterdam',
      'sgp': 'Sinqapur',
      'lax': 'Los-Anceles',
      'mel': 'Melburn',
      'syd': 'Sidney',
      'sao': 'San-Paulu',
      'yto': 'Toronto',
      'scl': 'Santyaqo',
      'cdg': 'Paris',
      'fra': 'Frankfurt',
      'del': 'Dehli',
      'bom': 'Mumbay',
      'blr': 'Banqalor',
      'tlv': 'Təl-Əviv',
      'itm': 'Osaka',
      'nrt': 'Tokio',
      'mex': 'Mexiko',
      'waw': 'Varşava',
      'jnb': 'Yohannesburq',
      'icn': 'Seul',
      'mad': 'Madrid',
      'sto': 'Stokholm',
      'lhr': 'London',
      'man': 'Mançester',
      'ord': 'Çikaqo',
      'dfw': 'Dallas',
      'sea': 'Sietl',
      'sjc': 'San-Fransisko',
      'mia': 'Mayami',
      'hnl': 'Honolulu',
      'ewr': 'Nyu-York',
      'atl': 'Atlanta',
      'hkg': 'Honq Konq',
      'zrh': 'Sürix',
      'gva': 'Cenevrə',
      'svo': 'Moskva',
      'led': 'Sankt-Peterburq',
      'hel': 'Helsinki',
      'tpe': 'Taybey',
      'dxb': 'Dubay',
      'kbp': 'Kiyev',
      'ist': 'İstanbul',
      'otp': 'Buxarest',
      'los': 'Laqos',
      'pty': 'Panama şəhəri',
      'kef': 'Reykyavik',
      'ber': 'Berlin',
      'ala': 'Almatı',
      'tbs': 'Tbilisi',
      'kul': 'Kuala-Lumpur',
      'bkk': 'Banqkok',
      'cgk': 'Cakarta',
      'mnl': 'Manila',
      'nbo': 'Nayrobi',
      'mxp': 'Milan',
      'dub': 'Dublin',
      'lis': 'Lissabon',
      'lux': 'Lüksemburq',
      'eze': 'Buenos-Ayres',
      'akl': 'Oklend',
      'yul': 'Monreal',
      'yvr': 'Vankuver',
      'den': 'Denver',
      'phx': 'Feniks',
      'iad': 'Vaşinqton',
      'bos': 'Boston',
      'edi': 'Edinburq',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => '1VPN xoşunuza gəlir?';

  @override
  String get onevpnYes => 'Bəli';

  @override
  String get onevpnNo => 'Xeyr';

  @override
  String get onevpnLocationLocked => 'Kilidli, yalnız Premium';

  @override
  String get onevpnManageSubscription => 'Abunəliyi idarə et';
}
