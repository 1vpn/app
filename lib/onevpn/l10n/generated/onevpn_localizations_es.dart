// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class OneVpnLocalizationsEs extends OneVpnLocalizations {
  OneVpnLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get onevpnFaq => 'Preguntas frecuentes';

  @override
  String get onevpnTermsOfService => 'Condiciones de servicio';

  @override
  String get onevpnMenu => 'Menú';

  @override
  String get onevpnUpgrade => 'Mejorar plan';

  @override
  String get onevpnUpgradeBannerTitle => 'Mejora a Premium';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Sin anuncios, todas las ubicaciones y más velocidad';

  @override
  String get onevpnLogIn => 'Iniciar sesión';

  @override
  String get onevpnLogOut => 'Cerrar sesión';

  @override
  String get onevpnAccount => 'Cuenta';

  @override
  String get onevpnContactUs => 'Contáctanos';

  @override
  String get onevpnRefundPolicy => 'Política de reembolsos';

  @override
  String get onevpnSupport => 'Ayuda';

  @override
  String get onevpnLanguage => 'Idioma';

  @override
  String get onevpnLanguageSystem => 'Predeterminado del sistema';

  @override
  String get onevpnPlanFree => 'Plan gratuito';

  @override
  String get onevpnPlanPremium => 'Plan Premium';

  @override
  String get onevpnSelectLocation => 'Seleccionar ubicación';

  @override
  String get onevpnDirectRegions => 'Regiones directas';

  @override
  String get onevpnFree => 'Gratis';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Gratis';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Automático · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Automático';

  @override
  String get onevpnStatusNoConnection => 'Sin conexión';

  @override
  String get onevpnStatusConnectionFailed => 'No se ha podido conectar';

  @override
  String get onevpnStatusUpdating => 'Actualizando…';

  @override
  String get onevpnStatusMeasuring => 'Comprobando servidores…';

  @override
  String get onevpnAutomaticSubtitle => 'El más rápido disponible';

  @override
  String get onevpnLocationsLoadFailed =>
      'No se han podido cargar tus ubicaciones.';

  @override
  String get onevpnLocationsUnavailable =>
      'Las ubicaciones no están disponibles en este momento.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Algunos sitios web solo funcionan si te conectas desde el mismo país que el sitio. Si seleccionas una región, los sitios de esa región no pasan por la VPN.';

  @override
  String onevpnSelectionReset(String location) {
    return '$location no está disponible, así que 1VPN ha cambiado a Automático.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'La ubicación elegida no está disponible, así que 1VPN ha cambiado a Automático.';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'No se ha podido cambiar a $location. La conexión sigue activa con tu ubicación anterior.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'No se ha podido aplicar el cambio. La conexión sigue activa con tu configuración anterior.';

  @override
  String get onevpnDirectRegionsOff => 'Desactivado (predeterminado)';

  @override
  String get onevpnAllViaVpnSubtitle => 'Todo el tráfico a través del túnel';

  @override
  String get onevpnRegionChina => 'China';

  @override
  String get onevpnFirstConnectTitle =>
      'Algunas regiones funcionan mejor con conexión directa';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'En lugares como China, Rusia e Irán, enviar todo el tráfico a través de la VPN puede hacer que dejen de funcionar las aplicaciones locales de banca y pagos.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN puede enrutar directamente la región que elijas, fuera del túnel y desde tu IP real.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Todo lo demás sigue protegido. Puedes cambiarlo cuando quieras.';

  @override
  String get onevpnFirstConnectChooseRegion => 'Elegir región directa';

  @override
  String get onevpnFirstConnectDismiss => 'Ahora no';

  @override
  String get onevpnCensorshipWarning =>
      'Algunos servidores pueden estar bloqueados en tu región debido a restricciones gubernamentales. Estamos trabajando para resolverlo. Gracias por tu comprensión.';

  @override
  String get onevpnAlwaysOnTitle => 'VPN siempre activada';

  @override
  String get onevpnAlwaysOnIntro =>
      'El túnel sigue activo cuando cierras la aplicación. Tras reiniciar el dispositivo o actualizar la aplicación, la opción \"VPN siempre activada\" vuelve a conectarlo automáticamente.';

  @override
  String get onevpnAlwaysOnStep1 => 'Toca \"Abrir ajustes de VPN\" abajo.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Busca 1VPN en la lista. Aparecerá después de tu primera conexión.';

  @override
  String get onevpnAlwaysOnStep3 => 'Toca el icono de engranaje junto a 1VPN.';

  @override
  String get onevpnAlwaysOnStep4 =>
      'Activa la opción \"VPN siempre activada\".';

  @override
  String get onevpnAlwaysOnOpenSettings => 'Abrir ajustes de VPN';

  @override
  String get onevpnPaywallTitle => 'Elige tu plan';

  @override
  String get onevpnPaywallBenefitLocations =>
      'Acceso a todas las ubicaciones de servidores';

  @override
  String get onevpnPaywallBenefitNoAds => 'Sin anuncios';

  @override
  String get onevpnPaywallBenefitSpeed => 'Velocidades de servidor más rápidas';

  @override
  String get onevpnPaywallBenefitP2p => 'Soporte BitTorrent (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack =>
      'Garantía de devolución de dinero de 10 días';

  @override
  String get onevpnPaywallPlanYearly => 'Anual';

  @override
  String get onevpnPaywallPlanMonthly => 'Mensual';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'Ahorra un $percent %';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / mes';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Precio no disponible';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'No se han podido cargar los planes. Comprueba tu conexión.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Los planes no están disponibles en este momento. Inténtalo de nuevo más tarde.';

  @override
  String get onevpnGetPremium => 'Obtener Premium';

  @override
  String get onevpnContinueFree => 'Continuar gratis';

  @override
  String get onevpnPaywallRetry => 'Reintentar';

  @override
  String get onevpnPaywallPurchaseError =>
      'Se ha producido un error. Inténtalo de nuevo.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'Esta cuenta de Google tiene una suscripción de 1VPN activa o finalizada hace poco, vinculada a otra cuenta de 1VPN. Inicia sesión en esa cuenta o ponte en contacto con el $support.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'Esta cuenta de Google ya tiene una suscripción de 1VPN. Si Premium no aparece, ponte en contacto con el $support.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play no completó tu última compra. Cierra cualquier pantalla de Google Play abierta e inténtalo de nuevo, o reinicia la aplicación.';

  @override
  String get onevpnPaywallSupportLink => 'soporte de 1VPN';

  @override
  String get onevpnSignUp => 'Registrarse';

  @override
  String get onevpnAuthEmailLabel => 'Correo electrónico';

  @override
  String get onevpnAuthPasswordLabel => 'Contraseña';

  @override
  String get onevpnAuthTwoFactorLabel => 'Código 2FA';

  @override
  String get onevpnAuthForgotPassword => '¿Has olvidado tu contraseña?';

  @override
  String get onevpnAuthSubmitting => 'Cargando…';

  @override
  String get onevpnAuthCreateAccount => 'Crear cuenta';

  @override
  String get onevpnAuthHaveAccount => '¿Tienes una cuenta?';

  @override
  String get onevpnAuthLogInInstead => 'Iniciar sesión';

  @override
  String get onevpnAuthFieldsRequired =>
      'Introduce el correo electrónico y la contraseña';

  @override
  String get onevpnAuthInvalidEmail =>
      'Introduce una dirección de correo electrónico válida';

  @override
  String get onevpnAuthInvalidCredentials =>
      'Correo electrónico o contraseña incorrectos';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Código 2FA no válido';

  @override
  String get onevpnAuthEmailInUse =>
      'Ya existe una cuenta con ese correo electrónico';

  @override
  String get onevpnAuthRateLimited =>
      'Demasiados intentos. Inténtalo de nuevo en breve';

  @override
  String get onevpnAuthUnreachable =>
      'No se ha podido conectar con el servidor. Comprueba tu conexión e inténtalo de nuevo';

  @override
  String get onevpnAuthGenericError =>
      'Se ha producido un error. Inténtalo de nuevo';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Tu compra está vinculada a esta dirección de correo electrónico.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Compra completada';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Tu compra está vinculada a $email. Crea una cuenta con esa dirección para usarla.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Premium · confirmando la compra';

  @override
  String get onevpnPremiumRecheck => 'Comprobando el estado de tu compra…';

  @override
  String get onevpnButtonRetry => 'Reintentar';

  @override
  String get onevpnAppVersion => 'Versión de la aplicación';

  @override
  String get onevpnPrivacyPolicy => 'Política de privacidad';

  @override
  String get onevpnConnect => 'Conectar';

  @override
  String get onevpnDisconnected => 'Desconectado';

  @override
  String get onevpnConnecting => 'Conectando…';

  @override
  String get onevpnConnected => 'Conectado';

  @override
  String get onevpnDisconnecting => 'Desconectando…';

  @override
  String get onevpnConnectionFailed => 'No se ha podido conectar';

  @override
  String get onevpnTemporarilyUnavailable => 'No disponible temporalmente';

  @override
  String get onevpnRetry => 'Reintentar';

  @override
  String get onevpnApplyChange => '¿Aplicar este cambio?';

  @override
  String get onevpnReconnectNotice =>
      'La VPN se desconectará y se volverá a conectar brevemente. Normalmente solo tarda unos segundos.';

  @override
  String onevpnWillUseName(String name) {
    return 'Se usará: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Aplicar y volver a conectar';

  @override
  String get onevpnCancel => 'Cancelar';

  @override
  String get onevpnContinue => 'Continuar';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'El dominio principal está bloqueado. Usando el de respaldo: $domain';
  }

  @override
  String get onevpnResultFailed => 'error';

  @override
  String get onevpnDownload => 'Descargar';

  @override
  String get onevpnPermissionNotGranted => 'Permiso no concedido';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action: $result';
  }

  @override
  String get onevpnDisconnect => 'Desconectar';

  @override
  String get onevpnTimeout => 'Tiempo de espera agotado';

  @override
  String get onevpnNoAvailableEntries =>
      'No hay servidores de entrada disponibles';

  @override
  String get onevpnAddServers => 'Añade servidores';

  @override
  String get onevpnNotEnoughServers =>
      'No hay suficientes servidores disponibles';

  @override
  String get onevpnVpnFinalExit => 'Salida final de la VPN';

  @override
  String get onevpnFinalExitEntryConflict =>
      'La salida final no puede ser también el servidor de entrada';

  @override
  String get onevpnChooseNamedRoute => 'Elige una ruta con nombre';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Concede acceso a los dispositivos y servicios de la red local.';

  @override
  String get onevpnSystemApprovalRequired =>
      'Se requiere la aprobación del sistema';

  @override
  String get onevpnVpnPermissionRequired =>
      'Se necesita el permiso de VPN. Vuelve a intentarlo para continuar.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Elige la interfaz que se usa para acceder a la red. Solo es obligatorio en Windows / Linux.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Andorra',
      'AE': 'Emiratos Árabes Unidos',
      'AF': 'Afganistán',
      'AG': 'Antigua y Barbuda',
      'AI': 'Anguila',
      'AL': 'Albania',
      'AM': 'Armenia',
      'AO': 'Angola',
      'AQ': 'Antártida',
      'AR': 'Argentina',
      'AS': 'Samoa Americana',
      'AT': 'Austria',
      'AU': 'Australia',
      'AW': 'Aruba',
      'AX': 'Islas Aland',
      'AZ': 'Azerbaiyán',
      'BA': 'Bosnia y Herzegovina',
      'BB': 'Barbados',
      'BD': 'Bangladés',
      'BE': 'Bélgica',
      'BF': 'Burkina Faso',
      'BG': 'Bulgaria',
      'BH': 'Baréin',
      'BI': 'Burundi',
      'BJ': 'Benín',
      'BL': 'San Bartolomé',
      'BM': 'Bermudas',
      'BN': 'Brunéi',
      'BO': 'Bolivia',
      'BQ': 'Caribe neerlandés',
      'BR': 'Brasil',
      'BS': 'Bahamas',
      'BT': 'Bután',
      'BV': 'Isla Bouvet',
      'BW': 'Botsuana',
      'BY': 'Bielorrusia',
      'BZ': 'Belice',
      'CA': 'Canadá',
      'CC': 'Islas Cocos',
      'CD': 'República Democrática del Congo',
      'CF': 'República Centroafricana',
      'CG': 'Congo',
      'CH': 'Suiza',
      'CI': 'Côte d’Ivoire',
      'CK': 'Islas Cook',
      'CL': 'Chile',
      'CM': 'Camerún',
      'CN': 'China continental',
      'CO': 'Colombia',
      'CR': 'Costa Rica',
      'CU': 'Cuba',
      'CV': 'Cabo Verde',
      'CW': 'Curazao',
      'CX': 'Isla de Navidad',
      'CY': 'Chipre',
      'CZ': 'Chequia',
      'DE': 'Alemania',
      'DJ': 'Yibuti',
      'DK': 'Dinamarca',
      'DM': 'Dominica',
      'DO': 'República Dominicana',
      'DZ': 'Argelia',
      'EC': 'Ecuador',
      'EE': 'Estonia',
      'EG': 'Egipto',
      'EH': 'Sáhara Occidental',
      'ER': 'Eritrea',
      'ES': 'España',
      'ET': 'Etiopía',
      'FI': 'Finlandia',
      'FJ': 'Fiyi',
      'FK': 'Islas Malvinas',
      'FM': 'Micronesia',
      'FO': 'Islas Feroe',
      'FR': 'Francia',
      'GA': 'Gabón',
      'GB': 'Reino Unido',
      'GD': 'Granada',
      'GE': 'Georgia',
      'GF': 'Guayana Francesa',
      'GG': 'Guernesey',
      'GH': 'Ghana',
      'GI': 'Gibraltar',
      'GL': 'Groenlandia',
      'GM': 'Gambia',
      'GN': 'Guinea',
      'GP': 'Guadalupe',
      'GQ': 'Guinea Ecuatorial',
      'GR': 'Grecia',
      'GS': 'Islas Georgia del Sur y Sandwich del Sur',
      'GT': 'Guatemala',
      'GU': 'Guam',
      'GW': 'Guinea-Bisáu',
      'GY': 'Guyana',
      'HK': 'Hong Kong',
      'HM': 'Islas Heard y McDonald',
      'HN': 'Honduras',
      'HR': 'Croacia',
      'HT': 'Haití',
      'HU': 'Hungría',
      'ID': 'Indonesia',
      'IE': 'Irlanda',
      'IL': 'Israel',
      'IM': 'Isla de Man',
      'IN': 'India',
      'IO': 'Archipiélago de Chagos',
      'IQ': 'Irak',
      'IR': 'Irán',
      'IS': 'Islandia',
      'IT': 'Italia',
      'JE': 'Jersey',
      'JM': 'Jamaica',
      'JO': 'Jordania',
      'JP': 'Japón',
      'KE': 'Kenia',
      'KG': 'Kirguistán',
      'KH': 'Camboya',
      'KI': 'Kiribati',
      'KM': 'Comoras',
      'KN': 'San Cristóbal y Nieves',
      'KP': 'Corea del Norte',
      'KR': 'Corea del Sur',
      'KW': 'Kuwait',
      'KY': 'Islas Caimán',
      'KZ': 'Kazajistán',
      'LA': 'Laos',
      'LB': 'Líbano',
      'LC': 'Santa Lucía',
      'LI': 'Liechtenstein',
      'LK': 'Sri Lanka',
      'LR': 'Liberia',
      'LS': 'Lesoto',
      'LT': 'Lituania',
      'LU': 'Luxemburgo',
      'LV': 'Letonia',
      'LY': 'Libia',
      'MA': 'Marruecos',
      'MC': 'Mónaco',
      'MD': 'Moldavia',
      'ME': 'Montenegro',
      'MF': 'San Martín',
      'MG': 'Madagascar',
      'MH': 'Islas Marshall',
      'MK': 'Macedonia del Norte',
      'ML': 'Mali',
      'MM': 'Myanmar (Birmania)',
      'MN': 'Mongolia',
      'MO': 'Macao',
      'MP': 'Islas Marianas del Norte',
      'MQ': 'Martinica',
      'MR': 'Mauritania',
      'MS': 'Montserrat',
      'MT': 'Malta',
      'MU': 'Mauricio',
      'MV': 'Maldivas',
      'MW': 'Malaui',
      'MX': 'México',
      'MY': 'Malasia',
      'MZ': 'Mozambique',
      'NA': 'Namibia',
      'NC': 'Nueva Caledonia',
      'NE': 'Níger',
      'NF': 'Isla Norfolk',
      'NG': 'Nigeria',
      'NI': 'Nicaragua',
      'NL': 'Países Bajos',
      'NO': 'Noruega',
      'NP': 'Nepal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'Nueva Zelanda',
      'OM': 'Omán',
      'PA': 'Panamá',
      'PE': 'Perú',
      'PF': 'Polinesia Francesa',
      'PG': 'Papúa Nueva Guinea',
      'PH': 'Filipinas',
      'PK': 'Pakistán',
      'PL': 'Polonia',
      'PM': 'San Pedro y Miquelón',
      'PN': 'Islas Pitcairn',
      'PR': 'Puerto Rico',
      'PS': 'Territorios Palestinos',
      'PT': 'Portugal',
      'PW': 'Palaos',
      'PY': 'Paraguay',
      'QA': 'Catar',
      'RE': 'Reunión',
      'RO': 'Rumanía',
      'RS': 'Serbia',
      'RU': 'Rusia',
      'RW': 'Ruanda',
      'SA': 'Arabia Saudí',
      'SB': 'Islas Salomón',
      'SC': 'Seychelles',
      'SD': 'Sudán',
      'SE': 'Suecia',
      'SG': 'Singapur',
      'SH': 'Santa Elena',
      'SI': 'Eslovenia',
      'SJ': 'Svalbard y Jan Mayen',
      'SK': 'Eslovaquia',
      'SL': 'Sierra Leona',
      'SM': 'San Marino',
      'SN': 'Senegal',
      'SO': 'Somalia',
      'SR': 'Surinam',
      'SS': 'Sudán del Sur',
      'ST': 'Santo Tomé y Príncipe',
      'SV': 'El Salvador',
      'SX': 'Sint Maarten',
      'SY': 'Siria',
      'SZ': 'Esuatini',
      'TC': 'Islas Turcas y Caicos',
      'TD': 'Chad',
      'TF': 'Territorios Australes Franceses',
      'TG': 'Togo',
      'TH': 'Tailandia',
      'TJ': 'Tayikistán',
      'TK': 'Tokelau',
      'TL': 'Timor Oriental',
      'TM': 'Turkmenistán',
      'TN': 'Túnez',
      'TO': 'Tonga',
      'TR': 'Turquía',
      'TT': 'Trinidad y Tobago',
      'TV': 'Tuvalu',
      'TW': 'Taiwán',
      'TZ': 'Tanzania',
      'UA': 'Ucrania',
      'UG': 'Uganda',
      'UM': 'Islas menores alejadas de EE. UU.',
      'US': 'Estados Unidos',
      'UY': 'Uruguay',
      'UZ': 'Uzbekistán',
      'VA': 'Ciudad del Vaticano',
      'VC': 'San Vicente y las Granadinas',
      'VE': 'Venezuela',
      'VG': 'Islas Vírgenes Británicas',
      'VI': 'Islas Vírgenes de EE. UU.',
      'VN': 'Vietnam',
      'VU': 'Vanuatu',
      'WF': 'Wallis y Futuna',
      'WS': 'Samoa',
      'XK': 'Kosovo',
      'YE': 'Yemen',
      'YT': 'Mayotte',
      'ZA': 'Sudáfrica',
      'ZM': 'Zambia',
      'ZW': 'Zimbabue',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Opciones de privacidad';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Ámsterdam',
      'sgp': 'Singapur',
      'lax': 'Los Ángeles',
      'mel': 'Melbourne',
      'syd': 'Sídney',
      'sao': 'São Paulo',
      'yto': 'Toronto',
      'scl': 'Santiago',
      'cdg': 'París',
      'fra': 'Fráncfort',
      'del': 'Nueva Delhi',
      'bom': 'Bombay',
      'blr': 'Bangalore',
      'tlv': 'Tel Aviv',
      'itm': 'Osaka',
      'nrt': 'Tokio',
      'mex': 'Ciudad de México',
      'waw': 'Varsovia',
      'jnb': 'Johannesburgo',
      'icn': 'Seúl',
      'mad': 'Madrid',
      'sto': 'Estocolmo',
      'lhr': 'Londres',
      'man': 'Mánchester',
      'ord': 'Chicago',
      'dfw': 'Dallas',
      'sea': 'Seattle',
      'sjc': 'San Francisco',
      'mia': 'Miami',
      'hnl': 'Honolulu',
      'ewr': 'Nueva York',
      'atl': 'Atlanta',
      'hkg': 'Hong Kong',
      'zrh': 'Zúrich',
      'gva': 'Ginebra',
      'svo': 'Moscú',
      'led': 'San Petersburgo',
      'hel': 'Helsinki',
      'tpe': 'Taipéi',
      'dxb': 'Dubái',
      'kbp': 'Kiev',
      'ist': 'Estambul',
      'otp': 'Bucarest',
      'los': 'Lagos',
      'pty': 'Ciudad de Panamá',
      'kef': 'Reikiavik',
      'ber': 'Berlín',
      'ala': 'Almaty',
      'tbs': 'Tiflis',
      'kul': 'Kuala Lumpur',
      'bkk': 'Bangkok',
      'cgk': 'Yakarta',
      'mnl': 'Manila',
      'nbo': 'Nairobi',
      'mxp': 'Milán',
      'dub': 'Dublín',
      'lis': 'Lisboa',
      'lux': 'Luxemburgo',
      'eze': 'Buenos Aires',
      'akl': 'Auckland',
      'yul': 'Montreal',
      'yvr': 'Vancouver',
      'den': 'Denver',
      'phx': 'Phoenix',
      'iad': 'Washington D. C.',
      'bos': 'Boston',
      'edi': 'Edimburgo',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => '¿Te está gustando 1VPN?';

  @override
  String get onevpnYes => 'Sí';

  @override
  String get onevpnNo => 'No';

  @override
  String get onevpnLocationLocked => 'Bloqueado, solo Premium';

  @override
  String get onevpnManageSubscription => 'Gestionar suscripción';
}
