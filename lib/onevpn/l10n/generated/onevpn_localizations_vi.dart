// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class OneVpnLocalizationsVi extends OneVpnLocalizations {
  OneVpnLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get onevpnFaq => 'Câu hỏi thường gặp';

  @override
  String get onevpnTermsOfService => 'Điều khoản dịch vụ';

  @override
  String get onevpnMenu => 'Trình đơn';

  @override
  String get onevpnUpgrade => 'Nâng cấp';

  @override
  String get onevpnUpgradeBannerTitle => 'Nâng cấp lên Premium';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'Không quảng cáo, tất cả vị trí & tốc độ nhanh hơn';

  @override
  String get onevpnLogIn => 'Đăng nhập';

  @override
  String get onevpnLogOut => 'Đăng xuất';

  @override
  String get onevpnAccount => 'Tài khoản';

  @override
  String get onevpnContactUs => 'Liên hệ với chúng tôi';

  @override
  String get onevpnRefundPolicy => 'Chính sách hoàn tiền';

  @override
  String get onevpnSupport => 'Hỗ trợ';

  @override
  String get onevpnLanguage => 'Ngôn ngữ';

  @override
  String get onevpnLanguageSystem => 'Theo chế độ mặc định của hệ thống';

  @override
  String get onevpnPlanFree => 'Gói miễn phí';

  @override
  String get onevpnPlanPremium => 'Gói Premium';

  @override
  String get onevpnSelectLocation => 'Chọn vị trí';

  @override
  String get onevpnDirectRegions => 'Khu vực kết nối trực tiếp';

  @override
  String get onevpnFree => 'Miễn phí';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · Miễn phí';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'Tự động · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'Tự động';

  @override
  String get onevpnStatusNoConnection => 'Không có kết nối';

  @override
  String get onevpnStatusConnectionFailed => 'Kết nối không thành công';

  @override
  String get onevpnStatusUpdating => 'Đang cập nhật…';

  @override
  String get onevpnStatusMeasuring => 'Đang kiểm tra máy chủ…';

  @override
  String get onevpnAutomaticSubtitle => 'Nhanh nhất hiện có';

  @override
  String get onevpnLocationsLoadFailed =>
      'Không thể tải danh sách vị trí của bạn.';

  @override
  String get onevpnLocationsUnavailable => 'Hiện không có vị trí nào khả dụng.';

  @override
  String get onevpnDirectRegionsCardBody =>
      'Một số trang web chỉ hoạt động khi bạn kết nối từ cùng quốc gia với trang web đó. Khi bạn chọn một khu vực, các trang web từ khu vực đó sẽ không đi qua VPN.';

  @override
  String onevpnSelectionReset(String location) {
    return '$location không khả dụng nên 1VPN đã chuyển sang “Tự động”.';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'Vị trí đã chọn không khả dụng nên 1VPN đã chuyển sang “Tự động”.';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'Không thể chuyển sang $location. Bạn vẫn đang kết nối với vị trí trước đó.';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'Không thể áp dụng thay đổi. Bạn vẫn đang kết nối bằng cài đặt trước đó.';

  @override
  String get onevpnDirectRegionsOff => 'Tắt (Mặc định)';

  @override
  String get onevpnAllViaVpnSubtitle =>
      'Mọi lưu lượng truy cập đều đi qua đường hầm';

  @override
  String get onevpnRegionChina => 'Trung Quốc';

  @override
  String get onevpnFirstConnectTitle =>
      'Một số khu vực hoạt động tốt hơn khi kết nối trực tiếp';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'Ở những nơi như Trung Quốc, Nga và Iran, việc chuyển toàn bộ lưu lượng truy cập qua VPN có thể làm gián đoạn các ứng dụng ngân hàng và thanh toán trong nước.';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN có thể định tuyến trực tiếp lưu lượng đến khu vực bạn chọn, bên ngoài đường hầm, bằng địa chỉ IP thực của bạn.';

  @override
  String get onevpnFirstConnectPointProtected =>
      'Mọi lưu lượng truy cập khác vẫn được bảo vệ. Bạn có thể thay đổi tùy chọn này bất cứ lúc nào.';

  @override
  String get onevpnFirstConnectChooseRegion => 'Chọn khu vực kết nối trực tiếp';

  @override
  String get onevpnFirstConnectDismiss => 'Để sau';

  @override
  String get onevpnCensorshipWarning =>
      'Một số máy chủ có thể bị chặn ở khu vực của bạn do các hạn chế của chính phủ. Chúng tôi đang nỗ lực giải quyết vấn đề này. Cảm ơn bạn đã thông cảm.';

  @override
  String get onevpnAlwaysOnTitle => 'VPN luôn bật';

  @override
  String get onevpnAlwaysOnIntro =>
      'Đường hầm vẫn được duy trì khi bạn đóng ứng dụng. Sau khi khởi động lại hoặc cập nhật ứng dụng, “VPN luôn bật” sẽ tự động kết nối lại đường hầm.';

  @override
  String get onevpnAlwaysOnStep1 => 'Nhấn vào “Mở cài đặt VPN” bên dưới.';

  @override
  String get onevpnAlwaysOnStep2 =>
      'Tìm 1VPN trong danh sách. Ứng dụng sẽ xuất hiện sau lần kết nối đầu tiên.';

  @override
  String get onevpnAlwaysOnStep3 =>
      'Nhấn vào biểu tượng bánh răng bên cạnh 1VPN.';

  @override
  String get onevpnAlwaysOnStep4 => 'Bật “VPN luôn bật”.';

  @override
  String get onevpnAlwaysOnOpenSettings => 'Mở cài đặt VPN';

  @override
  String get onevpnPaywallTitle => 'Chọn gói của bạn';

  @override
  String get onevpnPaywallBenefitLocations => 'Mở khóa tất cả vị trí máy chủ';

  @override
  String get onevpnPaywallBenefitNoAds => 'Không có quảng cáo';

  @override
  String get onevpnPaywallBenefitSpeed => 'Tốc độ máy chủ nhanh hơn';

  @override
  String get onevpnPaywallBenefitP2p => 'Hỗ trợ BitTorrent (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack => 'Bảo đảm hoàn tiền trong 10 ngày';

  @override
  String get onevpnPaywallPlanYearly => 'Hàng năm';

  @override
  String get onevpnPaywallPlanMonthly => 'Hàng tháng';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'Tiết kiệm $percent%';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / tháng';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'Không có thông tin giá';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'Không thể tải gói. Vui lòng kiểm tra kết nối của bạn.';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'Hiện không có gói nào. Vui lòng thử lại sau.';

  @override
  String get onevpnGetPremium => 'Nhận Premium';

  @override
  String get onevpnContinueFree => 'Tiếp tục miễn phí';

  @override
  String get onevpnPaywallRetry => 'Thử lại';

  @override
  String get onevpnPaywallPurchaseError => 'Đã xảy ra lỗi. Vui lòng thử lại.';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'Tài khoản Google này có gói đăng ký 1VPN đang hoạt động hoặc vừa kết thúc, được liên kết với một tài khoản 1VPN khác. Hãy đăng nhập vào tài khoản đó hoặc liên hệ với $support.';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'Tài khoản Google này đã có gói đăng ký 1VPN. Nếu Premium không xuất hiện, hãy liên hệ với $support.';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play chưa hoàn tất giao dịch mua gần nhất của bạn. Hãy đóng mọi màn hình Google Play đang mở rồi thử lại, hoặc khởi động lại ứng dụng.';

  @override
  String get onevpnPaywallSupportLink => 'bộ phận hỗ trợ 1VPN';

  @override
  String get onevpnSignUp => 'Đăng ký';

  @override
  String get onevpnAuthEmailLabel => 'Email';

  @override
  String get onevpnAuthPasswordLabel => 'Mật khẩu';

  @override
  String get onevpnAuthTwoFactorLabel => 'Mã 2FA';

  @override
  String get onevpnAuthForgotPassword => 'Quên mật khẩu?';

  @override
  String get onevpnAuthSubmitting => 'Đang tải…';

  @override
  String get onevpnAuthCreateAccount => 'Tạo tài khoản';

  @override
  String get onevpnAuthHaveAccount => 'Đã có tài khoản?';

  @override
  String get onevpnAuthLogInInstead => 'Chuyển sang đăng nhập';

  @override
  String get onevpnAuthFieldsRequired => 'Nhập email và mật khẩu';

  @override
  String get onevpnAuthInvalidEmail => 'Nhập địa chỉ email hợp lệ';

  @override
  String get onevpnAuthInvalidCredentials => 'Thông tin đăng nhập không hợp lệ';

  @override
  String get onevpnAuthInvalidTwoFactor => 'Mã 2FA không hợp lệ';

  @override
  String get onevpnAuthEmailInUse => 'Email này đã được đăng ký';

  @override
  String get onevpnAuthRateLimited =>
      'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau giây lát';

  @override
  String get onevpnAuthUnreachable =>
      'Không thể kết nối với máy chủ. Vui lòng kiểm tra kết nối của bạn và thử lại';

  @override
  String get onevpnAuthGenericError => 'Đã xảy ra lỗi. Vui lòng thử lại';

  @override
  String get onevpnAuthEmailLockedHint =>
      'Giao dịch mua của bạn được liên kết với địa chỉ email này.';

  @override
  String get onevpnPaywallPurchasedTitle => 'Đã hoàn tất giao dịch mua';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'Giao dịch mua của bạn được liên kết với $email. Hãy tạo tài khoản bằng địa chỉ đó để sử dụng gói đã mua.';
  }

  @override
  String get onevpnPlanPremiumPending =>
      'Premium · đang xác nhận giao dịch mua';

  @override
  String get onevpnPremiumRecheck =>
      'Đang kiểm tra trạng thái giao dịch mua của bạn…';

  @override
  String get onevpnButtonRetry => 'Thử lại';

  @override
  String get onevpnAppVersion => 'Phiên bản ứng dụng';

  @override
  String get onevpnPrivacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get onevpnConnect => 'Kết nối';

  @override
  String get onevpnDisconnected => 'Đã ngắt kết nối';

  @override
  String get onevpnConnecting => 'Đang kết nối…';

  @override
  String get onevpnConnected => 'Đã kết nối';

  @override
  String get onevpnDisconnecting => 'Đang ngắt kết nối…';

  @override
  String get onevpnConnectionFailed => 'Kết nối không thành công';

  @override
  String get onevpnTemporarilyUnavailable => 'Tạm thời không khả dụng';

  @override
  String get onevpnRetry => 'Thử lại';

  @override
  String get onevpnApplyChange => 'Áp dụng thay đổi này?';

  @override
  String get onevpnReconnectNotice =>
      'VPN sẽ tạm ngắt kết nối rồi kết nối lại. Quá trình này thường chỉ mất vài giây.';

  @override
  String onevpnWillUseName(String name) {
    return 'Sẽ sử dụng: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'Áp dụng và kết nối lại';

  @override
  String get onevpnCancel => 'Hủy';

  @override
  String get onevpnContinue => 'Tiếp tục';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'Tên miền chính bị chặn. Đang dùng tên miền dự phòng: $domain';
  }

  @override
  String get onevpnResultFailed => 'không thành công';

  @override
  String get onevpnDownload => 'Tải xuống';

  @override
  String get onevpnPermissionNotGranted => 'Chưa được cấp quyền';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action $result';
  }

  @override
  String get onevpnDisconnect => 'Ngắt kết nối';

  @override
  String get onevpnTimeout => 'Hết thời gian chờ';

  @override
  String get onevpnNoAvailableEntries => 'Không có máy chủ đầu vào khả dụng';

  @override
  String get onevpnAddServers => 'Thêm máy chủ';

  @override
  String get onevpnNotEnoughServers => 'Không đủ máy chủ khả dụng';

  @override
  String get onevpnVpnFinalExit => 'Điểm thoát cuối của VPN';

  @override
  String get onevpnFinalExitEntryConflict =>
      'Điểm thoát cuối không thể đồng thời là máy chủ đầu vào';

  @override
  String get onevpnChooseNamedRoute => 'Chọn một tuyến đã đặt tên';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'Cho phép truy cập các thiết bị và dịch vụ trong mạng cục bộ.';

  @override
  String get onevpnSystemApprovalRequired => 'Cần sự phê duyệt của hệ thống';

  @override
  String get onevpnVpnPermissionRequired =>
      'Cần cấp quyền VPN. Vui lòng thử lại để tiếp tục.';

  @override
  String get onevpnChooseInterfaceNotice =>
      'Chọn giao diện mạng dùng để truy cập mạng. Chỉ bắt buộc trên Windows / Linux.';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'Andorra',
      'AE': 'Các Tiểu Vương quốc Ả Rập Thống nhất',
      'AF': 'Afghanistan',
      'AG': 'Antigua và Barbuda',
      'AI': 'Anguilla',
      'AL': 'Albania',
      'AM': 'Armenia',
      'AO': 'Angola',
      'AQ': 'Nam Cực',
      'AR': 'Argentina',
      'AS': 'Samoa thuộc Mỹ',
      'AT': 'Áo',
      'AU': 'Úc',
      'AW': 'Aruba',
      'AX': 'Quần đảo Åland',
      'AZ': 'Azerbaijan',
      'BA': 'Bosnia và Herzegovina',
      'BB': 'Barbados',
      'BD': 'Bangladesh',
      'BE': 'Bỉ',
      'BF': 'Burkina Faso',
      'BG': 'Bulgaria',
      'BH': 'Bahrain',
      'BI': 'Burundi',
      'BJ': 'Benin',
      'BL': 'St. Barthélemy',
      'BM': 'Bermuda',
      'BN': 'Brunei',
      'BO': 'Bolivia',
      'BQ': 'Ca-ri-bê Hà Lan',
      'BR': 'Brazil',
      'BS': 'Bahamas',
      'BT': 'Bhutan',
      'BV': 'Đảo Bouvet',
      'BW': 'Botswana',
      'BY': 'Belarus',
      'BZ': 'Belize',
      'CA': 'Canada',
      'CC': 'Quần đảo Cocos (Keeling)',
      'CD': 'Congo - Kinshasa',
      'CF': 'Cộng hòa Trung Phi',
      'CG': 'Congo - Brazzaville',
      'CH': 'Thụy Sĩ',
      'CI': 'Côte d’Ivoire',
      'CK': 'Quần đảo Cook',
      'CL': 'Chile',
      'CM': 'Cameroon',
      'CN': 'Trung Quốc đại lục',
      'CO': 'Colombia',
      'CR': 'Costa Rica',
      'CU': 'Cuba',
      'CV': 'Cape Verde',
      'CW': 'Curaçao',
      'CX': 'Đảo Giáng Sinh',
      'CY': 'Síp',
      'CZ': 'Séc',
      'DE': 'Đức',
      'DJ': 'Djibouti',
      'DK': 'Đan Mạch',
      'DM': 'Dominica',
      'DO': 'Cộng hòa Dominica',
      'DZ': 'Algeria',
      'EC': 'Ecuador',
      'EE': 'Estonia',
      'EG': 'Ai Cập',
      'EH': 'Tây Sahara',
      'ER': 'Eritrea',
      'ES': 'Tây Ban Nha',
      'ET': 'Ethiopia',
      'FI': 'Phần Lan',
      'FJ': 'Fiji',
      'FK': 'Quần đảo Falkland',
      'FM': 'Micronesia',
      'FO': 'Quần đảo Faroe',
      'FR': 'Pháp',
      'GA': 'Gabon',
      'GB': 'Vương quốc Anh',
      'GD': 'Grenada',
      'GE': 'Georgia',
      'GF': 'Guiana thuộc Pháp',
      'GG': 'Guernsey',
      'GH': 'Ghana',
      'GI': 'Gibraltar',
      'GL': 'Greenland',
      'GM': 'Gambia',
      'GN': 'Guinea',
      'GP': 'Guadeloupe',
      'GQ': 'Guinea Xích Đạo',
      'GR': 'Hy Lạp',
      'GS': 'Nam Georgia & Quần đảo Nam Sandwich',
      'GT': 'Guatemala',
      'GU': 'Guam',
      'GW': 'Guinea-Bissau',
      'GY': 'Guyana',
      'HK': 'Hồng Kông',
      'HM': 'Quần đảo Heard và McDonald',
      'HN': 'Honduras',
      'HR': 'Croatia',
      'HT': 'Haiti',
      'HU': 'Hungary',
      'ID': 'Indonesia',
      'IE': 'Ireland',
      'IL': 'Israel',
      'IM': 'Đảo Man',
      'IN': 'Ấn Độ',
      'IO': 'Quần đảo Chagos',
      'IQ': 'Iraq',
      'IR': 'Iran',
      'IS': 'Iceland',
      'IT': 'Italy',
      'JE': 'Jersey',
      'JM': 'Jamaica',
      'JO': 'Jordan',
      'JP': 'Nhật Bản',
      'KE': 'Kenya',
      'KG': 'Kyrgyzstan',
      'KH': 'Campuchia',
      'KI': 'Kiribati',
      'KM': 'Comoros',
      'KN': 'St. Kitts và Nevis',
      'KP': 'Triều Tiên',
      'KR': 'Hàn Quốc',
      'KW': 'Kuwait',
      'KY': 'Quần đảo Cayman',
      'KZ': 'Kazakhstan',
      'LA': 'Lào',
      'LB': 'Li-băng',
      'LC': 'St. Lucia',
      'LI': 'Liechtenstein',
      'LK': 'Sri Lanka',
      'LR': 'Liberia',
      'LS': 'Lesotho',
      'LT': 'Litva',
      'LU': 'Luxembourg',
      'LV': 'Latvia',
      'LY': 'Libya',
      'MA': 'Ma-rốc',
      'MC': 'Monaco',
      'MD': 'Moldova',
      'ME': 'Montenegro',
      'MF': 'St. Martin',
      'MG': 'Madagascar',
      'MH': 'Quần đảo Marshall',
      'MK': 'Bắc Macedonia',
      'ML': 'Mali',
      'MM': 'Myanmar (Miến Điện)',
      'MN': 'Mông Cổ',
      'MO': 'Macao',
      'MP': 'Quần đảo Bắc Mariana',
      'MQ': 'Martinique',
      'MR': 'Mauritania',
      'MS': 'Montserrat',
      'MT': 'Malta',
      'MU': 'Mauritius',
      'MV': 'Maldives',
      'MW': 'Malawi',
      'MX': 'Mexico',
      'MY': 'Malaysia',
      'MZ': 'Mozambique',
      'NA': 'Namibia',
      'NC': 'New Caledonia',
      'NE': 'Niger',
      'NF': 'Đảo Norfolk',
      'NG': 'Nigeria',
      'NI': 'Nicaragua',
      'NL': 'Hà Lan',
      'NO': 'Na Uy',
      'NP': 'Nepal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'New Zealand',
      'OM': 'Oman',
      'PA': 'Panama',
      'PE': 'Peru',
      'PF': 'Polynesia thuộc Pháp',
      'PG': 'Papua New Guinea',
      'PH': 'Philippines',
      'PK': 'Pakistan',
      'PL': 'Ba Lan',
      'PM': 'Saint Pierre và Miquelon',
      'PN': 'Quần đảo Pitcairn',
      'PR': 'Puerto Rico',
      'PS': 'Lãnh thổ Palestine',
      'PT': 'Bồ Đào Nha',
      'PW': 'Palau',
      'PY': 'Paraguay',
      'QA': 'Qatar',
      'RE': 'Réunion',
      'RO': 'Romania',
      'RS': 'Serbia',
      'RU': 'Nga',
      'RW': 'Rwanda',
      'SA': 'Ả Rập Xê-út',
      'SB': 'Quần đảo Solomon',
      'SC': 'Seychelles',
      'SD': 'Sudan',
      'SE': 'Thụy Điển',
      'SG': 'Singapore',
      'SH': 'St. Helena',
      'SI': 'Slovenia',
      'SJ': 'Svalbard và Jan Mayen',
      'SK': 'Slovakia',
      'SL': 'Sierra Leone',
      'SM': 'San Marino',
      'SN': 'Senegal',
      'SO': 'Somalia',
      'SR': 'Suriname',
      'SS': 'Nam Sudan',
      'ST': 'São Tomé và Príncipe',
      'SV': 'El Salvador',
      'SX': 'Sint Maarten',
      'SY': 'Syria',
      'SZ': 'Eswatini',
      'TC': 'Quần đảo Turks và Caicos',
      'TD': 'Chad',
      'TF': 'Lãnh thổ phía Nam Thuộc Pháp',
      'TG': 'Togo',
      'TH': 'Thái Lan',
      'TJ': 'Tajikistan',
      'TK': 'Tokelau',
      'TL': 'Timor-Leste',
      'TM': 'Turkmenistan',
      'TN': 'Tunisia',
      'TO': 'Tonga',
      'TR': 'Thổ Nhĩ Kỳ',
      'TT': 'Trinidad và Tobago',
      'TV': 'Tuvalu',
      'TW': 'Đài Loan',
      'TZ': 'Tanzania',
      'UA': 'Ukraina',
      'UG': 'Uganda',
      'UM': 'Các tiểu đảo xa của Hoa Kỳ',
      'US': 'Hoa Kỳ',
      'UY': 'Uruguay',
      'UZ': 'Uzbekistan',
      'VA': 'Thành Vatican',
      'VC': 'St. Vincent và Grenadines',
      'VE': 'Venezuela',
      'VG': 'Quần đảo Virgin thuộc Anh',
      'VI': 'Quần đảo Virgin thuộc Hoa Kỳ',
      'VN': 'Việt Nam',
      'VU': 'Vanuatu',
      'WF': 'Wallis và Futuna',
      'WS': 'Samoa',
      'XK': 'Kosovo',
      'YE': 'Yemen',
      'YT': 'Mayotte',
      'ZA': 'Nam Phi',
      'ZM': 'Zambia',
      'ZW': 'Zimbabwe',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'Lựa chọn quyền riêng tư';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'Amsterdam',
      'sgp': 'Singapore',
      'lax': 'Los Angeles',
      'mel': 'Melbourne',
      'syd': 'Sydney',
      'sao': 'São Paulo',
      'yto': 'Toronto',
      'scl': 'Santiago',
      'cdg': 'Paris',
      'fra': 'Frankfurt',
      'del': 'New Delhi',
      'bom': 'Mumbai',
      'blr': 'Bangalore',
      'tlv': 'Tel Aviv',
      'itm': 'Osaka',
      'nrt': 'Tokyo',
      'mex': 'Thành phố Mexico',
      'waw': 'Warsaw',
      'jnb': 'Johannesburg',
      'icn': 'Seoul',
      'mad': 'Madrid',
      'sto': 'Stockholm',
      'lhr': 'Luân Đôn',
      'man': 'Manchester',
      'ord': 'Chicago',
      'dfw': 'Dallas',
      'sea': 'Seattle',
      'sjc': 'San Francisco',
      'mia': 'Miami',
      'hnl': 'Honolulu',
      'ewr': 'New York',
      'atl': 'Atlanta',
      'hkg': 'Hồng Kông',
      'zrh': 'Zürich',
      'gva': 'Genève',
      'svo': 'Moskva',
      'led': 'Sankt-Peterburg',
      'hel': 'Helsinki',
      'tpe': 'Đài Bắc',
      'dxb': 'Dubai',
      'kbp': 'Kyiv',
      'ist': 'Istanbul',
      'otp': 'Bucharest',
      'los': 'Lagos',
      'pty': 'Thành phố Panama',
      'kef': 'Reykjavík',
      'ber': 'Berlin',
      'ala': 'Almaty',
      'tbs': 'Tbilisi',
      'kul': 'Kuala Lumpur',
      'bkk': 'Bangkok',
      'cgk': 'Jakarta',
      'mnl': 'Manila',
      'nbo': 'Nairobi',
      'mxp': 'Milano',
      'dub': 'Dublin',
      'lis': 'Lisboa',
      'lux': 'Luxembourg',
      'eze': 'Buenos Aires',
      'akl': 'Auckland',
      'yul': 'Montréal',
      'yvr': 'Vancouver',
      'den': 'Denver',
      'phx': 'Phoenix',
      'iad': 'Washington, D.C.',
      'bos': 'Boston',
      'edi': 'Edinburgh',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'Bạn có thích 1VPN không?';

  @override
  String get onevpnYes => 'Có';

  @override
  String get onevpnNo => 'Không';

  @override
  String get onevpnLocationLocked => 'Đã khóa, chỉ dành cho Premium';

  @override
  String get onevpnManageSubscription => 'Quản lý gói đăng ký';
}
