// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class OneVpnLocalizationsFr extends OneVpnLocalizations {
  OneVpnLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get onevpnFaq => 'FAQ';

  @override
  String get onevpnTermsOfService => 'Conditions d\'utilisation';

  @override
  String get onevpnMenu => 'Menu';

  @override
  String get onevpnUpgrade => 'Mettre à niveau';

  @override
  String get onevpnUpgradeBannerTitle => 'Passer à Premium';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Sans publicités, tous les emplacements et plus de vitesse';

  @override
  String get onevpnLogIn => 'Connexion';

  @override
  String get onevpnLogOut => 'Déconnexion';

  @override
  String get onevpnAccount => 'Compte';

  @override
  String get onevpnContactUs => 'Contactez-nous';

  @override
  String get onevpnRefundPolicy => 'Politique de remboursement';

  @override
  String get onevpnSupport => 'Assistance';

  @override
  String get onevpnLanguage => 'Langue';

  @override
  String get onevpnLanguageSystem => 'Langue du système';

  @override
  String get onevpnPlanFree => 'Forfait gratuit';

  @override
  String get onevpnPlanPremium => 'Forfait Premium';

  @override
  String get onevpnSelectLocation => 'Choisir un emplacement';

  @override
  String get onevpnDirectRegions => 'Régions en accès direct';

  @override
  String get onevpnFree => 'Gratuit';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Gratuit';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Automatique · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Automatique';

  @override
  String get onevpnStatusNoConnection => 'Pas de connexion';

  @override
  String get onevpnStatusConnectionFailed => 'Échec de la connexion';

  @override
  String get onevpnStatusUpdating => 'Mise à jour…';

  @override
  String get onevpnStatusMeasuring => 'Test des serveurs…';

  @override
  String get onevpnAutomaticSubtitle => 'Le plus rapide disponible';

  @override
  String get onevpnLocationsLoadFailed =>
      'Impossible de charger vos emplacements.';

  @override
  String get onevpnLocationsUnavailable =>
      'Les emplacements sont indisponibles pour le moment.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Certains sites ne fonctionnent que si vous vous connectez depuis le même pays que le site. Si vous sélectionnez une région, les sites de cette région contournent le VPN.';

  @override
  String onevpnSelectionReset(String location) {
    return '$location est indisponible. 1VPN a basculé sur Automatique.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'L\'emplacement choisi est indisponible. 1VPN a basculé sur Automatique.';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'Impossible de basculer vers $location. Vous restez sur votre emplacement précédent.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Impossible d\'appliquer la modification. La connexion conserve vos paramètres précédents.';

  @override
  String get onevpnDirectRegionsOff => 'Désactivé (par défaut)';

  @override
  String get onevpnAllViaVpnSubtitle => 'Tout le trafic passe par le tunnel';

  @override
  String get onevpnRegionChina => 'Chine';

  @override
  String get onevpnFirstConnectTitle =>
      'Certaines régions fonctionnent mieux en direct';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'Dans des pays comme la Chine, la Russie et l\'Iran, faire passer tout le trafic par le VPN peut perturber les applications bancaires et de paiement locales.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN peut acheminer directement le trafic vers une région de votre choix, hors du tunnel, depuis votre adresse IP réelle.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Le reste du trafic reste protégé. Vous pouvez modifier ce choix à tout moment.';

  @override
  String get onevpnFirstConnectChooseRegion =>
      'Choisir une région en accès direct';

  @override
  String get onevpnFirstConnectDismiss => 'Pas maintenant';

  @override
  String get onevpnCensorshipWarning =>
      'Certains serveurs peuvent être bloqués dans votre région en raison de restrictions gouvernementales. Nous travaillons à résoudre ce problème. Merci de votre compréhension.';

  @override
  String get onevpnAlwaysOnTitle => 'VPN permanent';

  @override
  String get onevpnAlwaysOnIntro =>
      'Le tunnel reste actif lorsque vous fermez l\'application. Après un redémarrage ou une mise à jour de l\'application, l\'option « VPN permanent » le reconnecte automatiquement.';

  @override
  String get onevpnAlwaysOnStep1 =>
      'Appuyez sur « Ouvrir les paramètres VPN » ci-dessous.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Trouvez 1VPN dans la liste. L\'application y apparaît après votre première connexion.';

  @override
  String get onevpnAlwaysOnStep3 =>
      'Appuyez sur la roue dentée à côté de 1VPN.';

  @override
  String get onevpnAlwaysOnStep4 => 'Activez l\'option « VPN permanent ».';

  @override
  String get onevpnAlwaysOnOpenSettings => 'Ouvrir les paramètres VPN';

  @override
  String get onevpnPaywallTitle => 'Choisissez votre forfait';

  @override
  String get onevpnPaywallBenefitLocations =>
      'Débloquer tous les emplacements de serveurs';

  @override
  String get onevpnPaywallBenefitNoAds => 'Sans publicités';

  @override
  String get onevpnPaywallBenefitSpeed => 'Vitesses de serveur plus rapides';

  @override
  String get onevpnPaywallBenefitP2p => 'Support BitTorrent (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack =>
      'Garantie de remboursement de 10 jours';

  @override
  String get onevpnPaywallPlanYearly => 'Annuel';

  @override
  String get onevpnPaywallPlanMonthly => 'Mensuel';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'Économisez $percent %';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / mois';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Prix indisponible';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Impossible de charger les forfaits. Vérifiez votre connexion.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Les forfaits ne sont pas disponibles pour le moment. Veuillez réessayer plus tard.';

  @override
  String get onevpnGetPremium => 'Obtenir Premium';

  @override
  String get onevpnContinueFree => 'Continuer gratuitement';

  @override
  String get onevpnPaywallRetry => 'Réessayer';

  @override
  String get onevpnPaywallPurchaseError =>
      'Un problème est survenu. Veuillez réessayer.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'Ce compte Google a un abonnement 1VPN actif ou récemment terminé, associé à un autre compte 1VPN. Connectez-vous à ce compte ou contactez l\'$support.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'Ce compte Google a déjà un abonnement 1VPN. Si Premium n\'apparaît pas, contactez l\'$support.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play n\'a pas finalisé votre dernier achat. Fermez tout écran Google Play ouvert et réessayez, ou redémarrez l\'application.';

  @override
  String get onevpnPaywallSupportLink => 'assistance 1VPN';

  @override
  String get onevpnSignUp => 'S\'inscrire';

  @override
  String get onevpnAuthEmailLabel => 'Adresse e-mail';

  @override
  String get onevpnAuthPasswordLabel => 'Mot de passe';

  @override
  String get onevpnAuthTwoFactorLabel => 'Code 2FA';

  @override
  String get onevpnAuthForgotPassword => 'Mot de passe oublié ?';

  @override
  String get onevpnAuthSubmitting => 'Chargement…';

  @override
  String get onevpnAuthCreateAccount => 'Créer un compte';

  @override
  String get onevpnAuthHaveAccount => 'Vous avez un compte ?';

  @override
  String get onevpnAuthLogInInstead => 'Se connecter à ce compte';

  @override
  String get onevpnAuthFieldsRequired =>
      'Saisissez votre e-mail et votre mot de passe';

  @override
  String get onevpnAuthInvalidEmail => 'Saisissez une adresse e-mail valide';

  @override
  String get onevpnAuthInvalidCredentials => 'Identifiants incorrects';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Code 2FA incorrect';

  @override
  String get onevpnAuthEmailInUse =>
      'Un compte existe déjà avec cette adresse e-mail';

  @override
  String get onevpnAuthRateLimited =>
      'Trop de tentatives. Veuillez réessayer dans quelques instants';

  @override
  String get onevpnAuthUnreachable =>
      'Impossible de joindre le serveur. Vérifiez votre connexion et réessayez';

  @override
  String get onevpnAuthGenericError =>
      'Un problème est survenu. Veuillez réessayer';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Votre achat est associé à cette adresse e-mail.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Achat effectué';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Votre achat est associé à $email. Créez un compte avec cette adresse pour en profiter.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Premium · confirmation de l\'achat';

  @override
  String get onevpnPremiumRecheck => 'Vérification de l\'état de votre achat…';

  @override
  String get onevpnButtonRetry => 'Réessayer';

  @override
  String get onevpnAppVersion => 'Version de l\'application';

  @override
  String get onevpnPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get onevpnConnect => 'Connecter';

  @override
  String get onevpnDisconnected => 'Déconnecté';

  @override
  String get onevpnConnecting => 'Connexion en cours…';

  @override
  String get onevpnConnected => 'Connecté';

  @override
  String get onevpnDisconnecting => 'Déconnexion en cours…';

  @override
  String get onevpnConnectionFailed => 'Échec de la connexion';

  @override
  String get onevpnTemporarilyUnavailable => 'Temporairement indisponible';

  @override
  String get onevpnRetry => 'Réessayer';

  @override
  String get onevpnApplyChange => 'Appliquer cette modification ?';

  @override
  String get onevpnReconnectNotice =>
      'Le VPN va brièvement se déconnecter puis se reconnecter. Cela ne prend généralement que quelques secondes.';

  @override
  String onevpnWillUseName(String name) {
    return 'Le VPN utilisera $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Appliquer et reconnecter';

  @override
  String get onevpnCancel => 'Annuler';

  @override
  String get onevpnContinue => 'Continuer';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'Le domaine principal est bloqué. Domaine de secours utilisé : $domain';
  }

  @override
  String get onevpnResultFailed => 'échec';

  @override
  String get onevpnDownload => 'Télécharger';

  @override
  String get onevpnPermissionNotGranted => 'Autorisation non accordée';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action : $result';
  }

  @override
  String get onevpnDisconnect => 'Déconnecter';

  @override
  String get onevpnTimeout => 'Délai dépassé';

  @override
  String get onevpnNoAvailableEntries => 'Aucun serveur d\'entrée disponible';

  @override
  String get onevpnAddServers => 'Ajoutez des serveurs';

  @override
  String get onevpnNotEnoughServers => 'Pas assez de serveurs disponibles';

  @override
  String get onevpnVpnFinalExit => 'Sortie finale du VPN';

  @override
  String get onevpnFinalExitEntryConflict =>
      'La sortie finale ne peut pas être aussi le serveur d\'entrée';

  @override
  String get onevpnChooseNamedRoute => 'Choisissez une route nommée';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Autorisez l\'accès aux appareils et aux services du réseau local.';

  @override
  String get onevpnSystemApprovalRequired => 'Approbation du système requise';

  @override
  String get onevpnVpnPermissionRequired =>
      'L\'autorisation VPN est requise. Veuillez réessayer pour continuer.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Choisissez l\'interface utilisée pour accéder au réseau. Nécessaire uniquement sous Windows / Linux.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Andorre',
      'AE': 'Émirats arabes unis',
      'AF': 'Afghanistan',
      'AG': 'Antigua-et-Barbuda',
      'AI': 'Anguilla',
      'AL': 'Albanie',
      'AM': 'Arménie',
      'AO': 'Angola',
      'AQ': 'Antarctique',
      'AR': 'Argentine',
      'AS': 'Samoa américaines',
      'AT': 'Autriche',
      'AU': 'Australie',
      'AW': 'Aruba',
      'AX': 'Îles Åland',
      'AZ': 'Azerbaïdjan',
      'BA': 'Bosnie-Herzégovine',
      'BB': 'Barbade',
      'BD': 'Bangladesh',
      'BE': 'Belgique',
      'BF': 'Burkina Faso',
      'BG': 'Bulgarie',
      'BH': 'Bahreïn',
      'BI': 'Burundi',
      'BJ': 'Bénin',
      'BL': 'Saint-Barthélemy',
      'BM': 'Bermudes',
      'BN': 'Brunei',
      'BO': 'Bolivie',
      'BQ': 'Pays-Bas caribéens',
      'BR': 'Brésil',
      'BS': 'Bahamas',
      'BT': 'Bhoutan',
      'BV': 'Île Bouvet',
      'BW': 'Botswana',
      'BY': 'Biélorussie',
      'BZ': 'Belize',
      'CA': 'Canada',
      'CC': 'Îles Cocos',
      'CD': 'Congo-Kinshasa',
      'CF': 'République centrafricaine',
      'CG': 'Congo-Brazzaville',
      'CH': 'Suisse',
      'CI': 'Côte d\'Ivoire',
      'CK': 'Îles Cook',
      'CL': 'Chili',
      'CM': 'Cameroun',
      'CN': 'Chine continentale',
      'CO': 'Colombie',
      'CR': 'Costa Rica',
      'CU': 'Cuba',
      'CV': 'Cap-Vert',
      'CW': 'Curaçao',
      'CX': 'Île Christmas',
      'CY': 'Chypre',
      'CZ': 'Tchéquie',
      'DE': 'Allemagne',
      'DJ': 'Djibouti',
      'DK': 'Danemark',
      'DM': 'Dominique',
      'DO': 'République dominicaine',
      'DZ': 'Algérie',
      'EC': 'Équateur',
      'EE': 'Estonie',
      'EG': 'Égypte',
      'EH': 'Sahara occidental',
      'ER': 'Érythrée',
      'ES': 'Espagne',
      'ET': 'Éthiopie',
      'FI': 'Finlande',
      'FJ': 'Fidji',
      'FK': 'Îles Malouines',
      'FM': 'Micronésie',
      'FO': 'Îles Féroé',
      'FR': 'France',
      'GA': 'Gabon',
      'GB': 'Royaume-Uni',
      'GD': 'Grenade',
      'GE': 'Géorgie',
      'GF': 'Guyane française',
      'GG': 'Guernesey',
      'GH': 'Ghana',
      'GI': 'Gibraltar',
      'GL': 'Groenland',
      'GM': 'Gambie',
      'GN': 'Guinée',
      'GP': 'Guadeloupe',
      'GQ': 'Guinée équatoriale',
      'GR': 'Grèce',
      'GS': 'Géorgie du Sud-et-les Îles Sandwich du Sud',
      'GT': 'Guatemala',
      'GU': 'Guam',
      'GW': 'Guinée-Bissau',
      'GY': 'Guyana',
      'HK': 'Hong Kong',
      'HM': 'Îles Heard-et-McDonald',
      'HN': 'Honduras',
      'HR': 'Croatie',
      'HT': 'Haïti',
      'HU': 'Hongrie',
      'ID': 'Indonésie',
      'IE': 'Irlande',
      'IL': 'Israël',
      'IM': 'Île de Man',
      'IN': 'Inde',
      'IO': 'Archipel des Chagos',
      'IQ': 'Irak',
      'IR': 'Iran',
      'IS': 'Islande',
      'IT': 'Italie',
      'JE': 'Jersey',
      'JM': 'Jamaïque',
      'JO': 'Jordanie',
      'JP': 'Japon',
      'KE': 'Kenya',
      'KG': 'Kirghizistan',
      'KH': 'Cambodge',
      'KI': 'Kiribati',
      'KM': 'Comores',
      'KN': 'Saint-Christophe-et-Niévès',
      'KP': 'Corée du Nord',
      'KR': 'Corée du Sud',
      'KW': 'Koweït',
      'KY': 'Îles Caïmans',
      'KZ': 'Kazakhstan',
      'LA': 'Laos',
      'LB': 'Liban',
      'LC': 'Sainte-Lucie',
      'LI': 'Liechtenstein',
      'LK': 'Sri Lanka',
      'LR': 'Libéria',
      'LS': 'Lesotho',
      'LT': 'Lituanie',
      'LU': 'Luxembourg',
      'LV': 'Lettonie',
      'LY': 'Libye',
      'MA': 'Maroc',
      'MC': 'Monaco',
      'MD': 'Moldavie',
      'ME': 'Monténégro',
      'MF': 'Saint-Martin',
      'MG': 'Madagascar',
      'MH': 'Îles Marshall',
      'MK': 'Macédoine du Nord',
      'ML': 'Mali',
      'MM': 'Myanmar (Birmanie)',
      'MN': 'Mongolie',
      'MO': 'Macao',
      'MP': 'Îles Mariannes du Nord',
      'MQ': 'Martinique',
      'MR': 'Mauritanie',
      'MS': 'Montserrat',
      'MT': 'Malte',
      'MU': 'Maurice',
      'MV': 'Maldives',
      'MW': 'Malawi',
      'MX': 'Mexique',
      'MY': 'Malaisie',
      'MZ': 'Mozambique',
      'NA': 'Namibie',
      'NC': 'Nouvelle-Calédonie',
      'NE': 'Niger',
      'NF': 'Île Norfolk',
      'NG': 'Nigeria',
      'NI': 'Nicaragua',
      'NL': 'Pays-Bas',
      'NO': 'Norvège',
      'NP': 'Népal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'Nouvelle-Zélande',
      'OM': 'Oman',
      'PA': 'Panama',
      'PE': 'Pérou',
      'PF': 'Polynésie française',
      'PG': 'Papouasie-Nouvelle-Guinée',
      'PH': 'Philippines',
      'PK': 'Pakistan',
      'PL': 'Pologne',
      'PM': 'Saint-Pierre-et-Miquelon',
      'PN': 'Îles Pitcairn',
      'PR': 'Porto Rico',
      'PS': 'Territoires palestiniens',
      'PT': 'Portugal',
      'PW': 'Palaos',
      'PY': 'Paraguay',
      'QA': 'Qatar',
      'RE': 'La Réunion',
      'RO': 'Roumanie',
      'RS': 'Serbie',
      'RU': 'Russie',
      'RW': 'Rwanda',
      'SA': 'Arabie saoudite',
      'SB': 'Îles Salomon',
      'SC': 'Seychelles',
      'SD': 'Soudan',
      'SE': 'Suède',
      'SG': 'Singapour',
      'SH': 'Sainte-Hélène',
      'SI': 'Slovénie',
      'SJ': 'Svalbard et Jan Mayen',
      'SK': 'Slovaquie',
      'SL': 'Sierra Leone',
      'SM': 'Saint-Marin',
      'SN': 'Sénégal',
      'SO': 'Somalie',
      'SR': 'Suriname',
      'SS': 'Soudan du Sud',
      'ST': 'Sao Tomé-et-Principe',
      'SV': 'Salvador',
      'SX': 'Saint-Martin (partie néerlandaise)',
      'SY': 'Syrie',
      'SZ': 'Eswatini',
      'TC': 'Îles Turques-et-Caïques',
      'TD': 'Tchad',
      'TF': 'Terres australes françaises',
      'TG': 'Togo',
      'TH': 'Thaïlande',
      'TJ': 'Tadjikistan',
      'TK': 'Tokelau',
      'TL': 'Timor oriental',
      'TM': 'Turkménistan',
      'TN': 'Tunisie',
      'TO': 'Tonga',
      'TR': 'Turquie',
      'TT': 'Trinité-et-Tobago',
      'TV': 'Tuvalu',
      'TW': 'Taïwan',
      'TZ': 'Tanzanie',
      'UA': 'Ukraine',
      'UG': 'Ouganda',
      'UM': 'Îles mineures éloignées des États-Unis',
      'US': 'États-Unis',
      'UY': 'Uruguay',
      'UZ': 'Ouzbékistan',
      'VA': 'État de la Cité du Vatican',
      'VC': 'Saint-Vincent-et-les-Grenadines',
      'VE': 'Venezuela',
      'VG': 'Îles Vierges britanniques',
      'VI': 'Îles Vierges des États-Unis',
      'VN': 'Viêt Nam',
      'VU': 'Vanuatu',
      'WF': 'Wallis-et-Futuna',
      'WS': 'Samoa',
      'XK': 'Kosovo',
      'YE': 'Yémen',
      'YT': 'Mayotte',
      'ZA': 'Afrique du Sud',
      'ZM': 'Zambie',
      'ZW': 'Zimbabwe',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Choix de confidentialité';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Amsterdam',
      'sgp': 'Singapour',
      'lax': 'Los Angeles',
      'mel': 'Melbourne',
      'syd': 'Sydney',
      'sao': 'São Paulo',
      'yto': 'Toronto',
      'scl': 'Santiago',
      'cdg': 'Paris',
      'fra': 'Francfort',
      'del': 'New Delhi',
      'bom': 'Mumbai',
      'blr': 'Bangalore',
      'tlv': 'Tel Aviv',
      'itm': 'Osaka',
      'nrt': 'Tokyo',
      'mex': 'Mexico',
      'waw': 'Varsovie',
      'jnb': 'Johannesburg',
      'icn': 'Séoul',
      'mad': 'Madrid',
      'sto': 'Stockholm',
      'lhr': 'Londres',
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
      'gva': 'Genève',
      'svo': 'Moscou',
      'led': 'Saint-Pétersbourg',
      'hel': 'Helsinki',
      'tpe': 'Taipei',
      'dxb': 'Dubaï',
      'kbp': 'Kyiv',
      'ist': 'Istanbul',
      'otp': 'Bucarest',
      'los': 'Lagos',
      'pty': 'Panama',
      'kef': 'Reykjavik',
      'ber': 'Berlin',
      'ala': 'Almaty',
      'tbs': 'Tbilissi',
      'kul': 'Kuala Lumpur',
      'bkk': 'Bangkok',
      'cgk': 'Jakarta',
      'mnl': 'Manille',
      'nbo': 'Nairobi',
      'mxp': 'Milan',
      'dub': 'Dublin',
      'lis': 'Lisbonne',
      'lux': 'Luxembourg',
      'eze': 'Buenos Aires',
      'akl': 'Auckland',
      'yul': 'Montréal',
      'yvr': 'Vancouver',
      'den': 'Denver',
      'phx': 'Phoenix',
      'iad': 'Washington',
      'bos': 'Boston',
      'edi': 'Édimbourg',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'Vous appréciez 1VPN ?';

  @override
  String get onevpnYes => 'Oui';

  @override
  String get onevpnNo => 'Non';

  @override
  String get onevpnLocationLocked => 'Verrouillé, Premium uniquement';

  @override
  String get onevpnManageSubscription => 'Gérer l\'abonnement';
}
