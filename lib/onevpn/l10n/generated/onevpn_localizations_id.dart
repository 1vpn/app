// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class OneVpnLocalizationsId extends OneVpnLocalizations {
  OneVpnLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get onevpnFaq => 'FAQ';

  @override
  String get onevpnTermsOfService => 'Persyaratan layanan';

  @override
  String get onevpnMenu => 'Menu';

  @override
  String get onevpnUpgrade => 'Tingkatkan';

  @override
  String get onevpnUpgradeBannerTitle => 'Upgrade ke Premium';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Tanpa iklan, semua lokasi & kecepatan lebih tinggi';

  @override
  String get onevpnLogIn => 'Masuk';

  @override
  String get onevpnLogOut => 'Keluar';

  @override
  String get onevpnAccount => 'Akun';

  @override
  String get onevpnContactUs => 'Hubungi Kami';

  @override
  String get onevpnRefundPolicy => 'Kebijakan pengembalian dana';

  @override
  String get onevpnSupport => 'Dukungan';

  @override
  String get onevpnLanguage => 'Bahasa';

  @override
  String get onevpnLanguageSystem => 'Default sistem';

  @override
  String get onevpnPlanFree => 'Paket Gratis';

  @override
  String get onevpnPlanPremium => 'Paket Premium';

  @override
  String get onevpnSelectLocation => 'Pilih Lokasi';

  @override
  String get onevpnDirectRegions => 'Wilayah Akses Langsung';

  @override
  String get onevpnFree => 'Gratis';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Gratis';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Otomatis · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Otomatis';

  @override
  String get onevpnStatusNoConnection => 'Tidak Ada Koneksi';

  @override
  String get onevpnStatusConnectionFailed => 'Gagal terhubung';

  @override
  String get onevpnStatusUpdating => 'Memperbarui…';

  @override
  String get onevpnStatusMeasuring => 'Memeriksa server…';

  @override
  String get onevpnAutomaticSubtitle => 'Tercepat yang tersedia';

  @override
  String get onevpnLocationsLoadFailed => 'Tidak dapat memuat lokasi Anda.';

  @override
  String get onevpnLocationsUnavailable => 'Lokasi tidak tersedia saat ini.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Beberapa situs hanya berfungsi jika Anda terhubung dari negara yang sama dengan situs tersebut. Dengan memilih wilayah, situs dari wilayah tersebut diakses tanpa melalui VPN.';

  @override
  String onevpnSelectionReset(String location) {
    return 'Lokasi $location tidak tersedia, 1VPN beralih ke “Otomatis”.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'Lokasi yang dipilih tidak tersedia, 1VPN beralih ke “Otomatis”.';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'Tidak dapat beralih ke $location. Anda masih terhubung ke lokasi sebelumnya.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Tidak dapat menerapkan perubahan. Anda masih terhubung dengan setelan sebelumnya.';

  @override
  String get onevpnDirectRegionsOff => 'Nonaktif (Default)';

  @override
  String get onevpnAllViaVpnSubtitle => 'Semua lalu lintas melalui terowongan';

  @override
  String get onevpnRegionChina => 'Tiongkok';

  @override
  String get onevpnFirstConnectTitle =>
      'Beberapa Wilayah Lebih Baik Diakses Langsung';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'Di negara seperti Tiongkok, Rusia, dan Iran, mengirim semua lalu lintas melalui VPN dapat membuat aplikasi perbankan dan pembayaran lokal tidak berfungsi.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN dapat merutekan wilayah pilihan Anda secara langsung, di luar terowongan, dari IP asli Anda.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Semua lalu lintas lainnya tetap terlindungi. Anda dapat mengubah ini kapan saja.';

  @override
  String get onevpnFirstConnectChooseRegion => 'Pilih wilayah akses langsung';

  @override
  String get onevpnFirstConnectDismiss => 'Lain kali';

  @override
  String get onevpnCensorshipWarning =>
      'Beberapa server mungkin diblokir di wilayah Anda karena pembatasan pemerintah. Kami sedang bekerja untuk menyelesaikan masalah ini. Terima kasih atas pengertian Anda.';

  @override
  String get onevpnAlwaysOnTitle => 'VPN selalu aktif';

  @override
  String get onevpnAlwaysOnIntro =>
      'Terowongan tetap terhubung saat Anda menutup aplikasi. Setelah perangkat dinyalakan ulang atau aplikasi diperbarui, “VPN selalu aktif” akan menghubungkannya kembali secara otomatis.';

  @override
  String get onevpnAlwaysOnStep1 => 'Ketuk “Buka setelan VPN” di bawah.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Temukan 1VPN dalam daftar. Aplikasi ini muncul setelah Anda terhubung pertama kali.';

  @override
  String get onevpnAlwaysOnStep3 => 'Ketuk ikon roda gigi di samping 1VPN.';

  @override
  String get onevpnAlwaysOnStep4 => 'Aktifkan “VPN selalu aktif”.';

  @override
  String get onevpnAlwaysOnOpenSettings => 'Buka setelan VPN';

  @override
  String get onevpnPaywallTitle => 'Pilih Paket Anda';

  @override
  String get onevpnPaywallBenefitLocations => 'Buka Semua Lokasi Server';

  @override
  String get onevpnPaywallBenefitNoAds => 'Tanpa Iklan';

  @override
  String get onevpnPaywallBenefitSpeed => 'Kecepatan Server Lebih Cepat';

  @override
  String get onevpnPaywallBenefitP2p => 'Dukungan BitTorrent (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack => 'Garansi Uang Kembali 10 Hari';

  @override
  String get onevpnPaywallPlanYearly => 'Tahunan';

  @override
  String get onevpnPaywallPlanMonthly => 'Bulanan';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'Hemat $percent%';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / bln';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Harga tidak tersedia';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Gagal memuat paket. Periksa koneksi Anda.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Paket tidak tersedia saat ini. Silakan coba lagi nanti.';

  @override
  String get onevpnGetPremium => 'Dapatkan Premium';

  @override
  String get onevpnContinueFree => 'Lanjutkan Gratis';

  @override
  String get onevpnPaywallRetry => 'Coba lagi';

  @override
  String get onevpnPaywallPurchaseError =>
      'Terjadi kesalahan. Silakan coba lagi.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'Akun Google ini memiliki langganan 1VPN yang aktif atau baru berakhir dan ditautkan ke akun 1VPN lain. Masuk ke akun tersebut atau hubungi $support.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'Akun Google ini sudah memiliki langganan 1VPN. Jika Premium tidak muncul, hubungi $support.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play tidak menyelesaikan pembelian terakhir Anda. Tutup semua layar Google Play yang terbuka lalu coba lagi, atau mulai ulang aplikasi.';

  @override
  String get onevpnPaywallSupportLink => 'tim dukungan 1VPN';

  @override
  String get onevpnSignUp => 'Daftar';

  @override
  String get onevpnAuthEmailLabel => 'Email';

  @override
  String get onevpnAuthPasswordLabel => 'Kata Sandi';

  @override
  String get onevpnAuthTwoFactorLabel => 'Token 2FA';

  @override
  String get onevpnAuthForgotPassword => 'Lupa kata sandi?';

  @override
  String get onevpnAuthSubmitting => 'Memuat…';

  @override
  String get onevpnAuthCreateAccount => 'Buat Akun';

  @override
  String get onevpnAuthHaveAccount => 'Sudah punya akun?';

  @override
  String get onevpnAuthLogInInstead => 'Masuk ke akun yang ada';

  @override
  String get onevpnAuthFieldsRequired => 'Masukkan email dan kata sandi';

  @override
  String get onevpnAuthInvalidEmail => 'Masukkan alamat email yang valid';

  @override
  String get onevpnAuthInvalidCredentials => 'Email atau kata sandi salah';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Token 2FA tidak valid';

  @override
  String get onevpnAuthEmailInUse => 'Email ini sudah terdaftar';

  @override
  String get onevpnAuthRateLimited =>
      'Terlalu banyak percobaan. Silakan coba beberapa saat lagi';

  @override
  String get onevpnAuthUnreachable =>
      'Tidak dapat menghubungi server. Periksa koneksi Anda dan coba lagi';

  @override
  String get onevpnAuthGenericError => 'Terjadi kesalahan. Silakan coba lagi';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Pembelian Anda ditautkan ke alamat email ini.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Pembelian Selesai';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Pembelian Anda ditautkan ke $email. Buat akun dengan alamat tersebut untuk menggunakannya.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Premium · mengonfirmasi pembelian';

  @override
  String get onevpnPremiumRecheck => 'Memeriksa status pembelian Anda…';

  @override
  String get onevpnButtonRetry => 'Coba lagi';

  @override
  String get onevpnAppVersion => 'Versi aplikasi';

  @override
  String get onevpnPrivacyPolicy => 'Kebijakan privasi';

  @override
  String get onevpnConnect => 'Hubungkan';

  @override
  String get onevpnDisconnected => 'Terputus';

  @override
  String get onevpnConnecting => 'Menghubungkan…';

  @override
  String get onevpnConnected => 'Terhubung';

  @override
  String get onevpnDisconnecting => 'Memutuskan koneksi…';

  @override
  String get onevpnConnectionFailed => 'Gagal terhubung';

  @override
  String get onevpnTemporarilyUnavailable => 'Untuk sementara tidak tersedia';

  @override
  String get onevpnRetry => 'Coba lagi';

  @override
  String get onevpnApplyChange => 'Terapkan perubahan ini?';

  @override
  String get onevpnReconnectNotice =>
      'VPN akan terputus sebentar lalu terhubung kembali. Biasanya ini hanya memerlukan beberapa detik.';

  @override
  String onevpnWillUseName(String name) {
    return 'Akan menggunakan: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Terapkan dan hubungkan kembali';

  @override
  String get onevpnCancel => 'Batal';

  @override
  String get onevpnContinue => 'Lanjutkan';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'Domain utama diblokir. Menggunakan cadangan: $domain';
  }

  @override
  String get onevpnResultFailed => 'gagal';

  @override
  String get onevpnDownload => 'Unduh';

  @override
  String get onevpnPermissionNotGranted => 'Izin tidak diberikan';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action: $result';
  }

  @override
  String get onevpnDisconnect => 'Putuskan koneksi';

  @override
  String get onevpnTimeout => 'Waktu habis';

  @override
  String get onevpnNoAvailableEntries => 'Tidak ada server entri yang tersedia';

  @override
  String get onevpnAddServers => 'Tambahkan server';

  @override
  String get onevpnNotEnoughServers => 'Server yang tersedia tidak cukup';

  @override
  String get onevpnVpnFinalExit => 'Titik keluar akhir VPN';

  @override
  String get onevpnFinalExitEntryConflict =>
      'Titik keluar akhir tidak boleh sekaligus menjadi server entri';

  @override
  String get onevpnChooseNamedRoute => 'Pilih satu rute bernama';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Izinkan akses ke perangkat dan layanan di jaringan lokal.';

  @override
  String get onevpnSystemApprovalRequired => 'Persetujuan sistem diperlukan';

  @override
  String get onevpnVpnPermissionRequired =>
      'Izin VPN diperlukan. Silakan coba lagi untuk melanjutkan.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Pilih antarmuka yang digunakan untuk mengakses jaringan. Hanya diperlukan di Windows / Linux.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Andorra',
      'AE': 'Uni Emirat Arab',
      'AF': 'Afganistan',
      'AG': 'Antigua dan Barbuda',
      'AI': 'Anguilla',
      'AL': 'Albania',
      'AM': 'Armenia',
      'AO': 'Angola',
      'AQ': 'Antarktika',
      'AR': 'Argentina',
      'AS': 'Samoa Amerika',
      'AT': 'Austria',
      'AU': 'Australia',
      'AW': 'Aruba',
      'AX': 'Kepulauan Aland',
      'AZ': 'Azerbaijan',
      'BA': 'Bosnia dan Herzegovina',
      'BB': 'Barbados',
      'BD': 'Bangladesh',
      'BE': 'Belgia',
      'BF': 'Burkina Faso',
      'BG': 'Bulgaria',
      'BH': 'Bahrain',
      'BI': 'Burundi',
      'BJ': 'Benin',
      'BL': 'Saint Barthélemy',
      'BM': 'Bermuda',
      'BN': 'Brunei',
      'BO': 'Bolivia',
      'BQ': 'Belanda Karibia',
      'BR': 'Brasil',
      'BS': 'Bahama',
      'BT': 'Bhutan',
      'BV': 'Pulau Bouvet',
      'BW': 'Botswana',
      'BY': 'Belarus',
      'BZ': 'Belize',
      'CA': 'Kanada',
      'CC': 'Kepulauan Cocos (Keeling)',
      'CD': 'Kongo - Kinshasa',
      'CF': 'Republik Afrika Tengah',
      'CG': 'Kongo - Brazzaville',
      'CH': 'Swiss',
      'CI': 'Côte d’Ivoire',
      'CK': 'Kepulauan Cook',
      'CL': 'Cile',
      'CM': 'Kamerun',
      'CN': 'Tiongkok daratan',
      'CO': 'Kolombia',
      'CR': 'Kosta Rika',
      'CU': 'Kuba',
      'CV': 'Tanjung Verde',
      'CW': 'Curaçao',
      'CX': 'Pulau Natal',
      'CY': 'Siprus',
      'CZ': 'Ceko',
      'DE': 'Jerman',
      'DJ': 'Jibuti',
      'DK': 'Denmark',
      'DM': 'Dominika',
      'DO': 'Republik Dominika',
      'DZ': 'Aljazair',
      'EC': 'Ekuador',
      'EE': 'Estonia',
      'EG': 'Mesir',
      'EH': 'Sahara Barat',
      'ER': 'Eritrea',
      'ES': 'Spanyol',
      'ET': 'Etiopia',
      'FI': 'Finlandia',
      'FJ': 'Fiji',
      'FK': 'Kepulauan Falkland',
      'FM': 'Mikronesia',
      'FO': 'Kepulauan Faroe',
      'FR': 'Prancis',
      'GA': 'Gabon',
      'GB': 'Inggris Raya',
      'GD': 'Grenada',
      'GE': 'Georgia',
      'GF': 'Guyana Prancis',
      'GG': 'Guernsey',
      'GH': 'Ghana',
      'GI': 'Gibraltar',
      'GL': 'Greenland',
      'GM': 'Gambia',
      'GN': 'Guinea',
      'GP': 'Guadeloupe',
      'GQ': 'Guinea Ekuatorial',
      'GR': 'Yunani',
      'GS': 'Georgia Selatan & Kep. Sandwich Selatan',
      'GT': 'Guatemala',
      'GU': 'Guam',
      'GW': 'Guinea-Bissau',
      'GY': 'Guyana',
      'HK': 'Hong Kong',
      'HM': 'Pulau Heard dan Kepulauan McDonald',
      'HN': 'Honduras',
      'HR': 'Kroasia',
      'HT': 'Haiti',
      'HU': 'Hungaria',
      'ID': 'Indonesia',
      'IE': 'Irlandia',
      'IL': 'Israel',
      'IM': 'Pulau Man',
      'IN': 'India',
      'IO': 'Kepulauan Chagos',
      'IQ': 'Irak',
      'IR': 'Iran',
      'IS': 'Islandia',
      'IT': 'Italia',
      'JE': 'Jersey',
      'JM': 'Jamaika',
      'JO': 'Yordania',
      'JP': 'Jepang',
      'KE': 'Kenya',
      'KG': 'Kirgizstan',
      'KH': 'Kamboja',
      'KI': 'Kiribati',
      'KM': 'Komoro',
      'KN': 'Saint Kitts dan Nevis',
      'KP': 'Korea Utara',
      'KR': 'Korea Selatan',
      'KW': 'Kuwait',
      'KY': 'Kepulauan Cayman',
      'KZ': 'Kazakhstan',
      'LA': 'Laos',
      'LB': 'Lebanon',
      'LC': 'Saint Lucia',
      'LI': 'Liechtenstein',
      'LK': 'Sri Lanka',
      'LR': 'Liberia',
      'LS': 'Lesotho',
      'LT': 'Lituania',
      'LU': 'Luksemburg',
      'LV': 'Latvia',
      'LY': 'Libya',
      'MA': 'Maroko',
      'MC': 'Monako',
      'MD': 'Moldova',
      'ME': 'Montenegro',
      'MF': 'Saint Martin',
      'MG': 'Madagaskar',
      'MH': 'Kepulauan Marshall',
      'MK': 'Makedonia Utara',
      'ML': 'Mali',
      'MM': 'Myanmar (Burma)',
      'MN': 'Mongolia',
      'MO': 'Makau',
      'MP': 'Kepulauan Mariana Utara',
      'MQ': 'Martinik',
      'MR': 'Mauritania',
      'MS': 'Montserrat',
      'MT': 'Malta',
      'MU': 'Mauritius',
      'MV': 'Maladewa',
      'MW': 'Malawi',
      'MX': 'Meksiko',
      'MY': 'Malaysia',
      'MZ': 'Mozambik',
      'NA': 'Namibia',
      'NC': 'Kaledonia Baru',
      'NE': 'Niger',
      'NF': 'Kepulauan Norfolk',
      'NG': 'Nigeria',
      'NI': 'Nikaragua',
      'NL': 'Belanda',
      'NO': 'Norwegia',
      'NP': 'Nepal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'Selandia Baru',
      'OM': 'Oman',
      'PA': 'Panama',
      'PE': 'Peru',
      'PF': 'Polinesia Prancis',
      'PG': 'Papua Nugini',
      'PH': 'Filipina',
      'PK': 'Pakistan',
      'PL': 'Polandia',
      'PM': 'Saint Pierre dan Miquelon',
      'PN': 'Kepulauan Pitcairn',
      'PR': 'Puerto Riko',
      'PS': 'Wilayah Palestina',
      'PT': 'Portugal',
      'PW': 'Palau',
      'PY': 'Paraguay',
      'QA': 'Qatar',
      'RE': 'Réunion',
      'RO': 'Rumania',
      'RS': 'Serbia',
      'RU': 'Rusia',
      'RW': 'Rwanda',
      'SA': 'Arab Saudi',
      'SB': 'Kepulauan Solomon',
      'SC': 'Seychelles',
      'SD': 'Sudan',
      'SE': 'Swedia',
      'SG': 'Singapura',
      'SH': 'Saint Helena',
      'SI': 'Slovenia',
      'SJ': 'Kepulauan Svalbard dan Jan Mayen',
      'SK': 'Slovakia',
      'SL': 'Sierra Leone',
      'SM': 'San Marino',
      'SN': 'Senegal',
      'SO': 'Somalia',
      'SR': 'Suriname',
      'SS': 'Sudan Selatan',
      'ST': 'Sao Tome dan Principe',
      'SV': 'El Salvador',
      'SX': 'Sint Maarten',
      'SY': 'Suriah',
      'SZ': 'eSwatini',
      'TC': 'Kepulauan Turks dan Caicos',
      'TD': 'Chad',
      'TF': 'Wilayah Selatan Prancis',
      'TG': 'Togo',
      'TH': 'Thailand',
      'TJ': 'Tajikistan',
      'TK': 'Tokelau',
      'TL': 'Timor Leste',
      'TM': 'Turkmenistan',
      'TN': 'Tunisia',
      'TO': 'Tonga',
      'TR': 'Turki',
      'TT': 'Trinidad dan Tobago',
      'TV': 'Tuvalu',
      'TW': 'Taiwan',
      'TZ': 'Tanzania',
      'UA': 'Ukraina',
      'UG': 'Uganda',
      'UM': 'Kepulauan Terluar AS',
      'US': 'Amerika Serikat',
      'UY': 'Uruguay',
      'UZ': 'Uzbekistan',
      'VA': 'Vatikan',
      'VC': 'Saint Vincent dan Grenadine',
      'VE': 'Venezuela',
      'VG': 'Kepulauan Virgin Britania Raya',
      'VI': 'Kepulauan Virgin Amerika Serikat',
      'VN': 'Vietnam',
      'VU': 'Vanuatu',
      'WF': 'Kepulauan Wallis dan Futuna',
      'WS': 'Samoa',
      'XK': 'Kosovo',
      'YE': 'Yaman',
      'YT': 'Mayotte',
      'ZA': 'Afrika Selatan',
      'ZM': 'Zambia',
      'ZW': 'Zimbabwe',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Pilihan Privasi';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Amsterdam',
      'sgp': 'Singapura',
      'lax': 'Los Angeles',
      'mel': 'Melbourne',
      'syd': 'Sydney',
      'sao': 'São Paulo',
      'yto': 'Toronto',
      'scl': 'Santiago',
      'cdg': 'Paris',
      'fra': 'Frankfurt',
      'del': 'New Delhi',
      'bom': 'Mumbai',
      'blr': 'Bangalore',
      'tlv': 'Tel Aviv',
      'itm': 'Osaka',
      'nrt': 'Tokyo',
      'mex': 'Kota Meksiko',
      'waw': 'Warsawa',
      'jnb': 'Johannesburg',
      'icn': 'Seoul',
      'mad': 'Madrid',
      'sto': 'Stockholm',
      'lhr': 'London',
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
      'zrh': 'Zürich',
      'gva': 'Jenewa',
      'svo': 'Moskwa',
      'led': 'Sankt-Peterburg',
      'hel': 'Helsinki',
      'tpe': 'Taipei',
      'dxb': 'Dubai',
      'kbp': 'Kyiv',
      'ist': 'Istanbul',
      'otp': 'Bukares',
      'los': 'Lagos',
      'pty': 'Kota Panama',
      'kef': 'Reykjavík',
      'ber': 'Berlin',
      'ala': 'Almaty',
      'tbs': 'Tbilisi',
      'kul': 'Kuala Lumpur',
      'bkk': 'Bangkok',
      'cgk': 'Jakarta',
      'mnl': 'Manila',
      'nbo': 'Nairobi',
      'mxp': 'Milan',
      'dub': 'Dublin',
      'lis': 'Lisboa',
      'lux': 'Luksemburg',
      'eze': 'Buenos Aires',
      'akl': 'Auckland',
      'yul': 'Montréal',
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
  String get onevpnEnjoyingQuestion => 'Apakah Anda menikmati 1VPN?';

  @override
  String get onevpnYes => 'Ya';

  @override
  String get onevpnNo => 'Tidak';

  @override
  String get onevpnLocationLocked => 'Terkunci, khusus Premium';

  @override
  String get onevpnManageSubscription => 'Kelola langganan';
}
