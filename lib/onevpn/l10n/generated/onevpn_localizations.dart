// ignore_for_file: text_direction_code_point_in_literal
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'onevpn_localizations_am.dart';
import 'onevpn_localizations_ar.dart';
import 'onevpn_localizations_az.dart';
import 'onevpn_localizations_bn.dart';
import 'onevpn_localizations_de.dart';
import 'onevpn_localizations_en.dart';
import 'onevpn_localizations_es.dart';
import 'onevpn_localizations_fa.dart';
import 'onevpn_localizations_fr.dart';
import 'onevpn_localizations_hi.dart';
import 'onevpn_localizations_id.dart';
import 'onevpn_localizations_it.dart';
import 'onevpn_localizations_ja.dart';
import 'onevpn_localizations_ko.dart';
import 'onevpn_localizations_my.dart';
import 'onevpn_localizations_pl.dart';
import 'onevpn_localizations_pt.dart';
import 'onevpn_localizations_ru.dart';
import 'onevpn_localizations_th.dart';
import 'onevpn_localizations_tk.dart';
import 'onevpn_localizations_tr.dart';
import 'onevpn_localizations_uk.dart';
import 'onevpn_localizations_ur.dart';
import 'onevpn_localizations_vi.dart';
import 'onevpn_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of OneVpnLocalizations
/// returned by `OneVpnLocalizations.of(context)`.
///
/// Applications need to include `OneVpnLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/onevpn_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: OneVpnLocalizations.localizationsDelegates,
///   supportedLocales: OneVpnLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the OneVpnLocalizations.supportedLocales
/// property.
abstract class OneVpnLocalizations {
  OneVpnLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static OneVpnLocalizations? of(BuildContext context) {
    return Localizations.of<OneVpnLocalizations>(context, OneVpnLocalizations);
  }

