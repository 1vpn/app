// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class OneVpnLocalizationsDe extends OneVpnLocalizations {
  OneVpnLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get onevpnFaq => 'FAQ';

  @override
  String get onevpnTermsOfService => 'Nutzungsbedingungen';

  @override
  String get onevpnMenu => 'Menü';

  @override
  String get onevpnUpgrade => 'Upgrade';

  @override
  String get onevpnUpgradeBannerTitle => 'Auf Premium upgraden';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Keine Werbung, alle Standorte & höheres Tempo';

  @override
  String get onevpnLogIn => 'Anmelden';

  @override
  String get onevpnLogOut => 'Abmelden';

  @override
  String get onevpnAccount => 'Konto';

  @override
  String get onevpnContactUs => 'Kontaktieren Sie uns';

  @override
  String get onevpnRefundPolicy => 'Erstattungsrichtlinie';

  @override
  String get onevpnSupport => 'Support';

  @override
  String get onevpnLanguage => 'Sprache';

  @override
  String get onevpnLanguageSystem => 'Systemsprache';

  @override
  String get onevpnPlanFree => 'Kostenloser Tarif';

  @override
  String get onevpnPlanPremium => 'Premium-Tarif';

  @override
  String get onevpnSelectLocation => 'Standort auswählen';

  @override
  String get onevpnDirectRegions => 'Direkte Regionen';

  @override
  String get onevpnFree => 'Kostenlos';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Kostenlos';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Automatisch · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Automatisch';

  @override
  String get onevpnStatusNoConnection => 'Keine Verbindung';

  @override
  String get onevpnStatusConnectionFailed => 'Verbindung fehlgeschlagen';

  @override
  String get onevpnStatusUpdating => 'Wird aktualisiert…';

  @override
  String get onevpnStatusMeasuring => 'Server werden getestet…';

  @override
  String get onevpnAutomaticSubtitle => 'Schnellster verfügbarer Server';

  @override
  String get onevpnLocationsLoadFailed =>
      'Ihre Standorte konnten nicht geladen werden.';

  @override
  String get onevpnLocationsUnavailable =>
      'Standorte sind derzeit nicht verfügbar.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Manche Websites funktionieren nur, wenn Sie sich aus demselben Land wie die Website verbinden. Wenn Sie eine Region auswählen, umgehen Websites aus dieser Region das VPN.';

  @override
  String onevpnSelectionReset(String location) {
    return '$location ist nicht verfügbar, 1VPN hat auf „Automatisch“ umgestellt.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'Der gewählte Standort ist nicht verfügbar, 1VPN hat auf „Automatisch“ umgestellt.';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'Wechsel zu $location fehlgeschlagen. Sie sind weiterhin mit Ihrem bisherigen Standort verbunden.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Die Änderung konnte nicht übernommen werden. Sie sind weiterhin mit Ihren bisherigen Einstellungen verbunden.';

  @override
  String get onevpnDirectRegionsOff => 'Aus (Standard)';

  @override
  String get onevpnAllViaVpnSubtitle => 'Gesamter Datenverkehr über den Tunnel';

  @override
  String get onevpnRegionChina => 'China';

  @override
  String get onevpnFirstConnectTitle =>
      'Für manche Regionen ist eine direkte Verbindung besser';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'In Ländern wie China, Russland und Iran können lokale Banking- und Zahlungs-Apps ausfallen, wenn der gesamte Datenverkehr über das VPN läuft.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN kann den Datenverkehr einer von Ihnen gewählten Region direkt leiten, außerhalb des Tunnels und über Ihre echte IP-Adresse.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Alles andere bleibt geschützt. Sie können das jederzeit ändern.';

  @override
  String get onevpnFirstConnectChooseRegion => 'Direkte Region wählen';

  @override
  String get onevpnFirstConnectDismiss => 'Nicht jetzt';

  @override
  String get onevpnCensorshipWarning =>
      'Einige Server sind in Ihrer Region möglicherweise aufgrund staatlicher Beschränkungen gesperrt. Wir arbeiten daran, dies zu beheben. Vielen Dank für Ihr Verständnis.';

  @override
  String get onevpnAlwaysOnTitle => 'Durchgehend aktives VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      'Der Tunnel bleibt aktiv, wenn Sie die App schließen. Nach einem Neustart oder App-Update stellt „Durchgehend aktives VPN“ die Verbindung automatisch wieder her.';

  @override
  String get onevpnAlwaysOnStep1 =>
      'Tippen Sie unten auf „VPN-Einstellungen öffnen“.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Suchen Sie 1VPN in der Liste. Die App erscheint dort nach Ihrer ersten Verbindung.';

  @override
  String get onevpnAlwaysOnStep3 =>
      'Tippen Sie auf das Zahnradsymbol neben 1VPN.';

  @override
  String get onevpnAlwaysOnStep4 => 'Aktivieren Sie „Durchgehend aktives VPN“.';

  @override
  String get onevpnAlwaysOnOpenSettings => 'VPN-Einstellungen öffnen';

  @override
  String get onevpnPaywallTitle => 'Wählen Sie Ihren Tarif';

  @override
  String get onevpnPaywallBenefitLocations =>
      'Alle Serverstandorte freischalten';

  @override
  String get onevpnPaywallBenefitNoAds => 'Keine Werbung';

  @override
  String get onevpnPaywallBenefitSpeed => 'Schnellere Servergeschwindigkeit';

  @override
  String get onevpnPaywallBenefitP2p => 'BitTorrent-Unterstützung (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack => '10-Tage-Geld-zurück-Garantie';

  @override
  String get onevpnPaywallPlanYearly => 'Jährlich';

  @override
  String get onevpnPaywallPlanMonthly => 'Monatlich';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '$percent % sparen';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / Monat';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Preis nicht verfügbar';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Tarife konnten nicht geladen werden. Überprüfen Sie Ihre Verbindung.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Tarife sind derzeit nicht verfügbar. Bitte versuchen Sie es später erneut.';

  @override
  String get onevpnGetPremium => 'Premium erhalten';

  @override
  String get onevpnContinueFree => 'Kostenlos fortfahren';

  @override
  String get onevpnPaywallRetry => 'Erneut versuchen';

  @override
  String get onevpnPaywallPurchaseError =>
      'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'Dieses Google-Konto hat ein aktives oder kürzlich beendetes 1VPN-Abo, das mit einem anderen 1VPN-Konto verknüpft ist. Melden Sie sich bei diesem Konto an oder kontaktieren Sie den $support.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'Dieses Google-Konto hat bereits ein 1VPN-Abo. Wenn Premium nicht angezeigt wird, kontaktieren Sie den $support.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play hat Ihren letzten Kauf nicht abgeschlossen. Schließen Sie alle geöffneten Google-Play-Fenster und versuchen Sie es erneut oder starten Sie die App neu.';

  @override
  String get onevpnPaywallSupportLink => '1VPN-Support';

  @override
  String get onevpnSignUp => 'Registrieren';

  @override
  String get onevpnAuthEmailLabel => 'E-Mail';

  @override
  String get onevpnAuthPasswordLabel => 'Passwort';

  @override
  String get onevpnAuthTwoFactorLabel => '2FA-Code';

  @override
  String get onevpnAuthForgotPassword => 'Passwort vergessen?';

  @override
  String get onevpnAuthSubmitting => 'Wird geladen…';

  @override
  String get onevpnAuthCreateAccount => 'Konto erstellen';

  @override
  String get onevpnAuthHaveAccount => 'Bereits ein Konto?';

  @override
  String get onevpnAuthLogInInstead => 'Stattdessen anmelden';

  @override
  String get onevpnAuthFieldsRequired =>
      'Geben Sie Ihre E-Mail-Adresse und Ihr Passwort ein';

  @override
  String get onevpnAuthInvalidEmail =>
      'Geben Sie eine gültige E-Mail-Adresse ein';

  @override
  String get onevpnAuthInvalidCredentials => 'Ungültige Anmeldedaten';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Ungültiger 2FA-Code';

  @override
  String get onevpnAuthEmailInUse =>
      'Für diese E-Mail-Adresse besteht bereits ein Konto';

  @override
  String get onevpnAuthRateLimited =>
      'Zu viele Versuche. Bitte warten Sie kurz und versuchen Sie es erneut';

  @override
  String get onevpnAuthUnreachable =>
      'Der Server ist nicht erreichbar. Überprüfen Sie Ihre Verbindung und versuchen Sie es erneut';

  @override
  String get onevpnAuthGenericError =>
      'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Ihr Kauf ist mit dieser E-Mail-Adresse verknüpft.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Kauf abgeschlossen';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Ihr Kauf ist mit $email verknüpft. Erstellen Sie mit dieser Adresse ein Konto, um ihn zu nutzen.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Premium · Kauf wird bestätigt';

  @override
  String get onevpnPremiumRecheck => 'Kaufstatus wird geprüft…';

  @override
  String get onevpnButtonRetry => 'Erneut versuchen';

  @override
  String get onevpnAppVersion => 'App-Version';

  @override
  String get onevpnPrivacyPolicy => 'Datenschutzerklärung';

  @override
  String get onevpnConnect => 'Verbinden';

  @override
  String get onevpnDisconnected => 'Getrennt';

  @override
  String get onevpnConnecting => 'Wird verbunden…';

  @override
  String get onevpnConnected => 'Verbunden';

  @override
  String get onevpnDisconnecting => 'Verbindung wird getrennt…';

  @override
  String get onevpnConnectionFailed => 'Verbindung fehlgeschlagen';

  @override
  String get onevpnTemporarilyUnavailable => 'Vorübergehend nicht verfügbar';

  @override
  String get onevpnRetry => 'Erneut versuchen';

  @override
  String get onevpnApplyChange => 'Diese Änderung übernehmen?';

  @override
  String get onevpnReconnectNotice =>
      'Das VPN wird kurz getrennt und neu verbunden. Das dauert meist nur wenige Sekunden.';

  @override
  String onevpnWillUseName(String name) {
    return 'Wird verwendet: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Übernehmen und neu verbinden';

  @override
  String get onevpnCancel => 'Abbrechen';

  @override
  String get onevpnContinue => 'Fortfahren';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'Hauptdomain ist blockiert. Backup wird verwendet: $domain';
  }

  @override
  String get onevpnResultFailed => 'fehlgeschlagen';

  @override
  String get onevpnDownload => 'Herunterladen';

  @override
  String get onevpnPermissionNotGranted => 'Berechtigung nicht erteilt';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action $result';
  }

  @override
  String get onevpnDisconnect => 'Trennen';

  @override
  String get onevpnTimeout => 'Zeitüberschreitung';

  @override
  String get onevpnNoAvailableEntries => 'Keine verfügbaren Einstiegsserver';

  @override
  String get onevpnAddServers => 'Server hinzufügen';

  @override
  String get onevpnNotEnoughServers => 'Nicht genügend verfügbare Server';

  @override
  String get onevpnVpnFinalExit => 'Letzter VPN-Ausgangsserver';

  @override
  String get onevpnFinalExitEntryConflict =>
      'Der letzte Ausgangsserver kann nicht zugleich der Einstiegsserver sein';

  @override
  String get onevpnChooseNamedRoute => 'Wählen Sie genau eine benannte Route';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Erlauben Sie den Zugriff auf Geräte und Dienste im lokalen Netzwerk.';

  @override
  String get onevpnSystemApprovalRequired => 'Systemfreigabe erforderlich';

  @override
  String get onevpnVpnPermissionRequired =>
      'Die VPN-Berechtigung ist erforderlich. Bitte versuchen Sie es erneut, um fortzufahren.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Wählen Sie die Schnittstelle für den Netzwerkzugriff. Nur unter Windows / Linux erforderlich.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Andorra',
      'AE': 'Vereinigte Arabische Emirate',
      'AF': 'Afghanistan',
      'AG': 'Antigua und Barbuda',
      'AI': 'Anguilla',
      'AL': 'Albanien',
      'AM': 'Armenien',
      'AO': 'Angola',
      'AQ': 'Antarktis',
      'AR': 'Argentinien',
      'AS': 'Amerikanisch-Samoa',
      'AT': 'Österreich',
      'AU': 'Australien',
      'AW': 'Aruba',
      'AX': 'Ålandinseln',
      'AZ': 'Aserbaidschan',
      'BA': 'Bosnien und Herzegowina',
      'BB': 'Barbados',
      'BD': 'Bangladesch',
      'BE': 'Belgien',
      'BF': 'Burkina Faso',
      'BG': 'Bulgarien',
      'BH': 'Bahrain',
      'BI': 'Burundi',
      'BJ': 'Benin',
      'BL': 'St. Barthélemy',
      'BM': 'Bermuda',
      'BN': 'Brunei',
      'BO': 'Bolivien',
      'BQ': 'Karibische Niederlande',
      'BR': 'Brasilien',
      'BS': 'Bahamas',
      'BT': 'Bhutan',
      'BV': 'Bouvetinsel',
      'BW': 'Botsuana',
      'BY': 'Belarus',
      'BZ': 'Belize',
      'CA': 'Kanada',
      'CC': 'Kokosinseln',
      'CD': 'Kongo-Kinshasa',
      'CF': 'Zentralafrikanische Republik',
      'CG': 'Kongo-Brazzaville',
      'CH': 'Schweiz',
      'CI': 'Côte d’Ivoire',
      'CK': 'Cookinseln',
      'CL': 'Chile',
      'CM': 'Kamerun',
      'CN': 'Festlandchina',
      'CO': 'Kolumbien',
      'CR': 'Costa Rica',
      'CU': 'Kuba',
      'CV': 'Cabo Verde',
      'CW': 'Curaçao',
      'CX': 'Weihnachtsinsel',
      'CY': 'Zypern',
      'CZ': 'Tschechien',
      'DE': 'Deutschland',
      'DJ': 'Dschibuti',
      'DK': 'Dänemark',
      'DM': 'Dominica',
      'DO': 'Dominikanische Republik',
      'DZ': 'Algerien',
      'EC': 'Ecuador',
      'EE': 'Estland',
      'EG': 'Ägypten',
      'EH': 'Westsahara',
      'ER': 'Eritrea',
      'ES': 'Spanien',
      'ET': 'Äthiopien',
      'FI': 'Finnland',
      'FJ': 'Fidschi',
      'FK': 'Falklandinseln',
      'FM': 'Mikronesien',
      'FO': 'Färöer',
      'FR': 'Frankreich',
      'GA': 'Gabun',
      'GB': 'Vereinigtes Königreich',
      'GD': 'Grenada',
      'GE': 'Georgien',
      'GF': 'Französisch-Guayana',
      'GG': 'Guernsey',
      'GH': 'Ghana',
      'GI': 'Gibraltar',
      'GL': 'Grönland',
      'GM': 'Gambia',
      'GN': 'Guinea',
      'GP': 'Guadeloupe',
      'GQ': 'Äquatorialguinea',
      'GR': 'Griechenland',
      'GS': 'Südgeorgien und Südl. Sandwichinseln',
      'GT': 'Guatemala',
      'GU': 'Guam',
      'GW': 'Guinea-Bissau',
      'GY': 'Guyana',
      'HK': 'Hongkong',
      'HM': 'Heard und McDonaldinseln',
      'HN': 'Honduras',
      'HR': 'Kroatien',
      'HT': 'Haiti',
      'HU': 'Ungarn',
      'ID': 'Indonesien',
      'IE': 'Irland',
      'IL': 'Israel',
      'IM': 'Isle of Man',
      'IN': 'Indien',
      'IO': 'Chagos-Archipel',
      'IQ': 'Irak',
      'IR': 'Iran',
      'IS': 'Island',
      'IT': 'Italien',
      'JE': 'Jersey',
      'JM': 'Jamaika',
      'JO': 'Jordanien',
      'JP': 'Japan',
      'KE': 'Kenia',
      'KG': 'Kirgisistan',
      'KH': 'Kambodscha',
      'KI': 'Kiribati',
      'KM': 'Komoren',
      'KN': 'St. Kitts und Nevis',
      'KP': 'Nordkorea',
      'KR': 'Südkorea',
      'KW': 'Kuwait',
      'KY': 'Kaimaninseln',
      'KZ': 'Kasachstan',
      'LA': 'Laos',
      'LB': 'Libanon',
      'LC': 'St. Lucia',
      'LI': 'Liechtenstein',
      'LK': 'Sri Lanka',
      'LR': 'Liberia',
      'LS': 'Lesotho',
      'LT': 'Litauen',
      'LU': 'Luxemburg',
      'LV': 'Lettland',
      'LY': 'Libyen',
      'MA': 'Marokko',
      'MC': 'Monaco',
      'MD': 'Moldau',
      'ME': 'Montenegro',
      'MF': 'St. Martin',
      'MG': 'Madagaskar',
      'MH': 'Marshallinseln',
      'MK': 'Nordmazedonien',
      'ML': 'Mali',
      'MM': 'Myanmar',
      'MN': 'Mongolei',
      'MO': 'Macau',
      'MP': 'Nördliche Marianen',
      'MQ': 'Martinique',
      'MR': 'Mauretanien',
      'MS': 'Montserrat',
      'MT': 'Malta',
      'MU': 'Mauritius',
      'MV': 'Malediven',
      'MW': 'Malawi',
      'MX': 'Mexiko',
      'MY': 'Malaysia',
      'MZ': 'Mosambik',
      'NA': 'Namibia',
      'NC': 'Neukaledonien',
      'NE': 'Niger',
      'NF': 'Norfolkinsel',
      'NG': 'Nigeria',
      'NI': 'Nicaragua',
      'NL': 'Niederlande',
      'NO': 'Norwegen',
      'NP': 'Nepal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'Neuseeland',
      'OM': 'Oman',
      'PA': 'Panama',
      'PE': 'Peru',
      'PF': 'Französisch-Polynesien',
      'PG': 'Papua-Neuguinea',
      'PH': 'Philippinen',
      'PK': 'Pakistan',
      'PL': 'Polen',
      'PM': 'St. Pierre und Miquelon',
      'PN': 'Pitcairninseln',
      'PR': 'Puerto Rico',
      'PS': 'Palästinensische Autonomiegebiete',
      'PT': 'Portugal',
      'PW': 'Palau',
      'PY': 'Paraguay',
      'QA': 'Katar',
      'RE': 'Réunion',
      'RO': 'Rumänien',
      'RS': 'Serbien',
      'RU': 'Russland',
      'RW': 'Ruanda',
      'SA': 'Saudi-Arabien',
      'SB': 'Salomonen',
      'SC': 'Seychellen',
      'SD': 'Sudan',
      'SE': 'Schweden',
      'SG': 'Singapur',
      'SH': 'St. Helena',
      'SI': 'Slowenien',
      'SJ': 'Spitzbergen und Jan Mayen',
      'SK': 'Slowakei',
      'SL': 'Sierra Leone',
      'SM': 'San Marino',
      'SN': 'Senegal',
      'SO': 'Somalia',
      'SR': 'Suriname',
      'SS': 'Südsudan',
      'ST': 'São Tomé und Príncipe',
      'SV': 'El Salvador',
      'SX': 'Sint Maarten',
      'SY': 'Syrien',
      'SZ': 'Eswatini',
      'TC': 'Turks- und Caicosinseln',
      'TD': 'Tschad',
      'TF': 'Französische Süd- und Antarktisgebiete',
      'TG': 'Togo',
      'TH': 'Thailand',
      'TJ': 'Tadschikistan',
      'TK': 'Tokelau',
      'TL': 'Timor-Leste',
      'TM': 'Turkmenistan',
      'TN': 'Tunesien',
      'TO': 'Tonga',
      'TR': 'Türkei',
      'TT': 'Trinidad und Tobago',
      'TV': 'Tuvalu',
      'TW': 'Taiwan',
      'TZ': 'Tansania',
      'UA': 'Ukraine',
      'UG': 'Uganda',
      'UM': 'Amerikanische Überseeinseln',
      'US': 'Vereinigte Staaten',
      'UY': 'Uruguay',
      'UZ': 'Usbekistan',
      'VA': 'Vatikanstadt',
      'VC': 'St. Vincent und die Grenadinen',
      'VE': 'Venezuela',
      'VG': 'Britische Jungferninseln',
      'VI': 'Amerikanische Jungferninseln',
      'VN': 'Vietnam',
      'VU': 'Vanuatu',
      'WF': 'Wallis und Futuna',
      'WS': 'Samoa',
      'XK': 'Kosovo',
      'YE': 'Jemen',
      'YT': 'Mayotte',
      'ZA': 'Südafrika',
      'ZM': 'Sambia',
      'ZW': 'Simbabwe',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Datenschutzoptionen';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Amsterdam',
      'sgp': 'Singapur',
      'lax': 'Los Angeles',
      'mel': 'Melbourne',
      'syd': 'Sydney',
      'sao': 'São Paulo',
      'yto': 'Toronto',
      'scl': 'Santiago',
      'cdg': 'Paris',
      'fra': 'Frankfurt',
      'del': 'Neu-Delhi',
      'bom': 'Mumbai',
      'blr': 'Bangalore',
      'tlv': 'Tel Aviv',
      'itm': 'Osaka',
      'nrt': 'Tokio',
      'mex': 'Mexiko-Stadt',
      'waw': 'Warschau',
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
      'hkg': 'Hongkong',
      'zrh': 'Zürich',
      'gva': 'Genf',
      'svo': 'Moskau',
      'led': 'Sankt Petersburg',
      'hel': 'Helsinki',
      'tpe': 'Taipeh',
      'dxb': 'Dubai',
      'kbp': 'Kyjiw',
      'ist': 'Istanbul',
      'otp': 'Bukarest',
      'los': 'Lagos',
      'pty': 'Panama-Stadt',
      'kef': 'Reykjavík',
      'ber': 'Berlin',
      'ala': 'Almaty',
      'tbs': 'Tiflis',
      'kul': 'Kuala Lumpur',
      'bkk': 'Bangkok',
      'cgk': 'Jakarta',
      'mnl': 'Manila',
      'nbo': 'Nairobi',
      'mxp': 'Mailand',
      'dub': 'Dublin',
      'lis': 'Lissabon',
      'lux': 'Luxemburg',
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
  String get onevpnEnjoyingQuestion => 'Gefällt Ihnen 1VPN?';

  @override
  String get onevpnYes => 'Ja';

  @override
  String get onevpnNo => 'Nein';

  @override
  String get onevpnLocationLocked => 'Gesperrt, nur Premium';

  @override
  String get onevpnManageSubscription => 'Abo verwalten';
}
