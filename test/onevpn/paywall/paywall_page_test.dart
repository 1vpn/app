// Tests the paywall. It covers the benefits and plan cards, the live-price
// binding, and the fallback when offerings fail to load. The discount pill
// writes the saving in the digits of the per-month price. It covers the Get
// Premium and Continue Free wiring against the purchase fake. It covers the
// join-key capture and the purchased-but-unlinked state. It also covers the
// error surface for a failure other than cancel, and no clipping at 320dp.
// A failure names its cause, and a named cause lasts until closed. The two
// account causes link 1VPN Support in every locale, right to left in fa and
// ar. A failure notice closes when the paywall leaves the screen. A purchase
// with no result frees the buttons at the deadline. The first return after a
// pause during a purchase asks for the store sheet back. A later success
// still hands off, and a later failure shows nothing.
//
// At 360x800 the page stacks in one column capped at 480dp. At 800x360 the
// title and the benefits fill the start pane. The plan cards and the footer
// scroll together in the end pane, 24dp apart. The purchase error anchors to
// the end pane.

import 'dart:async';

import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:onexray/l10n/localizations/app_localizations.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/feedback/notice.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations.dart';
import 'package:onexray/onevpn/l10n/generated/onevpn_localizations_en.dart';
import 'package:onexray/onevpn/l10n/locales.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:onexray/onevpn/paywall/paywall_page.dart';
import 'package:onexray/onevpn/purchase/fake_purchase_service.dart';
import 'package:onexray/onevpn/purchase/offerings_cache.dart';
import 'package:onexray/onevpn/purchase/purchase_service.dart';
import 'package:onexray/onevpn/shell/layout.dart';
import 'package:onexray/onevpn/shell/links.dart';
import 'package:onexray/onevpn/theme/card.dart';
import 'package:onexray/pages/theme/theme.dart';

import '../support/ink.dart';
import '../support/localizations.dart';
import '../support/viewports.dart';

const _buyer = 'buyer@example.invalid';

/// A purchase service whose purchase answers only when the test completes
/// [result].
class _HeldPurchaseService extends OneVpnFakePurchaseService {
  final result = Completer<OneVpnPurchaseOutcome>();

  @override
  Future<OneVpnPurchaseOutcome> purchase({
    required OneVpnPurchasePackage package,
    required String email,
  }) {
    calls.add('purchase');
    return result.future;
  }
}

/// A purchase service whose purchases each answer only when the test
/// completes their entry in [results], in tap order.
class _QueuedPurchaseService extends OneVpnFakePurchaseService {
  final results = <Completer<OneVpnPurchaseOutcome>>[];

  @override
  Future<OneVpnPurchaseOutcome> purchase({
    required OneVpnPurchasePackage package,
    required String email,
  }) {
    calls.add('purchase');
    final result = Completer<OneVpnPurchaseOutcome>();
    results.add(result);
    return result.future;
  }
}

ValueNotifier<OneVpnAccountState> _signedIn(String email) =>
    ValueNotifier<OneVpnAccountState>(
      OneVpnAccountSignedIn(
        OneVpnSession(
          sessionAuthToken: 'token',
          username: 'someone',
          email: email,
          isPremium: false,
          credentials: const OneVpnCredentials(
            uuid: 'u',
            publicKey: 'p',
            shortId: 's',
          ),
          locations: const <OneVpnApiLocation>[],
        ),
      ),
    );

Future<void> _pump(
  WidgetTester tester,
  OneVpnPaywallPage page, {
  Size size = kPortraitViewport,
  Locale locale = const Locale('en'),
}) async {
  await setViewport(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      localizationsDelegates: oneVpnLocalizationsDelegates,
      supportedLocales: [for (final l in kOneVpnLocales) l.locale],
      home: page,
    ),
  );
  await tester.pumpAndSettle();
}

/// Any English yearly discount pill, whatever its percent.
final _anyPill = find.textContaining(RegExp(r'^Save -?\d+%$'));

