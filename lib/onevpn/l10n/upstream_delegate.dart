import 'package:flutter/widgets.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/service/settings/language/locale.dart';

/// Loads upstream strings for every locale, each fork locale included.
///
/// A locale the upstream bundle supports loads its upstream strings. Any
/// other locale loads the upstream English strings. An upstream lookup
/// therefore never returns null.
class OneVpnUpstreamLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const OneVpnUpstreamLocalizationsDelegate();

  static const _upstream = AppLocalizations.delegate;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) => _upstream.load(
    _upstream.isSupported(locale) ? locale : const Locale('en'),
  );

  @override
  bool shouldReload(OneVpnUpstreamLocalizationsDelegate old) => false;
}

/// Loads a Material, Cupertino or Widgets localization for every locale.
///
/// A locale [delegate] supports loads its own strings. Any other locale,
/// such as Turkmen, loads the English strings. A Material, Cupertino or
/// Widgets lookup therefore never fails on a fork locale. [type] is the
/// type of [delegate].
class OneVpnEnglishFallbackDelegate extends LocalizationsDelegate<dynamic> {
  const OneVpnEnglishFallbackDelegate(this.delegate);

  /// The wrapped Material, Cupertino or Widgets delegate.
  final LocalizationsDelegate<dynamic> delegate;

  @override
  Type get type => delegate.type;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<dynamic> load(Locale locale) =>
      delegate.load(delegate.isSupported(locale) ? locale : const Locale('en'));

  @override
  bool shouldReload(OneVpnEnglishFallbackDelegate old) =>
      old.delegate != delegate;

  @override
  bool operator ==(Object other) =>
      other is OneVpnEnglishFallbackDelegate && other.delegate == delegate;

  @override
  int get hashCode => delegate.hashCode;
}

/// The app's localization delegates. The fork delegate leads. The upstream
/// list follows, with [OneVpnUpstreamLocalizationsDelegate] in place of the
/// upstream delegate. Each Material, Cupertino and Widgets delegate sits in
/// an [OneVpnEnglishFallbackDelegate].
final List<LocalizationsDelegate<dynamic>> kOneVpnLocalizationsDelegates =
    List.unmodifiable([
      OneVpnLocalizations.delegate,
      for (final delegate in AppLocalePolicy.localizationsDelegates)
        delegate == AppLocalizations.delegate
            ? const OneVpnUpstreamLocalizationsDelegate()
            : OneVpnEnglishFallbackDelegate(delegate),
    ]);