  static const LocalizationsDelegate<OneVpnLocalizations> delegate =
      _OneVpnLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('ar'),
    Locale('az'),
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('my'),
    Locale('pl'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tk'),
    Locale('tr'),
    Locale('uk'),
    Locale('ur'),
    Locale('vi'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// Support link: the FAQ section on the 1vpn site
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get onevpnFaq;

  /// Support link: the terms of service on the 1vpn site
  ///
  /// In en, this message translates to:
  /// **'Terms of service'**
  String get onevpnTermsOfService;

  /// Connect screen: tooltip for the hamburger that opens the menu
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get onevpnMenu;

  /// Menu item: opens the paywall to upgrade to premium
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get onevpnUpgrade;

  /// Connect screen: upgrade banner title for a non-premium account
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Premium'**
  String get onevpnUpgradeBannerTitle;

  /// Connect screen: upgrade banner subtitle for a non-premium account
  ///
  /// In en, this message translates to:
  /// **'No ads, all locations & faster speeds'**
  String get onevpnUpgradeBannerSubtitle;

  /// Menu item: opens the sign-in surface
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get onevpnLogIn;

  /// Menu item: signs the account out
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get onevpnLogOut;

  /// Menu: label for the account row when the email is unknown
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get onevpnAccount;

  /// Support page row: opens the 1vpn contact page in the browser
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get onevpnContactUs;

  /// Support page row: opens the hosted refund policy in the browser
  ///
  /// In en, this message translates to:
  /// **'Refund Policy'**
  String get onevpnRefundPolicy;

  /// Menu item and page title: help links, contact, and legal pages
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get onevpnSupport;

  /// Menu item and page title: the app language picker
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get onevpnLanguage;

  /// Language picker: the choice that follows the device language
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get onevpnLanguageSystem;

  /// Menu: the plan label for a non-premium account
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get onevpnPlanFree;

  /// Menu: the plan label for a premium account
  ///
  /// In en, this message translates to:
  /// **'Premium plan'**
  String get onevpnPlanPremium;

  /// Title of the location picker the connect screen opens
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get onevpnSelectLocation;

  /// Title of the direct-regions screen and its menu item
  ///
  /// In en, this message translates to:
  /// **'Direct Regions'**
  String get onevpnDirectRegions;

  /// Location picker: section header over the free-tier locations
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get onevpnFree;

  /// Location picker: second line of a free-tier location listed among premium locations
  ///
  /// In en, this message translates to:
  /// **'{country} · Free'**
  String onevpnFreeSubtitle(String country);

  /// Connect screen: the node Automatic selection resolved to while connected
  ///
  /// In en, this message translates to:
  /// **'Automatic · {node}'**
  String onevpnAutomaticResolved(String node);

  /// The Automatic selection's name: the connect screen location row, the picker's Automatic row, the reconnect confirm, and notices
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get onevpnAutomaticSelection;

  /// Connect screen status label under the red connect control when no connect failed. It must read differently from "Disconnected": a literal translation can collide with it.
  ///
  /// In en, this message translates to:
  /// **'No Connection'**
  String get onevpnStatusNoConnection;

  /// Connect screen status label under the red connect control after a connect fails. No line shows under it.
  ///
  /// In en, this message translates to:
  /// **'Connection Failed'**
  String get onevpnStatusConnectionFailed;

  /// Connect screen status label while a location or direct-regions change applies to the running connection. The connection stays up throughout.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get onevpnStatusUpdating;

  /// Connect screen status label while a connect measures the servers before it picks the fastest one. It replaces "Connecting…" during the measurement.
  ///
  /// In en, this message translates to:
  /// **'Measuring Servers…'**
  String get onevpnStatusMeasuring;

  /// The Automatic selection's second line: the connect screen location row while Automatic names no location, and the picker's Automatic row
  ///
  /// In en, this message translates to:
  /// **'Fastest available'**
  String get onevpnAutomaticSubtitle;

  /// Location picker: caption when a premium account's own locations failed to load and the free nodes stand in
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your locations.'**
  String get onevpnLocationsLoadFailed;

  /// Location picker: terminal state when no location can be shown
  ///
  /// In en, this message translates to:
  /// **'Locations are unavailable right now.'**
  String get onevpnLocationsUnavailable;

  /// Direct-regions picker: body of the explainer card
  ///
  /// In en, this message translates to:
  /// **'Some sites only work when you connect from the same country as the site. By selecting a region, sites from that region bypass the VPN.'**
  String get onevpnDirectRegionsCardBody;

  /// Notice after a connect, a location change, or a direct-regions change: the picked location could not be used, so 1VPN replaced the selection with Automatic
  ///
  /// In en, this message translates to:
  /// **'{location} is unavailable, 1VPN switched to Automatic.'**
  String onevpnSelectionReset(String location);

  /// Notice after a connect, a location change, or a direct-regions change: the picked location could not be used and has no catalogue name, so 1VPN replaced the selection with Automatic
  ///
  /// In en, this message translates to:
  /// **'The picked location is unavailable, 1VPN switched to Automatic.'**
  String get onevpnSelectionResetUnnamed;

  /// Notice after a location change while connected did not apply. The connection keeps running on the previous location.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t switch to {location}. You\'re still connected to your previous location.'**
  String onevpnReloadRolledBack(String location);

  /// Notice after a direct-regions change while connected did not apply. The connection keeps running with the previous settings.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t apply the change. You\'re still connected with your previous settings.'**
  String get onevpnReloadRolledBackSettings;

  /// Direct regions: the first row, which turns direct routing off and sends all traffic through the VPN. The default state
  ///
  /// In en, this message translates to:
  /// **'Off (Default)'**
  String get onevpnDirectRegionsOff;

  /// Direct-regions picker: subtext under the Off (Default) row
  ///
  /// In en, this message translates to:
  /// **'All traffic through the tunnel'**
  String get onevpnAllViaVpnSubtitle;

  /// Direct-regions picker: the fork label for CN, overriding the shared region-name table
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get onevpnRegionChina;

  /// First-connect explainer modal: title
  ///
  /// In en, this message translates to:
  /// **'Some Regions Work Better Direct'**
  String get onevpnFirstConnectTitle;

  /// First-connect explainer: the headline card body, what a full tunnel can break
  ///
  /// In en, this message translates to:
  /// **'In places like China, Russia and Iran, sending everything through the VPN can break local banking and payment apps.'**
  String get onevpnFirstConnectPointBreaks;

  /// First-connect explainer: the first point under the card, that a direct region routes outside the tunnel from the real IP
  ///
  /// In en, this message translates to:
  /// **'1VPN can route a region you choose directly, outside the tunnel, from your real IP.'**
  String get onevpnFirstConnectPointDirect;

  /// First-connect explainer: the second point under the card, what stays in the tunnel
  ///
  /// In en, this message translates to:
  /// **'Everything else stays protected. You can change this anytime.'**
  String get onevpnFirstConnectPointProtected;

  /// First-connect explainer modal: primary button opening the Direct-regions picker
  ///
  /// In en, this message translates to:
  /// **'Choose direct region'**
  String get onevpnFirstConnectChooseRegion;

  /// First-connect explainer modal: dismiss button, connect proceeds
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onevpnFirstConnectDismiss;

  /// Connect screen: the censorship warning dialog's message. It shows once, on the first connect of a free account whose app language is Russian, Persian or Chinese. The dismiss button is onevpnContinue
  ///
  /// In en, this message translates to:
  /// **'Some servers may be blocked in your region due to government restrictions. We are working to resolve this. Thank you for your understanding.'**
  String get onevpnCensorshipWarning;

  /// Android always-on VPN guidance: menu row and page title
  ///
  /// In en, this message translates to:
  /// **'Always-On VPN'**
  String get onevpnAlwaysOnTitle;

  /// Android always-on VPN guidance: headline card body. What closing the app keeps and what always-on reconnects
  ///
  /// In en, this message translates to:
  /// **'The tunnel stays up when you close the app. After a restart or an app update, Always-on VPN reconnects it automatically.'**
  String get onevpnAlwaysOnIntro;

  /// Android always-on VPN guidance: step 1. Names the Open VPN settings button
  ///
  /// In en, this message translates to:
  /// **'Tap Open VPN settings below.'**
  String get onevpnAlwaysOnStep1;

  /// Android always-on VPN guidance: step 2
  ///
  /// In en, this message translates to:
  /// **'Find 1VPN in the list. It appears after your first connect.'**
  String get onevpnAlwaysOnStep2;

  /// Android always-on VPN guidance: step 3
  ///
  /// In en, this message translates to:
  /// **'Tap the gear icon next to 1VPN.'**
  String get onevpnAlwaysOnStep3;

  /// Android always-on VPN guidance: step 4. Names the system switch as Android labels it
  ///
  /// In en, this message translates to:
  /// **'Turn on Always-on VPN.'**
  String get onevpnAlwaysOnStep4;

  /// Android always-on VPN guidance: button opening the system VPN settings screen
  ///
  /// In en, this message translates to:
  /// **'Open VPN settings'**
  String get onevpnAlwaysOnOpenSettings;

  /// Paywall screen header
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get onevpnPaywallTitle;

  /// Paywall benefit bullet
  ///
  /// In en, this message translates to:
  /// **'Unlock All Server Locations'**
  String get onevpnPaywallBenefitLocations;

  /// Paywall benefit bullet
  ///
  /// In en, this message translates to:
  /// **'No Advertisements'**
  String get onevpnPaywallBenefitNoAds;

  /// Paywall benefit bullet
  ///
  /// In en, this message translates to:
  /// **'Faster Server Speeds'**
  String get onevpnPaywallBenefitSpeed;

  /// Paywall benefit bullet
  ///
  /// In en, this message translates to:
  /// **'BitTorrent (P2P) Support'**
  String get onevpnPaywallBenefitP2p;

  /// Paywall benefit bullet
  ///
  /// In en, this message translates to:
  /// **'10-Day Money-Back Guarantee'**
  String get onevpnPaywallBenefitMoneyBack;

  /// Paywall yearly plan card title
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get onevpnPaywallPlanYearly;

  /// Paywall monthly plan card title
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get onevpnPaywallPlanMonthly;

  /// Paywall: discount pill on the yearly plan card, the yearly plan's saving over twelve monthly payments as a whole percent from 1 to 99, in the locale's digits
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String onevpnPaywallSaleYearly(String percent);

  /// Paywall: a plan's price per month, as an amount and an ISO currency code
  ///
  /// In en, this message translates to:
  /// **'{amount} {currency} / mo'**
  String onevpnPaywallPricePerMonth(String amount, String currency);

  /// Paywall plan card price placeholder shown when live pricing could not be loaded
  ///
  /// In en, this message translates to:
  /// **'Price unavailable'**
  String get onevpnPaywallPriceUnavailable;

  /// Paywall notice shown when the offering fails to load because the store was unreachable
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load plans. Check your connection.'**
  String get onevpnPaywallPlansLoadFailed;

  /// Paywall notice shown when the store is reachable but offers no plan, such as a configuration error
  ///
  /// In en, this message translates to:
  /// **'Plans aren\'t available right now. Please try again later.'**
  String get onevpnPaywallPlansUnavailable;

  /// Paywall primary call to action that starts the purchase
  ///
  /// In en, this message translates to:
  /// **'Get Premium'**
  String get onevpnGetPremium;

  /// Paywall dismissal that returns to the connect screen on the free tier
  ///
  /// In en, this message translates to:
  /// **'Continue Free'**
  String get onevpnContinueFree;

  /// Paywall action that retries loading plans after a load failure
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get onevpnPaywallRetry;

  /// Paywall error shown when a purchase fails for a reason other than cancellation
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get onevpnPaywallPurchaseError;

  /// Paywall error that stays until closed. Google Play refused the purchase because this Google account has an active or recently ended 1VPN subscription linked to another 1VPN account. The support placeholder is the tappable link onevpnPaywallSupportLink, which opens the 1VPN contact page.
  ///
  /// In en, this message translates to:
  /// **'This Google account has an active or recently ended 1VPN subscription linked to another 1VPN account. Log in to that account, or contact {support}.'**
  String onevpnPaywallPurchaseOtherAccount(String support);

  /// Paywall error that stays until closed. Google Play reports that this Google account already owns the 1VPN subscription. The support placeholder is the tappable link onevpnPaywallSupportLink, which opens the 1VPN contact page.
  ///
  /// In en, this message translates to:
  /// **'This Google account already has a 1VPN subscription. If Premium does not appear, contact {support}.'**
  String onevpnPaywallPurchaseOwned(String support);

  /// Paywall error that stays until closed. Google Play still holds an earlier purchase open.
  ///
  /// In en, this message translates to:
  /// **'Google Play did not finish your last purchase. Close any open Google Play screen and try again, or restart the app.'**
  String get onevpnPaywallPurchaseUnfinished;

  /// Paywall error link text: opens the 1VPN contact page. It fills the support placeholder of onevpnPaywallPurchaseOtherAccount and onevpnPaywallPurchaseOwned, as the object of the verb for contact. Write it in the form that slot takes, such as the instrumental case.
  ///
  /// In en, this message translates to:
  /// **'1VPN Support'**
  String get onevpnPaywallSupportLink;

  /// Auth screen title and submit label in sign-up mode
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get onevpnSignUp;

  /// Auth screen email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get onevpnAuthEmailLabel;

  /// Auth screen password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get onevpnAuthPasswordLabel;

  /// Auth screen two-factor token field label, revealed on login when the backend requires a second factor
  ///
  /// In en, this message translates to:
  /// **'2FA Token'**
  String get onevpnAuthTwoFactorLabel;

  /// Auth screen: link opening the hosted password reset page
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get onevpnAuthForgotPassword;

  /// Auth screen: the submit button label while the log-in or sign-up request is in flight
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get onevpnAuthSubmitting;

  /// Auth screen link that switches from log-in mode to sign-up mode
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get onevpnAuthCreateAccount;

  /// Sign-up form: link that switches to the log-in form
  ///
  /// In en, this message translates to:
  /// **'Have an account?'**
  String get onevpnAuthHaveAccount;

  /// Auth screen action offered when sign-up reports the email already has an account
  ///
  /// In en, this message translates to:
  /// **'Log in instead'**
  String get onevpnAuthLogInInstead;

  /// Auth screen client-side validation when a field is empty
  ///
  /// In en, this message translates to:
  /// **'Enter email and password'**
  String get onevpnAuthFieldsRequired;

  /// Auth screen client-side validation for a malformed email
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get onevpnAuthInvalidEmail;

  /// Auth screen login error. The backend cannot distinguish a wrong password from an unknown email, so both collapse to this.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials'**
  String get onevpnAuthInvalidCredentials;

  /// Auth screen: the login error for a wrong 2FA code. The backend sends code 1001 for the first prompt and for a wrong code. A 1001 while the code field is shown means the submitted code was wrong.
  ///
  /// In en, this message translates to:
  /// **'Invalid 2FA token'**
  String get onevpnAuthInvalidTwoFactor;

  /// Auth screen sign-up error shown alongside the log-in-instead action
  ///
  /// In en, this message translates to:
  /// **'That email already has an account'**
  String get onevpnAuthEmailInUse;

  /// Auth screen error when the backend rate-limits the request
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please try again shortly'**
  String get onevpnAuthRateLimited;

  /// Auth screen error when no account domain answered
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection and try again'**
  String get onevpnAuthUnreachable;

  /// Auth screen fallback error for an unexpected failure
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again'**
  String get onevpnAuthGenericError;

  /// Auth screen hint under the locked email field when the sign-up follows a purchase
  ///
  /// In en, this message translates to:
  /// **'Your purchase is linked to this email address.'**
  String get onevpnAuthEmailLockedHint;

  /// Paywall heading after the store confirmed a purchase that has no account to link to yet
  ///
  /// In en, this message translates to:
  /// **'Purchase Complete'**
  String get onevpnPaywallPurchasedTitle;

  /// Paywall body after the store confirmed a purchase that has no account to link to yet. {email} is the address the purchase was made against.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is linked to {email}. Create an account on that address to use it.'**
  String onevpnPaywallPurchasedBody(String email);

  /// Account row plan label while an optimistic premium grant is waiting for server confirmation
  ///
  /// In en, this message translates to:
  /// **'Premium · confirming purchase'**
  String get onevpnPlanPremiumPending;

  /// Snackbar shown when the user taps the confirming-purchase row to re-check entitlement
  ///
  /// In en, this message translates to:
  /// **'Checking your purchase status…'**
  String get onevpnPremiumRecheck;

  /// Startup error screen: the button that retries the service start
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get onevpnButtonRetry;

  /// Support page: the label of the version line
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get onevpnAppVersion;

  /// Support link: the privacy policy on the 1vpn site
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get onevpnPrivacyPolicy;

  /// Connect screen: the accessibility label of the connect control. Failure notice: the action in a connect that timed out
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get onevpnConnect;

  /// Connect screen status label while the tunnel is down
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get onevpnDisconnected;

  /// Connect screen status label while the tunnel starts
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get onevpnConnecting;

  /// Connect screen status label while the tunnel is up
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get onevpnConnected;

  /// Connect screen status label while the tunnel stops
  ///
  /// In en, this message translates to:
  /// **'Disconnecting…'**
  String get onevpnDisconnecting;

  /// Connect screen: the detail line under "No Connection". Failure notice: the title of a failed connect
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get onevpnConnectionFailed;

  /// A location that cannot be used right now: the picker row subtitle and the connect screen location row. Connection failure notice: the tunnel status cannot be read
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable'**
  String get onevpnTemporarilyUnavailable;

  /// Location picker: the button that retries loading the locations
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get onevpnRetry;

  /// Reconnect confirm dialog: title
  ///
  /// In en, this message translates to:
  /// **'Apply this change?'**
  String get onevpnApplyChange;

  /// Reconnect confirm dialog: body
  ///
  /// In en, this message translates to:
  /// **'The VPN will briefly disconnect and reconnect. This usually takes only a few seconds.'**
  String get onevpnReconnectNotice;

  /// Reconnect confirm dialog: the line that names what the tunnel uses after the change
  ///
  /// In en, this message translates to:
  /// **'Will use: {name}'**
  String onevpnWillUseName(String name);

  /// Reconnect confirm dialog: the confirm button
  ///
  /// In en, this message translates to:
  /// **'Apply and reconnect'**
  String get onevpnApplyAndReconnect;

  /// Reconnect confirm dialog: the cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get onevpnCancel;

  /// Purchase email sheet: the button that submits the email. Censorship warning dialog: the dismiss button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onevpnContinue;

  /// Connect screen: the line at the foot of the screen while the account API answers on a backup domain. The whole line is a link that opens the backup domain. It shows whether or not the VPN is connected.
  ///
  /// In en, this message translates to:
  /// **'Main domain is unreachable. Using backup: {domain}'**
  String onevpnBackupDomainBlocked(String domain);

  /// Failure notice: the result word that ends an operation title, as in "Xray · failed". Also the whole title of an uncategorized failure
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get onevpnResultFailed;

  /// Failure notice: the operation title of a network failure, before "· failed"
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get onevpnDownload;

  /// Failure notice: the title of a permission failure
  ///
  /// In en, this message translates to:
  /// **'Permission not granted'**
  String get onevpnPermissionNotGranted;

  /// Failure notice: an action joined with its result, as in "Disconnect failed"
  ///
  /// In en, this message translates to:
  /// **'{action} {result}'**
  String onevpnActionResult(String action, String result);

  /// Failure notice: the action in a failed or timed-out disconnect
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get onevpnDisconnect;

  /// Failure notice: the result of a connect or disconnect that timed out, as in "Connect · Timeout"
  ///
  /// In en, this message translates to:
  /// **'Timeout'**
  String get onevpnTimeout;

  /// Connection failure notice: no entry server can be used
  ///
  /// In en, this message translates to:
  /// **'No available entry servers'**
  String get onevpnNoAvailableEntries;

  /// Connection failure notice: the hint after "No available entry servers"
  ///
  /// In en, this message translates to:
  /// **'Add servers'**
  String get onevpnAddServers;

  /// Connection failure notice: too few healthy servers for the route. A count in brackets can follow
  ///
  /// In en, this message translates to:
  /// **'Not enough available servers'**
  String get onevpnNotEnoughServers;

  /// Connection failure notice: names the final exit server before "· No available entry servers"
  ///
  /// In en, this message translates to:
  /// **'VPN final exit'**
  String get onevpnVpnFinalExit;

  /// Connection failure notice: the final exit and the entry server are the same server
  ///
  /// In en, this message translates to:
  /// **'The final exit cannot also be the entry server'**
  String get onevpnFinalExitEntryConflict;

  /// Connection failure notice: the connection settings name no valid route
  ///
  /// In en, this message translates to:
  /// **'Choose one named route'**
  String get onevpnChooseNamedRoute;

  /// Connection failure notice: Android needs the local network permission
  ///
  /// In en, this message translates to:
  /// **'Allow access to devices and services on the local network.'**
  String get onevpnAllowLocalNetworkHint;

  /// Connection failure notice: macOS needs the system extension approved
  ///
  /// In en, this message translates to:
  /// **'System approval required'**
  String get onevpnSystemApprovalRequired;

  /// Connection failure notice: the system VPN permission is missing
  ///
  /// In en, this message translates to:
  /// **'VPN permission is required. Please retry to continue.'**
  String get onevpnVpnPermissionRequired;

  /// Connection failure notice: a desktop connect needs an outbound network interface
  ///
  /// In en, this message translates to:
  /// **'Choose the interface used to access the network. Required on Windows / Linux only.'**
  String get onevpnChooseInterfaceNotice;

  /// Direct-regions picker: the region row title for an ISO 3166 code. CN takes onevpnRegionChina instead
  ///
  /// In en, this message translates to:
  /// **'{code, select, AD {Andorra} AE {United Arab Emirates} AF {Afghanistan} AG {Antigua & Barbuda} AI {Anguilla} AL {Albania} AM {Armenia} AO {Angola} AQ {Antarctica} AR {Argentina} AS {American Samoa} AT {Austria} AU {Australia} AW {Aruba} AX {Åland Islands} AZ {Azerbaijan} BA {Bosnia & Herzegovina} BB {Barbados} BD {Bangladesh} BE {Belgium} BF {Burkina Faso} BG {Bulgaria} BH {Bahrain} BI {Burundi} BJ {Benin} BL {St. Barthélemy} BM {Bermuda} BN {Brunei} BO {Bolivia} BQ {Caribbean Netherlands} BR {Brazil} BS {Bahamas} BT {Bhutan} BV {Bouvet Island} BW {Botswana} BY {Belarus} BZ {Belize} CA {Canada} CC {Cocos (Keeling) Islands} CD {Congo - Kinshasa} CF {Central African Republic} CG {Congo - Brazzaville} CH {Switzerland} CI {Côte d’Ivoire} CK {Cook Islands} CL {Chile} CM {Cameroon} CN {Mainland China} CO {Colombia} CR {Costa Rica} CU {Cuba} CV {Cape Verde} CW {Curaçao} CX {Christmas Island} CY {Cyprus} CZ {Czechia} DE {Germany} DJ {Djibouti} DK {Denmark} DM {Dominica} DO {Dominican Republic} DZ {Algeria} EC {Ecuador} EE {Estonia} EG {Egypt} EH {Western Sahara} ER {Eritrea} ES {Spain} ET {Ethiopia} FI {Finland} FJ {Fiji} FK {Falkland Islands} FM {Micronesia} FO {Faroe Islands} FR {France} GA {Gabon} GB {United Kingdom} GD {Grenada} GE {Georgia} GF {French Guiana} GG {Guernsey} GH {Ghana} GI {Gibraltar} GL {Greenland} GM {Gambia} GN {Guinea} GP {Guadeloupe} GQ {Equatorial Guinea} GR {Greece} GS {So. Georgia & So. Sandwich Isl.} GT {Guatemala} GU {Guam} GW {Guinea-Bissau} GY {Guyana} HK {Hong Kong} HM {Heard & McDonald Islands} HN {Honduras} HR {Croatia} HT {Haiti} HU {Hungary} ID {Indonesia} IE {Ireland} IL {Israel} IM {Isle of Man} IN {India} IO {Chagos Archipelago} IQ {Iraq} IR {Iran} IS {Iceland} IT {Italy} JE {Jersey} JM {Jamaica} JO {Jordan} JP {Japan} KE {Kenya} KG {Kyrgyzstan} KH {Cambodia} KI {Kiribati} KM {Comoros} KN {St. Kitts & Nevis} KP {North Korea} KR {South Korea} KW {Kuwait} KY {Cayman Islands} KZ {Kazakhstan} LA {Laos} LB {Lebanon} LC {St. Lucia} LI {Liechtenstein} LK {Sri Lanka} LR {Liberia} LS {Lesotho} LT {Lithuania} LU {Luxembourg} LV {Latvia} LY {Libya} MA {Morocco} MC {Monaco} MD {Moldova} ME {Montenegro} MF {St. Martin} MG {Madagascar} MH {Marshall Islands} MK {North Macedonia} ML {Mali} MM {Myanmar (Burma)} MN {Mongolia} MO {Macao} MP {Northern Mariana Islands} MQ {Martinique} MR {Mauritania} MS {Montserrat} MT {Malta} MU {Mauritius} MV {Maldives} MW {Malawi} MX {Mexico} MY {Malaysia} MZ {Mozambique} NA {Namibia} NC {New Caledonia} NE {Niger} NF {Norfolk Island} NG {Nigeria} NI {Nicaragua} NL {Netherlands} NO {Norway} NP {Nepal} NR {Nauru} NU {Niue} NZ {New Zealand} OM {Oman} PA {Panama} PE {Peru} PF {French Polynesia} PG {Papua New Guinea} PH {Philippines} PK {Pakistan} PL {Poland} PM {St. Pierre & Miquelon} PN {Pitcairn Islands} PR {Puerto Rico} PS {Palestinian Territories} PT {Portugal} PW {Palau} PY {Paraguay} QA {Qatar} RE {Réunion} RO {Romania} RS {Serbia} RU {Russia} RW {Rwanda} SA {Saudi Arabia} SB {Solomon Islands} SC {Seychelles} SD {Sudan} SE {Sweden} SG {Singapore} SH {St. Helena} SI {Slovenia} SJ {Svalbard & Jan Mayen} SK {Slovakia} SL {Sierra Leone} SM {San Marino} SN {Senegal} SO {Somalia} SR {Suriname} SS {South Sudan} ST {São Tomé & Príncipe} SV {El Salvador} SX {Sint Maarten} SY {Syria} SZ {Eswatini} TC {Turks & Caicos Islands} TD {Chad} TF {French Southern Territories} TG {Togo} TH {Thailand} TJ {Tajikistan} TK {Tokelau} TL {Timor-Leste} TM {Turkmenistan} TN {Tunisia} TO {Tonga} TR {Turkey} TT {Trinidad & Tobago} TV {Tuvalu} TW {Taiwan} TZ {Tanzania} UA {Ukraine} UG {Uganda} UM {U.S. Outlying Islands} US {United States} UY {Uruguay} UZ {Uzbekistan} VA {Vatican City} VC {St. Vincent & Grenadines} VE {Venezuela} VG {British Virgin Islands} VI {U.S. Virgin Islands} VN {Vietnam} VU {Vanuatu} WF {Wallis & Futuna} WS {Samoa} XK {Kosovo} YE {Yemen} YT {Mayotte} ZA {South Africa} ZM {Zambia} ZW {Zimbabwe} other {{code}}}'**
  String onevpnCountryRegionName(String code);

  /// Support page row: opens the ads consent platform's privacy options form. Shown only while that platform requires the entry
  ///
  /// In en, this message translates to:
  /// **'Privacy Choices'**
  String get onevpnPrivacyChoices;

  /// Picker and connect rows: the city name for a location display code. A code with no case returns the API name.
  ///
  /// In en, this message translates to:
  /// **'{code, select, ams {Amsterdam} sgp {Singapore} lax {Los Angeles} mel {Melbourne} syd {Sydney} sao {Sao Paulo} yto {Toronto} scl {Santiago} cdg {Paris} fra {Frankfurt} del {Delhi} bom {Mumbai} blr {Bangalore} tlv {Tel Aviv} itm {Osaka} nrt {Tokyo} mex {Mexico City} waw {Warsaw} jnb {Johannesburg} icn {Seoul} mad {Madrid} sto {Stockholm} lhr {London} man {Manchester} ord {Chicago} dfw {Dallas} sea {Seattle} sjc {San Francisco} mia {Miami} hnl {Honolulu} ewr {New York} atl {Atlanta} hkg {Hong Kong} zrh {Zurich} gva {Geneva} svo {Moscow} led {Saint Petersburg} hel {Helsinki} tpe {Taipei} dxb {Dubai} kbp {Kyiv} ist {Istanbul} otp {Bucharest} los {Lagos} pty {Panama City} kef {Reykjavik} ber {Berlin} ala {Almaty} tbs {Tbilisi} kul {Kuala Lumpur} bkk {Bangkok} cgk {Jakarta} mnl {Manila} nbo {Nairobi} mxp {Milan} dub {Dublin} lis {Lisbon} lux {Luxembourg} eze {Buenos Aires} akl {Auckland} yul {Montreal} yvr {Vancouver} den {Denver} phx {Phoenix} iad {Washington DC} bos {Boston} edi {Edinburgh} other {{name}}}'**
  String onevpnCityName(String code, String name);

  /// Rating dialog after a user disconnect: the question over the Yes and No buttons
  ///
  /// In en, this message translates to:
  /// **'Are You Enjoying 1VPN?'**
  String get onevpnEnjoyingQuestion;

  /// Rating dialog: the button that answers the user is enjoying the app and opens the store review
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get onevpnYes;

  /// Rating dialog: the button that answers the user is not enjoying the app
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get onevpnNo;

  /// Location picker: the screen-reader label of the lock on a Premium location row that a free account cannot select
  ///
  /// In en, this message translates to:
  /// **'Locked, Premium only'**
  String get onevpnLocationLocked;

  /// Support page: the row that opens the Google Play subscriptions page for this app, where a subscription is managed or cancelled
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get onevpnManageSubscription;
}

class _OneVpnLocalizationsDelegate
    extends LocalizationsDelegate<OneVpnLocalizations> {
  const _OneVpnLocalizationsDelegate();

  @override
  Future<OneVpnLocalizations> load(Locale locale) {
    return SynchronousFuture<OneVpnLocalizations>(
      lookupOneVpnLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'am',
    'ar',
    'az',
    'bn',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'hi',
    'id',
    'it',
    'ja',
    'ko',
    'my',
    'pl',
    'pt',
    'ru',
    'th',
    'tk',
    'tr',
    'uk',
    'ur',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_OneVpnLocalizationsDelegate old) => false;
}

OneVpnLocalizations lookupOneVpnLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return OneVpnLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return OneVpnLocalizationsAm();
    case 'ar':
      return OneVpnLocalizationsAr();
    case 'az':
      return OneVpnLocalizationsAz();
    case 'bn':
      return OneVpnLocalizationsBn();
    case 'de':
      return OneVpnLocalizationsDe();
    case 'en':
      return OneVpnLocalizationsEn();
    case 'es':
      return OneVpnLocalizationsEs();
    case 'fa':
      return OneVpnLocalizationsFa();
    case 'fr':
      return OneVpnLocalizationsFr();
    case 'hi':
      return OneVpnLocalizationsHi();
    case 'id':
      return OneVpnLocalizationsId();
    case 'it':
      return OneVpnLocalizationsIt();
    case 'ja':
      return OneVpnLocalizationsJa();
    case 'ko':
      return OneVpnLocalizationsKo();
    case 'my':
      return OneVpnLocalizationsMy();
    case 'pl':
      return OneVpnLocalizationsPl();
    case 'pt':
      return OneVpnLocalizationsPt();
    case 'ru':
      return OneVpnLocalizationsRu();
    case 'th':
      return OneVpnLocalizationsTh();
    case 'tk':
      return OneVpnLocalizationsTk();
    case 'tr':
      return OneVpnLocalizationsTr();
    case 'uk':
      return OneVpnLocalizationsUk();
    case 'ur':
      return OneVpnLocalizationsUr();
    case 'vi':
      return OneVpnLocalizationsVi();
    case 'zh':
      return OneVpnLocalizationsZh();
  }

  throw FlutterError(
    'OneVpnLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
