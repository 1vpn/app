// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class OneVpnLocalizationsUk extends OneVpnLocalizations {
  OneVpnLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get onevpnFaq => 'Поширені запитання';

  @override
  String get onevpnTermsOfService => 'Умови використання';

  @override
  String get onevpnMenu => 'Меню';

  @override
  String get onevpnUpgrade => 'Перейти на Преміум';

  @override
  String get onevpnUpgradeBannerTitle => 'Перейти на Преміум';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Без реклами, усі локації та вища швидкість';

  @override
  String get onevpnLogIn => 'Увійти';

  @override
  String get onevpnLogOut => 'Вийти';

  @override
  String get onevpnAccount => 'Обліковий запис';

  @override
  String get onevpnContactUs => 'Зв\'яжіться з нами';

  @override
  String get onevpnRefundPolicy => 'Політика повернення коштів';

  @override
  String get onevpnSupport => 'Підтримка';

  @override
  String get onevpnLanguage => 'Мова';

  @override
  String get onevpnLanguageSystem => 'Мова системи';

  @override
  String get onevpnPlanFree => 'Безкоштовний тариф';

  @override
  String get onevpnPlanPremium => 'Тариф Преміум';

  @override
  String get onevpnSelectLocation => 'Вибір локації';

  @override
  String get onevpnDirectRegions => 'Регіони прямого доступу';

  @override
  String get onevpnFree => 'Безкоштовно';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Безкоштовно';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Автоматично · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Автоматично';

  @override
  String get onevpnStatusNoConnection => 'Немає з\'єднання';

  @override
  String get onevpnStatusConnectionFailed => 'Не вдалося підключитися';

  @override
  String get onevpnStatusUpdating => 'Оновлення…';

  @override
  String get onevpnStatusMeasuring => 'Перевірка серверів…';

  @override
  String get onevpnAutomaticSubtitle => 'Найшвидший із доступних';

  @override
  String get onevpnLocationsLoadFailed =>
      'Не вдалося завантажити ваші локації.';

  @override
  String get onevpnLocationsUnavailable => 'Локації зараз недоступні.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Деякі сайти працюють, лише якщо ви підключаєтеся з тієї ж країни, що й сайт. Якщо вибрати регіон, сайти цього регіону відкриватимуться в обхід VPN.';

  @override
  String onevpnSelectionReset(String location) {
    return 'Локація $location недоступна, 1VPN перемкнувся на «Автоматично».';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'Вибрана локація недоступна, 1VPN перемкнувся на «Автоматично».';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'Не вдалося перемкнутися на локацію $location. Ви досі підключені до попередньої локації.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Не вдалося застосувати зміну. Ви досі підключені з попередніми налаштуваннями.';

  @override
  String get onevpnDirectRegionsOff => 'Вимкнено (за умовчанням)';

  @override
  String get onevpnAllViaVpnSubtitle => 'Увесь трафік через тунель';

  @override
  String get onevpnRegionChina => 'Китай';

  @override
  String get onevpnFirstConnectTitle => 'Деякі регіони краще працюють напряму';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'У таких країнах, як Китай, Росія та Іран, передавання всього трафіку через VPN може порушити роботу місцевих банківських і платіжних додатків.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN може спрямовувати трафік до вибраного вами регіону напряму, в обхід тунелю, з вашої справжньої IP-адреси.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Усе інше залишається захищеним. Це можна змінити будь-коли.';

  @override
  String get onevpnFirstConnectChooseRegion => 'Вибрати регіон прямого доступу';

  @override
  String get onevpnFirstConnectDismiss => 'Не зараз';

  @override
  String get onevpnCensorshipWarning =>
      'Деякі сервери можуть бути заблоковані у вашому регіоні через державні обмеження. Ми працюємо над вирішенням цієї проблеми. Дякуємо за розуміння.';

  @override
  String get onevpnAlwaysOnTitle => 'Постійна мережа VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      'Тунель залишається активним, коли ви закриваєте додаток. Після перезавантаження пристрою або оновлення додатка функція «Постійна мережа VPN» автоматично знову підключає тунель.';

  @override
  String get onevpnAlwaysOnStep1 =>
      'Натисніть «Відкрити налаштування VPN» нижче.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Знайдіть 1VPN у списку. Додаток з\'явиться там після першого підключення.';

  @override
  String get onevpnAlwaysOnStep3 => 'Натисніть значок шестірні поруч із 1VPN.';

  @override
  String get onevpnAlwaysOnStep4 => 'Увімкніть параметр «Постійна мережа VPN».';

  @override
  String get onevpnAlwaysOnOpenSettings => 'Відкрити налаштування VPN';

  @override
  String get onevpnPaywallTitle => 'Виберіть тариф';

  @override
  String get onevpnPaywallBenefitLocations => 'Доступ до всіх локацій серверів';

  @override
  String get onevpnPaywallBenefitNoAds => 'Без реклами';

  @override
  String get onevpnPaywallBenefitSpeed => 'Швидші сервери';

  @override
  String get onevpnPaywallBenefitP2p => 'Підтримка BitTorrent (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack =>
      '10-денна гарантія повернення коштів';

  @override
  String get onevpnPaywallPlanYearly => 'Річний';

  @override
  String get onevpnPaywallPlanMonthly => 'Місячний';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'Зекономте $percent%';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / міс.';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Ціна недоступна';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Не вдалося завантажити тарифи. Перевірте з\'єднання.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Тарифи зараз недоступні. Повторіть спробу пізніше.';

  @override
  String get onevpnGetPremium => 'Отримати Преміум';

  @override
  String get onevpnContinueFree => 'Продовжити безкоштовно';

  @override
  String get onevpnPaywallRetry => 'Повторити спробу';

  @override
  String get onevpnPaywallPurchaseError => 'Сталася помилка. Повторіть спробу.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'Цей обліковий запис Google має чинну або нещодавно завершену підписку 1VPN, прив\'язану до іншого облікового запису 1VPN. Увійдіть у той обліковий запис або зв\'яжіться зі $support.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'Цей обліковий запис Google уже має підписку 1VPN. Якщо Преміум не відображається, зв\'яжіться зі $support.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play не завершив вашу останню покупку. Закрийте відкриті екрани Google Play і повторіть спробу або перезапустіть додаток.';

  @override
  String get onevpnPaywallSupportLink => 'службою підтримки 1VPN';

  @override
  String get onevpnSignUp => 'Зареєструватися';

  @override
  String get onevpnAuthEmailLabel => 'Електронна пошта';

  @override
  String get onevpnAuthPasswordLabel => 'Пароль';

  @override
  String get onevpnAuthTwoFactorLabel => 'Код 2FA';

  @override
  String get onevpnAuthForgotPassword => 'Забули пароль?';

  @override
  String get onevpnAuthSubmitting => 'Завантаження…';

  @override
  String get onevpnAuthCreateAccount => 'Створити обліковий запис';

  @override
  String get onevpnAuthHaveAccount => 'Вже маєте обліковий запис?';

  @override
  String get onevpnAuthLogInInstead => 'Увійти замість реєстрації';

  @override
  String get onevpnAuthFieldsRequired => 'Введіть електронну пошту та пароль';

  @override
  String get onevpnAuthInvalidEmail =>
      'Введіть дійсну адресу електронної пошти';

  @override
  String get onevpnAuthInvalidCredentials =>
      'Неправильна адреса електронної пошти або пароль';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Неправильний код 2FA';

  @override
  String get onevpnAuthEmailInUse =>
      'Обліковий запис із цією адресою електронної пошти вже існує';

  @override
  String get onevpnAuthRateLimited =>
      'Забагато спроб. Повторіть спробу трохи пізніше';

  @override
  String get onevpnAuthUnreachable =>
      'Не вдалося зв\'язатися із сервером. Перевірте з\'єднання та повторіть спробу';

  @override
  String get onevpnAuthGenericError => 'Сталася помилка. Повторіть спробу';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Вашу покупку прив\'язано до цієї адреси електронної пошти.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Покупку завершено';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Вашу покупку прив\'язано до адреси $email. Створіть обліковий запис із цією адресою, щоб скористатися покупкою.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Преміум · підтвердження покупки';

  @override
  String get onevpnPremiumRecheck => 'Перевірка статусу покупки…';

  @override
  String get onevpnButtonRetry => 'Повторити';

  @override
  String get onevpnAppVersion => 'Версія додатка';

  @override
  String get onevpnPrivacyPolicy => 'Політика конфіденційності';

  @override
  String get onevpnConnect => 'Підключити';

  @override
  String get onevpnDisconnected => 'Відключено';

  @override
  String get onevpnConnecting => 'Підключення…';

  @override
  String get onevpnConnected => 'Підключено';

  @override
  String get onevpnDisconnecting => 'Відключення…';

  @override
  String get onevpnConnectionFailed => 'Не вдалося підключитися';

  @override
  String get onevpnTemporarilyUnavailable => 'Тимчасово недоступно';

  @override
  String get onevpnRetry => 'Повторити';

  @override
  String get onevpnApplyChange => 'Застосувати зміну?';

  @override
  String get onevpnReconnectNotice =>
      'VPN ненадовго відключиться й підключиться знову. Зазвичай це триває лише кілька секунд.';

  @override
  String onevpnWillUseName(String name) {
    return 'Буде використано: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Застосувати й перепідключити';

  @override
  String get onevpnCancel => 'Скасувати';

  @override
  String get onevpnContinue => 'Продовжити';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'Основний домен заблоковано. Використовується резервний: $domain';
  }

  @override
  String get onevpnResultFailed => 'не вдалося';

  @override
  String get onevpnDownload => 'Завантажити';

  @override
  String get onevpnPermissionNotGranted => 'Дозвіл не надано';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action $result';
  }

  @override
  String get onevpnDisconnect => 'Відключити';

  @override
  String get onevpnTimeout => 'Час очікування минув';

  @override
  String get onevpnNoAvailableEntries => 'Немає доступних вхідних серверів';

  @override
  String get onevpnAddServers => 'Додайте сервери';

  @override
  String get onevpnNotEnoughServers => 'Недостатньо доступних серверів';

  @override
  String get onevpnVpnFinalExit => 'Кінцевий вихідний сервер VPN';

  @override
  String get onevpnFinalExitEntryConflict =>
      'Кінцевий вихідний сервер не може бути одночасно вхідним';

  @override
  String get onevpnChooseNamedRoute => 'Виберіть один іменований маршрут';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Дозвольте доступ до пристроїв і сервісів у локальній мережі.';

  @override
  String get onevpnSystemApprovalRequired => 'Потрібен дозвіл системи';

  @override
  String get onevpnVpnPermissionRequired =>
      'Потрібен дозвіл для VPN. Повторіть спробу, щоб продовжити.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Виберіть інтерфейс для доступу до мережі. Потрібно лише в Windows / Linux.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Андорра',
      'AE': 'Об\'єднані Арабські Емірати',
      'AF': 'Афганістан',
      'AG': 'Антигуа і Барбуда',
      'AI': 'Ангілья',
      'AL': 'Албанія',
      'AM': 'Вірменія',
      'AO': 'Ангола',
      'AQ': 'Антарктика',
      'AR': 'Аргентина',
      'AS': 'Американське Самоа',
      'AT': 'Австрія',
      'AU': 'Австралія',
      'AW': 'Аруба',
      'AX': 'Аландські Острови',
      'AZ': 'Азербайджан',
      'BA': 'Боснія і Герцеговина',
      'BB': 'Барбадос',
      'BD': 'Бангладеш',
      'BE': 'Бельгія',
      'BF': 'Буркіна-Фасо',
      'BG': 'Болгарія',
      'BH': 'Бахрейн',
      'BI': 'Бурунді',
      'BJ': 'Бенін',
      'BL': 'Сен-Бартелемі',
      'BM': 'Бермудські Острови',
      'BN': 'Бруней',
      'BO': 'Болівія',
      'BQ': 'Карибські Нідерланди',
      'BR': 'Бразилія',
      'BS': 'Багамські Острови',
      'BT': 'Бутан',
      'BV': 'Острів Буве',
      'BW': 'Ботсвана',
      'BY': 'Білорусь',
      'BZ': 'Беліз',
      'CA': 'Канада',
      'CC': 'Кокосові (Кілінг) Острови',
      'CD': 'Конго – Кіншаса',
      'CF': 'Центральноафриканська Республіка',
      'CG': 'Конго – Браззавіль',
      'CH': 'Швейцарія',
      'CI': 'Кот-д\'Івуар',
      'CK': 'Острови Кука',
      'CL': 'Чилі',
      'CM': 'Камерун',
      'CN': 'Материковий Китай',
      'CO': 'Колумбія',
      'CR': 'Коста-Рика',
      'CU': 'Куба',
      'CV': 'Кабо-Верде',
      'CW': 'Кюрасао',
      'CX': 'Острів Різдва',
      'CY': 'Кіпр',
      'CZ': 'Чехія',
      'DE': 'Німеччина',
      'DJ': 'Джибуті',
      'DK': 'Данія',
      'DM': 'Домініка',
      'DO': 'Домініканська Республіка',
      'DZ': 'Алжир',
      'EC': 'Еквадор',
      'EE': 'Естонія',
      'EG': 'Єгипет',
      'EH': 'Західна Сахара',
      'ER': 'Еритрея',
      'ES': 'Іспанія',
      'ET': 'Ефіопія',
      'FI': 'Фінляндія',
      'FJ': 'Фіджі',
      'FK': 'Фолклендські Острови',
      'FM': 'Мікронезія',
      'FO': 'Фарерські Острови',
      'FR': 'Франція',
      'GA': 'Габон',
      'GB': 'Велика Британія',
      'GD': 'Гренада',
      'GE': 'Грузія',
      'GF': 'Французька Гвіана',
      'GG': 'Гернсі',
      'GH': 'Гана',
      'GI': 'Гібралтар',
      'GL': 'Гренландія',
      'GM': 'Ґамбія',
      'GN': 'Гвінея',
      'GP': 'Гваделупа',
      'GQ': 'Екваторіальна Гвінея',
      'GR': 'Греція',
      'GS': 'Південна Джорджія та Південні Сандвічеві Острови',
      'GT': 'Гватемала',
      'GU': 'Гуам',
      'GW': 'Гвінея-Бісау',
      'GY': 'Гаяна',
      'HK': 'Гонконг',
      'HM': 'Острови Герд і Макдоналд',
      'HN': 'Гондурас',
      'HR': 'Хорватія',
      'HT': 'Гаїті',
      'HU': 'Угорщина',
      'ID': 'Індонезія',
      'IE': 'Ірландія',
      'IL': 'Ізраїль',
      'IM': 'Острів Мен',
      'IN': 'Індія',
      'IO': 'Архіпелаг Чагос',
      'IQ': 'Ірак',
      'IR': 'Іран',
      'IS': 'Ісландія',
      'IT': 'Італія',
      'JE': 'Джерсі',
      'JM': 'Ямайка',
      'JO': 'Йорданія',
      'JP': 'Японія',
      'KE': 'Кенія',
      'KG': 'Киргизстан',
      'KH': 'Камбоджа',
      'KI': 'Кірибаті',
      'KM': 'Комори',
      'KN': 'Сент-Кітс і Невіс',
      'KP': 'Північна Корея',
      'KR': 'Південна Корея',
      'KW': 'Кувейт',
      'KY': 'Кайманові Острови',
      'KZ': 'Казахстан',
      'LA': 'Лаос',
      'LB': 'Ліван',
      'LC': 'Сент-Люсія',
      'LI': 'Ліхтенштейн',
      'LK': 'Шрі-Ланка',
      'LR': 'Ліберія',
      'LS': 'Лесото',
      'LT': 'Литва',
      'LU': 'Люксембург',
      'LV': 'Латвія',
      'LY': 'Лівія',
      'MA': 'Марокко',
      'MC': 'Монако',
      'MD': 'Молдова',
      'ME': 'Чорногорія',
      'MF': 'Сен-Мартен',
      'MG': 'Мадагаскар',
      'MH': 'Маршаллові Острови',
      'MK': 'Північна Македонія',
      'ML': 'Малі',
      'MM': 'М\'янма (Бірма)',
      'MN': 'Монголія',
      'MO': 'Макао',
      'MP': 'Північні Маріанські Острови',
      'MQ': 'Мартиніка',
      'MR': 'Мавританія',
      'MS': 'Монтсеррат',
      'MT': 'Мальта',
      'MU': 'Маврикій',
      'MV': 'Мальдіви',
      'MW': 'Малаві',
      'MX': 'Мексика',
      'MY': 'Малайзія',
      'MZ': 'Мозамбік',
      'NA': 'Намібія',
      'NC': 'Нова Каледонія',
      'NE': 'Нігер',
      'NF': 'Острів Норфолк',
      'NG': 'Нігерія',
      'NI': 'Нікарагуа',
      'NL': 'Нідерланди',
      'NO': 'Норвегія',
      'NP': 'Непал',
      'NR': 'Науру',
      'NU': 'Ніуе',
      'NZ': 'Нова Зеландія',
      'OM': 'Оман',
      'PA': 'Панама',
      'PE': 'Перу',
      'PF': 'Французька Полінезія',
      'PG': 'Папуа-Нова Гвінея',
      'PH': 'Філіппіни',
      'PK': 'Пакистан',
      'PL': 'Польща',
      'PM': 'Сен-П\'єр і Мікелон',
      'PN': 'Острови Піткерн',
      'PR': 'Пуерто-Рико',
      'PS': 'Палестинські території',
      'PT': 'Португалія',
      'PW': 'Палау',
      'PY': 'Парагвай',
      'QA': 'Катар',
      'RE': 'Реюньйон',
      'RO': 'Румунія',
      'RS': 'Сербія',
      'RU': 'Росія',
      'RW': 'Руанда',
      'SA': 'Саудівська Аравія',
      'SB': 'Соломонові Острови',
      'SC': 'Сейшельські Острови',
      'SD': 'Судан',
      'SE': 'Швеція',
      'SG': 'Сінгапур',
      'SH': 'Острів Святої Єлени',
      'SI': 'Словенія',
      'SJ': 'Шпіцберген та Ян-Маєн',
      'SK': 'Словаччина',
      'SL': 'Сьєрра-Леоне',
      'SM': 'Сан-Марино',
      'SN': 'Сенегал',
      'SO': 'Сомалі',
      'SR': 'Суринам',
      'SS': 'Південний Судан',
      'ST': 'Сан-Томе і Принсіпі',
      'SV': 'Сальвадор',
      'SX': 'Сінт-Мартен',
      'SY': 'Сирія',
      'SZ': 'Есватіні',
      'TC': 'Острови Теркс і Кайкос',
      'TD': 'Чад',
      'TF': 'Французькі Південні Території',
      'TG': 'Того',
      'TH': 'Таїланд',
      'TJ': 'Таджикистан',
      'TK': 'Токелау',
      'TL': 'Тимор-Лешті',
      'TM': 'Туркменістан',
      'TN': 'Туніс',
      'TO': 'Тонга',
      'TR': 'Туреччина',
      'TT': 'Тринідад і Тобаго',
      'TV': 'Тувалу',
      'TW': 'Тайвань',
      'TZ': 'Танзанія',
      'UA': 'Україна',
      'UG': 'Уганда',
      'UM': 'Віддалені острови США',
      'US': 'США',
      'UY': 'Уругвай',
      'UZ': 'Узбекистан',
      'VA': 'Ватикан',
      'VC': 'Сент-Вінсент і Гренадіни',
      'VE': 'Венесуела',
      'VG': 'Британські Віргінські острови',
      'VI': 'Віргінські Острови (США)',
      'VN': 'В\'єтнам',
      'VU': 'Вануату',
      'WF': 'Уолліс і Футуна',
      'WS': 'Самоа',
      'XK': 'Косово',
      'YE': 'Ємен',
      'YT': 'Майотта',
      'ZA': 'Південна Африка',
      'ZM': 'Замбія',
      'ZW': 'Зімбабве',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Налаштування конфіденційності';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Амстердам',
      'sgp': 'Сінгапур',
      'lax': 'Лос-Анджелес',
      'mel': 'Мельбурн',
      'syd': 'Сідней',
      'sao': 'Сан-Паулу',
      'yto': 'Торонто',
      'scl': 'Сантьяго',
      'cdg': 'Париж',
      'fra': 'Франкфурт',
      'del': 'Делі',
      'bom': 'Мумбаї',
      'blr': 'Бангалор',
      'tlv': 'Тель-Авів',
      'itm': 'Осака',
      'nrt': 'Токіо',
      'mex': 'Мехіко',
      'waw': 'Варшава',
      'jnb': 'Йоганнесбург',
      'icn': 'Сеул',
      'mad': 'Мадрид',
      'sto': 'Стокгольм',
      'lhr': 'Лондон',
      'man': 'Манчестер',
      'ord': 'Чикаго',
      'dfw': 'Даллас',
      'sea': 'Сіетл',
      'sjc': 'Сан-Франциско',
      'mia': 'Маямі',
      'hnl': 'Гонолулу',
      'ewr': 'Нью-Йорк',
      'atl': 'Атланта',
      'hkg': 'Гонконг',
      'zrh': 'Цюрих',
      'gva': 'Женева',
      'svo': 'Москва',
      'led': 'Санкт-Петербург',
      'hel': 'Гельсінкі',
      'tpe': 'Тайбей',
      'dxb': 'Дубай',
      'kbp': 'Київ',
      'ist': 'Стамбул',
      'otp': 'Бухарест',
      'los': 'Лагос',
      'pty': 'Панама',
      'kef': 'Рейк\'явік',
      'ber': 'Берлін',
      'ala': 'Алмати',
      'tbs': 'Тбілісі',
      'kul': 'Куала-Лумпур',
      'bkk': 'Бангкок',
      'cgk': 'Джакарта',
      'mnl': 'Манила',
      'nbo': 'Найробі',
      'mxp': 'Мілан',
      'dub': 'Дублін',
      'lis': 'Лісабон',
      'lux': 'Люксембург',
      'eze': 'Буенос-Айрес',
      'akl': 'Окленд',
      'yul': 'Монреаль',
      'yvr': 'Ванкувер',
      'den': 'Денвер',
      'phx': 'Фінікс',
      'iad': 'Вашингтон',
      'bos': 'Бостон',
      'edi': 'Единбург',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'Вам подобається 1VPN?';

  @override
  String get onevpnYes => 'Так';

  @override
  String get onevpnNo => 'Ні';

  @override
  String get onevpnLocationLocked => 'Заблоковано, лише Преміум';

  @override
  String get onevpnManageSubscription => 'Керування підпискою';
}
