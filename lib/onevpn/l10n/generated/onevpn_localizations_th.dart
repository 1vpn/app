// ignore_for_file: text_direction_code_point_in_literal

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class OneVpnLocalizationsTh extends OneVpnLocalizations {
  OneVpnLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get onevpnFaq => 'คำถามที่พบบ่อย';

  @override
  String get onevpnTermsOfService => 'ข้อกำหนดในการให้บริการ';

  @override
  String get onevpnMenu => 'เมนู';

  @override
  String get onevpnUpgrade => 'อัปเกรด';

  @override
  String get onevpnUpgradeBannerTitle => 'อัปเกรดเป็นพรีเมียม';

  @override
  String get onevpnUpgradeBannerSubtitle =>
      'ไม่มีโฆษณา ทุกตำแหน่ง และความเร็วที่สูงขึ้น';

  @override
  String get onevpnLogIn => 'เข้าสู่ระบบ';

  @override
  String get onevpnLogOut => 'ออกจากระบบ';

  @override
  String get onevpnAccount => 'บัญชี';

  @override
  String get onevpnContactUs => 'ติดต่อเรา';

  @override
  String get onevpnRefundPolicy => 'นโยบายการคืนเงิน';

  @override
  String get onevpnSupport => 'ความช่วยเหลือ';

  @override
  String get onevpnLanguage => 'ภาษา';

  @override
  String get onevpnLanguageSystem => 'ค่าเริ่มต้นของระบบ';

  @override
  String get onevpnPlanFree => 'แผนฟรี';

  @override
  String get onevpnPlanPremium => 'แผนพรีเมียม';

  @override
  String get onevpnSelectLocation => 'เลือกตำแหน่ง';

  @override
  String get onevpnDirectRegions => 'ภูมิภาคที่เชื่อมต่อโดยตรง';

  @override
  String get onevpnFree => 'ฟรี';

  @override
  String onevpnFreeSubtitle(String country) {
    return '$country · ฟรี';
  }

  @override
  String onevpnAutomaticResolved(String node) {
    return 'อัตโนมัติ · $node';
  }

  @override
  String get onevpnAutomaticSelection => 'อัตโนมัติ';

  @override
  String get onevpnStatusNoConnection => 'ไม่มีการเชื่อมต่อ';

  @override
  String get onevpnStatusConnectionFailed => 'การเชื่อมต่อล้มเหลว';

  @override
  String get onevpnStatusUpdating => 'กำลังอัปเดต…';

  @override
  String get onevpnStatusMeasuring => 'กำลังตรวจสอบเซิร์ฟเวอร์…';

  @override
  String get onevpnAutomaticSubtitle => 'เร็วที่สุดที่พร้อมใช้งาน';

  @override
  String get onevpnLocationsLoadFailed => 'โหลดตำแหน่งของคุณไม่ได้';

  @override
  String get onevpnLocationsUnavailable => 'ขณะนี้ไม่มีตำแหน่งที่ใช้งานได้';

  @override
  String get onevpnDirectRegionsCardBody =>
      'บางเว็บไซต์ใช้งานได้เฉพาะเมื่อคุณเชื่อมต่อจากประเทศเดียวกับเว็บไซต์นั้น เมื่อคุณเลือกภูมิภาค เว็บไซต์จากภูมิภาคนั้นจะเชื่อมต่อโดยไม่ผ่าน VPN';

  @override
  String onevpnSelectionReset(String location) {
    return '$location ใช้งานไม่ได้ 1VPN จึงเปลี่ยนเป็น \"อัตโนมัติ\" แล้ว';
  }

  @override
  String get onevpnSelectionResetUnnamed =>
      'ตำแหน่งที่เลือกใช้งานไม่ได้ 1VPN จึงเปลี่ยนเป็น \"อัตโนมัติ\" แล้ว';

  @override
  String onevpnReloadRolledBack(String location) {
    return 'เปลี่ยนไปใช้ $location ไม่ได้ คุณยังเชื่อมต่อกับตำแหน่งเดิมอยู่';
  }

  @override
  String get onevpnReloadRolledBackSettings =>
      'ใช้การเปลี่ยนแปลงไม่ได้ คุณยังเชื่อมต่อด้วยการตั้งค่าเดิมอยู่';

  @override
  String get onevpnDirectRegionsOff => 'ปิด (ค่าเริ่มต้น)';

  @override
  String get onevpnAllViaVpnSubtitle => 'การรับส่งข้อมูลทั้งหมดผ่านอุโมงค์';

  @override
  String get onevpnRegionChina => 'จีน';

  @override
  String get onevpnFirstConnectTitle =>
      'บางภูมิภาคใช้งานได้ดีกว่าเมื่อเชื่อมต่อโดยตรง';

  @override
  String get onevpnFirstConnectPointBreaks =>
      'ในประเทศอย่างจีน รัสเซีย และอิหร่าน การส่งทุกอย่างผ่าน VPN อาจทำให้แอปธนาคารและแอปชำระเงินในประเทศใช้งานไม่ได้';

  @override
  String get onevpnFirstConnectPointDirect =>
      '1VPN สามารถกำหนดเส้นทางให้ภูมิภาคที่คุณเลือกเชื่อมต่อโดยตรงนอกอุโมงค์ โดยใช้ IP จริงของคุณ';

  @override
  String get onevpnFirstConnectPointProtected =>
      'ส่วนอื่นๆ ทั้งหมดยังคงได้รับการปกป้อง คุณเปลี่ยนการตั้งค่านี้ได้ทุกเมื่อ';

  @override
  String get onevpnFirstConnectChooseRegion => 'เลือกภูมิภาคที่เชื่อมต่อโดยตรง';

  @override
  String get onevpnFirstConnectDismiss => 'ไว้ทีหลัง';

  @override
  String get onevpnCensorshipWarning =>
      'เซิร์ฟเวอร์บางตัวอาจถูกบล็อกในภูมิภาคของคุณเนื่องจากข้อจำกัดของรัฐบาล เรากำลังดำเนินการแก้ไขปัญหานี้ ขอบคุณสำหรับความเข้าใจของคุณ';

  @override
  String get onevpnAlwaysOnTitle => 'การเชื่อมต่อ VPN ตลอดเวลา';

  @override
  String get onevpnAlwaysOnIntro =>
      'อุโมงค์จะยังคงเชื่อมต่ออยู่เมื่อคุณปิดแอป หลังจากรีสตาร์ทอุปกรณ์หรืออัปเดตแอป \"การเชื่อมต่อ VPN ตลอดเวลา\" จะเชื่อมต่ออุโมงค์อีกครั้งโดยอัตโนมัติ';

  @override
  String get onevpnAlwaysOnStep1 => 'แตะ \"เปิดการตั้งค่า VPN\" ด้านล่าง';

  @override
  String get onevpnAlwaysOnStep2 =>
      'หา 1VPN ในรายการ 1VPN จะแสดงหลังจากที่คุณเชื่อมต่อครั้งแรก';

  @override
  String get onevpnAlwaysOnStep3 => 'แตะไอคอนรูปเฟืองข้าง 1VPN';

  @override
  String get onevpnAlwaysOnStep4 => 'เปิด \"การเชื่อมต่อ VPN ตลอดเวลา\"';

  @override
  String get onevpnAlwaysOnOpenSettings => 'เปิดการตั้งค่า VPN';

  @override
  String get onevpnPaywallTitle => 'เลือกแผนของคุณ';

  @override
  String get onevpnPaywallBenefitLocations =>
      'ปลดล็อกตำแหน่งเซิร์ฟเวอร์ทั้งหมด';

  @override
  String get onevpnPaywallBenefitNoAds => 'ไม่มีโฆษณา';

  @override
  String get onevpnPaywallBenefitSpeed => 'ความเร็วเซิร์ฟเวอร์ที่เร็วขึ้น';

  @override
  String get onevpnPaywallBenefitP2p => 'รองรับ BitTorrent (P2P)';

  @override
  String get onevpnPaywallBenefitMoneyBack => 'รับประกันคืนเงินภายใน 10 วัน';

  @override
  String get onevpnPaywallPlanYearly => 'รายปี';

  @override
  String get onevpnPaywallPlanMonthly => 'รายเดือน';

  @override
  String onevpnPaywallSaleYearly(String percent) {
    return 'ประหยัด $percent%';
  }

  @override
  String onevpnPaywallPricePerMonth(String amount, String currency) {
    return '$amount $currency / เดือน';
  }

  @override
  String get onevpnPaywallPriceUnavailable => 'ไม่มีข้อมูลราคา';

  @override
  String get onevpnPaywallPlansLoadFailed =>
      'โหลดแผนไม่ได้ โปรดตรวจสอบการเชื่อมต่อ';

  @override
  String get onevpnPaywallPlansUnavailable =>
      'ขณะนี้ยังไม่มีแผนให้เลือก โปรดลองอีกครั้งในภายหลัง';

  @override
  String get onevpnGetPremium => 'รับพรีเมียม';

  @override
  String get onevpnContinueFree => 'ดำเนินการต่อฟรี';

  @override
  String get onevpnPaywallRetry => 'ลองอีกครั้ง';

  @override
  String get onevpnPaywallPurchaseError => 'เกิดข้อผิดพลาด โปรดลองอีกครั้ง';

  @override
  String onevpnPaywallPurchaseOtherAccount(String support) {
    return 'บัญชี Google นี้มีการสมัครสมาชิก 1VPN ที่ใช้งานอยู่หรือเพิ่งสิ้นสุด ซึ่งเชื่อมโยงกับบัญชี 1VPN อื่น โปรดเข้าสู่ระบบบัญชีนั้นหรือติดต่อ$support';
  }

  @override
  String onevpnPaywallPurchaseOwned(String support) {
    return 'บัญชี Google นี้มีการสมัครสมาชิก 1VPN อยู่แล้ว หากพรีเมียมไม่แสดง โปรดติดต่อ$support';
  }

  @override
  String get onevpnPaywallPurchaseUnfinished =>
      'Google Play ยังทำการซื้อครั้งล่าสุดของคุณไม่เสร็จ โปรดปิดหน้าจอ Google Play ที่เปิดอยู่แล้วลองอีกครั้ง หรือรีสตาร์ทแอป';

  @override
  String get onevpnPaywallSupportLink => 'ฝ่ายสนับสนุนของ 1VPN';

  @override
  String get onevpnSignUp => 'สมัครสมาชิก';

  @override
  String get onevpnAuthEmailLabel => 'อีเมล';

  @override
  String get onevpnAuthPasswordLabel => 'รหัสผ่าน';

  @override
  String get onevpnAuthTwoFactorLabel => 'รหัส 2FA';

  @override
  String get onevpnAuthForgotPassword => 'ลืมรหัสผ่านใช่ไหม';

  @override
  String get onevpnAuthSubmitting => 'กำลังโหลด…';

  @override
  String get onevpnAuthCreateAccount => 'สร้างบัญชี';

  @override
  String get onevpnAuthHaveAccount => 'มีบัญชีอยู่แล้วใช่ไหม';

  @override
  String get onevpnAuthLogInInstead => 'เข้าสู่ระบบแทน';

  @override
  String get onevpnAuthFieldsRequired => 'ป้อนอีเมลและรหัสผ่าน';

  @override
  String get onevpnAuthInvalidEmail => 'ป้อนอีเมลที่ถูกต้อง';

  @override
  String get onevpnAuthInvalidCredentials => 'ข้อมูลเข้าสู่ระบบไม่ถูกต้อง';

  @override
  String get onevpnAuthInvalidTwoFactor => 'รหัส 2FA ไม่ถูกต้อง';

  @override
  String get onevpnAuthEmailInUse => 'อีเมลนี้มีบัญชีอยู่แล้ว';

  @override
  String get onevpnAuthRateLimited =>
      'พยายามหลายครั้งเกินไป โปรดลองอีกครั้งในอีกสักครู่';

  @override
  String get onevpnAuthUnreachable =>
      'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ โปรดตรวจสอบการเชื่อมต่อแล้วลองอีกครั้ง';

  @override
  String get onevpnAuthGenericError => 'เกิดข้อผิดพลาด โปรดลองอีกครั้ง';

  @override
  String get onevpnAuthEmailLockedHint =>
      'การซื้อของคุณเชื่อมโยงกับอีเมลนี้แล้ว';

  @override
  String get onevpnPaywallPurchasedTitle => 'การซื้อเสร็จสมบูรณ์';

  @override
  String onevpnPaywallPurchasedBody(String email) {
    return 'การซื้อของคุณเชื่อมโยงกับ $email แล้ว โปรดสร้างบัญชีด้วยอีเมลนี้เพื่อใช้งาน';
  }

  @override
  String get onevpnPlanPremiumPending => 'พรีเมียม · กำลังยืนยันการซื้อ';

  @override
  String get onevpnPremiumRecheck => 'กำลังตรวจสอบสถานะการซื้อของคุณ…';

  @override
  String get onevpnButtonRetry => 'ลองอีกครั้ง';

  @override
  String get onevpnAppVersion => 'เวอร์ชันแอป';

  @override
  String get onevpnPrivacyPolicy => 'นโยบายความเป็นส่วนตัว';

  @override
  String get onevpnConnect => 'เชื่อมต่อ';

  @override
  String get onevpnDisconnected => 'ไม่ได้เชื่อมต่อ';

  @override
  String get onevpnConnecting => 'กำลังเชื่อมต่อ…';

  @override
  String get onevpnConnected => 'เชื่อมต่อแล้ว';

  @override
  String get onevpnDisconnecting => 'กำลังยกเลิกการเชื่อมต่อ…';

  @override
  String get onevpnConnectionFailed => 'การเชื่อมต่อล้มเหลว';

  @override
  String get onevpnTemporarilyUnavailable => 'ไม่พร้อมใช้งานชั่วคราว';

  @override
  String get onevpnRetry => 'ลองอีกครั้ง';

  @override
  String get onevpnApplyChange => 'ใช้การเปลี่ยนแปลงนี้ไหม';

  @override
  String get onevpnReconnectNotice =>
      'VPN จะตัดการเชื่อมต่อชั่วครู่แล้วเชื่อมต่ออีกครั้ง โดยปกติจะใช้เวลาเพียงไม่กี่วินาที';

  @override
  String onevpnWillUseName(String name) {
    return 'จะใช้: $name';
  }

  @override
  String get onevpnApplyAndReconnect => 'ใช้และเชื่อมต่ออีกครั้ง';

  @override
  String get onevpnCancel => 'ยกเลิก';

  @override
  String get onevpnContinue => 'ดำเนินการต่อ';

  @override
  String onevpnBackupDomainBlocked(String domain) {
    return 'โดเมนหลักถูกบล็อก กำลังใช้โดเมนสำรอง: $domain';
  }

  @override
  String get onevpnResultFailed => 'ล้มเหลว';

  @override
  String get onevpnDownload => 'ดาวน์โหลด';

  @override
  String get onevpnPermissionNotGranted => 'ไม่ได้รับสิทธิ์';

  @override
  String onevpnActionResult(String action, String result) {
    return '$action $result';
  }

  @override
  String get onevpnDisconnect => 'ยกเลิกการเชื่อมต่อ';

  @override
  String get onevpnTimeout => 'หมดเวลา';

  @override
  String get onevpnNoAvailableEntries => 'ไม่มีเซิร์ฟเวอร์ทางเข้าที่ใช้งานได้';

  @override
  String get onevpnAddServers => 'เพิ่มเซิร์ฟเวอร์';

  @override
  String get onevpnNotEnoughServers => 'เซิร์ฟเวอร์ที่ใช้งานได้มีไม่เพียงพอ';

  @override
  String get onevpnVpnFinalExit => 'ทางออกสุดท้ายของ VPN';

  @override
  String get onevpnFinalExitEntryConflict =>
      'ทางออกสุดท้ายต้องไม่ใช่เซิร์ฟเวอร์เดียวกับเซิร์ฟเวอร์ทางเข้า';

  @override
  String get onevpnChooseNamedRoute => 'เลือกเส้นทางที่ตั้งชื่อไว้หนึ่งเส้นทาง';

  @override
  String get onevpnAllowLocalNetworkHint =>
      'อนุญาตให้เข้าถึงอุปกรณ์และบริการในเครือข่ายภายใน';

  @override
  String get onevpnSystemApprovalRequired => 'ต้องได้รับการอนุมัติจากระบบ';

  @override
  String get onevpnVpnPermissionRequired =>
      'ต้องมีสิทธิ์ VPN โปรดลองอีกครั้งเพื่อดำเนินการต่อ';

  @override
  String get onevpnChooseInterfaceNotice =>
      'เลือกอินเทอร์เฟซที่ใช้เข้าถึงเครือข่าย จำเป็นสำหรับ Windows / Linux เท่านั้น';

  @override
  String onevpnCountryRegionName(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'AD': 'อันดอร์รา',
      'AE': 'สหรัฐอาหรับเอมิเรตส์',
      'AF': 'อัฟกานิสถาน',
      'AG': 'แอนติกาและบาร์บูดา',
      'AI': 'แองกวิลลา',
      'AL': 'แอลเบเนีย',
      'AM': 'อาร์เมเนีย',
      'AO': 'แองโกลา',
      'AQ': 'แอนตาร์กติกา',
      'AR': 'อาร์เจนตินา',
      'AS': 'อเมริกันซามัว',
      'AT': 'ออสเตรีย',
      'AU': 'ออสเตรเลีย',
      'AW': 'อารูบา',
      'AX': 'หมู่เกาะโอลันด์',
      'AZ': 'อาเซอร์ไบจาน',
      'BA': 'บอสเนียและเฮอร์เซโกวีนา',
      'BB': 'บาร์เบโดส',
      'BD': 'บังกลาเทศ',
      'BE': 'เบลเยียม',
      'BF': 'บูร์กินาฟาโซ',
      'BG': 'บัลแกเรีย',
      'BH': 'บาห์เรน',
      'BI': 'บุรุนดี',
      'BJ': 'เบนิน',
      'BL': 'เซนต์บาร์เธเลมี',
      'BM': 'เบอร์มิวดา',
      'BN': 'บรูไน',
      'BO': 'โบลิเวีย',
      'BQ': 'เนเธอร์แลนด์แคริบเบียน',
      'BR': 'บราซิล',
      'BS': 'บาฮามาส',
      'BT': 'ภูฏาน',
      'BV': 'เกาะบูเว',
      'BW': 'บอตสวานา',
      'BY': 'เบลารุส',
      'BZ': 'เบลีซ',
      'CA': 'แคนาดา',
      'CC': 'หมู่เกาะโคโคส (คีลิง)',
      'CD': 'คองโก - กินชาซา',
      'CF': 'สาธารณรัฐแอฟริกากลาง',
      'CG': 'คองโก - บราซซาวิล',
      'CH': 'สวิตเซอร์แลนด์',
      'CI': 'โกตดิวัวร์',
      'CK': 'หมู่เกาะคุก',
      'CL': 'ชิลี',
      'CM': 'แคเมอรูน',
      'CN': 'จีนแผ่นดินใหญ่',
      'CO': 'โคลอมเบีย',
      'CR': 'คอสตาริกา',
      'CU': 'คิวบา',
      'CV': 'เคปเวิร์ด',
      'CW': 'คูราเซา',
      'CX': 'เกาะคริสต์มาส',
      'CY': 'ไซปรัส',
      'CZ': 'เช็ก',
      'DE': 'เยอรมนี',
      'DJ': 'จิบูตี',
      'DK': 'เดนมาร์ก',
      'DM': 'โดมินิกา',
      'DO': 'สาธารณรัฐโดมินิกัน',
      'DZ': 'แอลจีเรีย',
      'EC': 'เอกวาดอร์',
      'EE': 'เอสโตเนีย',
      'EG': 'อียิปต์',
      'EH': 'ซาฮาราตะวันตก',
      'ER': 'เอริเทรีย',
      'ES': 'สเปน',
      'ET': 'เอธิโอเปีย',
      'FI': 'ฟินแลนด์',
      'FJ': 'ฟิจิ',
      'FK': 'หมู่เกาะฟอล์กแลนด์',
      'FM': 'ไมโครนีเซีย',
      'FO': 'หมู่เกาะแฟโร',
      'FR': 'ฝรั่งเศส',
      'GA': 'กาบอง',
      'GB': 'สหราชอาณาจักร',
      'GD': 'เกรเนดา',
      'GE': 'จอร์เจีย',
      'GF': 'เฟรนช์เกียนา',
      'GG': 'เกิร์นซีย์',
      'GH': 'กานา',
      'GI': 'ยิบรอลตาร์',
      'GL': 'กรีนแลนด์',
      'GM': 'แกมเบีย',
      'GN': 'กินี',
      'GP': 'กวาเดอลูป',
      'GQ': 'อิเควทอเรียลกินี',
      'GR': 'กรีซ',
      'GS': 'เกาะเซาท์จอร์เจียและหมู่เกาะเซาท์แซนด์วิช',
      'GT': 'กัวเตมาลา',
      'GU': 'กวม',
      'GW': 'กินี-บิสเซา',
      'GY': 'กายอานา',
      'HK': 'ฮ่องกง',
      'HM': 'เกาะเฮิร์ดและหมู่เกาะแมกดอนัลด์',
      'HN': 'ฮอนดูรัส',
      'HR': 'โครเอเชีย',
      'HT': 'เฮติ',
      'HU': 'ฮังการี',
      'ID': 'อินโดนีเซีย',
      'IE': 'ไอร์แลนด์',
      'IL': 'อิสราเอล',
      'IM': 'เกาะแมน',
      'IN': 'อินเดีย',
      'IO': 'หมู่เกาะชากอส',
      'IQ': 'อิรัก',
      'IR': 'อิหร่าน',
      'IS': 'ไอซ์แลนด์',
      'IT': 'อิตาลี',
      'JE': 'เจอร์ซีย์',
      'JM': 'จาเมกา',
      'JO': 'จอร์แดน',
      'JP': 'ญี่ปุ่น',
      'KE': 'เคนยา',
      'KG': 'คีร์กีซสถาน',
      'KH': 'กัมพูชา',
      'KI': 'คิริบาส',
      'KM': 'คอโมโรส',
      'KN': 'เซนต์คิตส์และเนวิส',
      'KP': 'เกาหลีเหนือ',
      'KR': 'เกาหลีใต้',
      'KW': 'คูเวต',
      'KY': 'หมู่เกาะเคย์แมน',
      'KZ': 'คาซัคสถาน',
      'LA': 'ลาว',
      'LB': 'เลบานอน',
      'LC': 'เซนต์ลูเซีย',
      'LI': 'ลิกเตนสไตน์',
      'LK': 'ศรีลังกา',
      'LR': 'ไลบีเรีย',
      'LS': 'เลโซโท',
      'LT': 'ลิทัวเนีย',
      'LU': 'ลักเซมเบิร์ก',
      'LV': 'ลัตเวีย',
      'LY': 'ลิเบีย',
      'MA': 'โมร็อกโก',
      'MC': 'โมนาโก',
      'MD': 'มอลโดวา',
      'ME': 'มอนเตเนโกร',
      'MF': 'เซนต์มาร์ติน',
      'MG': 'มาดากัสการ์',
      'MH': 'หมู่เกาะมาร์แชลล์',
      'MK': 'มาซิโดเนียเหนือ',
      'ML': 'มาลี',
      'MM': 'เมียนมา (พม่า)',
      'MN': 'มองโกเลีย',
      'MO': 'มาเก๊า',
      'MP': 'หมู่เกาะนอร์เทิร์นมาเรียนา',
      'MQ': 'มาร์ตินีก',
      'MR': 'มอริเตเนีย',
      'MS': 'มอนต์เซอร์รัต',
      'MT': 'มอลตา',
      'MU': 'มอริเชียส',
      'MV': 'มัลดีฟส์',
      'MW': 'มาลาวี',
      'MX': 'เม็กซิโก',
      'MY': 'มาเลเซีย',
      'MZ': 'โมซัมบิก',
      'NA': 'นามิเบีย',
      'NC': 'นิวแคลิโดเนีย',
      'NE': 'ไนเจอร์',
      'NF': 'เกาะนอร์ฟอล์ก',
      'NG': 'ไนจีเรีย',
      'NI': 'นิการากัว',
      'NL': 'เนเธอร์แลนด์',
      'NO': 'นอร์เวย์',
      'NP': 'เนปาล',
      'NR': 'นาอูรู',
      'NU': 'นีอูเอ',
      'NZ': 'นิวซีแลนด์',
      'OM': 'โอมาน',
      'PA': 'ปานามา',
      'PE': 'เปรู',
      'PF': 'เฟรนช์โปลินีเซีย',
      'PG': 'ปาปัวนิวกินี',
      'PH': 'ฟิลิปปินส์',
      'PK': 'ปากีสถาน',
      'PL': 'โปแลนด์',
      'PM': 'แซงปีแยร์และมีเกอลง',
      'PN': 'หมู่เกาะพิตแคร์น',
      'PR': 'เปอร์โตริโก',
      'PS': 'ดินแดนปาเลสไตน์',
      'PT': 'โปรตุเกส',
      'PW': 'ปาเลา',
      'PY': 'ปารากวัย',
      'QA': 'กาตาร์',
      'RE': 'เรอูนียง',
      'RO': 'โรมาเนีย',
      'RS': 'เซอร์เบีย',
      'RU': 'รัสเซีย',
      'RW': 'รวันดา',
      'SA': 'ซาอุดีอาระเบีย',
      'SB': 'หมู่เกาะโซโลมอน',
      'SC': 'เซเชลส์',
      'SD': 'ซูดาน',
      'SE': 'สวีเดน',
      'SG': 'สิงคโปร์',
      'SH': 'เซนต์เฮเลนา',
      'SI': 'สโลวีเนีย',
      'SJ': 'สฟาลบาร์และยานไมเอน',
      'SK': 'สโลวะเกีย',
      'SL': 'เซียร์ราลีโอน',
      'SM': 'ซานมาริโน',
      'SN': 'เซเนกัล',
      'SO': 'โซมาเลีย',
      'SR': 'ซูรินาเม',
      'SS': 'ซูดานใต้',
      'ST': 'เซาตูเมและปรินซิปี',
      'SV': 'เอลซัลวาดอร์',
      'SX': 'ซินต์มาร์เทน',
      'SY': 'ซีเรีย',
      'SZ': 'เอสวาตีนี',
      'TC': 'หมู่เกาะเติกส์และหมู่เกาะเคคอส',
      'TD': 'ชาด',
      'TF': 'เฟรนช์เซาเทิร์นเทร์ริทอรีส์',
      'TG': 'โตโก',
      'TH': 'ไทย',
      'TJ': 'ทาจิกิสถาน',
      'TK': 'โตเกเลา',
      'TL': 'ติมอร์-เลสเต',
      'TM': 'เติร์กเมนิสถาน',
      'TN': 'ตูนิเซีย',
      'TO': 'ตองกา',
      'TR': 'ตุรกี',
      'TT': 'ตรินิแดดและโตเบโก',
      'TV': 'ตูวาลู',
      'TW': 'ไต้หวัน',
      'TZ': 'แทนซาเนีย',
      'UA': 'ยูเครน',
      'UG': 'ยูกันดา',
      'UM': 'หมู่เกาะรอบนอกของสหรัฐอเมริกา',
      'US': 'สหรัฐอเมริกา',
      'UY': 'อุรุกวัย',
      'UZ': 'อุซเบกิสถาน',
      'VA': 'นครวาติกัน',
      'VC': 'เซนต์วินเซนต์และเกรนาดีนส์',
      'VE': 'เวเนซุเอลา',
      'VG': 'หมู่เกาะบริติชเวอร์จิน',
      'VI': 'หมู่เกาะเวอร์จินของสหรัฐอเมริกา',
      'VN': 'เวียดนาม',
      'VU': 'วานูอาตู',
      'WF': 'วาลลิสและฟุตูนา',
      'WS': 'ซามัว',
      'XK': 'โคโซโว',
      'YE': 'เยเมน',
      'YT': 'มายอต',
      'ZA': 'แอฟริกาใต้',
      'ZM': 'แซมเบีย',
      'ZW': 'ซิมบับเว',
      'other': '$code',
    });
    return '$_temp0';
  }

  @override
  String get onevpnPrivacyChoices => 'ตัวเลือกความเป็นส่วนตัว';

  @override
  String onevpnCityName(String code, String name) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'ams': 'อัมสเตอร์ดัม',
      'sgp': 'สิงคโปร์',
      'lax': 'ลอสแอนเจลิส',
      'mel': 'เมลเบิร์น',
      'syd': 'ซิดนีย์',
      'sao': 'เซาเปาลู',
      'yto': 'โทรอนโต',
      'scl': 'ซันติอาโก',
      'cdg': 'ปารีส',
      'fra': 'แฟรงก์เฟิร์ต',
      'del': 'เดลี',
      'bom': 'มุมไบ',
      'blr': 'บังกาลอร์',
      'tlv': 'เทลอาวีฟ',
      'itm': 'โอซากา',
      'nrt': 'โตเกียว',
      'mex': 'เม็กซิโกซิตี้',
      'waw': 'วอร์ซอ',
      'jnb': 'โจฮันเนสเบิร์ก',
      'icn': 'โซล',
      'mad': 'มาดริด',
      'sto': 'สตอกโฮล์ม',
      'lhr': 'ลอนดอน',
      'man': 'แมนเชสเตอร์',
      'ord': 'ชิคาโก',
      'dfw': 'ดัลลัส',
      'sea': 'ซีแอตเทิล',
      'sjc': 'ซานฟรานซิสโก',
      'mia': 'ไมแอมี',
      'hnl': 'โฮโนลูลู',
      'ewr': 'นิวยอร์ก',
      'atl': 'แอตแลนตา',
      'hkg': 'ฮ่องกง',
      'zrh': 'ซูริก',
      'gva': 'เจนีวา',
      'svo': 'มอสโก',
      'led': 'เซนต์ปีเตอร์สเบิร์ก',
      'hel': 'เฮลซิงกิ',
      'tpe': 'ไทเป',
      'dxb': 'ดูไบ',
      'kbp': 'เคียฟ',
      'ist': 'อิสตันบูล',
      'otp': 'บูคาเรสต์',
      'los': 'ลากอส',
      'pty': 'ปานามาซิตี',
      'kef': 'เรคยาวิก',
      'ber': 'เบอร์ลิน',
      'ala': 'อัลมาตี',
      'tbs': 'ทบิลิซี',
      'kul': 'กัวลาลัมเปอร์',
      'bkk': 'กรุงเทพฯ',
      'cgk': 'จาการ์ตา',
      'mnl': 'มะนิลา',
      'nbo': 'ไนโรบี',
      'mxp': 'มิลาน',
      'dub': 'ดับลิน',
      'lis': 'ลิสบอน',
      'lux': 'ลักเซมเบิร์ก',
      'eze': 'บัวโนสไอเรส',
      'akl': 'โอ๊กแลนด์',
      'yul': 'มอนทรีออล',
      'yvr': 'แวนคูเวอร์',
      'den': 'เดนเวอร์',
      'phx': 'ฟีนิกซ์',
      'iad': 'วอชิงตัน ดี.ซี.',
      'bos': 'บอสตัน',
      'edi': 'เอดินบะระ',
      'other': '$name',
    });
    return '$_temp0';
  }

  @override
  String get onevpnEnjoyingQuestion => 'คุณชอบ 1VPN ไหม';

  @override
  String get onevpnYes => 'ชอบ';

  @override
  String get onevpnNo => 'ไม่ชอบ';

  @override
  String get onevpnLocationLocked => 'ล็อกอยู่ เฉพาะพรีเมียม';

  @override
  String get onevpnManageSubscription => 'จัดการการสมัครสมาชิก';
}
