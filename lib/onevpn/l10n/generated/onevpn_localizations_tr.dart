// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class OneVpnLocalizationsTr extends OneVpnLocalizations {
  OneVpnLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get onevpnFaq => 'SSS';

  @override
  String get onevpnTermsOfService => 'Hizmet şartları';

  @override
  String get onevpnMenu => 'Menü';

  @override
  String get onevpnUpgrade => 'Yükselt';

  @override
  String get onevpnUpgradeBannerTitle => 'Premium\'a Yükselt';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Reklamsız, tüm konumlar ve daha yüksek hız';

  @override
  String get onevpnLogIn => 'Giriş Yap';

  @override
  String get onevpnLogOut => 'Çıkış Yap';

  @override
  String get onevpnAccount => 'Hesap';

  @override
  String get onevpnContactUs => 'Bize Ulaşın';

  @override
  String get onevpnRefundPolicy => 'İade politikası';

  @override
  String get onevpnSupport => 'Destek';

  @override
  String get onevpnLanguage => 'Dil';

  @override
  String get onevpnLanguageSystem => 'Sistem varsayılanı';

  @override
  String get onevpnPlanFree => 'Ücretsiz plan';

  @override
  String get onevpnPlanPremium => 'Premium plan';

  @override
  String get onevpnSelectLocation => 'Konum Seçin';

  @override
  String get onevpnDirectRegions => 'Doğrudan Erişim Bölgeleri';

  @override
  String get onevpnFree => 'Ücretsiz';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Ücretsiz';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Otomatik · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Otomatik';

  @override
  String get onevpnStatusNoConnection => 'Bağlantı Yok';

  @override
  String get onevpnStatusConnectionFailed => 'Bağlantı kurulamadı';

  @override
  String get onevpnStatusUpdating => 'Güncelleniyor…';

  @override
  String get onevpnStatusMeasuring => 'Sunucular test ediliyor…';

  @override
  String get onevpnAutomaticSubtitle => 'Kullanılabilir en hızlı sunucu';

  @override
  String get onevpnLocationsLoadFailed => 'Konumlarınız yüklenemedi.';

  @override
  String get onevpnLocationsUnavailable => 'Konumlar şu anda kullanılamıyor.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Bazı siteler yalnızca sitenin bulunduğu ülkeden bağlandığınızda çalışır. Bir bölge seçtiğinizde o bölgedeki siteler VPN\'yi kullanmaz.';

  @override
  String onevpnSelectionReset(String location) {
    return '$location konumu kullanılamıyor, 1VPN “Otomatik” seçeneğine geçti.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'Seçilen konum kullanılamıyor, 1VPN “Otomatik” seçeneğine geçti.';

  @override
  String onevpnReloadRolledBack(String location) {
    return '$location konumuna geçilemedi. Hâlâ önceki konumunuza bağlısınız.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Değişiklik uygulanamadı. Hâlâ önceki ayarlarınızla bağlısınız.';

  @override
  String get onevpnDirectRegionsOff => 'Kapalı (Varsayılan)';

  @override
  String get onevpnAllViaVpnSubtitle => 'Tüm trafik tünelden geçer';

  @override
  String get onevpnRegionChina => 'Çin';

  @override
  String get onevpnFirstConnectTitle =>
      'Bazı Bölgeler Doğrudan Erişimle Daha İyi Çalışır';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'Çin, Rusya ve İran gibi yerlerde tüm trafiği VPN üzerinden göndermek yerel bankacılık ve ödeme uygulamalarının çalışmasını bozabilir.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN, seçtiğiniz bölgeye giden trafiği tünelin dışından, gerçek IP adresinizle doğrudan yönlendirebilir.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Diğer her şey korunmaya devam eder. Bunu istediğiniz zaman değiştirebilirsiniz.';

  @override
  String get onevpnFirstConnectChooseRegion => 'Doğrudan Erişim Bölgesi Seç';

  @override
  String get onevpnFirstConnectDismiss => 'Şimdi Değil';

  @override
  String get onevpnCensorshipWarning =>
      'Hükûmet kısıtlamaları nedeniyle bazı sunucular bölgenizde engellenmiş olabilir. Bu sorunu çözmek için çalışıyoruz. Anlayışınız için teşekkür ederiz.';

  @override
  String get onevpnAlwaysOnTitle => 'Her zaman açık VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      'Uygulamayı kapattığınızda tünel açık kalır. Yeniden başlatmanın veya uygulama güncellemesinin ardından “Her zaman açık VPN” tüneli otomatik olarak yeniden bağlar.';

  @override
  String get onevpnAlwaysOnStep1 =>
      'Aşağıdaki “VPN ayarlarını aç” düğmesine dokunun.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Listede 1VPN uygulamasını bulun. Uygulama, ilk bağlantınızdan sonra görünür.';

  @override
  String get onevpnAlwaysOnStep3 =>
      '1VPN uygulamasının yanındaki dişli simgesine dokunun.';

  @override
  String get onevpnAlwaysOnStep4 => '“Her zaman açık VPN” seçeneğini açın.';

  @override
  String get onevpnAlwaysOnOpenSettings => 'VPN ayarlarını aç';

  @override
  String get onevpnPaywallTitle => 'Planınızı seçin';

  @override
  String get onevpnPaywallBenefitLocations => 'Tüm Sunucu Konumlarına Erişim';

  @override
  String get onevpnPaywallBenefitNoAds => 'Reklam Yok';

  @override
  String get onevpnPaywallBenefitSpeed => 'Daha Hızlı Sunucu Hızları';

  @override
  String get onevpnPaywallBenefitP2p => 'BitTorrent (P2P) Desteği';

  @override
  String get onevpnPaywallBenefitMoneyBack => '10 Günlük Para İadesi Garantisi';

  @override
  String get onevpnPaywallPlanYearly => 'Yıllık';

  @override
  String get onevpnPaywallPlanMonthly => 'Aylık';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '%$percent Tasarruf';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / ay';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Fiyat alınamadı';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Planlar yüklenemedi. Bağlantınızı kontrol edin.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Planlar şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.';

  @override
  String get onevpnGetPremium => 'Premium\'u Edinin';

  @override
  String get onevpnContinueFree => 'Ücretsiz Devam Et';

  @override
  String get onevpnPaywallRetry => 'Tekrar Dene';

  @override
  String get onevpnPaywallPurchaseError =>
      'Bir hata oluştu. Lütfen tekrar deneyin.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'Bu Google hesabında, başka bir 1VPN hesabına bağlı, etkin veya yakın zamanda sona ermiş bir 1VPN aboneliği var. O hesaba giriş yapın veya $support ile iletişime geçin.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'Bu Google hesabında zaten bir 1VPN aboneliği var. Premium görünmezse $support ile iletişime geçin.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play son satın alma işleminizi tamamlamadı. Açık olan Google Play ekranlarını kapatıp tekrar deneyin veya uygulamayı yeniden başlatın.';

  @override
  String get onevpnPaywallSupportLink => '1VPN Destek';

  @override
  String get onevpnSignUp => 'Kayıt Ol';

  @override
  String get onevpnAuthEmailLabel => 'E-posta';

  @override
  String get onevpnAuthPasswordLabel => 'Şifre';

  @override
  String get onevpnAuthTwoFactorLabel => '2FA kodu';

  @override
  String get onevpnAuthForgotPassword => 'Şifremi unuttum';

  @override
  String get onevpnAuthSubmitting => 'Yükleniyor…';

  @override
  String get onevpnAuthCreateAccount => 'Hesap Oluştur';

  @override
  String get onevpnAuthHaveAccount => 'Zaten bir hesabınız var mı?';

  @override
  String get onevpnAuthLogInInstead => 'Bunun Yerine Giriş Yap';

  @override
  String get onevpnAuthFieldsRequired =>
      'E-posta adresinizi ve şifrenizi girin';

  @override
  String get onevpnAuthInvalidEmail => 'Geçerli bir e-posta adresi girin';

  @override
  String get onevpnAuthInvalidCredentials => 'E-posta veya şifre hatalı';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Geçersiz 2FA kodu';

  @override
  String get onevpnAuthEmailInUse =>
      'Bu e-posta adresine ait bir hesap zaten var';

  @override
  String get onevpnAuthRateLimited =>
      'Çok fazla deneme yapıldı. Lütfen biraz sonra tekrar deneyin';

  @override
  String get onevpnAuthUnreachable =>
      'Sunucuya ulaşılamadı. Bağlantınızı kontrol edip tekrar deneyin';

  @override
  String get onevpnAuthGenericError => 'Bir hata oluştu. Lütfen tekrar deneyin';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Satın alma işleminiz bu e-posta adresine bağlı.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Satın Alma Tamamlandı';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Satın alma işleminiz $email adresine bağlı. Kullanmak için bu adresle bir hesap oluşturun.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Premium · satın alma onaylanıyor';

  @override
  String get onevpnPremiumRecheck => 'Satın alma durumunuz kontrol ediliyor…';

  @override
  String get onevpnButtonRetry => 'Tekrar Dene';

  @override
  String get onevpnAppVersion => 'Uygulama sürümü';

  @override
  String get onevpnPrivacyPolicy => 'Gizlilik politikası';

  @override
  String get onevpnConnect => 'Bağlan';

  @override
  String get onevpnDisconnected => 'Bağlantı kesildi';

  @override
  String get onevpnConnecting => 'Bağlanıyor…';

  @override
  String get onevpnConnected => 'Bağlandı';

  @override
  String get onevpnDisconnecting => 'Bağlantı kesiliyor…';

  @override
  String get onevpnConnectionFailed => 'Bağlantı kurulamadı';

  @override
  String get onevpnTemporarilyUnavailable => 'Geçici olarak kullanılamıyor';

  @override
  String get onevpnRetry => 'Tekrar Dene';

  @override
  String get onevpnApplyChange => 'Bu değişiklik uygulansın mı?';

  @override
  String get onevpnReconnectNotice =>
      'VPN bağlantısı kısa bir süre kesilip yeniden kurulacak. Bu işlem genellikle yalnızca birkaç saniye sürer.';

  @override
  String onevpnWillUseName(String name) {
    return 'Kullanılacak: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Uygula ve Yeniden Bağlan';

  @override
  String get onevpnCancel => 'İptal';

  @override
  String get onevpnContinue => 'Devam Et';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'Ana alan adı engellendi. Yedek kullanılıyor: $domain';
  }

  @override
  String get onevpnResultFailed => 'başarısız';

  @override
  String get onevpnDownload => 'İndir';

  @override
  String get onevpnPermissionNotGranted => 'İzin verilmedi';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action: $result';
  }

  @override
  String get onevpnDisconnect => 'Bağlantıyı kes';

  @override
  String get onevpnTimeout => 'Zaman aşımı';

  @override
  String get onevpnNoAvailableEntries => 'Kullanılabilir giriş sunucusu yok';

  @override
  String get onevpnAddServers => 'Sunucu ekleyin';

  @override
  String get onevpnNotEnoughServers =>
      'Yeterli sayıda kullanılabilir sunucu yok';

  @override
  String get onevpnVpnFinalExit => 'VPN son çıkış sunucusu';

  @override
  String get onevpnFinalExitEntryConflict =>
      'Son çıkış sunucusu aynı zamanda giriş sunucusu olamaz';

  @override
  String get onevpnChooseNamedRoute => 'Adlandırılmış bir rota seçin';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Yerel ağdaki cihazlara ve hizmetlere erişime izin verin.';

  @override
  String get onevpnSystemApprovalRequired => 'Sistem onayı gerekiyor';

  @override
  String get onevpnVpnPermissionRequired =>
      'VPN izni gerekiyor. Devam etmek için lütfen tekrar deneyin.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Ağa erişmek için kullanılacak arayüzü seçin. Yalnızca Windows / Linux\'ta gereklidir.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Andorra',
      'AE': 'Birleşik Arap Emirlikleri',
      'AF': 'Afganistan',
      'AG': 'Antigua ve Barbuda',
      'AI': 'Anguilla',
      'AL': 'Arnavutluk',
      'AM': 'Ermenistan',
      'AO': 'Angola',
      'AQ': 'Antarktika',
      'AR': 'Arjantin',
      'AS': 'Amerikan Samoası',
      'AT': 'Avusturya',
      'AU': 'Avustralya',
      'AW': 'Aruba',
      'AX': 'Åland Adaları',
      'AZ': 'Azerbaycan',
      'BA': 'Bosna-Hersek',
      'BB': 'Barbados',
      'BD': 'Bangladeş',
      'BE': 'Belçika',
      'BF': 'Burkina Faso',
      'BG': 'Bulgaristan',
      'BH': 'Bahreyn',
      'BI': 'Burundi',
      'BJ': 'Benin',
      'BL': 'Saint Barthelemy',
      'BM': 'Bermuda',
      'BN': 'Brunei',
      'BO': 'Bolivya',
      'BQ': 'Karayip Hollandası',
      'BR': 'Brezilya',
      'BS': 'Bahamalar',
      'BT': 'Butan',
      'BV': 'Bouvet Adası',
      'BW': 'Botsvana',
      'BY': 'Belarus',
      'BZ': 'Belize',
      'CA': 'Kanada',
      'CC': 'Cocos (Keeling) Adaları',
      'CD': 'Kongo - Kinşasa',
      'CF': 'Orta Afrika Cumhuriyeti',
      'CG': 'Kongo - Brazavil',
      'CH': 'İsviçre',
      'CI': 'Côte d’Ivoire',
      'CK': 'Cook Adaları',
      'CL': 'Şili',
      'CM': 'Kamerun',
      'CN': 'Çin Anakarası',
      'CO': 'Kolombiya',
      'CR': 'Kosta Rika',
      'CU': 'Küba',
      'CV': 'Cabo Verde',
      'CW': 'Curaçao',
      'CX': 'Christmas Adası',
      'CY': 'Kıbrıs',
      'CZ': 'Çekya',
      'DE': 'Almanya',
      'DJ': 'Cibuti',
      'DK': 'Danimarka',
      'DM': 'Dominika',
      'DO': 'Dominik Cumhuriyeti',
      'DZ': 'Cezayir',
      'EC': 'Ekvador',
      'EE': 'Estonya',
      'EG': 'Mısır',
      'EH': 'Batı Sahra',
      'ER': 'Eritre',
      'ES': 'İspanya',
      'ET': 'Etiyopya',
      'FI': 'Finlandiya',
      'FJ': 'Fiji',
      'FK': 'Falkland Adaları',
      'FM': 'Mikronezya',
      'FO': 'Faroe Adaları',
      'FR': 'Fransa',
      'GA': 'Gabon',
      'GB': 'Birleşik Krallık',
      'GD': 'Grenada',
      'GE': 'Gürcistan',
      'GF': 'Fransız Guyanası',
      'GG': 'Guernsey',
      'GH': 'Gana',
      'GI': 'Cebelitarık',
      'GL': 'Grönland',
      'GM': 'Gambiya',
      'GN': 'Gine',
      'GP': 'Guadeloupe',
      'GQ': 'Ekvator Ginesi',
      'GR': 'Yunanistan',
      'GS': 'Güney Georgia ve Güney Sandwich Adaları',
      'GT': 'Guatemala',
      'GU': 'Guam',
      'GW': 'Gine-Bissau',
      'GY': 'Guyana',
      'HK': 'Hong Kong',
      'HM': 'Heard Adası ve McDonald Adaları',
      'HN': 'Honduras',
      'HR': 'Hırvatistan',
      'HT': 'Haiti',
      'HU': 'Macaristan',
      'ID': 'Endonezya',
      'IE': 'İrlanda',
      'IL': 'İsrail',
      'IM': 'Man Adası',
      'IN': 'Hindistan',
      'IO': 'Chagos Takımadaları',
      'IQ': 'Irak',
      'IR': 'İran',
      'IS': 'İzlanda',
      'IT': 'İtalya',
      'JE': 'Jersey',
      'JM': 'Jamaika',
      'JO': 'Ürdün',
      'JP': 'Japonya',
      'KE': 'Kenya',
      'KG': 'Kırgızistan',
      'KH': 'Kamboçya',
      'KI': 'Kiribati',
      'KM': 'Komorlar',
      'KN': 'Saint Kitts ve Nevis',
      'KP': 'Kuzey Kore',
      'KR': 'Güney Kore',
      'KW': 'Kuveyt',
      'KY': 'Cayman Adaları',
      'KZ': 'Kazakistan',
      'LA': 'Laos',
      'LB': 'Lübnan',
      'LC': 'Saint Lucia',
      'LI': 'Liechtenstein',
      'LK': 'Sri Lanka',
      'LR': 'Liberya',
      'LS': 'Lesotho',
      'LT': 'Litvanya',
      'LU': 'Lüksemburg',
      'LV': 'Letonya',
      'LY': 'Libya',
      'MA': 'Fas',
      'MC': 'Monako',
      'MD': 'Moldova',
      'ME': 'Karadağ',
      'MF': 'Saint Martin',
      'MG': 'Madagaskar',
      'MH': 'Marshall Adaları',
      'MK': 'Kuzey Makedonya',
      'ML': 'Mali',
      'MM': 'Myanmar (Burma)',
      'MN': 'Moğolistan',
      'MO': 'Makao',
      'MP': 'Kuzey Mariana Adaları',
      'MQ': 'Martinik',
      'MR': 'Moritanya',
      'MS': 'Montserrat',
      'MT': 'Malta',
      'MU': 'Mauritius',
      'MV': 'Maldivler',
      'MW': 'Malavi',
      'MX': 'Meksika',
      'MY': 'Malezya',
      'MZ': 'Mozambik',
      'NA': 'Namibya',
      'NC': 'Yeni Kaledonya',
      'NE': 'Nijer',
      'NF': 'Norfolk Adası',
      'NG': 'Nijerya',
      'NI': 'Nikaragua',
      'NL': 'Hollanda',
      'NO': 'Norveç',
      'NP': 'Nepal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'Yeni Zelanda',
      'OM': 'Umman',
      'PA': 'Panama',
      'PE': 'Peru',
      'PF': 'Fransız Polinezyası',
      'PG': 'Papua Yeni Gine',
      'PH': 'Filipinler',
      'PK': 'Pakistan',
      'PL': 'Polonya',
      'PM': 'Saint Pierre ve Miquelon',
      'PN': 'Pitcairn Adaları',
      'PR': 'Porto Riko',
      'PS': 'Filistin Bölgeleri',
      'PT': 'Portekiz',
      'PW': 'Palau',
      'PY': 'Paraguay',
      'QA': 'Katar',
      'RE': 'Réunion',
      'RO': 'Romanya',
      'RS': 'Sırbistan',
      'RU': 'Rusya',
      'RW': 'Ruanda',
      'SA': 'Suudi Arabistan',
      'SB': 'Solomon Adaları',
      'SC': 'Seyşeller',
      'SD': 'Sudan',
      'SE': 'İsveç',
      'SG': 'Singapur',
      'SH': 'Saint Helena',
      'SI': 'Slovenya',
      'SJ': 'Svalbard ve Jan Mayen',
      'SK': 'Slovakya',
      'SL': 'Sierra Leone',
      'SM': 'San Marino',
      'SN': 'Senegal',
      'SO': 'Somali',
      'SR': 'Surinam',
      'SS': 'Güney Sudan',
      'ST': 'São Tomé ve Príncipe',
      'SV': 'El Salvador',
      'SX': 'Sint Maarten',
      'SY': 'Suriye',
      'SZ': 'Esvatini',
      'TC': 'Turks ve Caicos Adaları',
      'TD': 'Çad',
      'TF': 'Fransız Güney Toprakları',
      'TG': 'Togo',
      'TH': 'Tayland',
      'TJ': 'Tacikistan',
      'TK': 'Tokelau',
      'TL': 'Timor-Leste',
      'TM': 'Türkmenistan',
      'TN': 'Tunus',
      'TO': 'Tonga',
      'TR': 'Türkiye',
      'TT': 'Trinidad ve Tobago',
      'TV': 'Tuvalu',
      'TW': 'Tayvan',
      'TZ': 'Tanzanya',
      'UA': 'Ukrayna',
      'UG': 'Uganda',
      'UM': 'ABD Küçük Harici Adaları',
      'US': 'Amerika Birleşik Devletleri',
      'UY': 'Uruguay',
      'UZ': 'Özbekistan',
      'VA': 'Vatikan',
      'VC': 'Saint Vincent ve Grenadinler',
      'VE': 'Venezuela',
      'VG': 'Britanya Virjin Adaları',
      'VI': 'ABD Virjin Adaları',
      'VN': 'Vietnam',
      'VU': 'Vanuatu',
      'WF': 'Wallis ve Futuna',
      'WS': 'Samoa',
      'XK': 'Kosova',
      'YE': 'Yemen',
      'YT': 'Mayotte',
      'ZA': 'Güney Afrika',
      'ZM': 'Zambiya',
      'ZW': 'Zimbabve',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Gizlilik Tercihleri';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Amsterdam',
      'sgp': 'Singapur',
      'lax': 'Los Angeles',
      'mel': 'Melbourne',
      'syd': 'Sidney',
      'sao': 'São Paulo',
      'yto': 'Toronto',
      'scl': 'Santiago',
      'cdg': 'Paris',
      'fra': 'Frankfurt',
      'del': 'Yeni Delhi',
      'bom': 'Mumbai',
      'blr': 'Bangalore',
      'tlv': 'Tel Aviv',
      'itm': 'Osaka',
      'nrt': 'Tokyo',
      'mex': 'Meksiko Şehri',
      'waw': 'Varşova',
      'jnb': 'Johannesburg',
      'icn': 'Seul',
      'mad': 'Madrid',
      'sto': 'Stockholm',
      'lhr': 'Londra',
      'man': 'Manchester',
      'ord': 'Chicago',
      'dfw': 'Dallas',
      'sea': 'Seattle',
      'sjc': 'San Francisco',
      'mia': 'Miami',
      'hnl': 'Honolulu',
      'ewr': 'New York',
      'atl': 'Atlanta',
      'hkg': 'Hong Kong',
      'zrh': 'Zürih',
      'gva': 'Cenevre',
      'svo': 'Moskova',
      'led': 'Sankt-Peterburg',
      'hel': 'Helsinki',
      'tpe': 'Taipei',
      'dxb': 'Dubai',
      'kbp': 'Kiev',
      'ist': 'İstanbul',
      'otp': 'Bükreş',
      'los': 'Lagos',
      'pty': 'Panama Şehri',
      'kef': 'Reykjavik',
      'ber': 'Berlin',
      'ala': 'Almatı',
      'tbs': 'Tiflis',
      'kul': 'Kuala Lumpur',
      'bkk': 'Bangkok',
      'cgk': 'Cakarta',
      'mnl': 'Manila',
      'nbo': 'Nairobi',
      'mxp': 'Milano',
      'dub': 'Dublin',
      'lis': 'Lizbon',
      'lux': 'Lüksemburg',
      'eze': 'Buenos Aires',
      'akl': 'Auckland',
      'yul': 'Montreal',
      'yvr': 'Vancouver',
      'den': 'Denver',
      'phx': 'Phoenix',
      'iad': 'Washington, D.C.',
      'bos': 'Boston',
      'edi': 'Edinburgh',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => '1VPN\'i beğeniyor musunuz?';

  @override
  String get onevpnYes => 'Evet';

  @override
  String get onevpnNo => 'Hayır';

  @override
  String get onevpnLocationLocked => 'Kilitli, yalnızca Premium';

  @override
  String get onevpnManageSubscription => 'Aboneliği yönet';
}