void main() {
  final l = OneVpnLocalizationsEn();

  testWidgets('renders the five benefits and both plan cards', (tester) async {
    await _pump(
      tester,
      OneVpnPaywallPage(
        service: OneVpnFakePurchaseService(),
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
      ),
    );

    expect(find.text(l.onevpnPaywallBenefitLocations), findsOneWidget);
    expect(find.text(l.onevpnPaywallBenefitNoAds), findsOneWidget);
    expect(find.text(l.onevpnPaywallBenefitSpeed), findsOneWidget);
    expect(find.text(l.onevpnPaywallBenefitP2p), findsOneWidget);
    expect(find.text(l.onevpnPaywallBenefitMoneyBack), findsOneWidget);
    expect(find.text(l.onevpnPaywallPlanYearly), findsOneWidget);
    expect(find.text(l.onevpnPaywallPlanMonthly), findsOneWidget);
    expect(find.text(l.onevpnGetPremium), findsOneWidget);
    expect(find.text(l.onevpnContinueFree), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('ar'), Locale('am')]) {
    testWidgets('under ${locale.languageCode}, the no-ads benefit sits second '
        'at 360x800', (tester) async {
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: OneVpnFakePurchaseService(),
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        ),
        locale: locale,
      );

      final local = lookupOneVpnLocalizations(locale);
      expect(tester.takeException(), isNull);
      final noAds = find.text(local.onevpnPaywallBenefitNoAds);
      expect(noAds, findsOneWidget);
      final locations = tester.getRect(
        find.text(local.onevpnPaywallBenefitLocations),
      );
      final speed = tester.getRect(find.text(local.onevpnPaywallBenefitSpeed));
      expect(locations.bottom, lessThan(tester.getRect(noAds).top));
      expect(tester.getRect(noAds).bottom, lessThan(speed.top));
    });
  }

  for (final size in [kPortraitViewport, const Size(768, 1024)]) {
    testWidgets('at ${size.width.toInt()}x${size.height.toInt()} the title '
        'sits above the benefits', (tester) async {
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: OneVpnFakePurchaseService(),
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        ),
        size: size,
      );

      final title = tester.getRect(find.text(l.onevpnPaywallTitle));
      final benefit = tester.getRect(
        find.text(l.onevpnPaywallBenefitLocations),
      );
      expect(title.bottom, lessThan(benefit.top));
    });
  }

  testWidgets('the plan cards and buttons keep the right ink', (tester) async {
    await _pump(
      tester,
      OneVpnPaywallPage(
        service: OneVpnFakePurchaseService(),
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
      ),
    );

    expectQuietInk(tester, [
      find.text(l.onevpnPaywallPlanYearly),
      find.text(l.onevpnPaywallPlanMonthly),
      find.text(l.onevpnContinueFree),
    ]);
    expectSolidInk(tester, [find.text(l.onevpnGetPremium)]);
  });

  testWidgets('binds live prices from the offering', (tester) async {
    final service = OneVpnFakePurchaseService(
      offerings: const OneVpnOfferings(
        yearly: OneVpnPurchasePackage(
          identifier: 'y',
          term: OneVpnPurchaseTerm.yearly,
          priceString: '€12.34',
        ),
        monthly: OneVpnPurchasePackage(
          identifier: 'm',
          term: OneVpnPurchaseTerm.monthly,
          priceString: '€1.99',
        ),
      ),
    );
    await _pump(
      tester,
      OneVpnPaywallPage(
        service: service,
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
      ),
    );

    expect(find.text('€12.34'), findsOneWidget);
    expect(find.text('€1.99'), findsOneWidget);
    // With no numeric price the card shows the store text and no sale.
    expect(_anyPill, findsNothing);
  });

  group('the offerings cache', () {
    const cachedYearly = OneVpnPurchasePackage(
      identifier: 'y',
      term: OneVpnPurchaseTerm.yearly,
      priceString: r'US$23.88',
      price: 23.88,
      currencyCode: 'USD',
    );
    const cachedMonthly = OneVpnPurchasePackage(
      identifier: 'm',
      term: OneVpnPurchaseTerm.monthly,
      priceString: r'US$4.99',
      price: 4.99,
      currencyCode: 'USD',
    );

    testWidgets('a warmed cache shows the prices on the first frame', (
      tester,
    ) async {
      final service = OneVpnFakePurchaseService(
        offerings: const OneVpnOfferings(
          yearly: cachedYearly,
          monthly: cachedMonthly,
        ),
      );
      await OneVpnOfferingsCache.warm(service);
      await setViewport(tester, kPortraitViewport);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: oneVpnLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OneVpnPaywallPage(
            service: service,
            accountState: ValueNotifier(const OneVpnAccountSignedOut()),
          ),
        ),
      );

      // One pump: no wait for the load.
      expect(
        find.text(l.onevpnPaywallPricePerMonth('1.99', 'USD')),
        findsOneWidget,
      );
      expect(find.text('…'), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('a cold cache shows the loading mark until the load ends', (
      tester,
    ) async {
      final service = OneVpnFakePurchaseService(
        offerings: const OneVpnOfferings(
          yearly: cachedYearly,
          monthly: cachedMonthly,
        ),
      );
      await setViewport(tester, kPortraitViewport);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: oneVpnLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OneVpnPaywallPage(
            service: service,
            accountState: ValueNotifier(const OneVpnAccountSignedOut()),
          ),
        ),
      );

      expect(find.text('…'), findsWidgets);
      await tester.pumpAndSettle();
      expect(
        find.text(l.onevpnPaywallPricePerMonth('1.99', 'USD')),
        findsOneWidget,
      );
    });
  });

  group('the sale treatment', () {
    OneVpnFakePurchaseService saleService() => OneVpnFakePurchaseService(
      offerings: const OneVpnOfferings(
        yearly: OneVpnPurchasePackage(
          identifier: 'y',
          term: OneVpnPurchaseTerm.yearly,
          priceString: r'US$23.88',
          price: 23.88,
          currencyCode: 'USD',
        ),
        monthly: OneVpnPurchasePackage(
          identifier: 'm',
          term: OneVpnPurchaseTerm.monthly,
          priceString: r'US$4.99',
          price: 4.99,
          currencyCode: 'USD',
        ),
      ),
    );

    for (final size in [kPortraitViewport, kLandscapeViewport]) {
      testWidgets('at ${size.width.toInt()}x${size.height.toInt()} each card '
          'the yearly card reads its per-month price under a centered discount '
          'tab, and the monthly card reads its price alone', (tester) async {
        await _pump(
          tester,
          OneVpnPaywallPage(
            service: saleService(),
            accountState: ValueNotifier(const OneVpnAccountSignedOut()),
          ),
          size: size,
        );
        expect(tester.takeException(), isNull);

        final yearly = l.onevpnPaywallPricePerMonth('1.99', 'USD');
        final monthly = l.onevpnPaywallPricePerMonth('4.99', 'USD');
        expect(find.text(yearly), findsOneWidget);
        expect(find.text(monthly), findsOneWidget);
        expect(find.text(r'US$23.88'), findsNothing);

        expect(find.textContaining('33%'), findsNothing);

        // The tab straddles the top edge of its card, centered on it both
        // ways.
        for (final (pill, title) in [
          (l.onevpnPaywallSaleYearly('60'), l.onevpnPaywallPlanYearly),
        ]) {
          final card = tester.getRect(
            find
                .ancestor(of: find.text(title), matching: find.byType(Material))
                .first,
          );
          final tab = tester.getRect(find.text(pill));
          expect(
            tab.center.dy,
            moreOrLessEquals(card.top, epsilon: 0.5),
            reason: pill,
          );
          expect(
            tab.center.dx,
            moreOrLessEquals(card.center.dx, epsilon: 0.5),
            reason: pill,
          );
          // The price line sits under the name, on its start edge.
          final name = tester.getRect(find.text(title));
          final priceLine = tester.getRect(find.text(yearly));
          expect(
            priceLine.top,
            greaterThanOrEqualTo(name.bottom),
            reason: title,
          );
          expect(
            priceLine.left,
            moreOrLessEquals(name.left, epsilon: 0.5),
            reason: title,
          );
        }
      });
    }

    for (final scale in [1.5, 2.0]) {
      testWidgets('at ${scale}x text the discount tab still straddles the '
          'top edge of its card', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearAllTestValues);
        await _pump(
          tester,
          OneVpnPaywallPage(
            service: saleService(),
            accountState: ValueNotifier(const OneVpnAccountSignedOut()),
          ),
        );
        expect(tester.takeException(), isNull);

        final card = tester.getRect(
          find
              .ancestor(
                of: find.text(l.onevpnPaywallPlanYearly),
                matching: find.byType(Material),
              )
              .first,
        );
        final tab = tester.getRect(find.text(l.onevpnPaywallSaleYearly('60')));
        expect(tab.center.dy, moreOrLessEquals(card.top, epsilon: 0.5));
      });
    }

    testWidgets('the yearly card holds still whether or not the tab shows', (
      tester,
    ) async {
      Future<double> cardTop(OneVpnFakePurchaseService service) async {
        await tester.pumpWidget(const SizedBox());
        await _pump(
          tester,
          OneVpnPaywallPage(
            service: service,
            accountState: ValueNotifier(const OneVpnAccountSignedOut()),
          ),
        );
        return tester
            .getRect(
              find
                  .ancestor(
                    of: find.text(l.onevpnPaywallPlanYearly),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .top;
      }

      final withTab = await cardTop(saleService());
      expect(find.text(l.onevpnPaywallSaleYearly('60')), findsOneWidget);
      // With no numeric price the tab is hidden and its room stays.
      final withoutTab = await cardTop(
        OneVpnFakePurchaseService(
          offerings: const OneVpnOfferings(
            yearly: OneVpnPurchasePackage(
              identifier: 'y',
              term: OneVpnPurchaseTerm.yearly,
              priceString: '€12.34',
            ),
            monthly: OneVpnPurchasePackage(
              identifier: 'm',
              term: OneVpnPurchaseTerm.monthly,
              priceString: '€1.99',
            ),
          ),
        ),
      );
      expect(_anyPill, findsNothing);
      expect(withoutTab, moreOrLessEquals(withTab, epsilon: 0.5));
    });

    testWidgets('a tap on either half of the discount tab selects its card', (
      tester,
    ) async {
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: saleService(),
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        ),
      );
      expect(find.byKey(OneVpnPaywallPage.selectedMarkKey), findsOneWidget);

      void expectSelected(String title, String reason) {
        final mark = tester.getRect(
          find.byKey(OneVpnPaywallPage.selectedMarkKey),
        );
        final row = tester.getRect(find.text(title));
        expect(
          (mark.center.dy - row.center.dy).abs(),
          lessThan(24),
          reason: reason,
        );
      }

      // Anti-vacuity: Yearly starts selected.
      expectSelected(l.onevpnPaywallPlanYearly, 'at start');
      // The top edge of the tab rises above its card. The lower quarter lies
      // over the card. Each tap follows a tap on the Monthly card and moves
      // the selection back to Yearly.
      for (final (edge, point) in [
        ('top edge', (Rect tab) => tab.topCenter + const Offset(0, 1)),
        ('lower quarter', (Rect tab) => tab.center + Offset(0, tab.height / 4)),
      ]) {
        await tester.tap(find.text(l.onevpnPaywallPlanMonthly));
        await tester.pumpAndSettle();
        expectSelected(l.onevpnPaywallPlanMonthly, 'monthly before $edge');
        final pill = l.onevpnPaywallSaleYearly('60');
        await tester.tapAt(point(tester.getRect(find.text(pill))));
        await tester.pumpAndSettle();
        expectSelected(l.onevpnPaywallPlanYearly, '$pill at its $edge');
      }
    });
  });

  group('the computed saving', () {
    OneVpnFakePurchaseService priced(double yearly, double monthly) =>
        OneVpnFakePurchaseService(
          offerings: OneVpnOfferings(
            yearly: OneVpnPurchasePackage(
              identifier: 'y',
              term: OneVpnPurchaseTerm.yearly,
              priceString: 'US\$$yearly',
              price: yearly,
              currencyCode: 'USD',
            ),
            monthly: OneVpnPurchasePackage(
              identifier: 'm',
              term: OneVpnPurchaseTerm.monthly,
              priceString: 'US\$$monthly',
              price: monthly,
              currencyCode: 'USD',
            ),
          ),
        );

    testWidgets('the pill states the saving at 1.99 and 4.99 a month', (
      tester,
    ) async {
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: priced(23.88, 4.99),
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        ),
      );
      expect(
        find.text(l.onevpnPaywallPricePerMonth('1.99', 'USD')),
        findsOneWidget,
      );
      expect(find.text('Save 60%'), findsOneWidget);
      expect(_anyPill, findsOneWidget);
    });

    testWidgets('under fa the pill reads the saving in Persian digits', (
      tester,
    ) async {
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: priced(23.88, 4.99),
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        ),
        locale: const Locale('fa'),
      );
      final fa = lookupOneVpnLocalizations(const Locale('fa'));
      // Anti-vacuity: the per-month price beside the pill is in Persian digits.
      expect(
        find.text(fa.onevpnPaywallPricePerMonth('۱٫۹۹', 'USD')),
        findsOneWidget,
      );
      expect(find.text(fa.onevpnPaywallSaleYearly('۶۰')), findsOneWidget);
      expect(find.textContaining('60'), findsNothing);
    });

    testWidgets('under tk the pill reads the saving in English digits', (
      tester,
    ) async {
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: priced(23.88, 4.99),
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        ),
        locale: const Locale('tk'),
      );
      final tk = lookupOneVpnLocalizations(const Locale('tk'));
      expect(
        find.text(tk.onevpnPaywallPricePerMonth('1.99', 'USD')),
        findsOneWidget,
      );
      expect(find.text(tk.onevpnPaywallSaleYearly('60')), findsOneWidget);
    });

    testWidgets('placeholder pricing shows no pill', (tester) async {
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: OneVpnFakePurchaseService(offeringsAvailable: false),
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        ),
      );
      // Anti-vacuity: the placeholder price shows on both cards.
      expect(find.text(l.onevpnPaywallPriceUnavailable), findsNWidgets(2));
      expect(_anyPill, findsNothing);
    });

    testWidgets('no saving shows no pill', (tester) async {
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: priced(59.88, 4.99),
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        ),
      );
      // Anti-vacuity: both live per-month prices show.
      expect(
        find.text(l.onevpnPaywallPricePerMonth('4.99', 'USD')),
        findsNWidgets(2),
      );
      expect(_anyPill, findsNothing);
    });

    testWidgets('a missing monthly plan shows no pill', (tester) async {
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: OneVpnFakePurchaseService(
            offerings: const OneVpnOfferings(
              yearly: OneVpnPurchasePackage(
                identifier: 'y',
                term: OneVpnPurchaseTerm.yearly,
                priceString: r'US$23.88',
                price: 23.88,
                currencyCode: 'USD',
              ),
            ),
          ),
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        ),
      );
      expect(
        find.text(l.onevpnPaywallPricePerMonth('1.99', 'USD')),
        findsOneWidget,
      );
      expect(_anyPill, findsNothing);
    });
  });

  testWidgets('stays usable when the offering fails to load, then recovers '
      'live prices on Retry', (tester) async {
    final service = OneVpnFakePurchaseService(
      offeringsAvailable: false,
      loadFailure: const OneVpnOfferingsUnreachable(),
    );
    await _pump(
      tester,
      OneVpnPaywallPage(
        service: service,
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
      ),
    );

    // The benefits and both cards still render. The paywall is never blank
    // or blocking.
    expect(find.text(l.onevpnPaywallBenefitLocations), findsOneWidget);
    expect(find.text(l.onevpnPaywallPlanYearly), findsOneWidget);
    expect(find.text(l.onevpnPaywallPlanMonthly), findsOneWidget);
    // Placeholder pricing and the load notice show, and the CTA offers retry.
    expect(find.text(l.onevpnPaywallPriceUnavailable), findsWidgets);
    expect(find.text(l.onevpnPaywallPlansLoadFailed), findsOneWidget);
    expect(find.text(l.onevpnPaywallRetry), findsOneWidget);
    expect(tester.takeException(), isNull);

    // The offering comes back and the user taps Retry. Live prices bind and
    // the failure surface clears back to the Get Premium CTA.
    service.offeringsAvailable = true;
    await tester.tap(find.text(l.onevpnPaywallRetry));
    await tester.pumpAndSettle();

    // The fake prices read per month.
    expect(
      find.text(l.onevpnPaywallPricePerMonth('3.33', 'USD')),
      findsOneWidget,
    );
    expect(
      find.text(l.onevpnPaywallPricePerMonth('6.99', 'USD')),
      findsOneWidget,
    );
    expect(find.text(l.onevpnPaywallPriceUnavailable), findsNothing);
    expect(find.text(l.onevpnPaywallPlansLoadFailed), findsNothing);
    expect(find.text(l.onevpnPaywallRetry), findsNothing);
    expect(find.text(l.onevpnGetPremium), findsOneWidget);
  });

  testWidgets('a store configuration error reads as unavailable, not '
      'connectivity', (tester) async {
    final service = OneVpnFakePurchaseService(
      offeringsAvailable: false,
      loadFailure: const OneVpnOfferingsUnavailable(),
    );
    await _pump(
      tester,
      OneVpnPaywallPage(
        service: service,
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
      ),
    );

    expect(find.text(l.onevpnPaywallPlansUnavailable), findsOneWidget);
    expect(find.text(l.onevpnPaywallPlansLoadFailed), findsNothing);
    expect(find.text(l.onevpnPaywallRetry), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Get Premium purchases the preselected yearly package', (
    tester,
  ) async {
    final service = OneVpnFakePurchaseService();
    var completed = 0;
    await _pump(
      tester,
      OneVpnPaywallPage(
        service: service,
        accountState: _signedIn('buyer@example.invalid'),
        onPurchaseComplete: (_, _) async => completed++,
      ),
    );

    await tester.tap(find.text(l.onevpnGetPremium));
    await tester.pumpAndSettle();

    expect(service.calls, contains('purchase'));
    expect(service.lastPackage?.term, OneVpnPurchaseTerm.yearly);
    expect(service.lastEmail, 'buyer@example.invalid');
    expect(completed, 1);
  });

  testWidgets('selecting Monthly then Get Premium purchases monthly', (
    tester,
  ) async {
    final service = OneVpnFakePurchaseService();
    await _pump(
      tester,
      OneVpnPaywallPage(
        service: service,
        accountState: _signedIn('buyer@example.invalid'),
        onPurchaseComplete: (_, _) async {},
      ),
    );

    await tester.tap(find.text(l.onevpnPaywallPlanMonthly));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.onevpnGetPremium));
    await tester.pumpAndSettle();

    expect(service.lastPackage?.term, OneVpnPurchaseTerm.monthly);
  });

  testWidgets('Continue Free invokes the dismissal', (tester) async {
    var dismissed = 0;
    await _pump(
      tester,
      OneVpnPaywallPage(
        service: OneVpnFakePurchaseService(),
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        onContinueFree: () => dismissed++,
      ),
    );

    await tester.tap(find.text(l.onevpnContinueFree));
    await tester.pump();
    expect(dismissed, 1);
  });

  testWidgets('a non-cancel failure surfaces a user-visible error', (
    tester,
  ) async {
    final service = OneVpnFakePurchaseService(
      outcome: const OneVpnPurchaseFailed('boom'),
    );
    var completed = 0;
    await _pump(
      tester,
      OneVpnPaywallPage(
        service: service,
        accountState: _signedIn('buyer@example.invalid'),
        onPurchaseComplete: (_, _) async => completed++,
      ),
    );

    await tester.tap(find.text(l.onevpnGetPremium));
    await tester.pump();
    await tester.pump();

    expect(find.text(l.onevpnPaywallPurchaseError), findsOneWidget);
    expect(completed, 0);
  });

  group('a named failure', () {
    /// Taps Get Premium under [locale] against a store that fails with
    /// [reason]. Returns the pages the support link opens.
    Future<List<Uri>> fail(
      WidgetTester tester,
      OneVpnPurchaseFailureReason reason, {
      Locale locale = const Locale('en'),
    }) async {
      final opened = <Uri>[];
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: OneVpnFakePurchaseService(
            outcome: OneVpnPurchaseFailed('refused', reason: reason),
          ),
          accountState: _signedIn(_buyer),
          onPurchaseComplete: (_, _) async {},
          openLink: (_, uri) async => opened.add(uri),
        ),
        locale: locale,
      );
      await tester.tap(
        find.text(lookupOneVpnLocalizations(locale).onevpnGetPremium),
      );
      await tester.pumpAndSettle();
      return opened;
    }

    Finder inNotice(Finder finder) =>
        find.descendant(of: find.byType(SnackBar), matching: finder);

    /// The notice paragraph that holds [label].
    Finder paragraphWith(String label) => inNotice(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText && widget.text.toPlainText().contains(label),
      ),
    );

    /// The text spans of the paragraph [finder] finds, in order.
    List<TextSpan> spansOf(WidgetTester tester, Finder finder) {
      final spans = <TextSpan>[];
      tester.widget<RichText>(finder).text.visitChildren((span) {
        if (span is TextSpan && span.text != null) spans.add(span);
        return true;
      });
      return spans;
    }

    for (final (reason, message) in <(OneVpnPurchaseFailureReason, String)>[
      (
        OneVpnPurchaseFailureReason.otherAccount,
        l.onevpnPaywallPurchaseOtherAccount(l.onevpnPaywallSupportLink),
      ),
      (
        OneVpnPurchaseFailureReason.owned,
        l.onevpnPaywallPurchaseOwned(l.onevpnPaywallSupportLink),
      ),
    ]) {
      testWidgets('${reason.name} names the cause, and its 1VPN Support link '
          'opens the contact page and closes the notice', (tester) async {
        final semantics = tester.ensureSemantics();
        final opened = await fail(tester, reason);
        final label = l.onevpnPaywallSupportLink;

        expect(inNotice(find.text(message, findRichText: true)), findsOne);
        expect(find.text(l.onevpnPaywallPurchaseError), findsNothing);
        expect(inNotice(find.text(l.onevpnContactUs)), findsNothing);
        // The notice stays until the user acts on it or closes it.
        await tester.pump(const Duration(seconds: 10));
        expect(inNotice(find.text(message, findRichText: true)), findsOne);
        expect(inNotice(find.byIcon(Icons.close)), findsOneWidget);
        // The link is underlined, and assistive technology reads a link.
        final link = spansOf(tester, paragraphWith(label))[1];
        expect(link.text, label);
        expect(link.style!.decoration, TextDecoration.underline);
        expect(
          find.semantics.byLabel(label).evaluate().single,
          isSemantics(isLink: true, hasTapAction: true),
        );

        await tester.tapOnText(
          find.textRange.ofSubstring(
            label,
            descendentOf: find.byType(SnackBar),
          ),
        );
        await tester.pumpAndSettle();

        expect(opened, [OneVpnLinks.contactUs]);
        expect(find.byType(SnackBar), findsNothing);
        semantics.dispose();
      });
    }

    testWidgets('unfinished names the unfinished purchase until the user '
        'closes it', (tester) async {
      await fail(tester, OneVpnPurchaseFailureReason.unfinished);

      expect(
        inNotice(find.text(l.onevpnPaywallPurchaseUnfinished)),
        findsOneWidget,
      );
      expect(find.text(l.onevpnPaywallPurchaseError), findsNothing);
      await tester.pump(const Duration(seconds: 10));
      expect(
        inNotice(find.text(l.onevpnPaywallPurchaseUnfinished)),
        findsOneWidget,
      );

      await tester.tap(inNotice(find.byIcon(Icons.close)));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('storeProblem shows the generic text, which leaves on its '
        'own with no close button', (tester) async {
      await fail(tester, OneVpnPurchaseFailureReason.storeProblem);

      expect(inNotice(find.text(l.onevpnPaywallPurchaseError)), findsOneWidget);
      expect(find.text(l.onevpnPaywallPurchaseUnfinished), findsNothing);
      expect(inNotice(find.byIcon(Icons.close)), findsNothing);
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    test('every locale places the support link once in both account '
        'causes', () {
      // Anti-vacuity guard. The 25 translations and the template are read.
      expect(OneVpnLocalizations.supportedLocales, hasLength(26));
      for (final locale in OneVpnLocalizations.supportedLocales) {
        final local = lookupOneVpnLocalizations(locale);
        final label = local.onevpnPaywallSupportLink;
        expect(label.trim(), isNotEmpty, reason: '$locale');
        for (final message in <OneVpnLinkedMessage>[
          local.onevpnPaywallPurchaseOtherAccount,
          local.onevpnPaywallPurchaseOwned,
        ]) {
          final parts = oneVpnLinkParts(message);
          expect(parts, isNotNull, reason: '$locale ${message(label)}');
          expect(
            '${parts!.$1}$label${parts.$2}',
            message(label),
            reason: '$locale',
          );
        }
      }
    });

    for (final code in ['fa', 'ar']) {
      testWidgets('under $code, the support link splits the message, and the '
          'paragraph runs right to left', (tester) async {
        final locale = Locale(code);
        final local = lookupOneVpnLocalizations(locale);
        await fail(
          tester,
          OneVpnPurchaseFailureReason.otherAccount,
          locale: locale,
        );
        final label = local.onevpnPaywallSupportLink;
        final paragraph = paragraphWith(label);

        expect(paragraph, findsOneWidget);
        expect(
          tester.renderObject<RenderParagraph>(paragraph).textDirection,
          TextDirection.rtl,
        );
        final spans = spansOf(tester, paragraph);
        expect(spans, hasLength(3));
        expect(spans[1].text, label);
        expect(spans[1].recognizer, isA<TapGestureRecognizer>());
        expect(
          spans.map((span) => span.text).join(),
          local.onevpnPaywallPurchaseOtherAccount(label),
        );
      });
    }
  });

  group('a failure notice belongs to the paywall', () {
    /// Opens the paywall over a launcher screen and fails a purchase with
    /// [reason]. Returns the navigator.
    Future<NavigatorState> failOverLauncher(
      WidgetTester tester,
      OneVpnPurchaseFailureReason reason,
    ) async {
      await setViewport(tester, kPortraitViewport);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: oneVpnLocalizationsDelegates,
          supportedLocales: [for (final l in kOneVpnLocales) l.locale],
          home: const Scaffold(body: Text('launcher')),
        ),
      );
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => OneVpnPaywallPage(
              service: OneVpnFakePurchaseService(
                outcome: OneVpnPurchaseFailed('refused', reason: reason),
              ),
              accountState: _signedIn(_buyer),
              onPurchaseComplete: (_, _) async {},
              openLink: (_, _) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);
      return navigator;
    }

    for (final reason in [
      OneVpnPurchaseFailureReason.otherAccount,
      OneVpnPurchaseFailureReason.owned,
      OneVpnPurchaseFailureReason.unfinished,
    ]) {
      testWidgets('${reason.name}: closing the paywall closes its notice', (
        tester,
      ) async {
        final navigator = await failOverLauncher(tester, reason);

        navigator.pop();
        await tester.pumpAndSettle();

        expect(find.text('launcher'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
      });
    }

    testWidgets('a route pushed over the paywall closes its notice', (
      tester,
    ) async {
      final navigator = await failOverLauncher(
        tester,
        OneVpnPurchaseFailureReason.otherAccount,
      );

      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('next')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('next'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
      // The paywall stays mounted under the new route.
      expect(
        find.byType(OneVpnPaywallPage, skipOffstage: false),
        findsOneWidget,
      );
    });
  });

  group('the purchase deadline', () {
    /// A paywall over [service] whose handoff records the address.
    Future<List<String>> open(
      WidgetTester tester,
      OneVpnFakePurchaseService service,
    ) async {
      final handoffs = <String>[];
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: service,
          accountState: _signedIn(_buyer),
          onPurchaseComplete: (_, email) async => handoffs.add(email),
        ),
      );
      return handoffs;
    }

    bool enabled(WidgetTester tester, String label) =>
        tester.widget<InkWell>(find.widgetWithText(InkWell, label)).onTap !=
        null;

    testWidgets('frees the buttons 30 s after the last return to the '
        'foreground', (tester) async {
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );
      await open(tester, _HeldPurchaseService());
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pump();
      expect(enabled(tester, l.onevpnGetPremium), isFalse);
      expect(enabled(tester, l.onevpnContinueFree), isFalse);

      // The store sheet holds the foreground. The count waits.
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump(const Duration(seconds: 45));
      expect(enabled(tester, l.onevpnGetPremium), isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 29));
      expect(enabled(tester, l.onevpnGetPremium), isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(enabled(tester, l.onevpnGetPremium), isTrue);
      expect(enabled(tester, l.onevpnContinueFree), isTrue);
    });

    testWidgets('a success after the deadline still hands off', (tester) async {
      final service = _HeldPurchaseService();
      final handoffs = await open(tester, service);
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pump(kOneVpnPurchaseDeadline);
      expect(enabled(tester, l.onevpnGetPremium), isTrue);

      service.result.complete(const OneVpnPurchaseSucceeded());
      await tester.pumpAndSettle();

      expect(handoffs, [_buyer]);
    });

    testWidgets('a failure with no purchase in flight shows nothing', (
      tester,
    ) async {
      final service = _HeldPurchaseService();
      await open(tester, service);
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pump(kOneVpnPurchaseDeadline);
      expect(enabled(tester, l.onevpnGetPremium), isTrue);

      service.result.complete(
        const OneVpnPurchaseFailed(
          'store problem',
          reason: OneVpnPurchaseFailureReason.storeProblem,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(enabled(tester, l.onevpnGetPremium), isTrue);
    });

    /// Home on the store sheet, then a launcher start.
    const homeAndBack = [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ];

    void move(WidgetTester tester, List<AppLifecycleState> states) {
      for (final state in states) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    }

    int restores(OneVpnFakePurchaseService service) =>
        service.calls.where((call) => call == 'restorePurchaseSheet').length;

    testWidgets('a return after a pause brings the sheet back once and shows '
        'nothing, and the sheet result frees the buttons', (tester) async {
      addTearDown(() => move(tester, [AppLifecycleState.resumed]));
      final service = _HeldPurchaseService()..sheetRestored = true;
      await open(tester, service);
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pump();

      move(tester, homeAndBack);
      await tester.pump();
      expect(restores(service), 1);
      expect(find.byType(SnackBar), findsNothing);
      expect(enabled(tester, l.onevpnGetPremium), isFalse);

      // A return with no pause asks for no sheet.
      move(tester, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
      await tester.pump();
      expect(restores(service), 1);

      service.result.complete(const OneVpnPurchaseCancelled());
      await tester.pumpAndSettle();
      expect(enabled(tester, l.onevpnGetPremium), isTrue);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a return with no sheet left behind keeps the deadline', (
      tester,
    ) async {
      addTearDown(() => move(tester, [AppLifecycleState.resumed]));
      final service = _HeldPurchaseService();
      await open(tester, service);
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pump();

      move(tester, homeAndBack);
      await tester.pump(const Duration(seconds: 29));
      expect(restores(service), 1);
      expect(enabled(tester, l.onevpnGetPremium), isFalse);
      await tester.pump(const Duration(seconds: 1));
      expect(enabled(tester, l.onevpnGetPremium), isTrue);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a return with no pause since the tap asks for no sheet', (
      tester,
    ) async {
      addTearDown(() => move(tester, [AppLifecycleState.resumed]));
      final service = _HeldPurchaseService()..sheetRestored = true;
      await open(tester, service);
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pump();

      move(tester, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
      await tester.pump();

      expect(restores(service), 0);
    });

    testWidgets('a return with no purchase in flight asks for no sheet', (
      tester,
    ) async {
      addTearDown(() => move(tester, [AppLifecycleState.resumed]));
      final service = _HeldPurchaseService()..sheetRestored = true;
      await open(tester, service);

      move(tester, homeAndBack);
      await tester.pump();

      expect(restores(service), 0);
      // Anti-vacuity guard. The same return during a purchase asks once.
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pump();
      move(tester, homeAndBack);
      await tester.pump();
      expect(restores(service), 1);
    });

    for (final (name, earlier) in <(String, OneVpnPurchaseOutcome)>[
      ('cancel', const OneVpnPurchaseCancelled()),
      (
        'failure',
        const OneVpnPurchaseFailed(
          'store problem',
          reason: OneVpnPurchaseFailureReason.storeProblem,
        ),
      ),
    ]) {
      testWidgets('a late $name of an earlier tap shows nothing and leaves '
          'the later tap holding the buttons', (tester) async {
        final service = _QueuedPurchaseService();
        await open(tester, service);
        await tester.tap(find.text(l.onevpnGetPremium));
        await tester.pump(kOneVpnPurchaseDeadline);
        expect(enabled(tester, l.onevpnGetPremium), isTrue);
        await tester.tap(find.text(l.onevpnGetPremium));
        await tester.pump();

        // A finished sheet ends the first purchase now.
        service.results[0].complete(earlier);
        await tester.pumpAndSettle();
        expect(find.byType(SnackBar), findsNothing);
        expect(enabled(tester, l.onevpnGetPremium), isFalse);

        // The later tap's own result frees the buttons and names its cause.
        service.results[1].complete(
          const OneVpnPurchaseFailed(
            'refused',
            reason: OneVpnPurchaseFailureReason.owned,
          ),
        );
        await tester.pumpAndSettle();
        expect(enabled(tester, l.onevpnGetPremium), isTrue);
        expect(
          find.text(
            l.onevpnPaywallPurchaseOwned(l.onevpnPaywallSupportLink),
            findRichText: true,
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('a pause during an earlier purchase asks for no sheet on '
        'the next one', (tester) async {
      addTearDown(() => move(tester, [AppLifecycleState.resumed]));
      final service = _QueuedPurchaseService()..sheetRestored = true;
      await open(tester, service);
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pump();

      // The first purchase ends while the app is in the background.
      move(tester, homeAndBack.take(3).toList());
      service.results[0].complete(const OneVpnPurchaseCancelled());
      await tester.pump();
      move(tester, homeAndBack.skip(3).toList());
      await tester.pump();
      expect(restores(service), 0);

      // The second sheet holds the screen with no pause.
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pump();
      move(tester, [AppLifecycleState.inactive, AppLifecycleState.resumed]);
      await tester.pump();

      expect(service.results, hasLength(2));
      expect(restores(service), 0);
    });
  });

  testWidgets('a cancelled purchase stays on the paywall silently', (
    tester,
  ) async {
    final service = OneVpnFakePurchaseService(
      outcome: const OneVpnPurchaseCancelled(),
    );
    var completed = 0;
    await _pump(
      tester,
      OneVpnPaywallPage(
        service: service,
        accountState: _signedIn('buyer@example.invalid'),
        onPurchaseComplete: (_, _) async => completed++,
      ),
    );

    await tester.tap(find.text(l.onevpnGetPremium));
    await tester.pumpAndSettle();

    expect(completed, 0);
    expect(find.text(l.onevpnPaywallPurchaseError), findsNothing);
    // The paywall stays open.
    expect(find.text(l.onevpnGetPremium), findsOneWidget);
  });

  testWidgets('keeps the primary action on-screen at 320dp', (tester) async {
    await _pump(
      tester,
      OneVpnPaywallPage(
        service: OneVpnFakePurchaseService(),
        accountState: ValueNotifier(const OneVpnAccountSignedOut()),
      ),
      size: const Size(320, 640),
    );

    expect(tester.takeException(), isNull);
    expect(find.text(l.onevpnPaywallBenefitLocations), findsOneWidget);
    expect(find.text(l.onevpnPaywallPlanYearly), findsOneWidget);
    // The Get Premium CTA lives in the fixed footer, outside the scroll
    // view. At the smallest supported height it stays within the 640dp
    // viewport.
    final cta = find.widgetWithText(InkWell, l.onevpnGetPremium);
    expect(cta, findsOneWidget);
    expect(tester.getBottomLeft(cta).dy, lessThanOrEqualTo(640.0));
  });

  testWidgets('auto-selects the only available term so Get Premium can buy', (
    tester,
  ) async {
    // A partial offering: Monthly only. Yearly is preselected with no live
    // package, so the paywall moves the selection to Monthly and buys it.
    final service = OneVpnFakePurchaseService(
      offerings: const OneVpnOfferings(
        monthly: OneVpnPurchasePackage(
          identifier: 'm',
          term: OneVpnPurchaseTerm.monthly,
          priceString: '€1.99',
        ),
      ),
    );
    await _pump(
      tester,
      OneVpnPaywallPage(
        service: service,
        accountState: _signedIn('buyer@example.invalid'),
        onPurchaseComplete: (_, _) async {},
      ),
    );

    // The live Monthly price binds. Yearly reads as unavailable.
    expect(find.text('€1.99'), findsOneWidget);
    expect(find.text(l.onevpnPaywallPriceUnavailable), findsOneWidget);

    await tester.tap(find.text(l.onevpnGetPremium));
    await tester.pumpAndSettle();

    // The paywall buys the available Monthly package and does not rerun the
    // load.
    expect(service.lastPackage?.term, OneVpnPurchaseTerm.monthly);
    expect(service.calls.where((c) => c == 'loadOfferings').length, 1);
    expect(service.calls, contains('purchase'));
  });

  group('the join key', () {
    testWidgets('a signed-out buyer is asked before the store sheet opens', (
      tester,
    ) async {
      final service = OneVpnFakePurchaseService();
      final order = <String>[];
      String? completedWith;
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: service,
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
          askForEmail: (_, _) async {
            order.add('ask');
            return 'buyer@example.invalid';
          },
          onPurchaseComplete: (_, email) async {
            order.add('complete');
            completedWith = email;
          },
        ),
      );

      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();

      // The address has to reach the store before the purchase, because the
      // backend links the purchase by it.
      expect(order, ['ask', 'complete']);
      expect(service.lastEmail, 'buyer@example.invalid');
      // The paywall hands the same address on. Sign-up uses the address the
      // purchase used.
      expect(completedWith, 'buyer@example.invalid');
    });

    testWidgets('an account with an email on file is never asked', (
      tester,
    ) async {
      final service = OneVpnFakePurchaseService();
      var asked = 0;
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: service,
          accountState: _signedIn('member@example.invalid'),
          askForEmail: (_, _) async {
            asked++;
            return 'other@example.invalid';
          },
          onPurchaseComplete: (_, _) async {},
        ),
      );

      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();

      expect(asked, 0);
      expect(service.lastEmail, 'member@example.invalid');
    });

    testWidgets('backing out of the prompt buys nothing', (tester) async {
      final service = OneVpnFakePurchaseService();
      var completed = 0;
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: service,
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
          askForEmail: (_, _) async => null,
          onPurchaseComplete: (_, _) async => completed++,
        ),
      );

      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();

      expect(service.calls, isNot(contains('purchase')));
      expect(completed, 0);
      expect(find.text(l.onevpnGetPremium), findsOneWidget);
    });

    testWidgets('the production build opens the real prompt sheet', (
      tester,
    ) async {
      // The router builds this screen without askForEmail. The default
      // adapts to the callback's positional shape. A bare tear-off of the
      // named-argument prompt throws at the call.
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: OneVpnFakePurchaseService(),
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
        ),
      );

      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('a second ask opens on the address already captured', (
      tester,
    ) async {
      // The store cancels, so the buyer is back on the paywall and taps
      // again.
      final service = OneVpnFakePurchaseService(
        outcome: const OneVpnPurchaseCancelled(),
      );
      final initials = <String>[];
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: service,
          accountState: ValueNotifier(const OneVpnAccountSignedOut()),
          askForEmail: (_, initial) async {
            initials.add(initial);
            return _buyer;
          },
        ),
      );

      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();

      // The first ask opens empty. The retry opens on the address the store
      // already has. A second answer cannot silently diverge from it.
      expect(initials, ['', _buyer]);
    });
  });

  group('the purchase with no account', () {
    /// A paywall whose handoff runs [onComplete] and records the address it
    /// was called with.
    Future<List<String>> buy(
      WidgetTester tester, {
      required ValueNotifier<OneVpnAccountState> account,
      Future<void> Function()? onComplete,
      OneVpnFakePurchaseService? service,
    }) async {
      final handoffs = <String>[];
      await _pump(
        tester,
        OneVpnPaywallPage(
          service: service ?? OneVpnFakePurchaseService(),
          accountState: account,
          askForEmail: (_, _) async => _buyer,
          onPurchaseComplete: (_, email) async {
            handoffs.add(email);
            await onComplete?.call();
          },
        ),
      );
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();
      return handoffs;
    }

    testWidgets('an abandoned sign-up leaves the purchase named on screen', (
      tester,
    ) async {
      await buy(tester, account: ValueNotifier(const OneVpnAccountSignedOut()));

      // Money moved and no account claimed it. The screen says so and names
      // the address the backend links on.
      expect(find.text(l.onevpnPaywallPurchasedTitle), findsOneWidget);
      expect(find.text(l.onevpnPaywallPurchasedBody(_buyer)), findsOneWidget);
      // With no title above it, the message starts 24dp from the top.
      expect(tester.getTopLeft(find.byIcon(LucideIcons.circleCheck)).dy, 24);
      // The purchase is done, so the plans and their action leave the screen.
      expect(find.text(l.onevpnGetPremium), findsNothing);
      expect(find.text(l.onevpnPaywallPlanYearly), findsNothing);
      expect(find.text(l.onevpnAuthCreateAccount), findsOneWidget);
    });

    testWidgets('the primary action reopens the account step, not the '
        'store', (tester) async {
      final service = OneVpnFakePurchaseService();
      final handoffs = await buy(
        tester,
        account: ValueNotifier(const OneVpnAccountSignedOut()),
        service: service,
      );
      final charges = service.calls.where((call) => call == 'purchase').length;

      await tester.tap(find.text(l.onevpnAuthCreateAccount));
      await tester.pumpAndSettle();

      // The same address goes back through the handoff, which opens sign-up
      // locked to it. Nothing is bought a second time.
      expect(handoffs, [_buyer, _buyer]);
      expect(service.calls.where((call) => call == 'purchase').length, charges);
    });

    testWidgets('a handoff that signs the buyer in leaves the screen '
        'alone', (tester) async {
      final account = ValueNotifier<OneVpnAccountState>(
        const OneVpnAccountSignedOut(),
      );

      await buy(
        tester,
        account: account,
        onComplete: () async => account.value = _signedIn(_buyer).value,
      );

      // The sign-up completes, so nothing unlinked remains to report. In the
      // app, the funnel dismisses this screen on completion.
      expect(find.text(l.onevpnPaywallPurchasedTitle), findsNothing);
      expect(find.text(l.onevpnGetPremium), findsOneWidget);
    });
  });

  group('the layout', () {
    OneVpnPaywallPage page({
      OneVpnFakePurchaseService? service,
      ValueNotifier<OneVpnAccountState>? account,
      OneVpnPaywallPurchased? onPurchaseComplete,
    }) => OneVpnPaywallPage(
      service: service ?? OneVpnFakePurchaseService(),
      accountState: account ?? ValueNotifier(const OneVpnAccountSignedOut()),
      askForEmail: (_, _) async => _buyer,
      onPurchaseComplete: onPurchaseComplete ?? (_, _) async {},
    );

    Finder inPane(Key pane, Finder finder) =>
        find.descendant(of: find.byKey(pane), matching: finder);

    void expectContent() {
      for (final text in [
        l.onevpnPaywallTitle,
        l.onevpnPaywallBenefitLocations,
        l.onevpnPaywallBenefitNoAds,
        l.onevpnPaywallBenefitSpeed,
        l.onevpnPaywallBenefitP2p,
        l.onevpnPaywallBenefitMoneyBack,
        l.onevpnPaywallPlanYearly,
        l.onevpnPaywallPlanMonthly,
        l.onevpnGetPremium,
        l.onevpnContinueFree,
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
    }

    testWidgets('at 360x800 the paywall stacks with no overflow', (
      tester,
    ) async {
      await _pump(tester, page());

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsNothing);
      expectContent();
      final title = tester.widget<Text>(find.text(l.onevpnPaywallTitle));
      expect(title.textAlign, TextAlign.center);
      // One column: the benefits over the cards over the footer.
      final benefit = tester.getRect(
        find.text(l.onevpnPaywallBenefitMoneyBack),
      );
      final monthly = tester.getRect(find.text(l.onevpnPaywallPlanMonthly));
      final cta = tester.getRect(find.text(l.onevpnGetPremium));
      expect(benefit.bottom, lessThan(monthly.top));
      expect(monthly.bottom, lessThan(cta.top));
    });

    testWidgets('a wide stacked window caps the column at 480dp', (
      tester,
    ) async {
      await _pump(tester, page(), size: const Size(768, 1024));

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsOneWidget);
      final cta = tester.getRect(
        find.widgetWithText(InkWell, l.onevpnGetPremium),
      );
      // The footer insets the card margin each side inside the 480dp column.
      expect(cta.width, OneVpnLayout.narrowCap - 2 * OneVpnCard.margin);
      expect(cta.center.dx, 768 / 2);
    });

    testWidgets('at 800x360 the paywall splits with no overflow', (
      tester,
    ) async {
      await _pump(tester, page(), size: kLandscapeViewport);

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
      expect(find.byKey(OneVpnConstrainedBody.stackedKey), findsNothing);
      expectContent();
      const start = OneVpnAdaptiveBody.startPaneKey;
      const end = OneVpnAdaptiveBody.endPaneKey;
      for (final text in [
        l.onevpnPaywallTitle,
        l.onevpnPaywallBenefitLocations,
        l.onevpnPaywallBenefitNoAds,
        l.onevpnPaywallBenefitSpeed,
        l.onevpnPaywallBenefitP2p,
        l.onevpnPaywallBenefitMoneyBack,
      ]) {
        expect(inPane(start, find.text(text)), findsOneWidget, reason: text);
      }
      final title = tester.widget<Text>(find.text(l.onevpnPaywallTitle));
      expect(title.textAlign, TextAlign.start);
      for (final text in [
        l.onevpnPaywallPlanYearly,
        l.onevpnPaywallPlanMonthly,
        l.onevpnGetPremium,
        l.onevpnContinueFree,
      ]) {
        expect(inPane(end, find.text(text)), findsOneWidget, reason: text);
      }
    });

    testWidgets('in split, the footer buttons scroll with the plan cards', (
      tester,
    ) async {
      // A status-bar inset and a larger text size push the end pane's
      // content past its height.
      tester.view.padding = const FakeViewPadding(top: 24);
      tester.view.viewPadding = const FakeViewPadding(top: 24);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, page(), size: kLandscapeViewport);

      expect(tester.takeException(), isNull);
      final pane = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
      final yearly = find.text(l.onevpnPaywallPlanYearly);
      final getPremium = find.widgetWithText(InkWell, l.onevpnGetPremium);
      final cardBefore = tester.getTopLeft(yearly).dy;
      final buttonBefore = tester.getTopLeft(getPremium).dy;

      await tester.dragFrom(
        pane.topCenter + const Offset(0, 40),
        const Offset(0, -1000),
      );
      await tester.pumpAndSettle();

      // The cards and the buttons move by the same offset.
      final shift = tester.getTopLeft(yearly).dy - cardBefore;
      expect(shift, lessThan(0));
      expect(tester.getTopLeft(getPremium).dy - buttonBefore, shift);
      // Scrolled to the end, both buttons sit whole inside the end pane.
      for (final label in [l.onevpnGetPremium, l.onevpnContinueFree]) {
        final rect = tester.getRect(find.widgetWithText(InkWell, label));
        expect(find.text(label).hitTestable(), findsOneWidget, reason: label);
        expect(pane.contains(rect.topLeft), isTrue, reason: label);
        expect(rect.bottom, lessThanOrEqualTo(pane.bottom), reason: label);
      }
    });

    testWidgets('in split, 24dp separate the plan cards from Get Premium', (
      tester,
    ) async {
      await _pump(tester, page(), size: kLandscapeViewport);

      final monthly = tester.getRect(
        find
            .ancestor(
              of: find.text(l.onevpnPaywallPlanMonthly),
              matching: find.byType(InkWell),
            )
            .first,
      );
      final getPremium = tester.getRect(
        find.widgetWithText(InkWell, l.onevpnGetPremium),
      );
      expect(getPremium.top - monthly.bottom, 24);
    });

    testWidgets('in split, the purchase error anchors to the end pane', (
      tester,
    ) async {
      await _pump(
        tester,
        page(
          service: OneVpnFakePurchaseService(
            outcome: const OneVpnPurchaseFailed('boom'),
          ),
          account: _signedIn(_buyer),
        ),
        size: kLandscapeViewport,
      );

      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();

      expect(find.text(l.onevpnPaywallPurchaseError), findsOneWidget);
      final pane = tester.getRect(find.byKey(OneVpnAdaptiveBody.endPaneKey));
      final snackBar = tester.getRect(
        find
            .descendant(
              of: find.byType(SnackBar),
              matching: find.byType(Material),
            )
            .first,
      );
      final insets =
          AppTheme.light.snackBarTheme.insetPadding ??
          OneVpnSnackBarAnchor.fallbackInsets;
      expect(snackBar.left, pane.left + insets.left);
      expect(snackBar.right, pane.right - insets.right);
    });

    testWidgets('in split, the unlinked message sits directly above Create '
        'account', (tester) async {
      await _pump(
        tester,
        page(account: ValueNotifier(const OneVpnAccountSignedOut())),
        size: kLandscapeViewport,
      );
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
      const end = OneVpnAdaptiveBody.endPaneKey;
      final body = find.text(l.onevpnPaywallPurchasedBody(_buyer));
      final create = find.widgetWithText(InkWell, l.onevpnAuthCreateAccount);
      expect(inPane(end, find.text(l.onevpnPaywallPurchasedTitle)), findsOne);
      expect(inPane(end, body), findsOneWidget);
      expect(inPane(end, create), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(OneVpnAdaptiveBody.startPaneKey),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      // Only the footer's 8dp top inset separates the message from the
      // button.
      final gap = tester.getRect(create).top - tester.getRect(body).bottom;
      expect(gap, inInclusiveRange(0, 8));
      expect(find.text(l.onevpnPaywallPlanYearly), findsNothing);
      expect(find.text(l.onevpnGetPremium), findsNothing);
    });

    testWidgets('a rotation keeps the selected plan', (tester) async {
      final service = OneVpnFakePurchaseService();
      await _pump(tester, page(service: service, account: _signedIn(_buyer)));
      await tester.tap(find.text(l.onevpnPaywallPlanMonthly));
      await tester.pumpAndSettle();

      await setViewport(tester, kLandscapeViewport);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(OneVpnAdaptiveBody.splitKey), findsOneWidget);
      await tester.tap(find.text(l.onevpnGetPremium));
      await tester.pumpAndSettle();

      expect(service.lastPackage?.term, OneVpnPurchaseTerm.monthly);
    });
  });
}
