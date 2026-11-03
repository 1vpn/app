// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class OneVpnLocalizationsZh extends OneVpnLocalizations {
  OneVpnLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get onevpnFaq => '常见问题';

  @override
  String get onevpnTermsOfService => '服务条款';

  @override
  String get onevpnMenu => '菜单';

  @override
  String get onevpnUpgrade => '升级';

  @override
  String get onevpnUpgradeBannerTitle => '升级到高级版';

  @override
  String get onevpnUpgradeBannerSubtitle => '无广告，所有位置，更快速度';

  @override
  String get onevpnLogIn => '登录';

  @override
  String get onevpnLogOut => '退出登录';

  @override
  String get onevpnAccount => '账户';

  @override
  String get onevpnContactUs => '联系我们';

  @override
  String get onevpnRefundPolicy => '退款政策';

  @override
  String get onevpnSupport => '支持';

  @override
  String get onevpnLanguage => '语言';

  @override
  String get onevpnLanguageSystem => '跟随系统';

  @override
  String get onevpnPlanFree => '免费套餐';

  @override
  String get onevpnPlanPremium => '高级版套餐';

  @override
  String get onevpnSelectLocation => '选择位置';

  @override
  String get onevpnDirectRegions => '直连地区';

  @override
  String get onevpnFree => '免费';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · 免费';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return '自动 · $node';
  }

  @override
  String get onevpnAutomaticSelection => '自动';

  @override
  String get onevpnStatusNoConnection => '无连接';

  @override
  String get onevpnStatusConnectionFailed => '连接失败';

  @override
  String get onevpnStatusUpdating => '正在更新…';

  @override
  String get onevpnStatusMeasuring => '正在测速…';

  @override
  String get onevpnAutomaticSubtitle => '最快的可用服务器';

  @override
  String get onevpnLocationsLoadFailed => '无法加载您的位置列表。';

  @override
  String get onevpnLocationsUnavailable => '目前没有可用的位置。';

  @override
  String get onevpnDirectRegionsCardBody =>
      '部分网站只有在您从网站所在的国家连接时才能正常使用。选择地区后，该地区的网站将绕过 VPN。';

  @override
  String onevpnSelectionReset(String location) {
    return '$location 不可用，1VPN 已切换为“自动”。';
  }

  @override
  String get onevpnSelectionResetUnnamed => '所选位置不可用，1VPN 已切换为“自动”。';

  @override
  String onevpnReloadRolledBack(String location) {
    return '无法切换到 $location。您仍与之前的位置保持连接。';
  }

  @override
  String get onevpnReloadRolledBackSettings => '无法应用此更改。您仍在使用之前的设置保持连接。';

  @override
  String get onevpnDirectRegionsOff => '关闭（默认）';

  @override
  String get onevpnAllViaVpnSubtitle => '所有流量都通过隧道';

  @override
  String get onevpnRegionChina => '中国';

  @override
  String get onevpnFirstConnectTitle => '部分地区直连效果更好';

  @override
  String get onevpnFirstConnectPointBreaks =>
      '在中国、俄罗斯和伊朗等地，让所有流量都通过 VPN 可能导致本地银行和支付应用无法正常使用。';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN 可将您选择的地区设为直连，在隧道之外使用您的真实 IP 访问。';

  @override
  String get onevpnFirstConnectPointProtected => '其他流量仍受保护。您可以随时更改此设置。';

  @override
  String get onevpnFirstConnectChooseRegion => '选择直连地区';

  @override
  String get onevpnFirstConnectDismiss => '以后再说';

  @override
  String get onevpnCensorshipWarning =>
      '由于政府限制，部分服务器在中国可能无法访问。我们正在努力解决此问题。感谢您的理解。';

  @override
  String get onevpnAlwaysOnTitle => '始终开启的 VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      '关闭应用后，隧道仍保持连接。重启或应用更新后，“始终开启的 VPN”会自动重新连接隧道。';

  @override
  String get onevpnAlwaysOnStep1 => '点按下方的“前往 VPN 设置”。';

  @override
  String get onevpnAlwaysOnStep2 => '在列表中找到 1VPN。首次连接后它才会出现。';

  @override
  String get onevpnAlwaysOnStep3 => '点按 1VPN 旁边的齿轮图标。';

  @override
  String get onevpnAlwaysOnStep4 => '打开“始终开启的 VPN”。';

  @override
  String get onevpnAlwaysOnOpenSettings => '前往 VPN 设置';

  @override
  String get onevpnPaywallTitle => '选择您的套餐';

  @override
  String get onevpnPaywallBenefitLocations => '解锁所有服务器位置';

  @override
  String get onevpnPaywallBenefitNoAds => '无广告';

  @override
  String get onevpnPaywallBenefitSpeed => '更快的服务器速度';

  @override
  String get onevpnPaywallBenefitP2p => '支持 BitTorrent（P2P）';

  @override
  String get onevpnPaywallBenefitMoneyBack => '10天退款保证';

  @override
  String get onevpnPaywallPlanYearly => '年度';

  @override
  String get onevpnPaywallPlanMonthly => '月度';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '节省 $percent%';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / 月';
  }

  @override
  String get onevpnPaywallPriceUnavailable => '暂无价格';

  @override
  String get onevpnPaywallPlansLoadFailed => '无法加载套餐。请检查您的网络连接。';

  @override
  String get onevpnPaywallPlansUnavailable => '目前没有可用的套餐。请稍后重试。';

  @override
  String get onevpnGetPremium => '获取高级版';

  @override
  String get onevpnContinueFree => '免费继续';

  @override
  String get onevpnPaywallRetry => '重试';

  @override
  String get onevpnPaywallPurchaseError => '出了点问题。请重试。';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return '此 Google 账户有一个有效或近期结束的 1VPN 订阅，该订阅已关联到另一个 1VPN 账户。请登录该账户，或联系 $support。';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return '此 Google 账户已有 1VPN 订阅。如果未显示高级版，请联系 $support。';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play 未完成您的上一次购买。请关闭所有打开的 Google Play 界面后重试，或重启应用。';

  @override
  String get onevpnPaywallSupportLink => '1VPN 客服';

  @override
  String get onevpnSignUp => '注册';

  @override
  String get onevpnAuthEmailLabel => '电子邮箱';

  @override
  String get onevpnAuthPasswordLabel => '密码';

  @override
  String get onevpnAuthTwoFactorLabel => '2FA 验证码';

  @override
  String get onevpnAuthForgotPassword => '忘记密码？';

  @override
  String get onevpnAuthSubmitting => '正在加载…';

  @override
  String get onevpnAuthCreateAccount => '创建账户';

  @override
  String get onevpnAuthHaveAccount => '已有账户？';

  @override
  String get onevpnAuthLogInInstead => '改为登录';

  @override
  String get onevpnAuthFieldsRequired => '请输入电子邮箱和密码';

  @override
  String get onevpnAuthInvalidEmail => '请输入有效的电子邮箱地址';

  @override
  String get onevpnAuthInvalidCredentials => '电子邮箱或密码错误';

  @override
  String get onevpnAuthInvalidTwoFactor => '2FA 验证码无效';

  @override
  String get onevpnAuthEmailInUse => '该电子邮箱已被注册';

  @override
  String get onevpnAuthRateLimited => '尝试次数过多，请稍后重试';

  @override
  String get onevpnAuthUnreachable => '无法连接到服务器，请检查您的网络连接后重试';

  @override
  String get onevpnAuthGenericError => '出了点问题。请重试';

  @override
  String get onevpnAuthEmailLockedHint => '您购买的项目已关联到此电子邮箱地址。';

  @override
  String get onevpnPaywallPurchasedTitle => '购买完成';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return '您购买的项目已关联到 $email。使用该地址创建账户后即可使用。';
  }

  @override
  String get onevpnPlanPremiumPending => '高级版 · 正在确认购买';

  @override
  String get onevpnPremiumRecheck => '正在检查您的购买状态…';

  @override
  String get onevpnButtonRetry => '重试';

  @override
  String get onevpnAppVersion => 'App 版本';

  @override
  String get onevpnPrivacyPolicy => '隐私政策';

  @override
  String get onevpnConnect => '连接';

  @override
  String get onevpnDisconnected => '未连接';

  @override
  String get onevpnConnecting => '正在连接…';

  @override
  String get onevpnConnected => '已连接';

  @override
  String get onevpnDisconnecting => '正在断开…';

  @override
  String get onevpnConnectionFailed => '连接失败';

  @override
  String get onevpnTemporarilyUnavailable => '暂时不可用';

  @override
  String get onevpnRetry => '重试';

  @override
  String get onevpnApplyChange => '应用这项更改？';

  @override
  String get onevpnReconnectNotice => 'VPN 会短暂断开并重新连接，通常只需几秒。';

  @override
  String onevpnWillUseName(String name) {
    return '将使用：$name';
  }

  @override
  String get onevpnApplyAndReconnect => '应用并重新连接';

  @override
  String get onevpnCancel => '取消';

  @override
  String get onevpnContinue => '继续';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return '主域名已被封锁。正在使用备用域名：$domain';
  }

  @override
  String get onevpnResultFailed => '失败';

  @override
  String get onevpnDownload => '下载';

  @override
  String get onevpnPermissionNotGranted => '尚未获得授权';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action $result';
  }

  @override
  String get onevpnDisconnect => '断开';

  @override
  String get onevpnTimeout => '超时';

  @override
  String get onevpnNoAvailableEntries => '没有可用的接入节点';

  @override
  String get onevpnAddServers => '添加服务器';

  @override
  String get onevpnNotEnoughServers => '可用节点数量不足';

  @override
  String get onevpnVpnFinalExit => 'VPN 最终出口';

  @override
  String get onevpnFinalExitEntryConflict => '最终出口不能同时作为接入服务器。';

  @override
  String get onevpnChooseNamedRoute => '选择一个具名路由方案';

  @override
  String get onevpnAllowLocalNetworkHint => '允许访问本地网络中的设备和服务。';

  @override
  String get onevpnSystemApprovalRequired => '需要系统批准';

  @override
  String get onevpnVpnPermissionRequired => '未完成 VPN 授权，请重试后继续。';

  @override
  String get onevpnChooseInterfaceNotice => '选择用于访问网络的网卡，仅 Windows / Linux 需要。';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': '安道尔',
      'AE': '阿拉伯联合酋长国',
      'AF': '阿富汗',
      'AG': '安提瓜和巴布达',
      'AI': '安圭拉',
      'AL': '阿尔巴尼亚',
      'AM': '亚美尼亚',
      'AO': '安哥拉',
      'AQ': '南极洲',
      'AR': '阿根廷',
      'AS': '美属萨摩亚',
      'AT': '奥地利',
      'AU': '澳大利亚',
      'AW': '阿鲁巴',
      'AX': '奥兰群岛',
      'AZ': '阿塞拜疆',
      'BA': '波斯尼亚和黑塞哥维那',
      'BB': '巴巴多斯',
      'BD': '孟加拉国',
      'BE': '比利时',
      'BF': '布基纳法索',
      'BG': '保加利亚',
      'BH': '巴林',
      'BI': '布隆迪',
      'BJ': '贝宁',
      'BL': '圣巴泰勒米',
      'BM': '百慕大',
      'BN': '文莱',
      'BO': '玻利维亚',
      'BQ': '荷属加勒比区',
      'BR': '巴西',
      'BS': '巴哈马',
      'BT': '不丹',
      'BV': '布韦岛',
      'BW': '博茨瓦纳',
      'BY': '白俄罗斯',
      'BZ': '伯利兹',
      'CA': '加拿大',
      'CC': '科科斯（基林）群岛',
      'CD': '刚果（金）',
      'CF': '中非共和国',
      'CG': '刚果（布）',
      'CH': '瑞士',
      'CI': '科特迪瓦',
      'CK': '库克群岛',
      'CL': '智利',
      'CM': '喀麦隆',
      'CN': '中国大陆',
      'CO': '哥伦比亚',
      'CR': '哥斯达黎加',
      'CU': '古巴',
      'CV': '佛得角',
      'CW': '库拉索',
      'CX': '圣诞岛',
      'CY': '塞浦路斯',
      'CZ': '捷克',
      'DE': '德国',
      'DJ': '吉布提',
      'DK': '丹麦',
      'DM': '多米尼克',
      'DO': '多米尼加共和国',
      'DZ': '阿尔及利亚',
      'EC': '厄瓜多尔',
      'EE': '爱沙尼亚',
      'EG': '埃及',
      'EH': '西撒哈拉',
      'ER': '厄立特里亚',
      'ES': '西班牙',
      'ET': '埃塞俄比亚',
      'FI': '芬兰',
      'FJ': '斐济',
      'FK': '福克兰群岛',
      'FM': '密克罗尼西亚',
      'FO': '法罗群岛',
      'FR': '法国',
      'GA': '加蓬',
      'GB': '英国',
      'GD': '格林纳达',
      'GE': '格鲁吉亚',
      'GF': '法属圭亚那',
      'GG': '根西岛',
      'GH': '加纳',
      'GI': '直布罗陀',
      'GL': '格陵兰',
      'GM': '冈比亚',
      'GN': '几内亚',
      'GP': '瓜德罗普',
      'GQ': '赤道几内亚',
      'GR': '希腊',
      'GS': '南乔治亚和南桑威奇群岛',
      'GT': '危地马拉',
      'GU': '关岛',
      'GW': '几内亚比绍',
      'GY': '圭亚那',
      'HK': '中国香港',
      'HM': '赫德岛和麦克唐纳群岛',
      'HN': '洪都拉斯',
      'HR': '克罗地亚',
      'HT': '海地',
      'HU': '匈牙利',
      'ID': '印度尼西亚',
      'IE': '爱尔兰',
      'IL': '以色列',
      'IM': '马恩岛',
      'IN': '印度',
      'IO': '查戈斯群岛',
      'IQ': '伊拉克',
      'IR': '伊朗',
      'IS': '冰岛',
      'IT': '意大利',
      'JE': '泽西岛',
      'JM': '牙买加',
      'JO': '约旦',
      'JP': '日本',
      'KE': '肯尼亚',
      'KG': '吉尔吉斯斯坦',
      'KH': '柬埔寨',
      'KI': '基里巴斯',
      'KM': '科摩罗',
      'KN': '圣基茨和尼维斯',
      'KP': '朝鲜',
      'KR': '韩国',
      'KW': '科威特',
      'KY': '开曼群岛',
      'KZ': '哈萨克斯坦',
      'LA': '老挝',
      'LB': '黎巴嫩',
      'LC': '圣卢西亚',
      'LI': '列支敦士登',
      'LK': '斯里兰卡',
      'LR': '利比里亚',
      'LS': '莱索托',
      'LT': '立陶宛',
      'LU': '卢森堡',
      'LV': '拉脱维亚',
      'LY': '利比亚',
      'MA': '摩洛哥',
      'MC': '摩纳哥',
      'MD': '摩尔多瓦',
      'ME': '黑山',
      'MF': '法属圣马丁',
      'MG': '马达加斯加',
      'MH': '马绍尔群岛',
      'MK': '北马其顿',
      'ML': '马里',
      'MM': '缅甸',
      'MN': '蒙古',
      'MO': '澳门',
      'MP': '北马里亚纳群岛',
      'MQ': '马提尼克',
      'MR': '毛里塔尼亚',
      'MS': '蒙特塞拉特',
      'MT': '马耳他',
      'MU': '毛里求斯',
      'MV': '马尔代夫',
      'MW': '马拉维',
      'MX': '墨西哥',
      'MY': '马来西亚',
      'MZ': '莫桑比克',
      'NA': '纳米比亚',
      'NC': '新喀里多尼亚',
      'NE': '尼日尔',
      'NF': '诺福克岛',
      'NG': '尼日利亚',
      'NI': '尼加拉瓜',
      'NL': '荷兰',
      'NO': '挪威',
      'NP': '尼泊尔',
      'NR': '瑙鲁',
      'NU': '纽埃',
      'NZ': '新西兰',
      'OM': '阿曼',
      'PA': '巴拿马',
      'PE': '秘鲁',
      'PF': '法属波利尼西亚',
      'PG': '巴布亚新几内亚',
      'PH': '菲律宾',
      'PK': '巴基斯坦',
      'PL': '波兰',
      'PM': '圣皮埃尔和密克隆群岛',
      'PN': '皮特凯恩群岛',
      'PR': '波多黎各',
      'PS': '巴勒斯坦领土',
      'PT': '葡萄牙',
      'PW': '帕劳',
      'PY': '巴拉圭',
      'QA': '卡塔尔',
      'RE': '留尼汪',
      'RO': '罗马尼亚',
      'RS': '塞尔维亚',
      'RU': '俄罗斯',
      'RW': '卢旺达',
      'SA': '沙特阿拉伯',
      'SB': '所罗门群岛',
      'SC': '塞舌尔',
      'SD': '苏丹',
      'SE': '瑞典',
      'SG': '新加坡',
      'SH': '圣赫勒拿',
      'SI': '斯洛文尼亚',
      'SJ': '斯瓦尔巴和扬马延',
      'SK': '斯洛伐克',
      'SL': '塞拉利昂',
      'SM': '圣马力诺',
      'SN': '塞内加尔',
      'SO': '索马里',
      'SR': '苏里南',
      'SS': '南苏丹',
      'ST': '圣多美和普林西比',
      'SV': '萨尔瓦多',
      'SX': '荷属圣马丁',
      'SY': '叙利亚',
      'SZ': '斯威士兰',
      'TC': '特克斯和凯科斯群岛',
      'TD': '乍得',
      'TF': '法属南部领地',
      'TG': '多哥',
      'TH': '泰国',
      'TJ': '塔吉克斯坦',
      'TK': '托克劳',
      'TL': '东帝汶',
      'TM': '土库曼斯坦',
      'TN': '突尼斯',
      'TO': '汤加',
      'TR': '土耳其',
      'TT': '特立尼达和多巴哥',
      'TV': '图瓦卢',
      'TW': '台湾',
      'TZ': '坦桑尼亚',
      'UA': '乌克兰',
      'UG': '乌干达',
      'UM': '美国本土外小岛屿',
      'US': '美国',
      'UY': '乌拉圭',
      'UZ': '乌兹别克斯坦',
      'VA': '梵蒂冈',
      'VC': '圣文森特和格林纳丁斯',
      'VE': '委内瑞拉',
      'VG': '英属维尔京群岛',
      'VI': '美属维尔京群岛',
      'VN': '越南',
      'VU': '瓦努阿图',
      'WF': '瓦利斯和富图纳',
      'WS': '萨摩亚',
      'XK': '科索沃',
      'YE': '也门',
      'YT': '马约特',
      'ZA': '南非',
      'ZM': '赞比亚',
      'ZW': '津巴布韦',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => '隐私选项';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': '阿姆斯特丹',
      'sgp': '新加坡',
      'lax': '洛杉矶',
      'mel': '墨尔本',
      'syd': '悉尼',
      'sao': '圣保罗',
      'yto': '多伦多',
      'scl': '圣地亚哥',
      'cdg': '巴黎',
      'fra': '法兰克福',
      'del': '德里',
      'bom': '孟买',
      'blr': '班加罗尔',
      'tlv': '特拉维夫',
      'itm': '大阪',
      'nrt': '东京',
      'mex': '墨西哥城',
      'waw': '华沙',
      'jnb': '约翰内斯堡',
      'icn': '首尔',
      'mad': '马德里',
      'sto': '斯德哥尔摩',
      'lhr': '伦敦',
      'man': '曼彻斯特',
      'ord': '芝加哥',
      'dfw': '达拉斯',
      'sea': '西雅图',
      'sjc': '旧金山',
      'mia': '迈阿密',
      'hnl': '火奴鲁鲁',
      'ewr': '纽约',
      'atl': '亚特兰大',
      'hkg': '香港',
      'zrh': '苏黎世',
      'gva': '日内瓦',
      'svo': '莫斯科',
      'led': '圣彼得堡',
      'hel': '赫尔辛基',
      'tpe': '台北',
      'dxb': '迪拜',
      'kbp': '基辅',
      'ist': '伊斯坦布尔',
      'otp': '布加勒斯特',
      'los': '拉各斯',
      'pty': '巴拿马城',
      'kef': '雷克雅未克',
      'ber': '柏林',
      'ala': '阿拉木图',
      'tbs': '第比利斯',
      'kul': '吉隆坡',
      'bkk': '曼谷',
      'cgk': '雅加达',
      'mnl': '马尼拉',
      'nbo': '内罗毕',
      'mxp': '米兰',
      'dub': '都柏林',
      'lis': '里斯本',
      'lux': '卢森堡',
      'eze': '布宜诺斯艾利斯',
      'akl': '奥克兰',
      'yul': '蒙特利尔',
      'yvr': '温哥华',
      'den': '丹佛',
      'phx': '凤凰城',
      'iad': '华盛顿',
      'bos': '波士顿',
      'edi': '爱丁堡',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => '您喜欢 1VPN 吗？';

  @override
  String get onevpnYes => '喜欢';

  @override
  String get onevpnNo => '不喜欢';

  @override
  String get onevpnLocationLocked => '已锁定，仅限高级版';

  @override
  String get onevpnManageSubscription => '管理订阅';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class OneVpnLocalizationsZhHant extends OneVpnLocalizationsZh {
  OneVpnLocalizationsZhHant() : super('zh_Hant');

  @override
  String get onevpnFaq => '常見問題';

  @override
  String get onevpnTermsOfService => '服務條款';

  @override
  String get onevpnMenu => '選單';

  @override
  String get onevpnUpgrade => '升級';

  @override
  String get onevpnUpgradeBannerTitle => '升級至高級版';

  @override
  String get onevpnUpgradeBannerSubtitle => '無廣告，所有位置，更快速度';

  @override
  String get onevpnLogIn => '登入';

  @override
  String get onevpnLogOut => '登出';

  @override
  String get onevpnAccount => '帳號';

  @override
  String get onevpnContactUs => '聯絡我們';

  @override
  String get onevpnRefundPolicy => '退款政策';

  @override
  String get onevpnSupport => '支援';

  @override
  String get onevpnLanguage => '語言';

  @override
  String get onevpnLanguageSystem => '跟隨系統';

  @override
  String get onevpnPlanFree => '免費方案';

  @override
  String get onevpnPlanPremium => '高級版方案';

  @override
  String get onevpnSelectLocation => '選擇位置';

  @override
  String get onevpnDirectRegions => '直連地區';

  @override
  String get onevpnFree => '免費';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · 免費';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return '自動 · $node';
  }

  @override
  String get onevpnAutomaticSelection => '自動';

  @override
  String get onevpnStatusNoConnection => '無連線';

  @override
  String get onevpnStatusConnectionFailed => '連線失敗';

  @override
  String get onevpnStatusUpdating => '正在更新…';

  @override
  String get onevpnStatusMeasuring => '正在為伺服器測速…';

  @override
  String get onevpnAutomaticSubtitle => '最快的可用伺服器';

  @override
  String get onevpnLocationsLoadFailed => '無法載入您的伺服器位置。';

  @override
  String get onevpnLocationsUnavailable => '目前沒有可用的位置。';

  @override
  String get onevpnDirectRegionsCardBody =>
      '部分網站只有在您從網站所在的國家連線時才能正常使用。選擇地區後，該地區的網站將繞過 VPN。';

  @override
  String onevpnSelectionReset(String location) {
    return '$location 不可用，1VPN 已切換為「自動」。';
  }

  @override
  String get onevpnSelectionResetUnnamed => '所選位置不可用，1VPN 已切換為「自動」。';

  @override
  String onevpnReloadRolledBack(String location) {
    return '無法切換至 $location。您仍與先前的位置保持連線。';
  }

  @override
  String get onevpnReloadRolledBackSettings => '無法套用此變更。您仍以先前的設定保持連線。';

  @override
  String get onevpnDirectRegionsOff => '關閉（預設）';

  @override
  String get onevpnAllViaVpnSubtitle => '所有流量都通過隧道';

  @override
  String get onevpnRegionChina => '中國';

  @override
  String get onevpnFirstConnectTitle => '部分地區直連效果更好';

  @override
  String get onevpnFirstConnectPointBreaks =>
      '在中國、俄羅斯和伊朗等地，讓所有流量都通過 VPN 可能導致當地的銀行和支付 App 無法正常使用。';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN 可將您選擇的地區設為直連，在隧道之外以您的真實 IP 存取。';

  @override
  String get onevpnFirstConnectPointProtected => '其他流量仍受保護。您可以隨時變更此設定。';

  @override
  String get onevpnFirstConnectChooseRegion => '選擇直連地區';

  @override
  String get onevpnFirstConnectDismiss => '以後再說';

  @override
  String get onevpnCensorshipWarning =>
      '由於政府限制，部分伺服器在中國可能無法存取。我們正在努力解決此問題。感謝您的理解。';

  @override
  String get onevpnAlwaysOnTitle => '永久連線 VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      '關閉 App 後，隧道仍會保持連線。重新啟動或 App 更新後，「永久連線 VPN」會自動恢復連線。';

  @override
  String get onevpnAlwaysOnStep1 => '輕觸下方的「前往 VPN 設定」。';

  @override
  String get onevpnAlwaysOnStep2 => '在清單中找到 1VPN。首次連線後才會顯示。';

  @override
  String get onevpnAlwaysOnStep3 => '輕觸 1VPN 旁邊的齒輪圖示。';

  @override
  String get onevpnAlwaysOnStep4 => '開啟「永久連線 VPN」。';

  @override
  String get onevpnAlwaysOnOpenSettings => '前往 VPN 設定';

  @override
  String get onevpnPaywallTitle => '選擇您的方案';

  @override
  String get onevpnPaywallBenefitLocations => '解鎖所有伺服器位置';

  @override
  String get onevpnPaywallBenefitNoAds => '無廣告';

  @override
  String get onevpnPaywallBenefitSpeed => '更快的伺服器速度';

  @override
  String get onevpnPaywallBenefitP2p => '支援 BitTorrent（P2P）';

  @override
  String get onevpnPaywallBenefitMoneyBack => '10天退款保證';

  @override
  String get onevpnPaywallPlanYearly => '年度';

  @override
  String get onevpnPaywallPlanMonthly => '月度';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '節省 $percent%';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / 月';
  }

  @override
  String get onevpnPaywallPriceUnavailable => '無法取得價格';

  @override
  String get onevpnPaywallPlansLoadFailed => '無法載入方案。請檢查您的網路連線。';

  @override
  String get onevpnPaywallPlansUnavailable => '目前沒有可用的方案。請稍後再試。';

  @override
  String get onevpnGetPremium => '取得高級版';

  @override
  String get onevpnContinueFree => '免費繼續';

  @override
  String get onevpnPaywallRetry => '重試';

  @override
  String get onevpnPaywallPurchaseError => '發生問題。請再試一次。';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return '此 Google 帳號有一個有效或近期結束的 1VPN 訂閱，該訂閱已連結至另一個 1VPN 帳號。請登入該帳號，或聯絡 $support。';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return '此 Google 帳號已有 1VPN 訂閱。如果未顯示高級版，請聯絡 $support。';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play 未完成您的上一筆購買。請關閉所有開啟的 Google Play 畫面後再試一次，或重新啟動 App。';

  @override
  String get onevpnPaywallSupportLink => '1VPN 客服';

  @override
  String get onevpnSignUp => '註冊';

  @override
  String get onevpnAuthEmailLabel => '電子郵件';

  @override
  String get onevpnAuthPasswordLabel => '密碼';

  @override
  String get onevpnAuthTwoFactorLabel => '2FA 驗證碼';

  @override
  String get onevpnAuthForgotPassword => '忘記密碼？';

  @override
  String get onevpnAuthSubmitting => '正在載入…';

  @override
  String get onevpnAuthCreateAccount => '建立帳號';

  @override
  String get onevpnAuthHaveAccount => '已有帳號？';

  @override
  String get onevpnAuthLogInInstead => '改為登入';

  @override
  String get onevpnAuthFieldsRequired => '請輸入電子郵件和密碼';

  @override
  String get onevpnAuthInvalidEmail => '請輸入有效的電子郵件地址';

  @override
  String get onevpnAuthInvalidCredentials => '電子郵件或密碼錯誤';

  @override
  String get onevpnAuthInvalidTwoFactor => '2FA 驗證碼無效';

  @override
  String get onevpnAuthEmailInUse => '此電子郵件已有帳號';

  @override
  String get onevpnAuthRateLimited => '嘗試次數過多。請稍後再試';

  @override
  String get onevpnAuthUnreachable => '無法連線至伺服器。請檢查您的網路連線後再試一次';

  @override
  String get onevpnAuthGenericError => '發生問題。請再試一次';

  @override
  String get onevpnAuthEmailLockedHint => '您購買的項目已連結至此電子郵件地址。';

  @override
  String get onevpnPaywallPurchasedTitle => '購買完成';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return '您購買的項目已連結至 $email。使用該地址建立帳號後，即可開始使用。';
  }

  @override
  String get onevpnPlanPremiumPending => '高級版 · 正在確認購買';

  @override
  String get onevpnPremiumRecheck => '正在檢查您的購買狀態…';

  @override
  String get onevpnButtonRetry => '重試';

  @override
  String get onevpnAppVersion => 'App 版本';

  @override
  String get onevpnPrivacyPolicy => '隱私政策';

  @override
  String get onevpnConnect => '連線';

  @override
  String get onevpnDisconnected => '未連線';

  @override
  String get onevpnConnecting => '正在連線…';

  @override
  String get onevpnConnected => '已連線';

  @override
  String get onevpnDisconnecting => '正在中斷連線…';

  @override
  String get onevpnConnectionFailed => '連線失敗';

  @override
  String get onevpnTemporarilyUnavailable => '暫時不可用';

  @override
  String get onevpnRetry => '重試';

  @override
  String get onevpnApplyChange => '套用這項變更？';

  @override
  String get onevpnReconnectNotice => 'VPN 會短暫中斷連線並重新連線，通常只需幾秒。';

  @override
  String onevpnWillUseName(String name) {
    return '將使用：$name';
  }

  @override
  String get onevpnApplyAndReconnect => '套用並重新連線';

  @override
  String get onevpnCancel => '取消';

  @override
  String get onevpnContinue => '繼續';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return '主網域已被封鎖。正在使用備用網域：$domain';
  }

  @override
  String get onevpnResultFailed => '失敗';

  @override
  String get onevpnDownload => '下載';

  @override
  String get onevpnPermissionNotGranted => '尚未獲得授權';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action $result';
  }

  @override
  String get onevpnDisconnect => '中斷連線';

  @override
  String get onevpnTimeout => '逾時';

  @override
  String get onevpnNoAvailableEntries => '沒有可用的接入節點';

  @override
  String get onevpnAddServers => '新增伺服器';

  @override
  String get onevpnNotEnoughServers => '可用節點數量不足';

  @override
  String get onevpnVpnFinalExit => 'VPN 最終出口';

  @override
  String get onevpnFinalExitEntryConflict => '最終出口不能同時作為接入伺服器。';

  @override
  String get onevpnChooseNamedRoute => '選擇一個具名路由方案';

  @override
  String get onevpnAllowLocalNetworkHint => '允許存取區域網路中的裝置和服務。';

  @override
  String get onevpnSystemApprovalRequired => '需要系統核准';

  @override
  String get onevpnVpnPermissionRequired => '未完成 VPN 授權，請重試後繼續。';

  @override
  String get onevpnChooseInterfaceNotice =>
      '選擇用於存取網路的網路介面卡，僅 Windows / Linux 需要。';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': '安道爾',
      'AE': '阿拉伯聯合大公國',
      'AF': '阿富汗',
      'AG': '安地卡及巴布達',
      'AI': '安奎拉',
      'AL': '阿爾巴尼亞',
      'AM': '亞美尼亞',
      'AO': '安哥拉',
      'AQ': '南極洲',
      'AR': '阿根廷',
      'AS': '美屬薩摩亞',
      'AT': '奧地利',
      'AU': '澳洲',
      'AW': '荷屬阿魯巴',
      'AX': '奧蘭群島',
      'AZ': '亞塞拜然',
      'BA': '波士尼亞與赫塞哥維納',
      'BB': '巴貝多',
      'BD': '孟加拉',
      'BE': '比利時',
      'BF': '布吉納法索',
      'BG': '保加利亞',
      'BH': '巴林',
      'BI': '蒲隆地',
      'BJ': '貝南',
      'BL': '聖巴瑟米',
      'BM': '百慕達',
      'BN': '汶萊',
      'BO': '玻利維亞',
      'BQ': '荷蘭加勒比區',
      'BR': '巴西',
      'BS': '巴哈馬',
      'BT': '不丹',
      'BV': '布威島',
      'BW': '波札那',
      'BY': '白俄羅斯',
      'BZ': '貝里斯',
      'CA': '加拿大',
      'CC': '科克斯（基靈）群島',
      'CD': '剛果（金夏沙）',
      'CF': '中非共和國',
      'CG': '剛果（布拉薩）',
      'CH': '瑞士',
      'CI': '象牙海岸',
      'CK': '庫克群島',
      'CL': '智利',
      'CM': '喀麥隆',
      'CN': '中國大陸',
      'CO': '哥倫比亞',
      'CR': '哥斯大黎加',
      'CU': '古巴',
      'CV': '維德角',
      'CW': '庫拉索',
      'CX': '聖誕島',
      'CY': '賽普勒斯',
      'CZ': '捷克',
      'DE': '德國',
      'DJ': '吉布地',
      'DK': '丹麥',
      'DM': '多米尼克',
      'DO': '多明尼加共和國',
      'DZ': '阿爾及利亞',
      'EC': '厄瓜多',
      'EE': '愛沙尼亞',
      'EG': '埃及',
      'EH': '西撒哈拉',
      'ER': '厄利垂亞',
      'ES': '西班牙',
      'ET': '衣索比亞',
      'FI': '芬蘭',
      'FJ': '斐濟',
      'FK': '福克蘭群島',
      'FM': '密克羅尼西亞',
      'FO': '法羅群島',
      'FR': '法國',
      'GA': '加彭',
      'GB': '英國',
      'GD': '格瑞那達',
      'GE': '喬治亞',
      'GF': '法屬圭亞那',
      'GG': '根息',
      'GH': '迦納',
      'GI': '直布羅陀',
      'GL': '格陵蘭',
      'GM': '甘比亞',
      'GN': '幾內亞',
      'GP': '瓜地洛普',
      'GQ': '赤道幾內亞',
      'GR': '希臘',
      'GS': '南喬治亞與南三明治群島',
      'GT': '瓜地馬拉',
      'GU': '關島',
      'GW': '幾內亞比索',
      'GY': '蓋亞那',
      'HK': '中國香港',
      'HM': '赫德島及麥唐納群島',
      'HN': '宏都拉斯',
      'HR': '克羅埃西亞',
      'HT': '海地',
      'HU': '匈牙利',
      'ID': '印尼',
      'IE': '愛爾蘭',
      'IL': '以色列',
      'IM': '曼島',
      'IN': '印度',
      'IO': '查戈斯群島',
      'IQ': '伊拉克',
      'IR': '伊朗',
      'IS': '冰島',
      'IT': '義大利',
      'JE': '澤西島',
      'JM': '牙買加',
      'JO': '約旦',
      'JP': '日本',
      'KE': '肯亞',
      'KG': '吉爾吉斯',
      'KH': '柬埔寨',
      'KI': '吉里巴斯',
      'KM': '葛摩',
      'KN': '聖克里斯多福及尼維斯',
      'KP': '北韓',
      'KR': '韓國',
      'KW': '科威特',
      'KY': '開曼群島',
      'KZ': '哈薩克',
      'LA': '寮國',
      'LB': '黎巴嫩',
      'LC': '聖露西亞',
      'LI': '列支敦斯登',
      'LK': '斯里蘭卡',
      'LR': '賴比瑞亞',
      'LS': '賴索托',
      'LT': '立陶宛',
      'LU': '盧森堡',
      'LV': '拉脫維亞',
      'LY': '利比亞',
      'MA': '摩洛哥',
      'MC': '摩納哥',
      'MD': '摩爾多瓦',
      'ME': '蒙特內哥羅',
      'MF': '法屬聖馬丁',
      'MG': '馬達加斯加',
      'MH': '馬紹爾群島',
      'MK': '北馬其頓',
      'ML': '馬利',
      'MM': '緬甸',
      'MN': '蒙古',
      'MO': '澳門',
      'MP': '北馬利安納群島',
      'MQ': '馬丁尼克',
      'MR': '茅利塔尼亞',
      'MS': '蒙哲臘',
      'MT': '馬爾他',
      'MU': '模里西斯',
      'MV': '馬爾地夫',
      'MW': '馬拉威',
      'MX': '墨西哥',
      'MY': '馬來西亞',
      'MZ': '莫三比克',
      'NA': '納米比亞',
      'NC': '新喀里多尼亞',
      'NE': '尼日',
      'NF': '諾福克島',
      'NG': '奈及利亞',
      'NI': '尼加拉瓜',
      'NL': '荷蘭',
      'NO': '挪威',
      'NP': '尼泊爾',
      'NR': '諾魯',
      'NU': '紐埃島',
      'NZ': '紐西蘭',
      'OM': '阿曼',
      'PA': '巴拿馬',
      'PE': '秘魯',
      'PF': '法屬玻里尼西亞',
      'PG': '巴布亞紐幾內亞',
      'PH': '菲律賓',
      'PK': '巴基斯坦',
      'PL': '波蘭',
      'PM': '聖皮埃與密克隆群島',
      'PN': '皮特肯群島',
      'PR': '波多黎各',
      'PS': '巴勒斯坦自治區',
      'PT': '葡萄牙',
      'PW': '帛琉',
      'PY': '巴拉圭',
      'QA': '卡達',
      'RE': '留尼旺',
      'RO': '羅馬尼亞',
      'RS': '塞爾維亞',
      'RU': '俄羅斯',
      'RW': '盧安達',
      'SA': '沙烏地阿拉伯',
      'SB': '索羅門群島',
      'SC': '塞席爾',
      'SD': '蘇丹',
      'SE': '瑞典',
      'SG': '新加坡',
      'SH': '聖赫勒拿島',
      'SI': '斯洛維尼亞',
      'SJ': '挪威屬斯瓦巴及尖棉',
      'SK': '斯洛伐克',
      'SL': '獅子山共和國',
      'SM': '聖馬利諾',
      'SN': '塞內加爾',
      'SO': '索馬利亞',
      'SR': '蘇利南',
      'SS': '南蘇丹',
      'ST': '聖多美普林西比',
      'SV': '薩爾瓦多',
      'SX': '荷屬聖馬丁',
      'SY': '敘利亞',
      'SZ': '史瓦帝尼',
      'TC': '土克斯及開科斯群島',
      'TD': '查德',
      'TF': '法屬南部屬地',
      'TG': '多哥',
      'TH': '泰國',
      'TJ': '塔吉克',
      'TK': '托克勞群島',
      'TL': '東帝汶',
      'TM': '土庫曼',
      'TN': '突尼西亞',
      'TO': '東加',
      'TR': '土耳其',
      'TT': '千里達及托巴哥',
      'TV': '吐瓦魯',
      'TW': '台灣',
      'TZ': '坦尚尼亞',
      'UA': '烏克蘭',
      'UG': '烏干達',
      'UM': '美國本土外小島嶼',
      'US': '美國',
      'UY': '烏拉圭',
      'UZ': '烏茲別克',
      'VA': '梵蒂岡',
      'VC': '聖文森及格瑞那丁',
      'VE': '委內瑞拉',
      'VG': '英屬維京群島',
      'VI': '美屬維京群島',
      'VN': '越南',
      'VU': '萬那杜',
      'WF': '瓦利斯群島和富圖那群島',
      'WS': '薩摩亞',
      'XK': '科索沃',
      'YE': '葉門',
      'YT': '馬約特島',
      'ZA': '南非',
      'ZM': '尚比亞',
      'ZW': '辛巴威',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => '隱私選項';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': '阿姆斯特丹',
      'sgp': '新加坡',
      'lax': '洛杉磯',
      'mel': '墨爾本',
      'syd': '雪梨',
      'sao': '聖保羅',
      'yto': '多倫多',
      'scl': '聖地牙哥',
      'cdg': '巴黎',
      'fra': '法蘭克福',
      'del': '德里',
      'bom': '孟買',
      'blr': '班加羅爾',
      'tlv': '特拉維夫',
      'itm': '大阪',
      'nrt': '東京',
      'mex': '墨西哥城',
      'waw': '華沙',
      'jnb': '約翰尼斯堡',
      'icn': '首爾',
      'mad': '馬德里',
      'sto': '斯德哥爾摩',
      'lhr': '倫敦',
      'man': '曼徹斯特',
      'ord': '芝加哥',
      'dfw': '達拉斯',
      'sea': '西雅圖',
      'sjc': '舊金山',
      'mia': '邁阿密',
      'hnl': '火奴魯魯',
      'ewr': '紐約',
      'atl': '亞特蘭大',
      'hkg': '香港',
      'zrh': '蘇黎世',
      'gva': '日內瓦',
      'svo': '莫斯科',
      'led': '聖彼得堡',
      'hel': '赫爾辛基',
      'tpe': '台北',
      'dxb': '杜拜',
      'kbp': '基輔',
      'ist': '伊斯坦堡',
      'otp': '布加勒斯特',
      'los': '拉哥斯',
      'pty': '巴拿馬市',
      'kef': '雷克雅維克',
      'ber': '柏林',
      'ala': '阿拉木圖',
      'tbs': '提比里斯',
      'kul': '吉隆坡',
      'bkk': '曼谷',
      'cgk': '雅加達',
      'mnl': '馬尼拉',
      'nbo': '奈洛比',
      'mxp': '米蘭',
      'dub': '都柏林',
      'lis': '里斯本',
      'lux': '盧森堡',
      'eze': '布宜諾斯艾利斯',
      'akl': '奧克蘭',
      'yul': '蒙特婁',
      'yvr': '溫哥華',
      'den': '丹佛',
      'phx': '鳳凰城',
      'iad': '華盛頓',
      'bos': '波士頓',
      'edi': '愛丁堡',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => '您喜歡 1VPN 嗎？';

  @override
  String get onevpnYes => '喜歡';

  @override
  String get onevpnNo => '不喜歡';

  @override
  String get onevpnLocationLocked => '已鎖定，僅限高級版';

  @override
  String get onevpnManageSubscription => '管理訂閱';
}
