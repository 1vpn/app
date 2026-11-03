// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class OneVpnLocalizationsIt extends OneVpnLocalizations {
  OneVpnLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get onevpnFaq => 'Domande frequenti';

  @override
  String get onevpnTermsOfService => 'Termini di servizio';

  @override
  String get onevpnMenu => 'Menu';

  @override
  String get onevpnUpgrade => 'Passa a Premium';

  @override
  String get onevpnUpgradeBannerTitle => 'Passa a Premium';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Nessuna pubblicità, tutte le posizioni e velocità più elevate';

  @override
  String get onevpnLogIn => 'Accedi';

  @override
  String get onevpnLogOut => 'Esci';

  @override
  String get onevpnAccount => 'Account';

  @override
  String get onevpnContactUs => 'Contattaci';

  @override
  String get onevpnRefundPolicy => 'Politica di rimborso';

  @override
  String get onevpnSupport => 'Assistenza';

  @override
  String get onevpnLanguage => 'Lingua';

  @override
  String get onevpnLanguageSystem => 'Predefinita di sistema';

  @override
  String get onevpnPlanFree => 'Piano gratuito';

  @override
  String get onevpnPlanPremium => 'Piano Premium';

  @override
  String get onevpnSelectLocation => 'Seleziona posizione';

  @override
  String get onevpnDirectRegions => 'Regioni ad accesso diretto';

  @override
  String get onevpnFree => 'Gratuito';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Gratuito';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Automatico · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Automatico';

  @override
  String get onevpnStatusNoConnection => 'Nessuna connessione';

  @override
  String get onevpnStatusConnectionFailed => 'Connessione non riuscita';

  @override
  String get onevpnStatusUpdating => 'Aggiornamento…';

  @override
  String get onevpnStatusMeasuring => 'Misurazione dei server…';

  @override
  String get onevpnAutomaticSubtitle => 'Il più veloce disponibile';

  @override
  String get onevpnLocationsLoadFailed =>
      'Impossibile caricare le tue posizioni.';

  @override
  String get onevpnLocationsUnavailable =>
      'Posizioni al momento non disponibili.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Alcuni siti funzionano solo se ti connetti dallo stesso Paese del sito. Se selezioni una regione, i siti di quella regione non passano attraverso la VPN.';

  @override
  String onevpnSelectionReset(String location) {
    return '$location non è disponibile, 1VPN è passato ad «Automatico».';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'La posizione scelta non è disponibile, 1VPN è passato ad «Automatico».';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'Impossibile passare a $location. Sei ancora connesso alla posizione precedente.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Impossibile applicare la modifica. Sei ancora connesso con le impostazioni precedenti.';

  @override
  String get onevpnDirectRegionsOff => 'Disattivato (predefinito)';

  @override
  String get onevpnAllViaVpnSubtitle =>
      'Tutto il traffico attraverso il tunnel';

  @override
  String get onevpnRegionChina => 'Cina';

  @override
  String get onevpnFirstConnectTitle =>
      'Alcune regioni funzionano meglio con accesso diretto';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'In Paesi come Cina, Russia e Iran, inviare tutto il traffico tramite la VPN può impedire il funzionamento delle app bancarie e di pagamento locali.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN può instradare direttamente una regione a tua scelta, fuori dal tunnel, usando il tuo IP reale.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Tutto il resto rimane protetto. Puoi modificare questa impostazione in qualsiasi momento.';

  @override
  String get onevpnFirstConnectChooseRegion =>
      'Scegli regione ad accesso diretto';

  @override
  String get onevpnFirstConnectDismiss => 'Non ora';

  @override
  String get onevpnCensorshipWarning =>
      'Alcuni server potrebbero essere bloccati nella tua regione a causa di restrizioni governative. Stiamo lavorando per risolvere questo problema. Grazie per la comprensione.';

  @override
  String get onevpnAlwaysOnTitle => 'VPN sempre attiva';

  @override
  String get onevpnAlwaysOnIntro =>
      'Il tunnel resta attivo quando chiudi l\'app. Dopo un riavvio o un aggiornamento dell\'app, «VPN sempre attiva» lo riconnette automaticamente.';

  @override
  String get onevpnAlwaysOnStep1 => 'Tocca «Apri impostazioni VPN» qui sotto.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Trova 1VPN nell\'elenco. Compare dopo la tua prima connessione.';

  @override
  String get onevpnAlwaysOnStep3 =>
      'Tocca l\'icona a forma di ingranaggio accanto a 1VPN.';

  @override
  String get onevpnAlwaysOnStep4 => 'Attiva «VPN sempre attiva».';

  @override
  String get onevpnAlwaysOnOpenSettings => 'Apri impostazioni VPN';

  @override
  String get onevpnPaywallTitle => 'Scegli il tuo piano';

  @override
  String get onevpnPaywallBenefitLocations =>
      'Sblocca tutte le posizioni dei server';

  @override
  String get onevpnPaywallBenefitNoAds => 'Nessuna pubblicità';

  @override
  String get onevpnPaywallBenefitSpeed => 'Velocità server più rapide';

  @override
  String get onevpnPaywallBenefitP2p => 'Supporto BitTorrent (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack =>
      'Garanzia di rimborso di 10 giorni';

  @override
  String get onevpnPaywallPlanYearly => 'Annuale';

  @override
  String get onevpnPaywallPlanMonthly => 'Mensile';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'Risparmia il $percent%';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / mese';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Prezzo non disponibile';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Impossibile caricare i piani. Controlla la connessione.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'I piani non sono disponibili al momento. Riprova più tardi.';

  @override
  String get onevpnGetPremium => 'Ottieni Premium';

  @override
  String get onevpnContinueFree => 'Continua gratuitamente';

  @override
  String get onevpnPaywallRetry => 'Riprova';

  @override
  String get onevpnPaywallPurchaseError =>
      'Si è verificato un problema. Riprova.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'Questo account Google ha un abbonamento 1VPN attivo o terminato di recente, collegato a un altro account 1VPN. Accedi a quell\'account o contatta l\'$support.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'Questo account Google ha già un abbonamento 1VPN. Se Premium non compare, contatta l\'$support.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play non ha completato il tuo ultimo acquisto. Chiudi le schermate di Google Play aperte e riprova, oppure riavvia l\'app.';

  @override
  String get onevpnPaywallSupportLink => 'assistenza 1VPN';

  @override
  String get onevpnSignUp => 'Registrati';

  @override
  String get onevpnAuthEmailLabel => 'Email';

  @override
  String get onevpnAuthPasswordLabel => 'Password';

  @override
  String get onevpnAuthTwoFactorLabel => 'Token 2FA';

  @override
  String get onevpnAuthForgotPassword => 'Password dimenticata?';

  @override
  String get onevpnAuthSubmitting => 'Caricamento…';

  @override
  String get onevpnAuthCreateAccount => 'Crea account';

  @override
  String get onevpnAuthHaveAccount => 'Hai già un account?';

  @override
  String get onevpnAuthLogInInstead => 'Accedi invece di registrarti';

  @override
  String get onevpnAuthFieldsRequired => 'Inserisci email e password';

  @override
  String get onevpnAuthInvalidEmail => 'Inserisci un indirizzo email valido';

  @override
  String get onevpnAuthInvalidCredentials => 'Credenziali non valide';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Token 2FA non valido';

  @override
  String get onevpnAuthEmailInUse => 'Esiste già un account con questa email';

  @override
  String get onevpnAuthRateLimited => 'Troppi tentativi. Riprova tra poco';

  @override
  String get onevpnAuthUnreachable =>
      'Impossibile raggiungere il server. Controlla la connessione e riprova';

  @override
  String get onevpnAuthGenericError => 'Si è verificato un problema. Riprova';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Il tuo acquisto è collegato a questo indirizzo email.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Acquisto completato';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Il tuo acquisto è collegato a $email. Crea un account con questo indirizzo per utilizzarlo.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Premium · conferma acquisto in corso';

  @override
  String get onevpnPremiumRecheck => 'Verifica dello stato dell\'acquisto…';

  @override
  String get onevpnButtonRetry => 'Riprova';

  @override
  String get onevpnAppVersion => 'Versione app';

  @override
  String get onevpnPrivacyPolicy => 'Informativa sulla privacy';

  @override
  String get onevpnConnect => 'Connetti';

  @override
  String get onevpnDisconnected => 'Disconnesso';

  @override
  String get onevpnConnecting => 'Connessione in corso…';

  @override
  String get onevpnConnected => 'Connesso';

  @override
  String get onevpnDisconnecting => 'Disconnessione in corso…';

  @override
  String get onevpnConnectionFailed => 'Connessione non riuscita';

  @override
  String get onevpnTemporarilyUnavailable => 'Temporaneamente non disponibile';

  @override
  String get onevpnRetry => 'Riprova';

  @override
  String get onevpnApplyChange => 'Applicare questa modifica?';

  @override
  String get onevpnReconnectNotice =>
      'La VPN si disconnetterà e si riconnetterà brevemente. Di solito bastano pochi secondi.';

  @override
  String onevpnWillUseName(String name) {
    return 'Verrà usato: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Applica e riconnetti';

  @override
  String get onevpnCancel => 'Annulla';

  @override
  String get onevpnContinue => 'Continua';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'Il dominio principale è bloccato. In uso il dominio di riserva: $domain';
  }

  @override
  String get onevpnResultFailed => 'non riuscito';

  @override
  String get onevpnDownload => 'Download';

  @override
  String get onevpnPermissionNotGranted => 'Autorizzazione non concessa';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action: $result';
  }

  @override
  String get onevpnDisconnect => 'Disconnetti';

  @override
  String get onevpnTimeout => 'Timeout';

  @override
  String get onevpnNoAvailableEntries =>
      'Nessun server di ingresso disponibile';

  @override
  String get onevpnAddServers => 'Aggiungi server';

  @override
  String get onevpnNotEnoughServers => 'Server disponibili insufficienti';

  @override
  String get onevpnVpnFinalExit => 'Uscita finale VPN';

  @override
  String get onevpnFinalExitEntryConflict =>
      'L\'uscita finale non può essere anche il server di ingresso';

  @override
  String get onevpnChooseNamedRoute => 'Scegli un percorso con nome';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Consenti l\'accesso a dispositivi e servizi sulla rete locale.';

  @override
  String get onevpnSystemApprovalRequired =>
      'È richiesta l\'approvazione del sistema';

  @override
  String get onevpnVpnPermissionRequired =>
      'È necessaria l\'autorizzazione VPN. Riprova per continuare.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Scegli l\'interfaccia usata per accedere alla rete. Necessaria solo su Windows / Linux.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Andorra',
      'AE': 'Emirati Arabi Uniti',
      'AF': 'Afghanistan',
      'AG': 'Antigua e Barbuda',
      'AI': 'Anguilla',
      'AL': 'Albania',
      'AM': 'Armenia',
      'AO': 'Angola',
      'AQ': 'Antartide',
      'AR': 'Argentina',
      'AS': 'Samoa Americane',
      'AT': 'Austria',
      'AU': 'Australia',
      'AW': 'Aruba',
      'AX': 'Isole Åland',
      'AZ': 'Azerbaigian',
      'BA': 'Bosnia ed Erzegovina',
      'BB': 'Barbados',
      'BD': 'Bangladesh',
      'BE': 'Belgio',
      'BF': 'Burkina Faso',
      'BG': 'Bulgaria',
      'BH': 'Bahrein',
      'BI': 'Burundi',
      'BJ': 'Benin',
      'BL': 'Saint-Barthélemy',
      'BM': 'Bermuda',
      'BN': 'Brunei',
      'BO': 'Bolivia',
      'BQ': 'Caraibi olandesi',
      'BR': 'Brasile',
      'BS': 'Bahamas',
      'BT': 'Bhutan',
      'BV': 'Isola Bouvet',
      'BW': 'Botswana',
      'BY': 'Bielorussia',
      'BZ': 'Belize',
      'CA': 'Canada',
      'CC': 'Isole Cocos (Keeling)',
      'CD': 'Congo-Kinshasa',
      'CF': 'Repubblica Centrafricana',
      'CG': 'Congo-Brazzaville',
      'CH': 'Svizzera',
      'CI': 'Costa d\'Avorio',
      'CK': 'Isole Cook',
      'CL': 'Cile',
      'CM': 'Camerun',
      'CN': 'Cina continentale',
      'CO': 'Colombia',
      'CR': 'Costa Rica',
      'CU': 'Cuba',
      'CV': 'Capo Verde',
      'CW': 'Curaçao',
      'CX': 'Isola Christmas',
      'CY': 'Cipro',
      'CZ': 'Cechia',
      'DE': 'Germania',
      'DJ': 'Gibuti',
      'DK': 'Danimarca',
      'DM': 'Dominica',
      'DO': 'Repubblica Dominicana',
      'DZ': 'Algeria',
      'EC': 'Ecuador',
      'EE': 'Estonia',
      'EG': 'Egitto',
      'EH': 'Sahara occidentale',
      'ER': 'Eritrea',
      'ES': 'Spagna',
      'ET': 'Etiopia',
      'FI': 'Finlandia',
      'FJ': 'Figi',
      'FK': 'Isole Falkland',
      'FM': 'Micronesia',
      'FO': 'Isole Fær Øer',
      'FR': 'Francia',
      'GA': 'Gabon',
      'GB': 'Regno Unito',
      'GD': 'Grenada',
      'GE': 'Georgia',
      'GF': 'Guyana Francese',
      'GG': 'Guernsey',
      'GH': 'Ghana',
      'GI': 'Gibilterra',
      'GL': 'Groenlandia',
      'GM': 'Gambia',
      'GN': 'Guinea',
      'GP': 'Guadalupa',
      'GQ': 'Guinea Equatoriale',
      'GR': 'Grecia',
      'GS': 'Georgia del Sud e Sandwich Australi',
      'GT': 'Guatemala',
      'GU': 'Guam',
      'GW': 'Guinea-Bissau',
      'GY': 'Guyana',
      'HK': 'Hong Kong',
      'HM': 'Isole Heard e McDonald',
      'HN': 'Honduras',
      'HR': 'Croazia',
      'HT': 'Haiti',
      'HU': 'Ungheria',
      'ID': 'Indonesia',
      'IE': 'Irlanda',
      'IL': 'Israele',
      'IM': 'Isola di Man',
      'IN': 'India',
      'IO': 'Isole Chagos',
      'IQ': 'Iraq',
      'IR': 'Iran',
      'IS': 'Islanda',
      'IT': 'Italia',
      'JE': 'Jersey',
      'JM': 'Giamaica',
      'JO': 'Giordania',
      'JP': 'Giappone',
      'KE': 'Kenya',
      'KG': 'Kirghizistan',
      'KH': 'Cambogia',
      'KI': 'Kiribati',
      'KM': 'Comore',
      'KN': 'Saint Kitts e Nevis',
      'KP': 'Corea del Nord',
      'KR': 'Corea del Sud',
      'KW': 'Kuwait',
      'KY': 'Isole Cayman',
      'KZ': 'Kazakistan',
      'LA': 'Laos',
      'LB': 'Libano',
      'LC': 'Saint Lucia',
      'LI': 'Liechtenstein',
      'LK': 'Sri Lanka',
      'LR': 'Liberia',
      'LS': 'Lesotho',
      'LT': 'Lituania',
      'LU': 'Lussemburgo',
      'LV': 'Lettonia',
      'LY': 'Libia',
      'MA': 'Marocco',
      'MC': 'Monaco',
      'MD': 'Moldavia',
      'ME': 'Montenegro',
      'MF': 'Saint Martin',
      'MG': 'Madagascar',
      'MH': 'Isole Marshall',
      'MK': 'Macedonia del Nord',
      'ML': 'Mali',
      'MM': 'Myanmar (Birmania)',
      'MN': 'Mongolia',
      'MO': 'Macao',
      'MP': 'Isole Marianne Settentrionali',
      'MQ': 'Martinica',
      'MR': 'Mauritania',
      'MS': 'Montserrat',
      'MT': 'Malta',
      'MU': 'Mauritius',
      'MV': 'Maldive',
      'MW': 'Malawi',
      'MX': 'Messico',
      'MY': 'Malaysia',
      'MZ': 'Mozambico',
      'NA': 'Namibia',
      'NC': 'Nuova Caledonia',
      'NE': 'Niger',
      'NF': 'Isola Norfolk',
      'NG': 'Nigeria',
      'NI': 'Nicaragua',
      'NL': 'Paesi Bassi',
      'NO': 'Norvegia',
      'NP': 'Nepal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'Nuova Zelanda',
      'OM': 'Oman',
      'PA': 'Panama',
      'PE': 'Perù',
      'PF': 'Polinesia Francese',
      'PG': 'Papua Nuova Guinea',
      'PH': 'Filippine',
      'PK': 'Pakistan',
      'PL': 'Polonia',
      'PM': 'Saint-Pierre e Miquelon',
      'PN': 'Isole Pitcairn',
      'PR': 'Portorico',
      'PS': 'Territori palestinesi',
      'PT': 'Portogallo',
      'PW': 'Palau',
      'PY': 'Paraguay',
      'QA': 'Qatar',
      'RE': 'Riunione',
      'RO': 'Romania',
      'RS': 'Serbia',
      'RU': 'Russia',
      'RW': 'Ruanda',
      'SA': 'Arabia Saudita',
      'SB': 'Isole Salomone',
      'SC': 'Seychelles',
      'SD': 'Sudan',
      'SE': 'Svezia',
      'SG': 'Singapore',
      'SH': 'Sant\'Elena',
      'SI': 'Slovenia',
      'SJ': 'Svalbard e Jan Mayen',
      'SK': 'Slovacchia',
      'SL': 'Sierra Leone',
      'SM': 'San Marino',
      'SN': 'Senegal',
      'SO': 'Somalia',
      'SR': 'Suriname',
      'SS': 'Sud Sudan',
      'ST': 'São Tomé e Príncipe',
      'SV': 'El Salvador',
      'SX': 'Sint Maarten',
      'SY': 'Siria',
      'SZ': 'Eswatini',
      'TC': 'Isole Turks e Caicos',
      'TD': 'Ciad',
      'TF': 'Terre Australi Francesi',
      'TG': 'Togo',
      'TH': 'Thailandia',
      'TJ': 'Tagikistan',
      'TK': 'Tokelau',
      'TL': 'Timor Est',
      'TM': 'Turkmenistan',
      'TN': 'Tunisia',
      'TO': 'Tonga',
      'TR': 'Turchia',
      'TT': 'Trinidad e Tobago',
      'TV': 'Tuvalu',
      'TW': 'Taiwan',
      'TZ': 'Tanzania',
      'UA': 'Ucraina',
      'UG': 'Uganda',
      'UM': 'Altre isole americane del Pacifico',
      'US': 'Stati Uniti',
      'UY': 'Uruguay',
      'UZ': 'Uzbekistan',
      'VA': 'Città del Vaticano',
      'VC': 'Saint Vincent e Grenadine',
      'VE': 'Venezuela',
      'VG': 'Isole Vergini Britanniche',
      'VI': 'Isole Vergini Americane',
      'VN': 'Vietnam',
      'VU': 'Vanuatu',
      'WF': 'Wallis e Futuna',
      'WS': 'Samoa',
      'XK': 'Kosovo',
      'YE': 'Yemen',
      'YT': 'Mayotte',
      'ZA': 'Sudafrica',
      'ZM': 'Zambia',
      'ZW': 'Zimbabwe',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Scelte sulla privacy';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Amsterdam',
      'sgp': 'Singapore',
      'lax': 'Los Angeles',
      'mel': 'Melbourne',
      'syd': 'Sydney',
      'sao': 'San Paolo',
      'yto': 'Toronto',
      'scl': 'Santiago',
      'cdg': 'Parigi',
      'fra': 'Francoforte',
      'del': 'Nuova Delhi',
      'bom': 'Mumbai',
      'blr': 'Bangalore',
      'tlv': 'Tel Aviv',
      'itm': 'Osaka',
      'nrt': 'Tokyo',
      'mex': 'Città del Messico',
      'waw': 'Varsavia',
      'jnb': 'Johannesburg',
      'icn': 'Seul',
      'mad': 'Madrid',
      'sto': 'Stoccolma',
      'lhr': 'Londra',
      'man': 'Manchester',
      'ord': 'Chicago',
      'dfw': 'Dallas',
      'sea': 'Seattle',
      'sjc': 'San Francisco',
      'mia': 'Miami',
      'hnl': 'Honolulu',
      'ewr': 'Nuova York',
      'atl': 'Atlanta',
      'hkg': 'Hong Kong',
      'zrh': 'Zurigo',
      'gva': 'Ginevra',
      'svo': 'Mosca',
      'led': 'San Pietroburgo',
      'hel': 'Helsinki',
      'tpe': 'Taipei',
      'dxb': 'Dubai',
      'kbp': 'Kiev',
      'ist': 'Istanbul',
      'otp': 'Bucarest',
      'los': 'Lagos',
      'pty': 'Panama',
      'kef': 'Reykjavík',
      'ber': 'Berlino',
      'ala': 'Almaty',
      'tbs': 'Tbilisi',
      'kul': 'Kuala Lumpur',
      'bkk': 'Bangkok',
      'cgk': 'Giacarta',
      'mnl': 'Manila',
      'nbo': 'Nairobi',
      'mxp': 'Milano',
      'dub': 'Dublino',
      'lis': 'Lisbona',
      'lux': 'Lussemburgo',
      'eze': 'Buenos Aires',
      'akl': 'Auckland',
      'yul': 'Montréal',
      'yvr': 'Vancouver',
      'den': 'Denver',
      'phx': 'Phoenix',
      'iad': 'Washington',
      'bos': 'Boston',
      'edi': 'Edimburgo',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'Ti sta piacendo 1VPN?';

  @override
  String get onevpnYes => 'Sì';

  @override
  String get onevpnNo => 'No';

  @override
  String get onevpnLocationLocked => 'Bloccato, solo Premium';

  @override
  String get onevpnManageSubscription => 'Gestisci abbonamento';
}
