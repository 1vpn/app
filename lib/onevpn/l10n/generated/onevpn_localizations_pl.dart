// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class OneVpnLocalizationsPl extends OneVpnLocalizations {
  OneVpnLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get onevpnFaq => 'Najczęstsze pytania';

  @override
  String get onevpnTermsOfService => 'Warunki korzystania z usługi';

  @override
  String get onevpnMenu => 'Menu';

  @override
  String get onevpnUpgrade => 'Uaktualnij';

  @override
  String get onevpnUpgradeBannerTitle => 'Przejdź na Premium';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Bez reklam, wszystkie lokalizacje i większa szybkość';

  @override
  String get onevpnLogIn => 'Zaloguj się';

  @override
  String get onevpnLogOut => 'Wyloguj się';

  @override
  String get onevpnAccount => 'Konto';

  @override
  String get onevpnContactUs => 'Skontaktuj się z nami';

  @override
  String get onevpnRefundPolicy => 'Zasady zwrotów';

  @override
  String get onevpnSupport => 'Pomoc';

  @override
  String get onevpnLanguage => 'Język';

  @override
  String get onevpnLanguageSystem => 'Ustawienie domyślne systemu';

  @override
  String get onevpnPlanFree => 'Plan bezpłatny';

  @override
  String get onevpnPlanPremium => 'Plan Premium';

  @override
  String get onevpnSelectLocation => 'Wybierz lokalizację';

  @override
  String get onevpnDirectRegions => 'Regiony bezpośrednie';

  @override
  String get onevpnFree => 'Bezpłatny';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Bezpłatny';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Automatycznie · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Automatycznie';

  @override
  String get onevpnStatusNoConnection => 'Brak połączenia';

  @override
  String get onevpnStatusConnectionFailed => 'Nie udało się połączyć';

  @override
  String get onevpnStatusUpdating => 'Aktualizowanie…';

  @override
  String get onevpnStatusMeasuring => 'Testowanie serwerów…';

  @override
  String get onevpnAutomaticSubtitle => 'Najszybszy dostępny serwer';

  @override
  String get onevpnLocationsLoadFailed =>
      'Nie udało się załadować Twoich lokalizacji.';

  @override
  String get onevpnLocationsUnavailable =>
      'Lokalizacje są obecnie niedostępne.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Niektóre strony działają tylko wtedy, gdy łączysz się z tego samego kraju co strona. Po wybraniu regionu strony z tego regionu omijają VPN.';

  @override
  String onevpnSelectionReset(String location) {
    return 'Lokalizacja $location jest niedostępna, więc 1VPN przełączył się na „Automatycznie”.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'Wybrana lokalizacja jest niedostępna, więc 1VPN przełączył się na „Automatycznie”.';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'Nie udało się przełączyć na lokalizację $location. Nadal masz połączenie z poprzednią lokalizacją.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Nie udało się zastosować zmiany. Połączenie nadal działa z poprzednimi ustawieniami.';

  @override
  String get onevpnDirectRegionsOff => 'Wyłączone (domyślnie)';

  @override
  String get onevpnAllViaVpnSubtitle => 'Cały ruch przez tunel';

  @override
  String get onevpnRegionChina => 'Chiny';

  @override
  String get onevpnFirstConnectTitle =>
      'Niektóre regiony działają lepiej bezpośrednio';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'W krajach takich jak Chiny, Rosja i Iran przesyłanie całego ruchu przez VPN może zakłócać działanie lokalnych aplikacji bankowych i płatniczych.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN może kierować ruch do wybranego przez Ciebie regionu bezpośrednio, poza tunelem, z Twojego prawdziwego adresu IP.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Cała reszta pozostaje chroniona. Możesz to zmienić w każdej chwili.';

  @override
  String get onevpnFirstConnectChooseRegion => 'Wybierz region bezpośredni';

  @override
  String get onevpnFirstConnectDismiss => 'Nie teraz';

  @override
  String get onevpnCensorshipWarning =>
      'Niektóre serwery mogą być zablokowane w Twoim regionie z powodu ograniczeń rządowych. Pracujemy nad rozwiązaniem tego problemu. Dziękujemy za zrozumienie.';

  @override
  String get onevpnAlwaysOnTitle => 'Stały VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      'Tunel pozostaje aktywny po zamknięciu aplikacji. Po ponownym uruchomieniu urządzenia lub aktualizacji aplikacji funkcja „Stały VPN” automatycznie przywraca połączenie.';

  @override
  String get onevpnAlwaysOnStep1 => 'Kliknij „Otwórz ustawienia VPN” poniżej.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Znajdź 1VPN na liście. Aplikacja pojawi się tam po pierwszym połączeniu.';

  @override
  String get onevpnAlwaysOnStep3 => 'Kliknij ikonę koła zębatego obok 1VPN.';

  @override
  String get onevpnAlwaysOnStep4 => 'Włącz opcję „Stały VPN”.';

  @override
  String get onevpnAlwaysOnOpenSettings => 'Otwórz ustawienia VPN';

  @override
  String get onevpnPaywallTitle => 'Wybierz swój plan';

  @override
  String get onevpnPaywallBenefitLocations =>
      'Odblokuj wszystkie lokalizacje serwerów';

  @override
  String get onevpnPaywallBenefitNoAds => 'Bez reklam';

  @override
  String get onevpnPaywallBenefitSpeed => 'Szybsze serwery';

  @override
  String get onevpnPaywallBenefitP2p => 'Wsparcie BitTorrent (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack =>
      '10-dniowa gwarancja zwrotu pieniędzy';

  @override
  String get onevpnPaywallPlanYearly => 'Roczny';

  @override
  String get onevpnPaywallPlanMonthly => 'Miesięczny';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'Oszczędź $percent%';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / mies.';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Cena niedostępna';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Nie udało się załadować planów. Sprawdź połączenie.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Plany są obecnie niedostępne. Spróbuj ponownie później.';

  @override
  String get onevpnGetPremium => 'Uzyskaj Premium';

  @override
  String get onevpnContinueFree => 'Kontynuuj bezpłatnie';

  @override
  String get onevpnPaywallRetry => 'Spróbuj ponownie';

  @override
  String get onevpnPaywallPurchaseError =>
      'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'To konto Google ma aktywną lub niedawno zakończoną subskrypcję 1VPN powiązaną z innym kontem 1VPN. Zaloguj się na to konto lub skontaktuj się z $support.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'To konto Google ma już subskrypcję 1VPN. Jeśli Premium się nie pojawi, skontaktuj się z $support.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Twój ostatni zakup w Google Play nie został dokończony. Zamknij otwarte ekrany Google Play i spróbuj ponownie albo uruchom ponownie aplikację.';

  @override
  String get onevpnPaywallSupportLink => 'pomocą techniczną 1VPN';

  @override
  String get onevpnSignUp => 'Zarejestruj się';

  @override
  String get onevpnAuthEmailLabel => 'E-mail';

  @override
  String get onevpnAuthPasswordLabel => 'Hasło';

  @override
  String get onevpnAuthTwoFactorLabel => 'Kod 2FA';

  @override
  String get onevpnAuthForgotPassword => 'Nie pamiętasz hasła?';

  @override
  String get onevpnAuthSubmitting => 'Ładowanie…';

  @override
  String get onevpnAuthCreateAccount => 'Utwórz konto';

  @override
  String get onevpnAuthHaveAccount => 'Masz już konto?';

  @override
  String get onevpnAuthLogInInstead => 'Zamiast tego zaloguj się';

  @override
  String get onevpnAuthFieldsRequired => 'Wprowadź adres e-mail i hasło';

  @override
  String get onevpnAuthInvalidEmail => 'Wprowadź poprawny adres e-mail';

  @override
  String get onevpnAuthInvalidCredentials => 'Nieprawidłowe dane logowania';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Nieprawidłowy kod 2FA';

  @override
  String get onevpnAuthEmailInUse => 'Konto z tym adresem e-mail już istnieje';

  @override
  String get onevpnAuthRateLimited =>
      'Zbyt wiele prób. Spróbuj ponownie za chwilę';

  @override
  String get onevpnAuthUnreachable =>
      'Nie udało się połączyć z serwerem. Sprawdź połączenie i spróbuj ponownie';

  @override
  String get onevpnAuthGenericError => 'Coś poszło nie tak. Spróbuj ponownie';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Twój zakup jest powiązany z tym adresem e-mail.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Zakup zakończony';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Twój zakup jest powiązany z adresem $email. Aby z niego korzystać, utwórz konto z tym adresem.';
  }

  @override
  String get onevpnPlanPremiumPending => 'Premium · potwierdzanie zakupu';

  @override
  String get onevpnPremiumRecheck => 'Sprawdzanie stanu zakupu…';

  @override
  String get onevpnButtonRetry => 'Ponów';

  @override
  String get onevpnAppVersion => 'Wersja aplikacji';

  @override
  String get onevpnPrivacyPolicy => 'Polityka prywatności';

  @override
  String get onevpnConnect => 'Połącz';

  @override
  String get onevpnDisconnected => 'Rozłączono';

  @override
  String get onevpnConnecting => 'Łączenie…';

  @override
  String get onevpnConnected => 'Połączono';

  @override
  String get onevpnDisconnecting => 'Rozłączanie…';

  @override
  String get onevpnConnectionFailed => 'Nie udało się połączyć';

  @override
  String get onevpnTemporarilyUnavailable => 'Tymczasowo niedostępne';

  @override
  String get onevpnRetry => 'Ponów';

  @override
  String get onevpnApplyChange => 'Zastosować zmianę?';

  @override
  String get onevpnReconnectNotice =>
      'VPN na chwilę się rozłączy i połączy ponownie. Zwykle trwa to tylko kilka sekund.';

  @override
  String onevpnWillUseName(String name) {
    return 'Tunel użyje: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Zastosuj i połącz ponownie';

  @override
  String get onevpnCancel => 'Anuluj';

  @override
  String get onevpnContinue => 'Kontynuuj';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'Główna domena jest zablokowana. Używana jest zapasowa: $domain';
  }

  @override
  String get onevpnResultFailed => 'nie powiodło się';

  @override
  String get onevpnDownload => 'Pobierz';

  @override
  String get onevpnPermissionNotGranted => 'Nie przyznano uprawnienia';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action: $result';
  }

  @override
  String get onevpnDisconnect => 'Rozłącz';

  @override
  String get onevpnTimeout => 'Limit czasu';

  @override
  String get onevpnNoAvailableEntries => 'Brak dostępnych serwerów wejściowych';

  @override
  String get onevpnAddServers => 'Dodaj serwery';

  @override
  String get onevpnNotEnoughServers => 'Za mało dostępnych serwerów';

  @override
  String get onevpnVpnFinalExit => 'Końcowy serwer wyjściowy VPN';

  @override
  String get onevpnFinalExitEntryConflict =>
      'Końcowy serwer wyjściowy nie może być jednocześnie serwerem wejściowym';

  @override
  String get onevpnChooseNamedRoute => 'Wybierz jedną nazwaną trasę';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Zezwól na dostęp do urządzeń i usług w sieci lokalnej.';

  @override
  String get onevpnSystemApprovalRequired =>
      'Wymagane zatwierdzenie przez system';

  @override
  String get onevpnVpnPermissionRequired =>
      'Wymagane jest uprawnienie VPN. Ponów próbę, aby kontynuować.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Wybierz interfejs używany do łączenia z siecią. Wymagane tylko w systemach Windows / Linux.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Andora',
      'AE': 'Zjednoczone Emiraty Arabskie',
      'AF': 'Afganistan',
      'AG': 'Antigua i Barbuda',
      'AI': 'Anguilla',
      'AL': 'Albania',
      'AM': 'Armenia',
      'AO': 'Angola',
      'AQ': 'Antarktyda',
      'AR': 'Argentyna',
      'AS': 'Samoa Amerykańskie',
      'AT': 'Austria',
      'AU': 'Australia',
      'AW': 'Aruba',
      'AX': 'Wyspy Alandzkie',
      'AZ': 'Azerbejdżan',
      'BA': 'Bośnia i Hercegowina',
      'BB': 'Barbados',
      'BD': 'Bangladesz',
      'BE': 'Belgia',
      'BF': 'Burkina Faso',
      'BG': 'Bułgaria',
      'BH': 'Bahrajn',
      'BI': 'Burundi',
      'BJ': 'Benin',
      'BL': 'Saint-Barthélemy',
      'BM': 'Bermudy',
      'BN': 'Brunei',
      'BO': 'Boliwia',
      'BQ': 'Niderlandy Karaibskie',
      'BR': 'Brazylia',
      'BS': 'Bahamy',
      'BT': 'Bhutan',
      'BV': 'Wyspa Bouveta',
      'BW': 'Botswana',
      'BY': 'Białoruś',
      'BZ': 'Belize',
      'CA': 'Kanada',
      'CC': 'Wyspy Kokosowe',
      'CD': 'Demokratyczna Republika Konga',
      'CF': 'Republika Środkowoafrykańska',
      'CG': 'Kongo',
      'CH': 'Szwajcaria',
      'CI': 'Côte d’Ivoire',
      'CK': 'Wyspy Cooka',
      'CL': 'Chile',
      'CM': 'Kamerun',
      'CN': 'Chiny kontynentalne',
      'CO': 'Kolumbia',
      'CR': 'Kostaryka',
      'CU': 'Kuba',
      'CV': 'Republika Zielonego Przylądka',
      'CW': 'Curaçao',
      'CX': 'Wyspa Bożego Narodzenia',
      'CY': 'Cypr',
      'CZ': 'Czechy',
      'DE': 'Niemcy',
      'DJ': 'Dżibuti',
      'DK': 'Dania',
      'DM': 'Dominika',
      'DO': 'Dominikana',
      'DZ': 'Algieria',
      'EC': 'Ekwador',
      'EE': 'Estonia',
      'EG': 'Egipt',
      'EH': 'Sahara Zachodnia',
      'ER': 'Erytrea',
      'ES': 'Hiszpania',
      'ET': 'Etiopia',
      'FI': 'Finlandia',
      'FJ': 'Fidżi',
      'FK': 'Falklandy',
      'FM': 'Mikronezja',
      'FO': 'Wyspy Owcze',
      'FR': 'Francja',
      'GA': 'Gabon',
      'GB': 'Wielka Brytania',
      'GD': 'Grenada',
      'GE': 'Gruzja',
      'GF': 'Gujana Francuska',
      'GG': 'Guernsey',
      'GH': 'Ghana',
      'GI': 'Gibraltar',
      'GL': 'Grenlandia',
      'GM': 'Gambia',
      'GN': 'Gwinea',
      'GP': 'Gwadelupa',
      'GQ': 'Gwinea Równikowa',
      'GR': 'Grecja',
      'GS': 'Georgia Południowa i Sandwich Południowy',
      'GT': 'Gwatemala',
      'GU': 'Guam',
      'GW': 'Gwinea Bissau',
      'GY': 'Gujana',
      'HK': 'Hongkong',
      'HM': 'Wyspy Heard i McDonalda',
      'HN': 'Honduras',
      'HR': 'Chorwacja',
      'HT': 'Haiti',
      'HU': 'Węgry',
      'ID': 'Indonezja',
      'IE': 'Irlandia',
      'IL': 'Izrael',
      'IM': 'Wyspa Man',
      'IN': 'Indie',
      'IO': 'Czagos',
      'IQ': 'Irak',
      'IR': 'Iran',
      'IS': 'Islandia',
      'IT': 'Włochy',
      'JE': 'Jersey',
      'JM': 'Jamajka',
      'JO': 'Jordania',
      'JP': 'Japonia',
      'KE': 'Kenia',
      'KG': 'Kirgistan',
      'KH': 'Kambodża',
      'KI': 'Kiribati',
      'KM': 'Komory',
      'KN': 'Saint Kitts i Nevis',
      'KP': 'Korea Północna',
      'KR': 'Korea Południowa',
      'KW': 'Kuwejt',
      'KY': 'Kajmany',
      'KZ': 'Kazachstan',
      'LA': 'Laos',
      'LB': 'Liban',
      'LC': 'Saint Lucia',
      'LI': 'Liechtenstein',
      'LK': 'Sri Lanka',
      'LR': 'Liberia',
      'LS': 'Lesotho',
      'LT': 'Litwa',
      'LU': 'Luksemburg',
      'LV': 'Łotwa',
      'LY': 'Libia',
      'MA': 'Maroko',
      'MC': 'Monako',
      'MD': 'Mołdawia',
      'ME': 'Czarnogóra',
      'MF': 'Saint-Martin',
      'MG': 'Madagaskar',
      'MH': 'Wyspy Marshalla',
      'MK': 'Macedonia Północna',
      'ML': 'Mali',
      'MM': 'Mjanma (Birma)',
      'MN': 'Mongolia',
      'MO': 'Makau',
      'MP': 'Mariany Północne',
      'MQ': 'Martynika',
      'MR': 'Mauretania',
      'MS': 'Montserrat',
      'MT': 'Malta',
      'MU': 'Mauritius',
      'MV': 'Malediwy',
      'MW': 'Malawi',
      'MX': 'Meksyk',
      'MY': 'Malezja',
      'MZ': 'Mozambik',
      'NA': 'Namibia',
      'NC': 'Nowa Kaledonia',
      'NE': 'Niger',
      'NF': 'Norfolk',
      'NG': 'Nigeria',
      'NI': 'Nikaragua',
      'NL': 'Holandia',
      'NO': 'Norwegia',
      'NP': 'Nepal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'Nowa Zelandia',
      'OM': 'Oman',
      'PA': 'Panama',
      'PE': 'Peru',
      'PF': 'Polinezja Francuska',
      'PG': 'Papua-Nowa Gwinea',
      'PH': 'Filipiny',
      'PK': 'Pakistan',
      'PL': 'Polska',
      'PM': 'Saint-Pierre i Miquelon',
      'PN': 'Pitcairn',
      'PR': 'Portoryko',
      'PS': 'Terytoria Palestyńskie',
      'PT': 'Portugalia',
      'PW': 'Palau',
      'PY': 'Paragwaj',
      'QA': 'Katar',
      'RE': 'Reunion',
      'RO': 'Rumunia',
      'RS': 'Serbia',
      'RU': 'Rosja',
      'RW': 'Rwanda',
      'SA': 'Arabia Saudyjska',
      'SB': 'Wyspy Salomona',
      'SC': 'Seszele',
      'SD': 'Sudan',
      'SE': 'Szwecja',
      'SG': 'Singapur',
      'SH': 'Wyspa Świętej Heleny',
      'SI': 'Słowenia',
      'SJ': 'Svalbard i Jan Mayen',
      'SK': 'Słowacja',
      'SL': 'Sierra Leone',
      'SM': 'San Marino',
      'SN': 'Senegal',
      'SO': 'Somalia',
      'SR': 'Surinam',
      'SS': 'Sudan Południowy',
      'ST': 'Wyspy Świętego Tomasza i Książęca',
      'SV': 'Salwador',
      'SX': 'Sint Maarten',
      'SY': 'Syria',
      'SZ': 'Eswatini',
      'TC': 'Turks i Caicos',
      'TD': 'Czad',
      'TF': 'Francuskie Terytoria Południowe i Antarktyczne',
      'TG': 'Togo',
      'TH': 'Tajlandia',
      'TJ': 'Tadżykistan',
      'TK': 'Tokelau',
      'TL': 'Timor Wschodni',
      'TM': 'Turkmenistan',
      'TN': 'Tunezja',
      'TO': 'Tonga',
      'TR': 'Turcja',
      'TT': 'Trynidad i Tobago',
      'TV': 'Tuvalu',
      'TW': 'Tajwan',
      'TZ': 'Tanzania',
      'UA': 'Ukraina',
      'UG': 'Uganda',
      'UM': 'Dalekie Wyspy Stanów Zjednoczonych',
      'US': 'Stany Zjednoczone',
      'UY': 'Urugwaj',
      'UZ': 'Uzbekistan',
      'VA': 'Watykan',
      'VC': 'Saint Vincent i Grenadyny',
      'VE': 'Wenezuela',
      'VG': 'Brytyjskie Wyspy Dziewicze',
      'VI': 'Wyspy Dziewicze Stanów Zjednoczonych',
      'VN': 'Wietnam',
      'VU': 'Vanuatu',
      'WF': 'Wallis i Futuna',
      'WS': 'Samoa',
      'XK': 'Kosowo',
      'YE': 'Jemen',
      'YT': 'Majotta',
      'ZA': 'Republika Południowej Afryki',
      'ZM': 'Zambia',
      'ZW': 'Zimbabwe',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Ustawienia prywatności';

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
      'cdg': 'Paryż',
      'fra': 'Frankfurt',
      'del': 'Nowe Delhi',
      'bom': 'Mumbaj',
      'blr': 'Bangalore',
      'tlv': 'Tel Awiw',
      'itm': 'Osaka',
      'nrt': 'Tokio',
      'mex': 'Meksyk',
      'waw': 'Warszawa',
      'jnb': 'Johannesburg',
      'icn': 'Seul',
      'mad': 'Madryt',
      'sto': 'Sztokholm',
      'lhr': 'Londyn',
      'man': 'Manchester',
      'ord': 'Chicago',
      'dfw': 'Dallas',
      'sea': 'Seattle',
      'sjc': 'San Francisco',
      'mia': 'Miami',
      'hnl': 'Honolulu',
      'ewr': 'Nowy Jork',
      'atl': 'Atlanta',
      'hkg': 'Hongkong',
      'zrh': 'Zurych',
      'gva': 'Genewa',
      'svo': 'Moskwa',
      'led': 'Sankt Petersburg',
      'hel': 'Helsinki',
      'tpe': 'Tajpej',
      'dxb': 'Dubaj',
      'kbp': 'Kijów',
      'ist': 'Stambuł',
      'otp': 'Bukareszt',
      'los': 'Lagos',
      'pty': 'Panama',
      'kef': 'Reykjavík',
      'ber': 'Berlin',
      'ala': 'Ałmaty',
      'tbs': 'Tbilisi',
      'kul': 'Kuala Lumpur',
      'bkk': 'Bangkok',
      'cgk': 'Dżakarta',
      'mnl': 'Manila',
      'nbo': 'Nairobi',
      'mxp': 'Mediolan',
      'dub': 'Dublin',
      'lis': 'Lizbona',
      'lux': 'Luksemburg',
      'eze': 'Buenos Aires',
      'akl': 'Auckland',
      'yul': 'Montreal',
      'yvr': 'Vancouver',
      'den': 'Denver',
      'phx': 'Phoenix',
      'iad': 'Waszyngton',
      'bos': 'Boston',
      'edi': 'Edynburg',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'Podoba Ci się 1VPN?';

  @override
  String get onevpnYes => 'Tak';

  @override
  String get onevpnNo => 'Nie';

  @override
  String get onevpnLocationLocked => 'Zablokowane, tylko Premium';

  @override
  String get onevpnManageSubscription => 'Zarządzaj subskrypcją';
}
