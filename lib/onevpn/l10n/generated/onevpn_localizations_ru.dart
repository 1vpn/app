// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class OneVpnLocalizationsRu extends OneVpnLocalizations {
  OneVpnLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get onevpnFaq => 'Частые вопросы';

  @override
  String get onevpnTermsOfService => 'Условия использования';

  @override
  String get onevpnMenu => 'Меню';

  @override
  String get onevpnUpgrade => 'Перейти на Премиум';

  @override
  String get onevpnUpgradeBannerTitle => 'Перейти на Премиум';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Без рекламы, все локации и высокая скорость';

  @override
  String get onevpnLogIn => 'Войти';

  @override
  String get onevpnLogOut => 'Выйти';

  @override
  String get onevpnAccount => 'Аккаунт';

  @override
  String get onevpnContactUs => 'Связаться с нами';

  @override
  String get onevpnRefundPolicy => 'Политика возврата';

  @override
  String get onevpnSupport => 'Поддержка';

  @override
  String get onevpnLanguage => 'Язык';

  @override
  String get onevpnLanguageSystem => 'Как в системе';

  @override
  String get onevpnPlanFree => 'Бесплатный тариф';

  @override
  String get onevpnPlanPremium => 'Тариф Премиум';

  @override
  String get onevpnSelectLocation => 'Выбор локации';

  @override
  String get onevpnDirectRegions => 'Регионы прямого доступа';

  @override
  String get onevpnFree => 'Бесплатно';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Бесплатно';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Автоматически · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Автоматически';

  @override
  String get onevpnStatusNoConnection => 'Нет соединения';

  @override
  String get onevpnStatusConnectionFailed => 'Не удалось подключиться';

  @override
  String get onevpnStatusUpdating => 'Обновление…';

  @override
  String get onevpnStatusMeasuring => 'Проверка серверов…';

  @override
  String get onevpnAutomaticSubtitle => 'Самый быстрый из доступных';

  @override
  String get onevpnLocationsLoadFailed => 'Не удалось загрузить ваши локации.';

  @override
  String get onevpnLocationsUnavailable => 'Локации сейчас недоступны.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Некоторые сайты работают, только если вы подключаетесь из той же страны, что и сайт. Если выбрать регион, сайты этого региона будут открываться в обход VPN.';

  @override
  String onevpnSelectionReset(String location) {
    return 'Локация $location недоступна, 1VPN переключился на «Автоматически».';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'Выбранная локация недоступна, 1VPN переключился на «Автоматически».';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'Не удалось переключиться на локацию $location. Вы по-прежнему подключены к предыдущей локации.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Не удалось применить изменение. Вы по-прежнему подключены с предыдущими настройками.';

  @override
  String get onevpnDirectRegionsOff => 'Выключено (по умолчанию)';

  @override
  String get onevpnAllViaVpnSubtitle => 'Весь трафик через туннель';

  @override
  String get onevpnRegionChina => 'Китай';

  @override
  String get onevpnFirstConnectTitle =>
      'Некоторые регионы лучше работают напрямую';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'В таких странах, как Китай, Россия и Иран, передача всего трафика через VPN может нарушить работу местных банковских и платёжных приложений.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN может направлять трафик к выбранному вами региону напрямую, в обход туннеля, с вашего реального IP.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Всё остальное остаётся под защитой. Это можно изменить в любой момент.';

  @override
  String get onevpnFirstConnectChooseRegion => 'Выбрать регион прямого доступа';

  @override
  String get onevpnFirstConnectDismiss => 'Не сейчас';

  @override
  String get onevpnCensorshipWarning =>
      'Некоторые серверы могут быть заблокированы в России из-за государственных ограничений. Мы работаем над решением этой проблемы. Спасибо за понимание.';

  @override
  String get onevpnAlwaysOnTitle => 'Постоянная VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      'Туннель остаётся включённым, когда вы закрываете приложение. После перезагрузки или обновления приложения функция «Постоянная VPN» автоматически подключает его снова.';

  @override
  String get onevpnAlwaysOnStep1 => 'Нажмите «Открыть настройки VPN» ниже.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Найдите 1VPN в списке. Приложение появится там после первого подключения.';

  @override
  String get onevpnAlwaysOnStep3 => 'Нажмите значок шестерёнки рядом с 1VPN.';

  @override
  String get onevpnAlwaysOnStep4 => 'Включите параметр «Постоянная VPN».';

  @override
  String get onevpnAlwaysOnOpenSettings => 'Открыть настройки VPN';

  @override
  String get onevpnPaywallTitle => 'Выберите тариф';

  @override
  String get onevpnPaywallBenefitLocations =>
      'Доступ ко всем локациям серверов';

  @override
  String get onevpnPaywallBenefitNoAds => 'Без рекламы';

  @override
  String get onevpnPaywallBenefitSpeed => 'Более высокая скорость';

  @override
  String get onevpnPaywallBenefitP2p => 'Поддержка BitTorrent (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack =>
      '10-дневная гарантия возврата денег';

  @override
  String get onevpnPaywallPlanYearly => 'Годовой';

  @override
  String get onevpnPaywallPlanMonthly => 'Месячный';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'Экономия $percent%';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / мес.';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Цена недоступна';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Не удалось загрузить тарифы. Проверьте подключение.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Тарифы сейчас недоступны. Повторите попытку позже.';

  @override
  String get onevpnGetPremium => 'Получить Премиум';

  @override
  String get onevpnContinueFree => 'Продолжить бесплатно';

  @override
  String get onevpnPaywallRetry => 'Повторить';

  @override
  String get onevpnPaywallPurchaseError =>
      'Что-то пошло не так. Повторите попытку.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'У этого аккаунта Google есть действующая или недавно завершившаяся подписка 1VPN, привязанная к другому аккаунту 1VPN. Войдите в тот аккаунт или свяжитесь со $support.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'У этого аккаунта Google уже есть подписка 1VPN. Если Премиум не отображается, свяжитесь со $support.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play не завершил вашу последнюю покупку. Закройте открытые экраны Google Play и повторите попытку или перезапустите приложение.';

  @override
  String get onevpnPaywallSupportLink => 'службой поддержки 1VPN';

  @override
  String get onevpnSignUp => 'Зарегистрироваться';

  @override
  String get onevpnAuthEmailLabel => 'Электронная почта';

  @override
  String get onevpnAuthPasswordLabel => 'Пароль';

  @override
  String get onevpnAuthTwoFactorLabel => 'Код 2FA';

  @override
  String get onevpnAuthForgotPassword => 'Забыли пароль?';

  @override
  String get onevpnAuthSubmitting => 'Загрузка…';

  @override
  String get onevpnAuthCreateAccount => 'Создать аккаунт';

  @override
  String get onevpnAuthHaveAccount => 'Уже есть аккаунт?';

  @override
  String get onevpnAuthLogInInstead => 'Войти вместо регистрации';

  @override
  String get onevpnAuthFieldsRequired => 'Введите электронную почту и пароль';

  @override
  String get onevpnAuthInvalidEmail =>
      'Введите действительный адрес электронной почты';

  @override
  String get onevpnAuthInvalidCredentials =>
      'Неверный адрес электронной почты или пароль';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Неверный код 2FA';

  @override
  String get onevpnAuthEmailInUse =>
      'Аккаунт с этим адресом электронной почты уже существует';

  @override
  String get onevpnAuthRateLimited =>
      'Слишком много попыток. Попробуйте немного позже';

  @override
  String get onevpnAuthUnreachable =>
      'Не удалось связаться с сервером. Проверьте подключение и попробуйте снова';

  @override
  String get onevpnAuthGenericError => 'Что-то пошло не так. Повторите попытку';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Ваша покупка привязана к этому адресу электронной почты.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Покупка завершена';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Ваша покупка привязана к $email. Создайте аккаунт с этим адресом, чтобы воспользоваться покупкой.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Премиум · подтверждение покупки';

  @override
  String get onevpnPremiumRecheck => 'Проверка статуса покупки…';

  @override
  String get onevpnButtonRetry => 'Повторить';

  @override
  String get onevpnAppVersion => 'Версия приложения';

  @override
  String get onevpnPrivacyPolicy => 'Политика конфиденциальности';

  @override
  String get onevpnConnect => 'Подключение';

  @override
  String get onevpnDisconnected => 'Не подключено';

  @override
  String get onevpnConnecting => 'Подключение…';

  @override
  String get onevpnConnected => 'Подключено';

  @override
  String get onevpnDisconnecting => 'Отключение…';

  @override
  String get onevpnConnectionFailed => 'Не удалось подключиться';

  @override
  String get onevpnTemporarilyUnavailable => 'Временно недоступен';

  @override
  String get onevpnRetry => 'Повторить';

  @override
  String get onevpnApplyChange => 'Применить изменение?';

  @override
  String get onevpnReconnectNotice =>
      'VPN ненадолго отключится и подключится снова. Обычно это занимает несколько секунд.';

  @override
  String onevpnWillUseName(String name) {
    return 'Будет использовано: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Применить и переподключить';

  @override
  String get onevpnCancel => 'Отмена';

  @override
  String get onevpnContinue => 'Продолжить';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'Основной домен заблокирован. Используется резервный: $domain';
  }

  @override
  String get onevpnResultFailed => 'Ошибка';

  @override
  String get onevpnDownload => 'Загрузка';

  @override
  String get onevpnPermissionNotGranted => 'Разрешение не получено';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action $result';
  }

  @override
  String get onevpnDisconnect => 'Отключить';

  @override
  String get onevpnTimeout => 'Тайм-аут';

  @override
  String get onevpnNoAvailableEntries => 'Нет доступных входных узлов';

  @override
  String get onevpnAddServers => 'Добавить серверы';

  @override
  String get onevpnNotEnoughServers => 'Недостаточно доступных серверов';

  @override
  String get onevpnVpnFinalExit => 'Конечный выход VPN';

  @override
  String get onevpnFinalExitEntryConflict =>
      'Конечный выход не может одновременно быть входным узлом';

  @override
  String get onevpnChooseNamedRoute => 'Выберите схему маршрутизации';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Разрешить доступ к устройствам и службам локальной сети.';

  @override
  String get onevpnSystemApprovalRequired => 'Требуется разрешение системы';

  @override
  String get onevpnVpnPermissionRequired =>
      'Требуется разрешение VPN. Повторите попытку, чтобы продолжить.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Выберите интерфейс для доступа к сети. Требуется только в Windows / Linux.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Андорра',
      'AE': 'ОАЭ',
      'AF': 'Афганистан',
      'AG': 'Антигуа и Барбуда',
      'AI': 'Ангилья',
      'AL': 'Албания',
      'AM': 'Армения',
      'AO': 'Ангола',
      'AQ': 'Антарктида',
      'AR': 'Аргентина',
      'AS': 'Американское Самоа',
      'AT': 'Австрия',
      'AU': 'Австралия',
      'AW': 'Аруба',
      'AX': 'Аландские о-ва',
      'AZ': 'Азербайджан',
      'BA': 'Босния и Герцеговина',
      'BB': 'Барбадос',
      'BD': 'Бангладеш',
      'BE': 'Бельгия',
      'BF': 'Буркина-Фасо',
      'BG': 'Болгария',
      'BH': 'Бахрейн',
      'BI': 'Бурунди',
      'BJ': 'Бенин',
      'BL': 'Сен-Бартелеми',
      'BM': 'Бермудские о-ва',
      'BN': 'Бруней',
      'BO': 'Боливия',
      'BQ': 'Бонэйр, Синт-Эстатиус и Саба',
      'BR': 'Бразилия',
      'BS': 'Багамы',
      'BT': 'Бутан',
      'BV': 'о-в Буве',
      'BW': 'Ботсвана',
      'BY': 'Беларусь',
      'BZ': 'Белиз',
      'CA': 'Канада',
      'CC': 'Кокосовые о-ва',
      'CD': 'Конго - Киншаса',
      'CF': 'Центрально-Африканская Республика',
      'CG': 'Конго - Браззавиль',
      'CH': 'Швейцария',
      'CI': 'Кот-д’Ивуар',
      'CK': 'о-ва Кука',
      'CL': 'Чили',
      'CM': 'Камерун',
      'CN': 'Материковый Китай',
      'CO': 'Колумбия',
      'CR': 'Коста-Рика',
      'CU': 'Куба',
      'CV': 'Кабо-Верде',
      'CW': 'Кюрасао',
      'CX': 'о-в Рождества',
      'CY': 'Кипр',
      'CZ': 'Чехия',
      'DE': 'Германия',
      'DJ': 'Джибути',
      'DK': 'Дания',
      'DM': 'Доминика',
      'DO': 'Доминиканская Республика',
      'DZ': 'Алжир',
      'EC': 'Эквадор',
      'EE': 'Эстония',
      'EG': 'Египет',
      'EH': 'Западная Сахара',
      'ER': 'Эритрея',
      'ES': 'Испания',
      'ET': 'Эфиопия',
      'FI': 'Финляндия',
      'FJ': 'Фиджи',
      'FK': 'Фолклендские о-ва',
      'FM': 'Микронезия',
      'FO': 'Фарерские о-ва',
      'FR': 'Франция',
      'GA': 'Габон',
      'GB': 'Великобритания',
      'GD': 'Гренада',
      'GE': 'Грузия',
      'GF': 'Французская Гвиана',
      'GG': 'Гернси',
      'GH': 'Гана',
      'GI': 'Гибралтар',
      'GL': 'Гренландия',
      'GM': 'Гамбия',
      'GN': 'Гвинея',
      'GP': 'Гваделупа',
      'GQ': 'Экваториальная Гвинея',
      'GR': 'Греция',
      'GS': 'Южная Георгия и Южные Сандвичевы о-ва',
      'GT': 'Гватемала',
      'GU': 'Гуам',
      'GW': 'Гвинея-Бисау',
      'GY': 'Гайана',
      'HK': 'Гонконг',
      'HM': 'о-ва Херд и Макдональд',
      'HN': 'Гондурас',
      'HR': 'Хорватия',
      'HT': 'Гаити',
      'HU': 'Венгрия',
      'ID': 'Индонезия',
      'IE': 'Ирландия',
      'IL': 'Израиль',
      'IM': 'о-в Мэн',
      'IN': 'Индия',
      'IO': 'Архипелаг Чагос',
      'IQ': 'Ирак',
      'IR': 'Иран',
      'IS': 'Исландия',
      'IT': 'Италия',
      'JE': 'Джерси',
      'JM': 'Ямайка',
      'JO': 'Иордания',
      'JP': 'Япония',
      'KE': 'Кения',
      'KG': 'Киргизия',
      'KH': 'Камбоджа',
      'KI': 'Кирибати',
      'KM': 'Коморы',
      'KN': 'Сент-Китс и Невис',
      'KP': 'КНДР',
      'KR': 'Южная Корея',
      'KW': 'Кувейт',
      'KY': 'о-ва Кайман',
      'KZ': 'Казахстан',
      'LA': 'Лаос',
      'LB': 'Ливан',
      'LC': 'Сент-Люсия',
      'LI': 'Лихтенштейн',
      'LK': 'Шри-Ланка',
      'LR': 'Либерия',
      'LS': 'Лесото',
      'LT': 'Литва',
      'LU': 'Люксембург',
      'LV': 'Латвия',
      'LY': 'Ливия',
      'MA': 'Марокко',
      'MC': 'Монако',
      'MD': 'Молдова',
      'ME': 'Черногория',
      'MF': 'Сен-Мартен',
      'MG': 'Мадагаскар',
      'MH': 'Маршалловы о-ва',
      'MK': 'Северная Македония',
      'ML': 'Мали',
      'MM': 'Мьянма (Бирма)',
      'MN': 'Монголия',
      'MO': 'Макао',
      'MP': 'Северные Марианские о-ва',
      'MQ': 'Мартиника',
      'MR': 'Мавритания',
      'MS': 'Монтсеррат',
      'MT': 'Мальта',
      'MU': 'Маврикий',
      'MV': 'Мальдивы',
      'MW': 'Малави',
      'MX': 'Мексика',
      'MY': 'Малайзия',
      'MZ': 'Мозамбик',
      'NA': 'Намибия',
      'NC': 'Новая Каледония',
      'NE': 'Нигер',
      'NF': 'о-в Норфолк',
      'NG': 'Нигерия',
      'NI': 'Никарагуа',
      'NL': 'Нидерланды',
      'NO': 'Норвегия',
      'NP': 'Непал',
      'NR': 'Науру',
      'NU': 'Ниуэ',
      'NZ': 'Новая Зеландия',
      'OM': 'Оман',
      'PA': 'Панама',
      'PE': 'Перу',
      'PF': 'Французская Полинезия',
      'PG': 'Папуа — Новая Гвинея',
      'PH': 'Филиппины',
      'PK': 'Пакистан',
      'PL': 'Польша',
      'PM': 'Сен-Пьер и Микелон',
      'PN': 'о-ва Питкэрн',
      'PR': 'Пуэрто-Рико',
      'PS': 'Палестинские территории',
      'PT': 'Португалия',
      'PW': 'Палау',
      'PY': 'Парагвай',
      'QA': 'Катар',
      'RE': 'Реюньон',
      'RO': 'Румыния',
      'RS': 'Сербия',
      'RU': 'Россия',
      'RW': 'Руанда',
      'SA': 'Саудовская Аравия',
      'SB': 'Соломоновы о-ва',
      'SC': 'Сейшельские о-ва',
      'SD': 'Судан',
      'SE': 'Швеция',
      'SG': 'Сингапур',
      'SH': 'о-в Св. Елены',
      'SI': 'Словения',
      'SJ': 'Шпицберген и Ян-Майен',
      'SK': 'Словакия',
      'SL': 'Сьерра-Леоне',
      'SM': 'Сан-Марино',
      'SN': 'Сенегал',
      'SO': 'Сомали',
      'SR': 'Суринам',
      'SS': 'Южный Судан',
      'ST': 'Сан-Томе и Принсипи',
      'SV': 'Сальвадор',
      'SX': 'Синт-Мартен',
      'SY': 'Сирия',
      'SZ': 'Эсватини',
      'TC': 'Тёркс и Кайкос',
      'TD': 'Чад',
      'TF': 'Французские Южные территории',
      'TG': 'Того',
      'TH': 'Таиланд',
      'TJ': 'Таджикистан',
      'TK': 'Токелау',
      'TL': 'Восточный Тимор',
      'TM': 'Туркменистан',
      'TN': 'Тунис',
      'TO': 'Тонга',
      'TR': 'Турция',
      'TT': 'Тринидад и Тобаго',
      'TV': 'Тувалу',
      'TW': 'Тайвань',
      'TZ': 'Танзания',
      'UA': 'Украина',
      'UG': 'Уганда',
      'UM': 'Внешние малые о-ва (США)',
      'US': 'США',
      'UY': 'Уругвай',
      'UZ': 'Узбекистан',
      'VA': 'Ватикан',
      'VC': 'Сент-Винсент и Гренадины',
      'VE': 'Венесуэла',
      'VG': 'Виргинские о-ва (Великобритания)',
      'VI': 'Виргинские о-ва (США)',
      'VN': 'Вьетнам',
      'VU': 'Вануату',
      'WF': 'Уоллис и Футуна',
      'WS': 'Самоа',
      'XK': 'Косово',
      'YE': 'Йемен',
      'YT': 'Майотта',
      'ZA': 'Южно-Африканская Республика',
      'ZM': 'Замбия',
      'ZW': 'Зимбабве',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Настройки конфиденциальности';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Амстердам',
      'sgp': 'Сингапур',
      'lax': 'Лос-Анджелес',
      'mel': 'Мельбурн',
      'syd': 'Сидней',
      'sao': 'Сан-Паулу',
      'yto': 'Торонто',
      'scl': 'Сантьяго',
      'cdg': 'Париж',
      'fra': 'Франкфурт',
      'del': 'Дели',
      'bom': 'Мумбаи',
      'blr': 'Бангалор',
      'tlv': 'Тель-Авив',
      'itm': 'Осака',
      'nrt': 'Токио',
      'mex': 'Мехико',
      'waw': 'Варшава',
      'jnb': 'Йоханнесбург',
      'icn': 'Сеул',
      'mad': 'Мадрид',
      'sto': 'Стокгольм',
      'lhr': 'Лондон',
      'man': 'Манчестер',
      'ord': 'Чикаго',
      'dfw': 'Даллас',
      'sea': 'Сиэтл',
      'sjc': 'Сан-Франциско',
      'mia': 'Майами',
      'hnl': 'Гонолулу',
      'ewr': 'Нью-Йорк',
      'atl': 'Атланта',
      'hkg': 'Гонконг',
      'zrh': 'Цюрих',
      'gva': 'Женева',
      'svo': 'Москва',
      'led': 'Санкт-Петербург',
      'hel': 'Хельсинки',
      'tpe': 'Тайбэй',
      'dxb': 'Дубай',
      'kbp': 'Киев',
      'ist': 'Стамбул',
      'otp': 'Бухарест',
      'los': 'Лагос',
      'pty': 'Панама',
      'kef': 'Рейкьявик',
      'ber': 'Берлин',
      'ala': 'Алматы',
      'tbs': 'Тбилиси',
      'kul': 'Куала-Лумпур',
      'bkk': 'Бангкок',
      'cgk': 'Джакарта',
      'mnl': 'Манила',
      'nbo': 'Найроби',
      'mxp': 'Милан',
      'dub': 'Дублин',
      'lis': 'Лиссабон',
      'lux': 'Люксембург',
      'eze': 'Буэнос-Айрес',
      'akl': 'Окленд',
      'yul': 'Монреаль',
      'yvr': 'Ванкувер',
      'den': 'Денвер',
      'phx': 'Финикс',
      'iad': 'Вашингтон',
      'bos': 'Бостон',
      'edi': 'Эдинбург',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'Вам нравится 1VPN?';

  @override
  String get onevpnYes => 'Да';

  @override
  String get onevpnNo => 'Нет';

  @override
  String get onevpnLocationLocked => 'Заблокировано, только Премиум';

  @override
  String get onevpnManageSubscription => 'Управление подпиской';
}
