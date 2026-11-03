// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class OneVpnLocalizationsKo extends OneVpnLocalizations {
  OneVpnLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get onevpnFaq => '자주 묻는 질문';

  @override
  String get onevpnTermsOfService => '서비스 약관';

  @override
  String get onevpnMenu => '메뉴';

  @override
  String get onevpnUpgrade => '업그레이드';

  @override
  String get onevpnUpgradeBannerTitle => '프리미엄으로 업그레이드';

  @override
  String get onevpnUpgradeBannerSubtitle => '광고 없음, 모든 위치와 더 빠른 속도';

  @override
  String get onevpnLogIn => '로그인';

  @override
  String get onevpnLogOut => '로그아웃';

  @override
  String get onevpnAccount => '계정';

  @override
  String get onevpnContactUs => '문의하기';

  @override
  String get onevpnRefundPolicy => '환불 정책';

  @override
  String get onevpnSupport => '지원';

  @override
  String get onevpnLanguage => '언어';

  @override
  String get onevpnLanguageSystem => '시스템 기본값';

  @override
  String get onevpnPlanFree => '무료 요금제';

  @override
  String get onevpnPlanPremium => '프리미엄 요금제';

  @override
  String get onevpnSelectLocation => '위치 선택';

  @override
  String get onevpnDirectRegions => '직접 연결 지역';

  @override
  String get onevpnFree => '무료';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · 무료';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return '자동 · $node';
  }

  @override
  String get onevpnAutomaticSelection => '자동';

  @override
  String get onevpnStatusNoConnection => '연결 없음';

  @override
  String get onevpnStatusConnectionFailed => '연결 실패';

  @override
  String get onevpnStatusUpdating => '업데이트 중…';

  @override
  String get onevpnStatusMeasuring => '서버 측정 중…';

  @override
  String get onevpnAutomaticSubtitle => '사용 가능한 가장 빠른 서버';

  @override
  String get onevpnLocationsLoadFailed => '위치 목록을 불러올 수 없습니다.';

  @override
  String get onevpnLocationsUnavailable => '지금은 사용할 수 있는 위치가 없습니다.';

  @override
  String get onevpnDirectRegionsCardBody =>
      '일부 사이트는 해당 사이트와 같은 국가에서 접속할 때만 작동합니다. 지역을 선택하면 그 지역의 사이트는 VPN을 우회합니다.';

  @override
  String onevpnSelectionReset(String location) {
    return '$location 위치를 사용할 수 없어 1VPN이 \'자동\'으로 전환했습니다.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      '선택한 위치를 사용할 수 없어 1VPN이 \'자동\'으로 전환했습니다.';

  @override
  String onevpnReloadRolledBack(String location) {
    return '$location 위치로 전환하지 못했습니다. 이전 위치에 계속 연결되어 있습니다.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      '변경사항을 적용하지 못했습니다. 이전 설정으로 계속 연결되어 있습니다.';

  @override
  String get onevpnDirectRegionsOff => '사용 안함(기본값)';

  @override
  String get onevpnAllViaVpnSubtitle => '모든 트래픽을 터널로 전송';

  @override
  String get onevpnRegionChina => '중국';

  @override
  String get onevpnFirstConnectTitle => '일부 지역은 직접 연결이 더 낫습니다';

  @override
  String get onevpnFirstConnectPointBreaks =>
      '중국, 러시아, 이란 등에서는 모든 트래픽을 VPN으로 보내면 현지 은행 및 결제 앱이 작동하지 않을 수 있습니다.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN은 선택한 지역으로의 연결을 터널 밖에서 실제 IP로 직접 라우팅할 수 있습니다.';

  @override
  String get onevpnFirstConnectPointProtected =>
      '나머지 트래픽은 계속 보호됩니다. 이 설정은 언제든지 변경할 수 있습니다.';

  @override
  String get onevpnFirstConnectChooseRegion => '직접 연결 지역 선택';

  @override
  String get onevpnFirstConnectDismiss => '나중에';

  @override
  String get onevpnCensorshipWarning =>
      '정부 규제로 인해 일부 서버가 귀하의 지역에서 차단될 수 있습니다. 해결을 위해 노력하고 있습니다. 이해해 주셔서 감사합니다.';

  @override
  String get onevpnAlwaysOnTitle => '연결 유지 VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      '앱을 닫아도 터널은 계속 연결되어 있습니다. 기기를 다시 시작하거나 앱을 업데이트한 후에는 연결 유지 VPN이 터널을 자동으로 다시 연결합니다.';

  @override
  String get onevpnAlwaysOnStep1 => '아래의 \'VPN 설정 열기\'를 탭하세요.';

  @override
  String get onevpnAlwaysOnStep2 => '목록에서 1VPN을 찾으세요. 처음 연결한 후에 표시됩니다.';

  @override
  String get onevpnAlwaysOnStep3 => '1VPN 옆의 톱니바퀴 아이콘을 탭하세요.';

  @override
  String get onevpnAlwaysOnStep4 => '\'연결 유지 VPN\'을 사용 설정하세요.';

  @override
  String get onevpnAlwaysOnOpenSettings => 'VPN 설정 열기';

  @override
  String get onevpnPaywallTitle => '요금제 선택';

  @override
  String get onevpnPaywallBenefitLocations => '모든 서버 위치 잠금 해제';

  @override
  String get onevpnPaywallBenefitNoAds => '광고 없음';

  @override
  String get onevpnPaywallBenefitSpeed => '더 빠른 서버 속도';

  @override
  String get onevpnPaywallBenefitP2p => 'BitTorrent (P2P) 지원';

  @override
  String get onevpnPaywallBenefitMoneyBack => '10일 환불 보장';

  @override
  String get onevpnPaywallPlanYearly => '연간';

  @override
  String get onevpnPaywallPlanMonthly => '월간';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '$percent% 할인';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency/월';
  }

  @override
  String get onevpnPaywallPriceUnavailable => '가격 정보 없음';

  @override
  String get onevpnPaywallPlansLoadFailed => '요금제를 불러올 수 없습니다. 연결을 확인하세요.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      '지금은 사용할 수 있는 요금제가 없습니다. 나중에 다시 시도하세요.';

  @override
  String get onevpnGetPremium => '프리미엄 구독';

  @override
  String get onevpnContinueFree => '무료로 계속하기';

  @override
  String get onevpnPaywallRetry => '다시 시도';

  @override
  String get onevpnPaywallPurchaseError => '문제가 발생했습니다. 다시 시도하세요.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return '이 Google 계정에는 다른 1VPN 계정에 연결된, 이용 중이거나 최근에 종료된 1VPN 구독이 있습니다. 해당 계정에 로그인하거나 $support에 문의하세요.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return '이 Google 계정에는 이미 1VPN 구독이 있습니다. 프리미엄이 표시되지 않으면 $support에 문의하세요.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play에서 마지막 구매가 완료되지 않았습니다. 열려 있는 Google Play 화면을 닫고 다시 시도하거나 앱을 다시 시작하세요.';

  @override
  String get onevpnPaywallSupportLink => '1VPN 지원팀';

  @override
  String get onevpnSignUp => '회원가입';

  @override
  String get onevpnAuthEmailLabel => '이메일';

  @override
  String get onevpnAuthPasswordLabel => '비밀번호';

  @override
  String get onevpnAuthTwoFactorLabel => '2FA 토큰';

  @override
  String get onevpnAuthForgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get onevpnAuthSubmitting => '로딩 중…';

  @override
  String get onevpnAuthCreateAccount => '계정 만들기';

  @override
  String get onevpnAuthHaveAccount => '계정이 있으신가요?';

  @override
  String get onevpnAuthLogInInstead => '로그인하기';

  @override
  String get onevpnAuthFieldsRequired => '이메일과 비밀번호를 입력하세요';

  @override
  String get onevpnAuthInvalidEmail => '유효한 이메일 주소를 입력하세요';

  @override
  String get onevpnAuthInvalidCredentials => '이메일 또는 비밀번호가 올바르지 않습니다';

  @override
  String get onevpnAuthInvalidTwoFactor => '2FA 토큰이 올바르지 않습니다';

  @override
  String get onevpnAuthEmailInUse => '이미 계정이 있는 이메일입니다';

  @override
  String get onevpnAuthRateLimited => '시도 횟수가 너무 많습니다. 잠시 후 다시 시도하세요';

  @override
  String get onevpnAuthUnreachable => '서버에 연결할 수 없습니다. 연결을 확인하고 다시 시도하세요';

  @override
  String get onevpnAuthGenericError => '문제가 발생했습니다. 다시 시도하세요';

  @override
  String get onevpnAuthEmailLockedHint => '구매 항목이 이 이메일 주소에 연결되어 있습니다.';

  @override
  String get onevpnPaywallPurchasedTitle => '구매 완료';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return '구매 항목이 $email에 연결되어 있습니다. 사용하려면 이 주소로 계정을 만드세요.';
  }

  @override
  String get onevpnPlanPremiumPending => '프리미엄 · 구매 확인 중';

  @override
  String get onevpnPremiumRecheck => '구매 상태 확인 중…';

  @override
  String get onevpnButtonRetry => '다시 시도';

  @override
  String get onevpnAppVersion => '앱 버전';

  @override
  String get onevpnPrivacyPolicy => '개인정보처리방침';

  @override
  String get onevpnConnect => '연결';

  @override
  String get onevpnDisconnected => '연결 해제됨';

  @override
  String get onevpnConnecting => '연결 중…';

  @override
  String get onevpnConnected => '연결됨';

  @override
  String get onevpnDisconnecting => '연결 해제 중…';

  @override
  String get onevpnConnectionFailed => '연결 실패';

  @override
  String get onevpnTemporarilyUnavailable => '일시적으로 사용할 수 없음';

  @override
  String get onevpnRetry => '다시 시도';

  @override
  String get onevpnApplyChange => '이 변경사항을 적용하시겠습니까?';

  @override
  String get onevpnReconnectNotice =>
      'VPN 연결이 잠시 끊긴 후 다시 연결됩니다. 보통 몇 초밖에 걸리지 않습니다.';

  @override
  String onevpnWillUseName(String name) {
    return '사용 예정: $name';
  }

  @override
  String get onevpnApplyAndReconnect => '적용 후 다시 연결';

  @override
  String get onevpnCancel => '취소';

  @override
  String get onevpnContinue => '계속';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return '기본 도메인이 차단되었습니다. 백업 사용 중: $domain';
  }

  @override
  String get onevpnResultFailed => '실패';

  @override
  String get onevpnDownload => '다운로드';

  @override
  String get onevpnPermissionNotGranted => '권한이 부여되지 않음';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action $result';
  }

  @override
  String get onevpnDisconnect => '연결 해제';

  @override
  String get onevpnTimeout => '시간 초과';

  @override
  String get onevpnNoAvailableEntries => '사용 가능한 진입 서버 없음';

  @override
  String get onevpnAddServers => '서버 추가';

  @override
  String get onevpnNotEnoughServers => '사용 가능한 서버 부족';

  @override
  String get onevpnVpnFinalExit => 'VPN 최종 출구';

  @override
  String get onevpnFinalExitEntryConflict => '최종 출구는 진입 서버와 같을 수 없습니다';

  @override
  String get onevpnChooseNamedRoute => '이름이 지정된 경로를 하나 선택하세요';

  @override
  String get onevpnAllowLocalNetworkHint => '로컬 네트워크의 기기 및 서비스에 대한 액세스를 허용하세요.';

  @override
  String get onevpnSystemApprovalRequired => '시스템 승인 필요';

  @override
  String get onevpnVpnPermissionRequired => 'VPN 권한이 필요합니다. 계속하려면 다시 시도하세요.';

  @override
  String get onevpnChooseInterfaceNotice =>
      '네트워크 액세스에 사용할 인터페이스를 선택하세요. Windows / Linux에서만 필요합니다.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': '안도라',
      'AE': '아랍에미리트',
      'AF': '아프가니스탄',
      'AG': '앤티가 바부다',
      'AI': '앵귈라',
      'AL': '알바니아',
      'AM': '아르메니아',
      'AO': '앙골라',
      'AQ': '남극 대륙',
      'AR': '아르헨티나',
      'AS': '아메리칸 사모아',
      'AT': '오스트리아',
      'AU': '오스트레일리아',
      'AW': '아루바',
      'AX': '올란드 제도',
      'AZ': '아제르바이잔',
      'BA': '보스니아 헤르체고비나',
      'BB': '바베이도스',
      'BD': '방글라데시',
      'BE': '벨기에',
      'BF': '부르키나파소',
      'BG': '불가리아',
      'BH': '바레인',
      'BI': '부룬디',
      'BJ': '베냉',
      'BL': '생바르텔레미',
      'BM': '버뮤다',
      'BN': '브루나이',
      'BO': '볼리비아',
      'BQ': '네덜란드령 카리브',
      'BR': '브라질',
      'BS': '바하마',
      'BT': '부탄',
      'BV': '부베섬',
      'BW': '보츠와나',
      'BY': '벨라루스',
      'BZ': '벨리즈',
      'CA': '캐나다',
      'CC': '코코스 제도',
      'CD': '콩고-킨샤사',
      'CF': '중앙 아프리카 공화국',
      'CG': '콩고-브라자빌',
      'CH': '스위스',
      'CI': '코트디부아르',
      'CK': '쿡 제도',
      'CL': '칠레',
      'CM': '카메룬',
      'CN': '중국 본토',
      'CO': '콜롬비아',
      'CR': '코스타리카',
      'CU': '쿠바',
      'CV': '카보베르데',
      'CW': '퀴라소',
      'CX': '크리스마스섬',
      'CY': '키프로스',
      'CZ': '체코',
      'DE': '독일',
      'DJ': '지부티',
      'DK': '덴마크',
      'DM': '도미니카',
      'DO': '도미니카 공화국',
      'DZ': '알제리',
      'EC': '에콰도르',
      'EE': '에스토니아',
      'EG': '이집트',
      'EH': '서사하라',
      'ER': '에리트리아',
      'ES': '스페인',
      'ET': '에티오피아',
      'FI': '핀란드',
      'FJ': '피지',
      'FK': '포클랜드 제도',
      'FM': '미크로네시아',
      'FO': '페로 제도',
      'FR': '프랑스',
      'GA': '가봉',
      'GB': '영국',
      'GD': '그레나다',
      'GE': '조지아',
      'GF': '프랑스령 기아나',
      'GG': '건지',
      'GH': '가나',
      'GI': '지브롤터',
      'GL': '그린란드',
      'GM': '감비아',
      'GN': '기니',
      'GP': '과들루프',
      'GQ': '적도 기니',
      'GR': '그리스',
      'GS': '사우스조지아 사우스샌드위치 제도',
      'GT': '과테말라',
      'GU': '괌',
      'GW': '기니비사우',
      'GY': '가이아나',
      'HK': '홍콩',
      'HM': '허드 맥도널드 제도',
      'HN': '온두라스',
      'HR': '크로아티아',
      'HT': '아이티',
      'HU': '헝가리',
      'ID': '인도네시아',
      'IE': '아일랜드',
      'IL': '이스라엘',
      'IM': '맨섬',
      'IN': '인도',
      'IO': '차고스 제도',
      'IQ': '이라크',
      'IR': '이란',
      'IS': '아이슬란드',
      'IT': '이탈리아',
      'JE': '저지',
      'JM': '자메이카',
      'JO': '요르단',
      'JP': '일본',
      'KE': '케냐',
      'KG': '키르기스스탄',
      'KH': '캄보디아',
      'KI': '키리바시',
      'KM': '코모로',
      'KN': '세인트키츠 네비스',
      'KP': '북한',
      'KR': '대한민국',
      'KW': '쿠웨이트',
      'KY': '케이맨 제도',
      'KZ': '카자흐스탄',
      'LA': '라오스',
      'LB': '레바논',
      'LC': '세인트루시아',
      'LI': '리히텐슈타인',
      'LK': '스리랑카',
      'LR': '라이베리아',
      'LS': '레소토',
      'LT': '리투아니아',
      'LU': '룩셈부르크',
      'LV': '라트비아',
      'LY': '리비아',
      'MA': '모로코',
      'MC': '모나코',
      'MD': '몰도바',
      'ME': '몬테네그로',
      'MF': '생마르탱',
      'MG': '마다가스카르',
      'MH': '마셜 제도',
      'MK': '북마케도니아',
      'ML': '말리',
      'MM': '미얀마',
      'MN': '몽골',
      'MO': '마카오',
      'MP': '북마리아나제도',
      'MQ': '마르티니크',
      'MR': '모리타니',
      'MS': '몬트세라트',
      'MT': '몰타',
      'MU': '모리셔스',
      'MV': '몰디브',
      'MW': '말라위',
      'MX': '멕시코',
      'MY': '말레이시아',
      'MZ': '모잠비크',
      'NA': '나미비아',
      'NC': '뉴칼레도니아',
      'NE': '니제르',
      'NF': '노퍽섬',
      'NG': '나이지리아',
      'NI': '니카라과',
      'NL': '네덜란드',
      'NO': '노르웨이',
      'NP': '네팔',
      'NR': '나우루',
      'NU': '니우에',
      'NZ': '뉴질랜드',
      'OM': '오만',
      'PA': '파나마',
      'PE': '페루',
      'PF': '프랑스령 폴리네시아',
      'PG': '파푸아뉴기니',
      'PH': '필리핀',
      'PK': '파키스탄',
      'PL': '폴란드',
      'PM': '생피에르 미클롱',
      'PN': '핏케언 제도',
      'PR': '푸에르토리코',
      'PS': '팔레스타인 지구',
      'PT': '포르투갈',
      'PW': '팔라우',
      'PY': '파라과이',
      'QA': '카타르',
      'RE': '레위니옹',
      'RO': '루마니아',
      'RS': '세르비아',
      'RU': '러시아',
      'RW': '르완다',
      'SA': '사우디아라비아',
      'SB': '솔로몬 제도',
      'SC': '세이셸',
      'SD': '수단',
      'SE': '스웨덴',
      'SG': '싱가포르',
      'SH': '세인트헬레나',
      'SI': '슬로베니아',
      'SJ': '스발바르제도-얀마웬섬',
      'SK': '슬로바키아',
      'SL': '시에라리온',
      'SM': '산마리노',
      'SN': '세네갈',
      'SO': '소말리아',
      'SR': '수리남',
      'SS': '남수단',
      'ST': '상투메 프린시페',
      'SV': '엘살바도르',
      'SX': '신트마르턴',
      'SY': '시리아',
      'SZ': '에스와티니',
      'TC': '터크스 케이커스 제도',
      'TD': '차드',
      'TF': '프랑스령 남방 지역',
      'TG': '토고',
      'TH': '태국',
      'TJ': '타지키스탄',
      'TK': '토켈라우',
      'TL': '동티모르',
      'TM': '투르크메니스탄',
      'TN': '튀니지',
      'TO': '통가',
      'TR': '튀르키예',
      'TT': '트리니다드 토바고',
      'TV': '투발루',
      'TW': '대만',
      'TZ': '탄자니아',
      'UA': '우크라이나',
      'UG': '우간다',
      'UM': '미국령 해외 제도',
      'US': '미국',
      'UY': '우루과이',
      'UZ': '우즈베키스탄',
      'VA': '바티칸 시국',
      'VC': '세인트빈센트그레나딘',
      'VE': '베네수엘라',
      'VG': '영국령 버진아일랜드',
      'VI': '미국령 버진아일랜드',
      'VN': '베트남',
      'VU': '바누아투',
      'WF': '왈리스-푸투나 제도',
      'WS': '사모아',
      'XK': '코소보',
      'YE': '예멘',
      'YT': '마요트',
      'ZA': '남아프리카',
      'ZM': '잠비아',
      'ZW': '짐바브웨',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => '개인정보 보호 선택';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': '암스테르담',
      'sgp': '싱가포르',
      'lax': '로스앤젤레스',
      'mel': '멜버른',
      'syd': '시드니',
      'sao': '상파울루',
      'yto': '토론토',
      'scl': '산티아고',
      'cdg': '파리',
      'fra': '프랑크푸르트',
      'del': '델리',
      'bom': '뭄바이',
      'blr': '벵갈루루',
      'tlv': '텔아비브',
      'itm': '오사카',
      'nrt': '도쿄',
      'mex': '멕시코시티',
      'waw': '바르샤바',
      'jnb': '요하네스버그',
      'icn': '서울',
      'mad': '마드리드',
      'sto': '스톡홀름',
      'lhr': '런던',
      'man': '맨체스터',
      'ord': '시카고',
      'dfw': '댈러스',
      'sea': '시애틀',
      'sjc': '샌프란시스코',
      'mia': '마이애미',
      'hnl': '호놀룰루',
      'ewr': '뉴욕',
      'atl': '애틀랜타',
      'hkg': '홍콩',
      'zrh': '취리히',
      'gva': '제네바',
      'svo': '모스크바',
      'led': '상트페테르부르크',
      'hel': '헬싱키',
      'tpe': '타이베이',
      'dxb': '두바이',
      'kbp': '키이우',
      'ist': '이스탄불',
      'otp': '부쿠레슈티',
      'los': '라고스',
      'pty': '파나마시티',
      'kef': '레이캬비크',
      'ber': '베를린',
      'ala': '알마티',
      'tbs': '트빌리시',
      'kul': '쿠알라룸푸르',
      'bkk': '방콕',
      'cgk': '자카르타',
      'mnl': '마닐라',
      'nbo': '나이로비',
      'mxp': '밀라노',
      'dub': '더블린',
      'lis': '리스본',
      'lux': '룩셈부르크',
      'eze': '부에노스아이레스',
      'akl': '오클랜드',
      'yul': '몬트리올',
      'yvr': '밴쿠버',
      'den': '덴버',
      'phx': '피닉스',
      'iad': '워싱턴 D.C.',
      'bos': '보스턴',
      'edi': '에든버러',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => '1VPN이 마음에 드시나요?';

  @override
  String get onevpnYes => '예';

  @override
  String get onevpnNo => '아니요';

  @override
  String get onevpnLocationLocked => '잠김, 프리미엄 전용';

  @override
  String get onevpnManageSubscription => '구독 관리';
}
