// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class OneVpnLocalizationsJa extends OneVpnLocalizations {
  OneVpnLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get onevpnFaq => 'よくある質問';

  @override
  String get onevpnTermsOfService => '利用規約';

  @override
  String get onevpnMenu => 'メニュー';

  @override
  String get onevpnUpgrade => 'アップグレード';

  @override
  String get onevpnUpgradeBannerTitle => 'プレミアムにアップグレード';

  @override
  String get onevpnUpgradeBannerSubtitle => '広告なし、すべてのロケーションと高速通信';

  @override
  String get onevpnLogIn => 'ログイン';

  @override
  String get onevpnLogOut => 'ログアウト';

  @override
  String get onevpnAccount => 'アカウント';

  @override
  String get onevpnContactUs => 'お問い合わせ';

  @override
  String get onevpnRefundPolicy => '返金ポリシー';

  @override
  String get onevpnSupport => 'サポート';

  @override
  String get onevpnLanguage => '言語';

  @override
  String get onevpnLanguageSystem => 'システムのデフォルト';

  @override
  String get onevpnPlanFree => '無料プラン';

  @override
  String get onevpnPlanPremium => 'プレミアムプラン';

  @override
  String get onevpnSelectLocation => 'ロケーションを選択';

  @override
  String get onevpnDirectRegions => '直接接続する地域';

  @override
  String get onevpnFree => '無料';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · 無料';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return '自動 · $node';
  }

  @override
  String get onevpnAutomaticSelection => '自動';

  @override
  String get onevpnStatusNoConnection => '接続なし';

  @override
  String get onevpnStatusConnectionFailed => '接続に失敗しました';

  @override
  String get onevpnStatusUpdating => '更新中…';

  @override
  String get onevpnStatusMeasuring => 'サーバーを測定中…';

  @override
  String get onevpnAutomaticSubtitle => '利用可能な最速のサーバー';

  @override
  String get onevpnLocationsLoadFailed => 'ロケーションを読み込めませんでした。';

  @override
  String get onevpnLocationsUnavailable => '現在、利用できるロケーションはありません。';

  @override
  String get onevpnDirectRegionsCardBody =>
      '一部のサイトは、そのサイトと同じ国から接続した場合にのみ利用できます。地域を選択すると、その地域のサイトには VPN を経由せずに接続します。';

  @override
  String onevpnSelectionReset(String location) {
    return '$location は利用できないため、1VPN は「自動」に切り替えました。';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      '選択したロケーションは利用できないため、1VPN は「自動」に切り替えました。';

  @override
  String onevpnReloadRolledBack(String location) {
    return '$location に切り替えられませんでした。引き続き以前のロケーションに接続しています。';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      '変更を適用できませんでした。引き続き以前の設定で接続しています。';

  @override
  String get onevpnDirectRegionsOff => 'OFF（デフォルト）';

  @override
  String get onevpnAllViaVpnSubtitle => 'すべてのトラフィックがトンネルを経由します';

  @override
  String get onevpnRegionChina => '中国';

  @override
  String get onevpnFirstConnectTitle => '直接接続のほうが快適な地域もあります';

  @override
  String get onevpnFirstConnectPointBreaks =>
      '中国、ロシア、イランなどでは、すべてのトラフィックを VPN 経由にすると、現地の銀行アプリや決済アプリが使えなくなることがあります。';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN では、選択した地域への通信を、トンネルを経由せず実際の IP アドレスから直接送信できます。';

  @override
  String get onevpnFirstConnectPointProtected =>
      'その他のトラフィックは引き続き保護されます。この設定はいつでも変更できます。';

  @override
  String get onevpnFirstConnectChooseRegion => '直接接続する地域を選択';

  @override
  String get onevpnFirstConnectDismiss => '後で';

  @override
  String get onevpnCensorshipWarning =>
      '政府の規制により、一部のサーバーがお住まいの地域でブロックされている場合があります。解決に取り組んでいます。ご理解ありがとうございます。';

  @override
  String get onevpnAlwaysOnTitle => '常時接続 VPN';

  @override
  String get onevpnAlwaysOnIntro =>
      'アプリを閉じてもトンネルは接続されたままです。再起動後やアプリの更新後は、「常時接続 VPN」によって自動的に再接続されます。';

  @override
  String get onevpnAlwaysOnStep1 => '下の「VPN 設定を開く」をタップします。';

  @override
  String get onevpnAlwaysOnStep2 => 'リストで 1VPN を探します。初回の接続後に表示されます。';

  @override
  String get onevpnAlwaysOnStep3 => '1VPN の横にある歯車アイコンをタップします。';

  @override
  String get onevpnAlwaysOnStep4 => '「常時接続 VPN」を ON にします。';

  @override
  String get onevpnAlwaysOnOpenSettings => 'VPN 設定を開く';

  @override
  String get onevpnPaywallTitle => 'プランを選択してください';

  @override
  String get onevpnPaywallBenefitLocations => 'すべてのサーバーロケーションをアンロック';

  @override
  String get onevpnPaywallBenefitNoAds => '広告なし';

  @override
  String get onevpnPaywallBenefitSpeed => 'より速いサーバー速度';

  @override
  String get onevpnPaywallBenefitP2p => 'BitTorrent（P2P）対応';

  @override
  String get onevpnPaywallBenefitMoneyBack => '10日間返金保証';

  @override
  String get onevpnPaywallPlanYearly => '年間';

  @override
  String get onevpnPaywallPlanMonthly => '月間';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return '$percent%お得';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / 月';
  }

  @override
  String get onevpnPaywallPriceUnavailable => '価格を表示できません';

  @override
  String get onevpnPaywallPlansLoadFailed => 'プランを読み込めませんでした。接続を確認してください。';

  @override
  String get onevpnPaywallPlansUnavailable =>
      '現在、利用できるプランはありません。しばらくしてからもう一度お試しください。';

  @override
  String get onevpnGetPremium => 'プレミアムを取得';

  @override
  String get onevpnContinueFree => '無料で続行';

  @override
  String get onevpnPaywallRetry => '再試行';

  @override
  String get onevpnPaywallPurchaseError => '問題が発生しました。もう一度お試しください。';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'この Google アカウントには、別の 1VPN アカウントに関連付けられた、有効または最近終了した 1VPN サブスクリプションがあります。そのアカウントにログインするか、$supportにお問い合わせください。';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'この Google アカウントには、すでに 1VPN サブスクリプションがあります。プレミアムが表示されない場合は、$supportにお問い合わせください。';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play で前回の購入が完了していません。開いている Google Play の画面を閉じてもう一度お試しいただくか、アプリを再起動してください。';

  @override
  String get onevpnPaywallSupportLink => '1VPN サポート';

  @override
  String get onevpnSignUp => 'サインアップ';

  @override
  String get onevpnAuthEmailLabel => 'メール';

  @override
  String get onevpnAuthPasswordLabel => 'パスワード';

  @override
  String get onevpnAuthTwoFactorLabel => '2FAトークン';

  @override
  String get onevpnAuthForgotPassword => 'パスワードをお忘れですか？';

  @override
  String get onevpnAuthSubmitting => '読み込み中…';

  @override
  String get onevpnAuthCreateAccount => 'アカウントを作成';

  @override
  String get onevpnAuthHaveAccount => 'アカウントをお持ちですか？';

  @override
  String get onevpnAuthLogInInstead => 'ログインに切り替える';

  @override
  String get onevpnAuthFieldsRequired => 'メールアドレスとパスワードを入力してください';

  @override
  String get onevpnAuthInvalidEmail => '有効なメールアドレスを入力してください';

  @override
  String get onevpnAuthInvalidCredentials => 'メールアドレスまたはパスワードが正しくありません';

  @override
  String get onevpnAuthInvalidTwoFactor => '2FAトークンが無効です';

  @override
  String get onevpnAuthEmailInUse => 'このメールアドレスのアカウントはすでに存在します';

  @override
  String get onevpnAuthRateLimited => '試行回数が上限を超えました。しばらくしてからもう一度お試しください';

  @override
  String get onevpnAuthUnreachable => 'サーバーに接続できませんでした。接続を確認して、もう一度お試しください';

  @override
  String get onevpnAuthGenericError => '問題が発生しました。もう一度お試しください';

  @override
  String get onevpnAuthEmailLockedHint => 'ご購入はこのメールアドレスに関連付けられています。';

  @override
  String get onevpnPaywallPurchasedTitle => '購入が完了しました';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'ご購入は $email に関連付けられています。ご利用いただくには、このメールアドレスでアカウントを作成してください。';
  }

  @override
  String get onevpnPlanPremiumPending => 'プレミアム · 購入を確認中';

  @override
  String get onevpnPremiumRecheck => '購入状況を確認しています…';

  @override
  String get onevpnButtonRetry => '再試行';

  @override
  String get onevpnAppVersion => 'アプリのバージョン';

  @override
  String get onevpnPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get onevpnConnect => '接続';

  @override
  String get onevpnDisconnected => '切断されました';

  @override
  String get onevpnConnecting => '接続中…';

  @override
  String get onevpnConnected => '接続済み';

  @override
  String get onevpnDisconnecting => '切断中…';

  @override
  String get onevpnConnectionFailed => '接続に失敗しました';

  @override
  String get onevpnTemporarilyUnavailable => '一時的に利用できません';

  @override
  String get onevpnRetry => '再試行';

  @override
  String get onevpnApplyChange => 'この変更を適用しますか？';

  @override
  String get onevpnReconnectNotice => 'VPN の接続が一時的に切断され、再接続されます。通常は数秒で完了します。';

  @override
  String onevpnWillUseName(String name) {
    return '変更後：$name';
  }

  @override
  String get onevpnApplyAndReconnect => '適用して再接続';

  @override
  String get onevpnCancel => 'キャンセル';

  @override
  String get onevpnContinue => '続行';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'メインドメインがブロックされています。バックアップを使用中：$domain';
  }

  @override
  String get onevpnResultFailed => '失敗';

  @override
  String get onevpnDownload => 'ダウンロード';

  @override
  String get onevpnPermissionNotGranted => '権限が付与されていません';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action$result';
  }

  @override
  String get onevpnDisconnect => '切断';

  @override
  String get onevpnTimeout => 'タイムアウト';

  @override
  String get onevpnNoAvailableEntries => '利用できるエントリーサーバーがありません';

  @override
  String get onevpnAddServers => 'サーバーを追加してください';

  @override
  String get onevpnNotEnoughServers => '利用できるサーバーが不足しています';

  @override
  String get onevpnVpnFinalExit => 'VPN 最終出口';

  @override
  String get onevpnFinalExitEntryConflict => '最終出口とエントリーサーバーを同じサーバーにすることはできません';

  @override
  String get onevpnChooseNamedRoute => '名前付きルートを 1 つ選択してください';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'ローカルネットワーク上のデバイスとサービスへのアクセスを許可してください。';

  @override
  String get onevpnSystemApprovalRequired => 'システムの承認が必要です';

  @override
  String get onevpnVpnPermissionRequired => 'VPN の権限が必要です。続行するには再試行してください。';

  @override
  String get onevpnChooseInterfaceNotice =>
      'ネットワークへのアクセスに使用するインターフェースを選択してください。Windows / Linux でのみ必要です。';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'アンドラ',
      'AE': 'アラブ首長国連邦',
      'AF': 'アフガニスタン',
      'AG': 'アンティグア・バーブーダ',
      'AI': 'アンギラ',
      'AL': 'アルバニア',
      'AM': 'アルメニア',
      'AO': 'アンゴラ',
      'AQ': '南極',
      'AR': 'アルゼンチン',
      'AS': '米領サモア',
      'AT': 'オーストリア',
      'AU': 'オーストラリア',
      'AW': 'アルバ',
      'AX': 'オーランド諸島',
      'AZ': 'アゼルバイジャン',
      'BA': 'ボスニア・ヘルツェゴビナ',
      'BB': 'バルバドス',
      'BD': 'バングラデシュ',
      'BE': 'ベルギー',
      'BF': 'ブルキナファソ',
      'BG': 'ブルガリア',
      'BH': 'バーレーン',
      'BI': 'ブルンジ',
      'BJ': 'ベナン',
      'BL': 'サン・バルテルミー',
      'BM': 'バミューダ',
      'BN': 'ブルネイ',
      'BO': 'ボリビア',
      'BQ': 'オランダ領カリブ',
      'BR': 'ブラジル',
      'BS': 'バハマ',
      'BT': 'ブータン',
      'BV': 'ブーベ島',
      'BW': 'ボツワナ',
      'BY': 'ベラルーシ',
      'BZ': 'ベリーズ',
      'CA': 'カナダ',
      'CC': 'ココス（キーリング）諸島',
      'CD': 'コンゴ民主共和国（キンシャサ）',
      'CF': '中央アフリカ共和国',
      'CG': 'コンゴ共和国（ブラザビル）',
      'CH': 'スイス',
      'CI': 'コートジボワール',
      'CK': 'クック諸島',
      'CL': 'チリ',
      'CM': 'カメルーン',
      'CN': '中国本土',
      'CO': 'コロンビア',
      'CR': 'コスタリカ',
      'CU': 'キューバ',
      'CV': 'カーボベルデ',
      'CW': 'キュラソー',
      'CX': 'クリスマス島',
      'CY': 'キプロス',
      'CZ': 'チェコ',
      'DE': 'ドイツ',
      'DJ': 'ジブチ',
      'DK': 'デンマーク',
      'DM': 'ドミニカ国',
      'DO': 'ドミニカ共和国',
      'DZ': 'アルジェリア',
      'EC': 'エクアドル',
      'EE': 'エストニア',
      'EG': 'エジプト',
      'EH': '西サハラ',
      'ER': 'エリトリア',
      'ES': 'スペイン',
      'ET': 'エチオピア',
      'FI': 'フィンランド',
      'FJ': 'フィジー',
      'FK': 'フォークランド諸島',
      'FM': 'ミクロネシア連邦',
      'FO': 'フェロー諸島',
      'FR': 'フランス',
      'GA': 'ガボン',
      'GB': 'イギリス',
      'GD': 'グレナダ',
      'GE': 'ジョージア',
      'GF': '仏領ギアナ',
      'GG': 'ガーンジー',
      'GH': 'ガーナ',
      'GI': 'ジブラルタル',
      'GL': 'グリーンランド',
      'GM': 'ガンビア',
      'GN': 'ギニア',
      'GP': 'グアドループ',
      'GQ': '赤道ギニア',
      'GR': 'ギリシャ',
      'GS': 'サウスジョージア・サウスサンドウィッチ諸島',
      'GT': 'グアテマラ',
      'GU': 'グアム',
      'GW': 'ギニアビサウ',
      'GY': 'ガイアナ',
      'HK': '香港',
      'HM': 'ハード島・マクドナルド諸島',
      'HN': 'ホンジュラス',
      'HR': 'クロアチア',
      'HT': 'ハイチ',
      'HU': 'ハンガリー',
      'ID': 'インドネシア',
      'IE': 'アイルランド',
      'IL': 'イスラエル',
      'IM': 'マン島',
      'IN': 'インド',
      'IO': 'チャゴス諸島',
      'IQ': 'イラク',
      'IR': 'イラン',
      'IS': 'アイスランド',
      'IT': 'イタリア',
      'JE': 'ジャージー',
      'JM': 'ジャマイカ',
      'JO': 'ヨルダン',
      'JP': '日本',
      'KE': 'ケニア',
      'KG': 'キルギス',
      'KH': 'カンボジア',
      'KI': 'キリバス',
      'KM': 'コモロ',
      'KN': 'セントクリストファー・ネーヴィス',
      'KP': '北朝鮮',
      'KR': '韓国',
      'KW': 'クウェート',
      'KY': 'ケイマン諸島',
      'KZ': 'カザフスタン',
      'LA': 'ラオス',
      'LB': 'レバノン',
      'LC': 'セントルシア',
      'LI': 'リヒテンシュタイン',
      'LK': 'スリランカ',
      'LR': 'リベリア',
      'LS': 'レソト',
      'LT': 'リトアニア',
      'LU': 'ルクセンブルク',
      'LV': 'ラトビア',
      'LY': 'リビア',
      'MA': 'モロッコ',
      'MC': 'モナコ',
      'MD': 'モルドバ',
      'ME': 'モンテネグロ',
      'MF': 'サン・マルタン',
      'MG': 'マダガスカル',
      'MH': 'マーシャル諸島',
      'MK': '北マケドニア',
      'ML': 'マリ',
      'MM': 'ミャンマー（ビルマ）',
      'MN': 'モンゴル',
      'MO': 'マカオ',
      'MP': '北マリアナ諸島',
      'MQ': 'マルティニーク',
      'MR': 'モーリタニア',
      'MS': 'モントセラト',
      'MT': 'マルタ',
      'MU': 'モーリシャス',
      'MV': 'モルディブ',
      'MW': 'マラウイ',
      'MX': 'メキシコ',
      'MY': 'マレーシア',
      'MZ': 'モザンビーク',
      'NA': 'ナミビア',
      'NC': 'ニューカレドニア',
      'NE': 'ニジェール',
      'NF': 'ノーフォーク島',
      'NG': 'ナイジェリア',
      'NI': 'ニカラグア',
      'NL': 'オランダ',
      'NO': 'ノルウェー',
      'NP': 'ネパール',
      'NR': 'ナウル',
      'NU': 'ニウエ',
      'NZ': 'ニュージーランド',
      'OM': 'オマーン',
      'PA': 'パナマ',
      'PE': 'ペルー',
      'PF': '仏領ポリネシア',
      'PG': 'パプアニューギニア',
      'PH': 'フィリピン',
      'PK': 'パキスタン',
      'PL': 'ポーランド',
      'PM': 'サンピエール島・ミクロン島',
      'PN': 'ピトケアン諸島',
      'PR': 'プエルトリコ',
      'PS': 'パレスチナ自治区',
      'PT': 'ポルトガル',
      'PW': 'パラオ',
      'PY': 'パラグアイ',
      'QA': 'カタール',
      'RE': 'レユニオン',
      'RO': 'ルーマニア',
      'RS': 'セルビア',
      'RU': 'ロシア',
      'RW': 'ルワンダ',
      'SA': 'サウジアラビア',
      'SB': 'ソロモン諸島',
      'SC': 'セーシェル',
      'SD': 'スーダン',
      'SE': 'スウェーデン',
      'SG': 'シンガポール',
      'SH': 'セントヘレナ',
      'SI': 'スロベニア',
      'SJ': 'スバールバル諸島・ヤンマイエン島',
      'SK': 'スロバキア',
      'SL': 'シエラレオネ',
      'SM': 'サンマリノ',
      'SN': 'セネガル',
      'SO': 'ソマリア',
      'SR': 'スリナム',
      'SS': '南スーダン',
      'ST': 'サントメ・プリンシペ',
      'SV': 'エルサルバドル',
      'SX': 'シント・マールテン',
      'SY': 'シリア',
      'SZ': 'エスワティニ',
      'TC': 'タークス・カイコス諸島',
      'TD': 'チャド',
      'TF': '仏領極南諸島',
      'TG': 'トーゴ',
      'TH': 'タイ',
      'TJ': 'タジキスタン',
      'TK': 'トケラウ',
      'TL': '東ティモール',
      'TM': 'トルクメニスタン',
      'TN': 'チュニジア',
      'TO': 'トンガ',
      'TR': 'トルコ',
      'TT': 'トリニダード・トバゴ',
      'TV': 'ツバル',
      'TW': '台湾',
      'TZ': 'タンザニア',
      'UA': 'ウクライナ',
      'UG': 'ウガンダ',
      'UM': '合衆国領有小離島',
      'US': 'アメリカ合衆国',
      'UY': 'ウルグアイ',
      'UZ': 'ウズベキスタン',
      'VA': 'バチカン市国',
      'VC': 'セントビンセント及びグレナディーン諸島',
      'VE': 'ベネズエラ',
      'VG': '英領ヴァージン諸島',
      'VI': '米領ヴァージン諸島',
      'VN': 'ベトナム',
      'VU': 'バヌアツ',
      'WF': 'ウォリス・フツナ',
      'WS': 'サモア',
      'XK': 'コソボ',
      'YE': 'イエメン',
      'YT': 'マヨット',
      'ZA': '南アフリカ',
      'ZM': 'ザンビア',
      'ZW': 'ジンバブエ',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'プライバシーの選択';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'アムステルダム',
      'sgp': 'シンガポール',
      'lax': 'ロサンゼルス',
      'mel': 'メルボルン',
      'syd': 'シドニー',
      'sao': 'サンパウロ',
      'yto': 'トロント',
      'scl': 'サンティアゴ',
      'cdg': 'パリ',
      'fra': 'フランクフルト',
      'del': 'デリー',
      'bom': 'ムンバイ',
      'blr': 'バンガロール',
      'tlv': 'テルアビブ',
      'itm': '大阪',
      'nrt': '東京',
      'mex': 'メキシコシティ',
      'waw': 'ワルシャワ',
      'jnb': 'ヨハネスブルク',
      'icn': 'ソウル',
      'mad': 'マドリード',
      'sto': 'ストックホルム',
      'lhr': 'ロンドン',
      'man': 'マンチェスター',
      'ord': 'シカゴ',
      'dfw': 'ダラス',
      'sea': 'シアトル',
      'sjc': 'サンフランシスコ',
      'mia': 'マイアミ',
      'hnl': 'ホノルル',
      'ewr': 'ニューヨーク',
      'atl': 'アトランタ',
      'hkg': '香港',
      'zrh': 'チューリッヒ',
      'gva': 'ジュネーブ',
      'svo': 'モスクワ',
      'led': 'サンクトペテルブルク',
      'hel': 'ヘルシンキ',
      'tpe': '台北',
      'dxb': 'ドバイ',
      'kbp': 'キーウ',
      'ist': 'イスタンブール',
      'otp': 'ブカレスト',
      'los': 'ラゴス',
      'pty': 'パナマシティ',
      'kef': 'レイキャビク',
      'ber': 'ベルリン',
      'ala': 'アルマトイ',
      'tbs': 'トビリシ',
      'kul': 'クアラルンプール',
      'bkk': 'バンコク',
      'cgk': 'ジャカルタ',
      'mnl': 'マニラ',
      'nbo': 'ナイロビ',
      'mxp': 'ミラノ',
      'dub': 'ダブリン',
      'lis': 'リスボン',
      'lux': 'ルクセンブルク',
      'eze': 'ブエノスアイレス',
      'akl': 'オークランド',
      'yul': 'モントリオール',
      'yvr': 'バンクーバー',
      'den': 'デンバー',
      'phx': 'フェニックス',
      'iad': 'ワシントンD.C.',
      'bos': 'ボストン',
      'edi': 'エディンバラ',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => '1VPN を気に入っていただけていますか？';

  @override
  String get onevpnYes => 'はい';

  @override
  String get onevpnNo => 'いいえ';

  @override
  String get onevpnLocationLocked => 'ロック中、プレミアム限定';

  @override
  String get onevpnManageSubscription => 'サブスクリプションを管理';
}
