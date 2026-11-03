// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class OneVpnLocalizationsPt extends OneVpnLocalizations {
  OneVpnLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get onevpnFaq => 'Perguntas frequentes';

  @override
  String get onevpnTermsOfService => 'Termos de serviço';

  @override
  String get onevpnMenu => 'Menu';

  @override
  String get onevpnUpgrade => 'Fazer upgrade';

  @override
  String get onevpnUpgradeBannerTitle => 'Fazer upgrade para o Premium';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Sem anúncios, todos os locais e mais velocidade';

  @override
  String get onevpnLogIn => 'Entrar';

  @override
  String get onevpnLogOut => 'Sair';

  @override
  String get onevpnAccount => 'Conta';

  @override
  String get onevpnContactUs => 'Fale conosco';

  @override
  String get onevpnRefundPolicy => 'Política de reembolso';

  @override
  String get onevpnSupport => 'Suporte';

  @override
  String get onevpnLanguage => 'Idioma';

  @override
  String get onevpnLanguageSystem => 'Padrão do sistema';

  @override
  String get onevpnPlanFree => 'Plano grátis';

  @override
  String get onevpnPlanPremium => 'Plano Premium';

  @override
  String get onevpnSelectLocation => 'Selecionar local';

  @override
  String get onevpnDirectRegions => 'Regiões diretas';

  @override
  String get onevpnFree => 'Grátis';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Grátis';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Automático · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Automático';

  @override
  String get onevpnStatusNoConnection => 'Sem conexão';

  @override
  String get onevpnStatusConnectionFailed => 'Falha na conexão';

  @override
  String get onevpnStatusUpdating => 'Atualizando…';

  @override
  String get onevpnStatusMeasuring => 'Medindo servidores…';

  @override
  String get onevpnAutomaticSubtitle => 'O mais rápido disponível';

  @override
  String get onevpnLocationsLoadFailed =>
      'Não foi possível carregar seus locais.';

  @override
  String get onevpnLocationsUnavailable =>
      'Os locais não estão disponíveis no momento.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Alguns sites só funcionam quando você se conecta do mesmo país do site. Ao selecionar uma região, os sites dessa região não passam pela VPN.';

  @override
  String onevpnSelectionReset(String location) {
    return '$location está indisponível. O 1VPN mudou para Automático.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'O local escolhido está indisponível. O 1VPN mudou para Automático.';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'Não foi possível mudar para $location. Você continua conectado ao local anterior.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Não foi possível aplicar a alteração. Você continua conectado com as configurações anteriores.';

  @override
  String get onevpnDirectRegionsOff => 'Desativado (padrão)';

  @override
  String get onevpnAllViaVpnSubtitle => 'Todo o tráfego pelo túnel';

  @override
  String get onevpnRegionChina => 'China';

  @override
  String get onevpnFirstConnectTitle =>
      'Algumas regiões funcionam melhor com conexão direta';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'Em lugares como China, Rússia e Irã, enviar todo o tráfego pela VPN pode impedir o funcionamento de apps locais de banco e pagamento.';

  @override
  String get onevpnFirstConnectPointDirect =>
      'O 1VPN pode rotear uma região escolhida por você diretamente, fora do túnel, usando seu IP real.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Todo o resto continua protegido. Você pode alterar isso a qualquer momento.';

  @override
  String get onevpnFirstConnectChooseRegion => 'Escolher região direta';

  @override
  String get onevpnFirstConnectDismiss => 'Agora não';

  @override
  String get onevpnCensorshipWarning =>
      'Alguns servidores podem estar bloqueados na sua região devido a restrições governamentais. Estamos trabalhando para resolver isso. Obrigado pela compreensão.';

  @override
  String get onevpnAlwaysOnTitle => 'VPN sempre ativa';

  @override
  String get onevpnAlwaysOnIntro =>
      'O túnel continua ativo quando você fecha o app. Após uma reinicialização ou uma atualização do app, a opção “VPN sempre ativa” reconecta o túnel automaticamente.';

  @override
  String get onevpnAlwaysOnStep1 =>
      'Toque em “Abrir configurações de VPN” abaixo.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Encontre o 1VPN na lista. Ele aparece depois da sua primeira conexão.';

  @override
  String get onevpnAlwaysOnStep3 =>
      'Toque no ícone de engrenagem ao lado do 1VPN.';

  @override
  String get onevpnAlwaysOnStep4 => 'Ative a opção “VPN sempre ativa”.';

  @override
  String get onevpnAlwaysOnOpenSettings => 'Abrir configurações de VPN';

  @override
  String get onevpnPaywallTitle => 'Escolha seu plano';

  @override
  String get onevpnPaywallBenefitLocations =>
      'Desbloquear todos os locais de servidor';

  @override
  String get onevpnPaywallBenefitNoAds => 'Sem anúncios';

  @override
  String get onevpnPaywallBenefitSpeed =>
      'Velocidades de servidor mais rápidas';

  @override
  String get onevpnPaywallBenefitP2p => 'Suporte a BitTorrent (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack =>
      'Garantia de reembolso de 10 dias';

  @override
  String get onevpnPaywallPlanYearly => 'Anual';

  @override
  String get onevpnPaywallPlanMonthly => 'Mensal';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'Economize $percent%';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / mês';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Preço indisponível';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Não foi possível carregar os planos. Verifique sua conexão.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Os planos não estão disponíveis no momento. Tente novamente mais tarde.';

  @override
  String get onevpnGetPremium => 'Obter Premium';

  @override
  String get onevpnContinueFree => 'Continuar grátis';

  @override
  String get onevpnPaywallRetry => 'Tentar novamente';

  @override
  String get onevpnPaywallPurchaseError => 'Algo deu errado. Tente novamente.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'Esta conta do Google tem uma assinatura do 1VPN ativa ou encerrada recentemente, vinculada a outra conta do 1VPN. Entre nessa conta ou fale com o $support.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'Esta conta do Google já tem uma assinatura do 1VPN. Se o Premium não aparecer, fale com o $support.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'O Google Play não concluiu sua última compra. Feche as telas do Google Play que estiverem abertas e tente novamente, ou reinicie o app.';

  @override
  String get onevpnPaywallSupportLink => 'suporte do 1VPN';

  @override
  String get onevpnSignUp => 'Cadastre-se';

  @override
  String get onevpnAuthEmailLabel => 'E-mail';

  @override
  String get onevpnAuthPasswordLabel => 'Senha';

  @override
  String get onevpnAuthTwoFactorLabel => 'Token 2FA';

  @override
  String get onevpnAuthForgotPassword => 'Esqueceu a senha?';

  @override
  String get onevpnAuthSubmitting => 'Carregando…';

  @override
  String get onevpnAuthCreateAccount => 'Criar conta';

  @override
  String get onevpnAuthHaveAccount => 'Já tem uma conta?';

  @override
  String get onevpnAuthLogInInstead => 'Entrar com este e-mail';

  @override
  String get onevpnAuthFieldsRequired => 'Digite o e-mail e a senha';

  @override
  String get onevpnAuthInvalidEmail => 'Digite um endereço de e-mail válido';

  @override
  String get onevpnAuthInvalidCredentials => 'E-mail ou senha inválidos';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Token 2FA inválido';

  @override
  String get onevpnAuthEmailInUse => 'Já existe uma conta com esse e-mail';

  @override
  String get onevpnAuthRateLimited =>
      'Muitas tentativas. Tente novamente em instantes';

  @override
  String get onevpnAuthUnreachable =>
      'Não foi possível acessar o servidor. Verifique sua conexão e tente novamente';

  @override
  String get onevpnAuthGenericError => 'Algo deu errado. Tente novamente';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Sua compra está vinculada a este endereço de e-mail.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Compra concluída';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Sua compra está vinculada a $email. Crie uma conta com esse endereço para usá-la.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Premium · confirmando compra';

  @override
  String get onevpnPremiumRecheck => 'Verificando o status da sua compra…';

  @override
  String get onevpnButtonRetry => 'Tentar novamente';

  @override
  String get onevpnAppVersion => 'Versão do app';

  @override
  String get onevpnPrivacyPolicy => 'Política de privacidade';

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
  String get onevpnConnectionFailed => 'Falha na conexão';

  @override
  String get onevpnTemporarilyUnavailable => 'Temporariamente indisponível';

  @override
  String get onevpnRetry => 'Tentar novamente';

  @override
  String get onevpnApplyChange => 'Aplicar esta alteração?';

  @override
  String get onevpnReconnectNotice =>
      'A VPN vai se desconectar por um instante e reconectar. Isso normalmente leva só alguns segundos.';

  @override
  String onevpnWillUseName(String name) {
    return 'Vai usar: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Aplicar e reconectar';

  @override
  String get onevpnCancel => 'Cancelar';

  @override
  String get onevpnContinue => 'Continuar';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'O domínio principal está bloqueado. Usando o de backup: $domain';
  }

  @override
  String get onevpnResultFailed => 'falhou';

  @override
  String get onevpnDownload => 'Baixar';

  @override
  String get onevpnPermissionNotGranted => 'Permissão não concedida';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action: $result';
  }

  @override
  String get onevpnDisconnect => 'Desconectar';

  @override
  String get onevpnTimeout => 'Tempo esgotado';

  @override
  String get onevpnNoAvailableEntries =>
      'Nenhum servidor de entrada disponível';

  @override
  String get onevpnAddServers => 'Adicione servidores';

  @override
  String get onevpnNotEnoughServers =>
      'Não há servidores suficientes disponíveis';

  @override
  String get onevpnVpnFinalExit => 'Saída final da VPN';

  @override
  String get onevpnFinalExitEntryConflict =>
      'A saída final não pode ser também o servidor de entrada';

  @override
  String get onevpnChooseNamedRoute => 'Escolha uma rota nomeada';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Permita o acesso a dispositivos e serviços na rede local.';

  @override
  String get onevpnSystemApprovalRequired => 'Aprovação do sistema necessária';

  @override
  String get onevpnVpnPermissionRequired =>
      'A permissão de VPN é necessária. Tente novamente para continuar.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Escolha a interface usada para acessar a rede. Necessário apenas no Windows / Linux.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Andorra',
      'AE': 'Emirados Árabes Unidos',
      'AF': 'Afeganistão',
      'AG': 'Antígua e Barbuda',
      'AI': 'Anguila',
      'AL': 'Albânia',
      'AM': 'Armênia',
      'AO': 'Angola',
      'AQ': 'Antártida',
      'AR': 'Argentina',
      'AS': 'Samoa Americana',
      'AT': 'Áustria',
      'AU': 'Austrália',
      'AW': 'Aruba',
      'AX': 'Ilhas Aland',
      'AZ': 'Azerbaijão',
      'BA': 'Bósnia e Herzegovina',
      'BB': 'Barbados',
      'BD': 'Bangladesh',
      'BE': 'Bélgica',
      'BF': 'Burquina Faso',
      'BG': 'Bulgária',
      'BH': 'Barein',
      'BI': 'Burundi',
      'BJ': 'Benin',
      'BL': 'São Bartolomeu',
      'BM': 'Bermudas',
      'BN': 'Brunei',
      'BO': 'Bolívia',
      'BQ': 'Países Baixos Caribenhos',
      'BR': 'Brasil',
      'BS': 'Bahamas',
      'BT': 'Butão',
      'BV': 'Ilha Bouvet',
      'BW': 'Botsuana',
      'BY': 'Bielorrússia',
      'BZ': 'Belize',
      'CA': 'Canadá',
      'CC': 'Ilhas Cocos (Keeling)',
      'CD': 'Congo - Kinshasa',
      'CF': 'República Centro-Africana',
      'CG': 'República do Congo',
      'CH': 'Suíça',
      'CI': 'Costa do Marfim',
      'CK': 'Ilhas Cook',
      'CL': 'Chile',
      'CM': 'Camarões',
      'CN': 'China continental',
      'CO': 'Colômbia',
      'CR': 'Costa Rica',
      'CU': 'Cuba',
      'CV': 'Cabo Verde',
      'CW': 'Curaçau',
      'CX': 'Ilha Christmas',
      'CY': 'Chipre',
      'CZ': 'Tchéquia',
      'DE': 'Alemanha',
      'DJ': 'Djibuti',
      'DK': 'Dinamarca',
      'DM': 'Dominica',
      'DO': 'República Dominicana',
      'DZ': 'Argélia',
      'EC': 'Equador',
      'EE': 'Estônia',
      'EG': 'Egito',
      'EH': 'Saara Ocidental',
      'ER': 'Eritreia',
      'ES': 'Espanha',
      'ET': 'Etiópia',
      'FI': 'Finlândia',
      'FJ': 'Fiji',
      'FK': 'Ilhas Malvinas',
      'FM': 'Micronésia',
      'FO': 'Ilhas Faroé',
      'FR': 'França',
      'GA': 'Gabão',
      'GB': 'Reino Unido',
      'GD': 'Granada',
      'GE': 'Geórgia',
      'GF': 'Guiana Francesa',
      'GG': 'Guernsey',
      'GH': 'Gana',
      'GI': 'Gibraltar',
      'GL': 'Groenlândia',
      'GM': 'Gâmbia',
      'GN': 'Guiné',
      'GP': 'Guadalupe',
      'GQ': 'Guiné Equatorial',
      'GR': 'Grécia',
      'GS': 'Ilhas Geórgia do Sul e Sandwich do Sul',
      'GT': 'Guatemala',
      'GU': 'Guam',
      'GW': 'Guiné-Bissau',
      'GY': 'Guiana',
      'HK': 'Hong Kong',
      'HM': 'Ilhas Heard e McDonald',
      'HN': 'Honduras',
      'HR': 'Croácia',
      'HT': 'Haiti',
      'HU': 'Hungria',
      'ID': 'Indonésia',
      'IE': 'Irlanda',
      'IL': 'Israel',
      'IM': 'Ilha de Man',
      'IN': 'Índia',
      'IO': 'Arquipélago de Chagos',
      'IQ': 'Iraque',
      'IR': 'Irã',
      'IS': 'Islândia',
      'IT': 'Itália',
      'JE': 'Jersey',
      'JM': 'Jamaica',
      'JO': 'Jordânia',
      'JP': 'Japão',
      'KE': 'Quênia',
      'KG': 'Quirguistão',
      'KH': 'Camboja',
      'KI': 'Quiribati',
      'KM': 'Comores',
      'KN': 'São Cristóvão e Névis',
      'KP': 'Coreia do Norte',
      'KR': 'Coreia do Sul',
      'KW': 'Kuwait',
      'KY': 'Ilhas Cayman',
      'KZ': 'Cazaquistão',
      'LA': 'Laos',
      'LB': 'Líbano',
      'LC': 'Santa Lúcia',
      'LI': 'Liechtenstein',
      'LK': 'Sri Lanka',
      'LR': 'Libéria',
      'LS': 'Lesoto',
      'LT': 'Lituânia',
      'LU': 'Luxemburgo',
      'LV': 'Letônia',
      'LY': 'Líbia',
      'MA': 'Marrocos',
      'MC': 'Mônaco',
      'MD': 'Moldávia',
      'ME': 'Montenegro',
      'MF': 'Saint-Martin',
      'MG': 'Madagascar',
      'MH': 'Ilhas Marshall',
      'MK': 'Macedônia do Norte',
      'ML': 'Mali',
      'MM': 'Mianmar (Birmânia)',
      'MN': 'Mongólia',
      'MO': 'Macau',
      'MP': 'Ilhas Marianas do Norte',
      'MQ': 'Martinica',
      'MR': 'Mauritânia',
      'MS': 'Montserrat',
      'MT': 'Malta',
      'MU': 'Maurício',
      'MV': 'Maldivas',
      'MW': 'Malaui',
      'MX': 'México',
      'MY': 'Malásia',
      'MZ': 'Moçambique',
      'NA': 'Namíbia',
      'NC': 'Nova Caledônia',
      'NE': 'Níger',
      'NF': 'Ilha Norfolk',
      'NG': 'Nigéria',
      'NI': 'Nicarágua',
      'NL': 'Países Baixos',
      'NO': 'Noruega',
      'NP': 'Nepal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'Nova Zelândia',
      'OM': 'Omã',
      'PA': 'Panamá',
      'PE': 'Peru',
      'PF': 'Polinésia Francesa',
      'PG': 'Papua-Nova Guiné',
      'PH': 'Filipinas',
      'PK': 'Paquistão',
      'PL': 'Polônia',
      'PM': 'São Pedro e Miquelão',
      'PN': 'Ilhas Pitcairn',
      'PR': 'Porto Rico',
      'PS': 'Territórios palestinos',
      'PT': 'Portugal',
      'PW': 'Palau',
      'PY': 'Paraguai',
      'QA': 'Catar',
      'RE': 'Reunião',
      'RO': 'Romênia',
      'RS': 'Sérvia',
      'RU': 'Rússia',
      'RW': 'Ruanda',
      'SA': 'Arábia Saudita',
      'SB': 'Ilhas Salomão',
      'SC': 'Seicheles',
      'SD': 'Sudão',
      'SE': 'Suécia',
      'SG': 'Singapura',
      'SH': 'Santa Helena',
      'SI': 'Eslovênia',
      'SJ': 'Svalbard e Jan Mayen',
      'SK': 'Eslováquia',
      'SL': 'Serra Leoa',
      'SM': 'San Marino',
      'SN': 'Senegal',
      'SO': 'Somália',
      'SR': 'Suriname',
      'SS': 'Sudão do Sul',
      'ST': 'São Tomé e Príncipe',
      'SV': 'El Salvador',
      'SX': 'Sint Maarten',
      'SY': 'Síria',
      'SZ': 'Essuatíni',
      'TC': 'Ilhas Turcas e Caicos',
      'TD': 'Chade',
      'TF': 'Territórios Franceses do Sul',
      'TG': 'Togo',
      'TH': 'Tailândia',
      'TJ': 'Tadjiquistão',
      'TK': 'Tokelau',
      'TL': 'Timor-Leste',
      'TM': 'Turcomenistão',
      'TN': 'Tunísia',
      'TO': 'Tonga',
      'TR': 'Turquia',
      'TT': 'Trinidad e Tobago',
      'TV': 'Tuvalu',
      'TW': 'Taiwan',
      'TZ': 'Tanzânia',
      'UA': 'Ucrânia',
      'UG': 'Uganda',
      'UM': 'Ilhas Menores Distantes dos EUA',
      'US': 'Estados Unidos',
      'UY': 'Uruguai',
      'UZ': 'Uzbequistão',
      'VA': 'Cidade do Vaticano',
      'VC': 'São Vicente e Granadinas',
      'VE': 'Venezuela',
      'VG': 'Ilhas Virgens Britânicas',
      'VI': 'Ilhas Virgens Americanas',
      'VN': 'Vietnã',
      'VU': 'Vanuatu',
      'WF': 'Wallis e Futuna',
      'WS': 'Samoa',
      'XK': 'Kosovo',
      'YE': 'Iêmen',
      'YT': 'Mayotte',
      'ZA': 'África do Sul',
      'ZM': 'Zâmbia',
      'ZW': 'Zimbábue',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Opções de privacidade';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Amsterdã',
      'sgp': 'Singapura',
      'lax': 'Los Angeles',
      'mel': 'Melbourne',
      'syd': 'Sydney',
      'sao': 'São Paulo',
      'yto': 'Toronto',
      'scl': 'Santiago',
      'cdg': 'Paris',
      'fra': 'Frankfurt',
      'del': 'Nova Delhi',
      'bom': 'Mumbai',
      'blr': 'Bangalore',
      'tlv': 'Tel Aviv',
      'itm': 'Osaka',
      'nrt': 'Tóquio',
      'mex': 'Cidade do México',
      'waw': 'Varsóvia',
      'jnb': 'Joanesburgo',
      'icn': 'Seul',
      'mad': 'Madrid',
      'sto': 'Estocolmo',
      'lhr': 'Londres',
      'man': 'Manchester',
      'ord': 'Chicago',
      'dfw': 'Dallas',
      'sea': 'Seattle',
      'sjc': 'São Francisco',
      'mia': 'Miami',
      'hnl': 'Honolulu',
      'ewr': 'Nova York',
      'atl': 'Atlanta',
      'hkg': 'Hong Kong',
      'zrh': 'Zurique',
      'gva': 'Genebra',
      'svo': 'Moscou',
      'led': 'São Petersburgo',
      'hel': 'Helsinque',
      'tpe': 'Taipé',
      'dxb': 'Dubai',
      'kbp': 'Kiev',
      'ist': 'Istambul',
      'otp': 'Bucareste',
      'los': 'Lagos',
      'pty': 'Cidade do Panamá',
      'kef': 'Reykjavík',
      'ber': 'Berlim',
      'ala': 'Almaty',
      'tbs': 'Tbilisi',
      'kul': 'Kuala Lumpur',
      'bkk': 'Bangkok',
      'cgk': 'Jacarta',
      'mnl': 'Manila',
      'nbo': 'Nairóbi',
      'mxp': 'Milão',
      'dub': 'Dublin',
      'lis': 'Lisboa',
      'lux': 'Luxemburgo',
      'eze': 'Buenos Aires',
      'akl': 'Auckland',
      'yul': 'Montreal',
      'yvr': 'Vancouver',
      'den': 'Denver',
      'phx': 'Phoenix',
      'iad': 'Washington, D.C.',
      'bos': 'Boston',
      'edi': 'Edimburgo',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'Está gostando do 1VPN?';

  @override
  String get onevpnYes => 'Sim';

  @override
  String get onevpnNo => 'Não';

  @override
  String get onevpnLocationLocked => 'Bloqueado, apenas Premium';

  @override
  String get onevpnManageSubscription => 'Gerenciar assinatura';
}
