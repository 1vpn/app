// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class OneVpnLocalizationsEn extends OneVpnLocalizations {
  OneVpnLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get onevpnFaq => 'FAQ';

  @override
  String get onevpnTermsOfService => 'Terms of service';

  @override
  String get onevpnMenu => 'Menu';

  @override
  String get onevpnUpgrade => 'Upgrade';

  @override
  String get onevpnUpgradeBannerTitle => 'Upgrade to Premium';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'No ads, all locations & faster speeds';

  @override
  String get onevpnLogIn => 'Login';

  @override
  String get onevpnLogOut => 'Logout';

  @override
  String get onevpnAccount => 'Account';

  @override
  String get onevpnContactUs => 'Contact Us';

  @override
  String get onevpnRefundPolicy => 'Refund Policy';

  @override
  String get onevpnSupport => 'Support';

  @override
  String get onevpnLanguage => 'Language';

  @override
  String get onevpnLanguageSystem => 'System Default';

  @override
  String get onevpnPlanFree => 'Free plan';

  @override
  String get onevpnPlanPremium => 'Premium plan';

  @override
  String get onevpnSelectLocation => 'Select Location';

  @override
  String get onevpnDirectRegions => 'Direct Regions';

  @override
  String get onevpnFree => 'Free';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Free';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Automatic · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Automatic';

  @override
  String get onevpnStatusNoConnection => 'No Connection';

  @override
  String get onevpnStatusConnectionFailed => 'Connection Failed';

  @override
  String get onevpnStatusUpdating => 'Updating…';

  @override
  String get onevpnStatusMeasuring => 'Measuring Servers…';

  @override
  String get onevpnAutomaticSubtitle => 'Fastest available';

  @override
  String get onevpnLocationsLoadFailed => 'Couldn\'t load your locations.';

  @override
  String get onevpnLocationsUnavailable =>
      'Locations are unavailable right now.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Some sites only work when you connect from the same country as the site. By selecting a region, sites from that region bypass the VPN.';

  @override
  String onevpnSelectionReset(String location) {
    return '$location is unavailable, 1VPN switched to Automatic.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'The picked location is unavailable, 1VPN switched to Automatic.';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'Couldn\'t switch to $location. You\'re still connected to your previous location.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Couldn\'t apply the change. You\'re still connected with your previous settings.';

  @override
  String get onevpnDirectRegionsOff => 'Off (Default)';

  @override
  String get onevpnAllViaVpnSubtitle => 'All traffic through the tunnel';

  @override
  String get onevpnRegionChina => 'China';

  @override
  String get onevpnFirstConnectTitle => 'Some Regions Work Better Direct';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'In places like China, Russia and Iran, sending everything through the VPN can break local banking and payment apps.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN can route a region you choose directly, outside the tunnel, from your real IP.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Everything else stays protected. You can change this anytime.';

  @override
  String get onevpnFirstConnectChooseRegion => 'Choose direct region';

  @override
  String get onevpnFirstConnectDismiss => 'Not now';

  @override
  String get onevpnCensorshipWarning =>
      'Some servers may be blocked in your region due to government restrictions. We are working to resolve this. Thank you for your understanding.';

  @override
  String get onevpnAlwaysOnTitle => 'Always-On VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      'The tunnel stays up when you close the app. After a restart or an app update, Always-on VPN reconnects it automatically.';

  @override
  String get onevpnAlwaysOnStep1 => 'Tap Open VPN settings below.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Find 1VPN in the list. It appears after your first connect.';

  @override
  String get onevpnAlwaysOnStep3 => 'Tap the gear icon next to 1VPN.';

  @override
  String get onevpnAlwaysOnStep4 => 'Turn on Always-on VPN.';

  @override
  String get onevpnAlwaysOnOpenSettings => 'Open VPN settings';

  @override
  String get onevpnPaywallTitle => 'Choose Your Plan';

  @override
  String get onevpnPaywallBenefitLocations => 'Unlock All Server Locations';

  @override
  String get onevpnPaywallBenefitNoAds => 'No Advertisements';

  @override
  String get onevpnPaywallBenefitSpeed => 'Faster Server Speeds';

  @override
  String get onevpnPaywallBenefitP2p => 'BitTorrent (P2P) Support';

  @override
  String get onevpnPaywallBenefitMoneyBack => '10-Day Money-Back Guarantee';

  @override
  String get onevpnPaywallPlanYearly => 'Yearly';

  @override
  String get onevpnPaywallPlanMonthly => 'Monthly';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'Save $percent%';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / mo';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Price unavailable';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Couldn\'t load plans. Check your connection.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Plans aren\'t available right now. Please try again later.';

  @override
  String get onevpnGetPremium => 'Get Premium';

  @override
  String get onevpnContinueFree => 'Continue Free';

  @override
  String get onevpnPaywallRetry => 'Try again';

  @override
  String get onevpnPaywallPurchaseError =>
      'Something went wrong. Please try again.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'This Google account has an active or recently ended 1VPN subscription linked to another 1VPN account. Log in to that account, or contact $support.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'This Google account already has a 1VPN subscription. If Premium does not appear, contact $support.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play did not finish your last purchase. Close any open Google Play screen and try again, or restart the app.';

  @override
  String get onevpnPaywallSupportLink => '1VPN Support';

  @override
  String get onevpnSignUp => 'Sign Up';

  @override
  String get onevpnAuthEmailLabel => 'Email';

  @override
  String get onevpnAuthPasswordLabel => 'Password';

  @override
  String get onevpnAuthTwoFactorLabel => '2FA Token';

  @override
  String get onevpnAuthForgotPassword => 'Forgot password?';

  @override
  String get onevpnAuthSubmitting => 'Loading…';

  @override
  String get onevpnAuthCreateAccount => 'Create account';

  @override
  String get onevpnAuthHaveAccount => 'Have an account?';

  @override
  String get onevpnAuthLogInInstead => 'Log in instead';

  @override
  String get onevpnAuthFieldsRequired => 'Enter email and password';

  @override
  String get onevpnAuthInvalidEmail => 'Enter a valid email address';

  @override
  String get onevpnAuthInvalidCredentials => 'Invalid credentials';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Invalid 2FA token';

  @override
  String get onevpnAuthEmailInUse => 'That email already has an account';

  @override
  String get onevpnAuthRateLimited =>
      'Too many attempts. Please try again shortly';

  @override
  String get onevpnAuthUnreachable =>
      'Couldn\'t reach the server. Check your connection and try again';

  @override
  String get onevpnAuthGenericError => 'Something went wrong. Please try again';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Your purchase is linked to this email address.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Purchase Complete';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Your purchase is linked to $email. Create an account on that address to use it.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Premium · confirming purchase';

  @override
  String get onevpnPremiumRecheck => 'Checking your purchase status…';

  @override
  String get onevpnButtonRetry => 'Retry';

  @override
  String get onevpnAppVersion => 'App version';

  @override
  String get onevpnPrivacyPolicy => 'Privacy policy';

  @override
  String get onevpnConnect => 'Connect';

  @override
  String get onevpnDisconnected => 'Disconnected';

  @override
  String get onevpnConnecting => 'Connecting…';

  @override
  String get onevpnConnected => 'Connected';

  @override
  String get onevpnDisconnecting => 'Disconnecting…';

  @override
  String get onevpnConnectionFailed => 'Connection failed';

  @override
  String get onevpnTemporarilyUnavailable => 'Temporarily unavailable';

  @override
  String get onevpnRetry => 'Retry';

  @override
  String get onevpnApplyChange => 'Apply this change?';

  @override
  String get onevpnReconnectNotice =>
      'The VPN will briefly disconnect and reconnect. This usually takes only a few seconds.';

  @override
  String onevpnWillUseName(String name) {
    return 'Will use: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Apply and reconnect';

  @override
  String get onevpnCancel => 'Cancel';

  @override
  String get onevpnContinue => 'Continue';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'Main domain is unreachable. Using backup: $domain';
  }

  @override
  String get onevpnResultFailed => 'failed';

  @override
  String get onevpnDownload => 'Download';

  @override
  String get onevpnPermissionNotGranted => 'Permission not granted';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action $result';
  }

  @override
  String get onevpnDisconnect => 'Disconnect';

  @override
  String get onevpnTimeout => 'Timeout';

  @override
  String get onevpnNoAvailableEntries => 'No available entry servers';

  @override
  String get onevpnAddServers => 'Add servers';

  @override
  String get onevpnNotEnoughServers => 'Not enough available servers';

  @override
  String get onevpnVpnFinalExit => 'VPN final exit';

  @override
  String get onevpnFinalExitEntryConflict =>
      'The final exit cannot also be the entry server';

  @override
  String get onevpnChooseNamedRoute => 'Choose one named route';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Allow access to devices and services on the local network.';

  @override
  String get onevpnSystemApprovalRequired => 'System approval required';

  @override
  String get onevpnVpnPermissionRequired =>
      'VPN permission is required. Please retry to continue.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Choose the interface used to access the network. Required on Windows / Linux only.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Andorra',
      'AE': 'United Arab Emirates',
      'AF': 'Afghanistan',
      'AG': 'Antigua & Barbuda',
      'AI': 'Anguilla',
      'AL': 'Albania',
      'AM': 'Armenia',
      'AO': 'Angola',
      'AQ': 'Antarctica',
      'AR': 'Argentina',
      'AS': 'American Samoa',
      'AT': 'Austria',
      'AU': 'Australia',
      'AW': 'Aruba',
      'AX': 'Åland Islands',
      'AZ': 'Azerbaijan',
      'BA': 'Bosnia & Herzegovina',
      'BB': 'Barbados',
      'BD': 'Bangladesh',
      'BE': 'Belgium',
      'BF': 'Burkina Faso',
      'BG': 'Bulgaria',
      'BH': 'Bahrain',
      'BI': 'Burundi',
      'BJ': 'Benin',
      'BL': 'St. Barthélemy',
      'BM': 'Bermuda',
      'BN': 'Brunei',
      'BO': 'Bolivia',
      'BQ': 'Caribbean Netherlands',
      'BR': 'Brazil',
      'BS': 'Bahamas',
      'BT': 'Bhutan',
      'BV': 'Bouvet Island',
      'BW': 'Botswana',
      'BY': 'Belarus',
      'BZ': 'Belize',
      'CA': 'Canada',
      'CC': 'Cocos (Keeling) Islands',
      'CD': 'Congo - Kinshasa',
      'CF': 'Central African Republic',
      'CG': 'Congo - Brazzaville',
      'CH': 'Switzerland',
      'CI': 'Côte d’Ivoire',
      'CK': 'Cook Islands',
      'CL': 'Chile',
      'CM': 'Cameroon',
      'CN': 'Mainland China',
      'CO': 'Colombia',
      'CR': 'Costa Rica',
      'CU': 'Cuba',
      'CV': 'Cape Verde',
      'CW': 'Curaçao',
      'CX': 'Christmas Island',
      'CY': 'Cyprus',
      'CZ': 'Czechia',
      'DE': 'Germany',
      'DJ': 'Djibouti',
      'DK': 'Denmark',
      'DM': 'Dominica',
      'DO': 'Dominican Republic',
      'DZ': 'Algeria',
      'EC': 'Ecuador',
      'EE': 'Estonia',
      'EG': 'Egypt',
      'EH': 'Western Sahara',
      'ER': 'Eritrea',
      'ES': 'Spain',
      'ET': 'Ethiopia',
      'FI': 'Finland',
      'FJ': 'Fiji',
      'FK': 'Falkland Islands',
      'FM': 'Micronesia',
      'FO': 'Faroe Islands',
      'FR': 'France',
      'GA': 'Gabon',
      'GB': 'United Kingdom',
      'GD': 'Grenada',
      'GE': 'Georgia',
      'GF': 'French Guiana',
      'GG': 'Guernsey',
      'GH': 'Ghana',
      'GI': 'Gibraltar',
      'GL': 'Greenland',
      'GM': 'Gambia',
      'GN': 'Guinea',
      'GP': 'Guadeloupe',
      'GQ': 'Equatorial Guinea',
      'GR': 'Greece',
      'GS': 'So. Georgia & So. Sandwich Isl.',
      'GT': 'Guatemala',
      'GU': 'Guam',
      'GW': 'Guinea-Bissau',
      'GY': 'Guyana',
      'HK': 'Hong Kong',
      'HM': 'Heard & McDonald Islands',
      'HN': 'Honduras',
      'HR': 'Croatia',
      'HT': 'Haiti',
      'HU': 'Hungary',
      'ID': 'Indonesia',
      'IE': 'Ireland',
      'IL': 'Israel',
      'IM': 'Isle of Man',
      'IN': 'India',
      'IO': 'Chagos Archipelago',
      'IQ': 'Iraq',
      'IR': 'Iran',
      'IS': 'Iceland',
      'IT': 'Italy',
      'JE': 'Jersey',
      'JM': 'Jamaica',
      'JO': 'Jordan',
      'JP': 'Japan',
      'KE': 'Kenya',
      'KG': 'Kyrgyzstan',
      'KH': 'Cambodia',
      'KI': 'Kiribati',
      'KM': 'Comoros',
      'KN': 'St. Kitts & Nevis',
      'KP': 'North Korea',
      'KR': 'South Korea',
      'KW': 'Kuwait',
      'KY': 'Cayman Islands',
      'KZ': 'Kazakhstan',
      'LA': 'Laos',
      'LB': 'Lebanon',
      'LC': 'St. Lucia',
      'LI': 'Liechtenstein',
      'LK': 'Sri Lanka',
      'LR': 'Liberia',
      'LS': 'Lesotho',
      'LT': 'Lithuania',
      'LU': 'Luxembourg',
      'LV': 'Latvia',
      'LY': 'Libya',
      'MA': 'Morocco',
      'MC': 'Monaco',
      'MD': 'Moldova',
      'ME': 'Montenegro',
      'MF': 'St. Martin',
      'MG': 'Madagascar',
      'MH': 'Marshall Islands',
      'MK': 'North Macedonia',
      'ML': 'Mali',
      'MM': 'Myanmar (Burma)',
      'MN': 'Mongolia',
      'MO': 'Macao',
      'MP': 'Northern Mariana Islands',
      'MQ': 'Martinique',
      'MR': 'Mauritania',
      'MS': 'Montserrat',
      'MT': 'Malta',
      'MU': 'Mauritius',
      'MV': 'Maldives',
      'MW': 'Malawi',
      'MX': 'Mexico',
      'MY': 'Malaysia',
      'MZ': 'Mozambique',
      'NA': 'Namibia',
      'NC': 'New Caledonia',
      'NE': 'Niger',
      'NF': 'Norfolk Island',
      'NG': 'Nigeria',
      'NI': 'Nicaragua',
      'NL': 'Netherlands',
      'NO': 'Norway',
      'NP': 'Nepal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'New Zealand',
      'OM': 'Oman',
      'PA': 'Panama',
      'PE': 'Peru',
      'PF': 'French Polynesia',
      'PG': 'Papua New Guinea',
      'PH': 'Philippines',
      'PK': 'Pakistan',
      'PL': 'Poland',
      'PM': 'St. Pierre & Miquelon',
      'PN': 'Pitcairn Islands',
      'PR': 'Puerto Rico',
      'PS': 'Palestinian Territories',
      'PT': 'Portugal',
      'PW': 'Palau',
      'PY': 'Paraguay',
      'QA': 'Qatar',
      'RE': 'Réunion',
      'RO': 'Romania',
      'RS': 'Serbia',
      'RU': 'Russia',
      'RW': 'Rwanda',
      'SA': 'Saudi Arabia',
      'SB': 'Solomon Islands',
      'SC': 'Seychelles',
      'SD': 'Sudan',
      'SE': 'Sweden',
      'SG': 'Singapore',
      'SH': 'St. Helena',
      'SI': 'Slovenia',
      'SJ': 'Svalbard & Jan Mayen',
      'SK': 'Slovakia',
      'SL': 'Sierra Leone',
      'SM': 'San Marino',
      'SN': 'Senegal',
      'SO': 'Somalia',
      'SR': 'Suriname',
      'SS': 'South Sudan',
      'ST': 'São Tomé & Príncipe',
      'SV': 'El Salvador',
      'SX': 'Sint Maarten',
      'SY': 'Syria',
      'SZ': 'Eswatini',
      'TC': 'Turks & Caicos Islands',
      'TD': 'Chad',
      'TF': 'French Southern Territories',
      'TG': 'Togo',
      'TH': 'Thailand',
      'TJ': 'Tajikistan',
      'TK': 'Tokelau',
      'TL': 'Timor-Leste',
      'TM': 'Turkmenistan',
      'TN': 'Tunisia',
      'TO': 'Tonga',
      'TR': 'Turkey',
      'TT': 'Trinidad & Tobago',
      'TV': 'Tuvalu',
      'TW': 'Taiwan',
      'TZ': 'Tanzania',
      'UA': 'Ukraine',
      'UG': 'Uganda',
      'UM': 'U.S. Outlying Islands',
      'US': 'United States',
      'UY': 'Uruguay',
      'UZ': 'Uzbekistan',
      'VA': 'Vatican City',
      'VC': 'St. Vincent & Grenadines',
      'VE': 'Venezuela',
      'VG': 'British Virgin Islands',
      'VI': 'U.S. Virgin Islands',
      'VN': 'Vietnam',
      'VU': 'Vanuatu',
      'WF': 'Wallis & Futuna',
      'WS': 'Samoa',
      'XK': 'Kosovo',
      'YE': 'Yemen',
      'YT': 'Mayotte',
      'ZA': 'South Africa',
      'ZM': 'Zambia',
      'ZW': 'Zimbabwe',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Privacy Choices';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Amsterdam',
      'sgp': 'Singapore',
      'lax': 'Los Angeles',
      'mel': 'Melbourne',
      'syd': 'Sydney',
      'sao': 'Sao Paulo',
      'yto': 'Toronto',
      'scl': 'Santiago',
      'cdg': 'Paris',
      'fra': 'Frankfurt',
      'del': 'Delhi',
      'bom': 'Mumbai',
      'blr': 'Bangalore',
      'tlv': 'Tel Aviv',
      'itm': 'Osaka',
      'nrt': 'Tokyo',
      'mex': 'Mexico City',
      'waw': 'Warsaw',
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
      'zrh': 'Zurich',
      'gva': 'Geneva',
      'svo': 'Moscow',
      'led': 'Saint Petersburg',
      'hel': 'Helsinki',
      'tpe': 'Taipei',
      'dxb': 'Dubai',
      'kbp': 'Kyiv',
      'ist': 'Istanbul',
      'otp': 'Bucharest',
      'los': 'Lagos',
      'pty': 'Panama City',
      'kef': 'Reykjavik',
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
      'lis': 'Lisbon',
      'lux': 'Luxembourg',
      'eze': 'Buenos Aires',
      'akl': 'Auckland',
      'yul': 'Montreal',
      'yvr': 'Vancouver',
      'den': 'Denver',
      'phx': 'Phoenix',
      'iad': 'Washington DC',
      'bos': 'Boston',
      'edi': 'Edinburgh',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'Are You Enjoying 1VPN?';

  @override
  String get onevpnYes => 'Yes';

  @override
  String get onevpnNo => 'No';

  @override
  String get onevpnLocationLocked => 'Locked, Premium only';

  @override
  String get onevpnManageSubscription => 'Manage subscription';
}
