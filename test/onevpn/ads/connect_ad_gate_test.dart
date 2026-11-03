// The connect ad gate's contract, against a fake gateway.
//
// A premium or pending-premium session proceeds and never touches the
// gateway. A restoring account state does the same. The first connect of a
// free account is ad-free and form-free. A free preload refreshes the
// consent information with no form, and loads only once ads are allowed. A
// failed update reruns on the next preload. While ads are not allowed, the
// second tap shows the consent form and proceeds with no ad. An allowing
// form starts no load. The disconnect preload caches the ad the third tap
// shows. A form tap first waits on a pending update. A refusing or throwing
// form proceeds with no ad, and the update and the form both run again
// later. A tap during a pending form runs no second form. Where no form is required, the second tap shows the
// ad. A cached ad shows, and its close proceeds and starts no load. A
// failed show cancels.
//
// A switch with no cached ad starts a load when none is in flight, then
// waits on the load for at most the bound. A load that lands within the wait
// shows. A wait that runs out, or a no-fill, proceeds with no ad and starts
// the tap's load. A cached ad shows with no wait. A switch while ads are not
// allowed waits on no load. A tap never waits on the load. A switch shows
// its ad only while the app is in front, read when the load lands. A switch
// out of front proceeds with no show and keeps the ad for the next tap. A
// tap out of front shows as before. A failed show cancels a switch too.
//
// A throwing preference store never fails the tap, and a failed read counts
// as the first connect. A tap waits on a pending update for at most the
// bound, then proceeds with no ad while the update runs on. A preload
// requested while the tunnel is up starts nothing, and an update that lands
// once the tunnel is up starts no load.
//
// A show still open past the grace after a resume ends as abandoned and
// cancels the connect, and the next tap runs fresh. A close within the
// grace, or before the resume, proceeds. A resume with no show in flight
// does nothing. A close after the abandon settles nothing twice. An app
// hidden inside the grace cancels it, and a second resume does not restart
// it. A tap inside the grace abandons at once. A show the user leaves ends
// as abandoned only after the return. A switch then proceeds, with no
// second show and no load. A tap cancels.

import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onexray/onevpn/account/account_service.dart';
import 'package:onexray/onevpn/account/session.dart';
import 'package:onexray/onevpn/ads/ad_gateway.dart';
import 'package:onexray/onevpn/ads/connect_ad_gate.dart';
import 'package:onexray/onevpn/model/user_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fake_ad_gateway.dart';

/// Preferences whose boolean reads and writes throw as configured.
final class _FailingPreferences extends InMemorySharedPreferencesAsync {
  _FailingPreferences({required this.readThrows, required this.writeThrows})
    : super.empty();

  final bool readThrows;
  final bool writeThrows;

  @override
  Future<bool?> getBool(String key, SharedPreferencesOptions options) =>
      readThrows
      ? Future<bool?>.error(StateError('prefs unavailable'))
      : super.getBool(key, options);

  @override
  Future<bool> setBool(
    String key,
    bool value,
    SharedPreferencesOptions options,
  ) => writeThrows
      ? Future<bool>.error(StateError('prefs unavailable'))
      : super.setBool(key, value, options);
}

OneVpnSession _session({bool premium = false, DateTime? pendingSince}) =>
    OneVpnSession(
      sessionAuthToken: 'token',
      username: 'someone',
      email: 'someone@example.invalid',
      isPremium: premium,
      credentials: const OneVpnCredentials(
        uuid: '',
        publicKey: '',
        shortId: '',
      ),
      locations: const [],
      premiumPendingSince: pendingSince,
    );

const OneVpnAccountState _signedOut = OneVpnAccountSignedOut();

/// The load source of a preload whose path the test does not read.
const _entry = OneVpnAdLoadSource.entry;

/// Lets the gate's unawaited preload run to its end.
Future<void> _drain() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeAdGateway gateway;
  late OneVpnConnectAdGate gate;

  /// What the gate's in-front check answers.
  var inFront = true;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    gateway = FakeAdGateway();
    inFront = true;
    gate = OneVpnConnectAdGate(gateway: gateway, inFront: () => inFront);
  });

  /// Stamps the first-connect key, so the next tap is not the first.
  Future<void> pastFirstConnect() => SharedPreferencesAsync().setBool(
    OneVpnConnectAdGate.firstConnectKey,
    true,
  );

  test('the first-connect key sits in the fork namespace', () {
    expect(OneVpnConnectAdGate.firstConnectKey, 'onevpn.firstConnectAdSkipped');
  });

  group('rule 1: premium and restoring', () {
    for (final (name, session) in [
      ('a premium session', OneVpnAccountSignedIn(_session(premium: true))),
      (
        'a pending-premium session',
        OneVpnAccountSignedIn(_session(pendingSince: DateTime.utc(2026))),
      ),
    ]) {
      test('$name proceeds and never touches the gateway', () async {
        await pastFirstConnect();
        gateway.ready = true;

        expect(await gate.beforeConnect(session), isTrue);
        gate.preload(session, source: _entry, tunnelDown: () => true);
        await _drain();

        expect(gateway.calls, isEmpty);
      });
    }

    test('a restoring account runs no consent and shows no ad', () async {
      await pastFirstConnect();
      gateway.ready = true;
      const restoring = OneVpnAccountRestoring();

      gate.preload(restoring, source: _entry, tunnelDown: () => true);
      await _drain();
      expect(await gate.beforeConnect(restoring), isTrue);
      await _drain();

      expect(gateway.calls, isEmpty);
    });

    test('a restoring tap leaves the first-connect key unstamped', () async {
      expect(await gate.beforeConnect(const OneVpnAccountRestoring()), isTrue);
      expect(
        await SharedPreferencesAsync().getBool(
          OneVpnConnectAdGate.firstConnectKey,
        ),
        isNull,
      );
    });

    test('a premium tap leaves the first-connect key unstamped', () async {
      expect(
        await gate.beforeConnect(
          OneVpnAccountSignedIn(_session(premium: true)),
        ),
        isTrue,
      );
      expect(
        await SharedPreferencesAsync().getBool(
          OneVpnConnectAdGate.firstConnectKey,
        ),
        isNull,
      );
    });
  });

  group('rule 2: the first connect of a free account is ad-free', () {
    test('first-ever connect tap shows no ad and no form', () async {
      // Ads are allowed and an ad is cached, so only the rule keeps it out.
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      expect(gateway.isReady, isTrue);
      gateway.calls.clear();

      expect(await gate.beforeConnect(_signedOut), isTrue);
      await _drain();

      expect(gateway.calls, isNot(contains('show')));
      expect(gateway.calls, isNot(contains('form')));
      expect(
        await SharedPreferencesAsync().getBool(
          OneVpnConnectAdGate.firstConnectKey,
        ),
        isTrue,
      );
    });

    test('the first tap shows no form where consent is required', () async {
      gateway.allowAds = false;
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();

      expect(await gate.beforeConnect(_signedOut), isTrue);
      await _drain();

      expect(gateway.calls, isNot(contains('form')));
      expect(gateway.calls, isNot(contains('show')));
    });

    test('the second free tap shows the cached ad', () async {
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      await gate.beforeConnect(_signedOut);

      expect(await gate.beforeConnect(_signedOut), isTrue);

      expect(gateway.count('show'), 1);
    });

    test('a signed-in free session follows the same rule', () async {
      final session = OneVpnAccountSignedIn(_session());
      gate.preload(session, source: _entry, tunnelDown: () => true);
      await _drain();

      await gate.beforeConnect(session);
      expect(gateway.calls, isNot(contains('show')));
      await gate.beforeConnect(session);
      expect(gateway.count('show'), 1);
    });
  });

  group('rule 3: the consent form', () {
    test(
      'a required form shows on the second tap, the ad on the third',
      () async {
        gateway.allowAds = false;

        // Screen entry.
        gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
        await _drain();
        expect(gateway.calls, isNot(contains('form')));
        expect(gateway.calls, isNot(contains('preload')));

        // Tap one: no form, no ad.
        expect(await gate.beforeConnect(_signedOut), isTrue);
        await _drain();
        expect(gateway.calls, isNot(contains('form')));

        // Disconnect.
        gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
        await _drain();
        expect(gateway.calls, isNot(contains('preload')));
        gateway.calls.clear();

        // Tap two: the form, no load, and no ad.
        expect(await gate.beforeConnect(_signedOut), isTrue);
        await _drain();
        expect(gateway.calls, ['form', 'privacy']);
        expect(gateway.isReady, isFalse);

        // Disconnect, then tap three shows the ad.
        gate.preload(
          _signedOut,
          source: OneVpnAdLoadSource.disconnect,
          tunnelDown: () => true,
        );
        await _drain();
        expect(gateway.calls, ['form', 'privacy', 'preload']);
        gateway.calls.clear();
        expect(await gate.beforeConnect(_signedOut), isTrue);
        await _drain();
        expect(gateway.calls, ['show']);
        expect(gateway.count('form'), 0);
      },
    );

    test(
      'a refusing form connects with no ad, and the next tap retries',
      () async {
        gateway
          ..allowAds = false
          ..formAllows = false;
        gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
        await _drain();
        await gate.beforeConnect(_signedOut);

        expect(await gate.beforeConnect(_signedOut), isTrue);
        await _drain();
        gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
        await _drain();
        expect(await gate.beforeConnect(_signedOut), isTrue);
        await _drain();

        expect(gateway.count('form'), 2);
        expect(gateway.count('update'), 2);
        expect(gateway.calls, isNot(contains('preload')));
        expect(gateway.calls, isNot(contains('show')));
      },
    );

    test('an update that allows after a refused form turns ads on', () async {
      gateway
        ..allowAds = false
        ..formAllows = false;
      await pastFirstConnect();
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      expect(await gate.beforeConnect(_signedOut), isTrue);
      await _drain();

      // The user allows ads later, through the privacy options form.
      gateway.allowAds = true;
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      expect(gateway.isReady, isTrue);
      gateway.calls.clear();

      expect(await gate.beforeConnect(_signedOut), isTrue);
      await _drain();
      expect(gateway.calls, ['show']);
    });

    test(
      'a thrown form connects with no ad, and the next tap retries',
      () async {
        gateway
          ..allowAds = false
          ..formError = StateError('no form');
        await pastFirstConnect();
        gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
        await _drain();

        expect(await gate.beforeConnect(_signedOut), isTrue);
        await _drain();
        expect(gateway.calls, isNot(contains('preload')));
        expect(gateway.calls, isNot(contains('show')));

        // The retry allows and starts no load.
        expect(await gate.beforeConnect(_signedOut), isTrue);
        await _drain();
        expect(gateway.count('form'), 2);
        expect(gateway.count('preload'), 0);
        expect(gateway.calls, isNot(contains('show')));
      },
    );

    test('the form tap waits on the form', () async {
      gateway
        ..allowAds = false
        ..formGate = Completer<void>();
      await pastFirstConnect();
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();

      var proceeded = false;
      unawaited(
        gate.beforeConnect(_signedOut).then((value) => proceeded = value),
      );
      await _drain();
      expect(proceeded, isFalse);

      gateway.formGate!.complete();
      await _drain();
      await _drain();
      expect(proceeded, isTrue);
      expect(gateway.calls, isNot(contains('show')));
    });

    test('a tap during a pending form runs no second form', () async {
      gateway
        ..allowAds = false
        ..formGate = Completer<void>();
      await pastFirstConnect();
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();

      final first = gate.beforeConnect(_signedOut);
      await _drain();
      expect(await gate.beforeConnect(_signedOut), isTrue);
      expect(gateway.count('form'), 1);

      gateway.formGate!.complete();
      expect(await first, isTrue);
      await _drain();
      expect(gateway.count('form'), 1);
      expect(gateway.calls, isNot(contains('show')));
    });

    test('the privacy options entry follows the form', () async {
      gateway
        ..allowAds = false
        ..formPrivacyRequired = true;
      await pastFirstConnect();
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      expect(gate.privacyOptionsRequired.value, isFalse);

      await gate.beforeConnect(_signedOut);
      await _drain();

      expect(gate.privacyOptionsRequired.value, isTrue);
    });

    test('a form tap waits on a pending update first', () async {
      gateway
        ..allowAds = false
        ..updateGate = Completer<void>();
      await pastFirstConnect();
      // A disconnect starts an update, then the user taps connect.
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();

      var proceeded = false;
      unawaited(
        gate.beforeConnect(_signedOut).then((value) => proceeded = value),
      );
      await _drain();
      expect(proceeded, isFalse);
      expect(gateway.calls, ['update']);

      gateway.updateGate!.complete();
      await _drain();
      await _drain();
      expect(proceeded, isTrue);
      expect(gateway.calls, ['update', 'privacy', 'form', 'privacy']);
    });

    test('a pending update that allows skips the form', () async {
      gateway.updateGate = Completer<void>();
      await pastFirstConnect();
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();

      final tap = gate.beforeConnect(_signedOut);
      await _drain();
      gateway.updateGate!.complete();

      expect(await tap, isTrue);
      await _drain();
      // The entry preload cached an ad once the update allowed, so it shows.
      expect(gateway.calls, isNot(contains('form')));
      expect(gateway.count('update'), 1);
      expect(gateway.calls, contains('show'));
    });
  });

  test('an accepted form requests no load, and the next disconnect '
      'preload caches the ad the next tap shows', () async {
    await pastFirstConnect();
    gateway.allowAds = false;

    expect(await gate.beforeConnect(_signedOut), isTrue);
    await _drain();
    expect(gateway.calls, ['form', 'privacy']);
    expect(gateway.sources, isEmpty);

    gate.preload(
      _signedOut,
      source: OneVpnAdLoadSource.disconnect,
      tunnelDown: () => true,
    );
    await _drain();
    expect(gateway.sources, [OneVpnAdLoadSource.disconnect]);
    expect(gateway.isReady, isTrue);

    expect(await gate.beforeConnect(_signedOut), isTrue);
    expect(gateway.calls.last, 'show');
  });

  test('rule 5: no cached ad starts a load and proceeds', () async {
    await pastFirstConnect();
    gateway.loads = false;
    gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
    await _drain();
    gateway.calls.clear();

    expect(await gate.beforeConnect(_signedOut), isTrue);
    await _drain();

    expect(gateway.calls, ['preload']);
    expect(gateway.sources.last, OneVpnAdLoadSource.tap);
  });

  group('rule 5: a switch waits on the load in flight', () {
    /// Allows ads with nothing cached, then holds the disconnect preload's
    /// load open. The load caches an ad as [loads] says.
    Future<void> heldLoad({bool loads = true}) async {
      await pastFirstConnect();
      gateway.loads = false;
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      gateway
        ..loads = loads
        ..loadGate = Completer<void>();
      gate.preload(
        _signedOut,
        source: OneVpnAdLoadSource.disconnect,
        tunnelDown: () => true,
      );
      await _drain();
      gateway.calls.clear();
    }

    test('a load that lands within the wait shows', () async {
      await heldLoad();
      bool? proceeded;
      unawaited(
        gate
            .beforeConnect(_signedOut, switching: true)
            .then((value) => proceeded = value),
      );
      await _drain();
      // The switch's request starts no second load while the held load runs.
      expect(gateway.calls, ['preload', 'wait']);
      expect(gateway.sources.last, OneVpnAdLoadSource.switching);
      expect(proceeded, isNull);

      gateway.loadGate!.complete();
      await _drain();
      await _drain();

      expect(proceeded, isTrue);
      expect(gateway.calls, ['preload', 'wait', 'show']);
    });

    test(
      'a switch with no load in flight starts one and waits on it',
      () async {
        await pastFirstConnect();
        gateway.loads = false;
        gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
        await _drain();
        // No disconnect preload ran, so no load is in flight.
        gateway
          ..loads = true
          ..loadGate = Completer<void>();
        gateway.calls.clear();

        bool? proceeded;
        unawaited(
          gate
              .beforeConnect(_signedOut, switching: true)
              .then((value) => proceeded = value),
        );
        await _drain();
        expect(gateway.calls, ['preload', 'wait']);
        expect(gateway.sources.last, OneVpnAdLoadSource.switching);
        expect(proceeded, isNull);

        gateway.loadGate!.complete();
        await _drain();
        await _drain();

        expect(proceeded, isTrue);
        expect(gateway.calls, ['preload', 'wait', 'show']);
      },
    );

    test('a load that misses the wait proceeds with no ad', () {
      fakeAsync((async) {
        unawaited(pastFirstConnect());
        gateway.loads = false;
        gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
        async.flushMicrotasks();
        gateway
          ..loads = true
          ..loadGate = Completer<void>();
        gate.preload(
          _signedOut,
          source: OneVpnAdLoadSource.disconnect,
          tunnelDown: () => true,
        );
        async.flushMicrotasks();
        gateway.calls.clear();

        bool? proceeded;
        unawaited(
          gate
              .beforeConnect(_signedOut, switching: true)
              .then((value) => proceeded = value),
        );
        async.elapse(gate.switchLoadWait - const Duration(milliseconds: 1));
        expect(proceeded, isNull);
        async.elapse(const Duration(milliseconds: 1));

        expect(proceeded, isTrue);
        // Neither request starts a second load while the held load runs on.
        expect(gateway.calls, ['preload', 'wait', 'preload']);
        expect(gateway.sources.last, OneVpnAdLoadSource.tap);
        expect(gateway.isReady, isFalse);
      });
    });

    test('a no-fill within the wait proceeds with no ad and starts the '
        "tap's load", () async {
      await heldLoad(loads: false);
      bool? proceeded;
      unawaited(
        gate
            .beforeConnect(_signedOut, switching: true)
            .then((value) => proceeded = value),
      );
      await _drain();
      expect(proceeded, isNull);

      gateway.loadGate!.complete();
      await _drain();
      await _drain();

      expect(proceeded, isTrue);
      expect(gateway.calls, ['preload', 'wait', 'preload']);
      expect(gateway.sources.last, OneVpnAdLoadSource.tap);
    });

    test('a cached ad shows with no wait', () async {
      await pastFirstConnect();
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      gateway.calls.clear();

      expect(await gate.beforeConnect(_signedOut, switching: true), isTrue);
      expect(gateway.calls, ['show']);
    });

    for (final allows in [true, false]) {
      test('a switch while ads are not allowed waits on no load, with a form '
          'that ${allows ? 'allows' : 'refuses'}', () async {
        await pastFirstConnect();
        gateway
          ..allowAds = false
          ..formAllows = allows;

        expect(await gate.beforeConnect(_signedOut, switching: true), isTrue);
        await _drain();

        // A refusing form also stands for the inert gateway off Android.
        expect(gateway.calls, ['form', 'privacy']);
      });
    }

    test('a tap never waits on the load in flight', () async {
      await heldLoad();

      expect(await gate.beforeConnect(_signedOut), isTrue);
      await _drain();

      expect(gateway.calls, ['preload']);
      expect(gateway.sources.last, OneVpnAdLoadSource.tap);
      gateway.loadGate!.complete();
    });

    test('the wait is five seconds', () {
      expect(gate.switchLoadWait, const Duration(seconds: 5));
    });
  });

  test('rule 6: a closed ad proceeds and starts no load', () async {
    await pastFirstConnect();
    // The update has allowed ads and cached one, as on screen entry.
    gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
    await _drain();
    gateway.calls.clear();
    gateway.showGate = Completer<void>();

    var proceeded = false;
    unawaited(
      gate.beforeConnect(_signedOut).then((value) => proceeded = value),
    );
    await _drain();
    // The connect waits on the showing ad.
    expect(gateway.calls, ['show']);
    expect(proceeded, isFalse);

    gateway.showGate!.complete();
    await _drain();
    await _drain();

    expect(proceeded, isTrue);
    expect(gateway.calls, ['show']);
    expect(gateway.isReady, isFalse);
  });

  group('rule 6: a switch shows only while the app is in front', () {
    /// Allows ads and caches one, as on screen entry.
    Future<void> adCached() async {
      await pastFirstConnect();
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      gateway.calls.clear();
    }

    test('a switch out of front proceeds with no show and keeps the ad for '
        'the next tap', () async {
      await adCached();
      inFront = false;

      expect(await gate.beforeConnect(_signedOut, switching: true), isTrue);
      expect(gateway.calls, isEmpty);
      expect(gateway.isReady, isTrue);

      inFront = true;
      expect(await gate.beforeConnect(_signedOut), isTrue);
      expect(gateway.calls, ['show']);
    });

    test('a switch in front shows', () async {
      await adCached();

      expect(await gate.beforeConnect(_signedOut, switching: true), isTrue);
      expect(gateway.calls, ['show']);
    });

    for (final (atSwitch, atLoad) in [(true, false), (false, true)]) {
      test('the check reads when the load lands: a switch '
          '${atSwitch ? 'in' : 'out of'} front whose load lands '
          '${atLoad ? 'in' : 'out of'} front shows '
          '${atLoad ? 'the ad' : 'no ad'}', () async {
        await pastFirstConnect();
        gateway.loads = false;
        gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
        await _drain();
        gateway
          ..loads = true
          ..loadGate = Completer<void>();
        gateway.calls.clear();
        inFront = atSwitch;

        bool? proceeded;
        unawaited(
          gate
              .beforeConnect(_signedOut, switching: true)
              .then((value) => proceeded = value),
        );
        await _drain();
        expect(gateway.calls, ['preload', 'wait']);
        expect(proceeded, isNull);

        inFront = atLoad;
        gateway.loadGate!.complete();
        await _drain();
        await _drain();

        expect(proceeded, isTrue);
        expect(gateway.calls, ['preload', 'wait', if (atLoad) 'show']);
        expect(gateway.isReady, !atLoad);
      });
    }

    test('a tap out of front shows as before', () async {
      await adCached();
      inFront = false;

      expect(await gate.beforeConnect(_signedOut), isTrue);
      expect(gateway.calls, ['show']);
    });
  });

  test('rule 7: a failed show cancels the connect', () async {
    await pastFirstConnect();
    gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
    await _drain();
    gateway
      ..calls.clear()
      ..showResult = OneVpnAdShowResult.failed;

    expect(await gate.beforeConnect(_signedOut), isFalse);
    await _drain();

    expect(gateway.calls, ['show']);
  });

  test('rule 7: a failed show cancels a switch too', () async {
    await pastFirstConnect();
    gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
    await _drain();
    gateway
      ..calls.clear()
      ..showResult = OneVpnAdShowResult.failed;

    expect(await gate.beforeConnect(_signedOut, switching: true), isFalse);
    await _drain();

    expect(gateway.calls, ['show']);
  });

  group('rule 8: preloads', () {
    test('a free preload loads an ad', () async {
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();

      expect(gateway.count('preload'), 1);
      expect(gateway.isReady, isTrue);
    });

    test('a disconnect preload after a closed ad caches the next ad', () async {
      await pastFirstConnect();
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      expect(await gate.beforeConnect(_signedOut), isTrue);
      await _drain();
      expect(gateway.isReady, isFalse);
      gateway.calls.clear();

      // Disconnect.
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      expect(gateway.calls, ['preload']);
      expect(gateway.isReady, isTrue);
      expect(await gate.beforeConnect(_signedOut), isTrue);
      expect(gateway.calls.last, 'show');
    });

    test('exempt states are premium, pending premium and restoring', () {
      expect(
        OneVpnConnectAdGate.exempts(const OneVpnAccountRestoring()),
        isTrue,
      );
      expect(
        OneVpnConnectAdGate.exempts(
          OneVpnAccountSignedIn(_session(premium: true)),
        ),
        isTrue,
      );
      expect(
        OneVpnConnectAdGate.exempts(
          OneVpnAccountSignedIn(_session(pendingSince: DateTime.utc(2026))),
        ),
        isTrue,
      );
      expect(OneVpnConnectAdGate.exempts(_signedOut), isFalse);
      expect(
        OneVpnConnectAdGate.exempts(OneVpnAccountSignedIn(_session())),
        isFalse,
      );
    });

    test('a premium preload starts nothing', () async {
      gate.preload(
        OneVpnAccountSignedIn(_session(premium: true)),
        source: _entry,
        tunnelDown: () => true,
      );
      await _drain();

      expect(gateway.calls, isEmpty);
    });
  });

  group('rule 9: the consent information update', () {
    test(
      'the update runs before the first preload, once, with no form',
      () async {
        gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
        gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
        await _drain();
        gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
        await _drain();

        expect(gateway.calls.first, 'update');
        expect(gateway.count('update'), 1);
        expect(gateway.calls.indexOf('preload'), greaterThan(0));
        expect(gateway.calls, isNot(contains('form')));
      },
    );

    test('an update that does not allow ads loads nothing', () async {
      gateway.allowAds = false;

      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();

      expect(gateway.calls, isNot(contains('preload')));
      expect(gateway.calls, isNot(contains('form')));
    });

    test('a failed update reruns on the next preload', () async {
      gateway.updateError = StateError('offline');

      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      expect(gateway.calls, isNot(contains('preload')));

      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();

      expect(gateway.count('update'), 2);
      expect(gateway.count('preload'), 1);
      expect(gateway.calls, isNot(contains('form')));
    });

    test('the privacy options entry follows the update', () async {
      gateway
        ..privacyRequired = true
        ..allowAds = false;
      expect(gate.privacyOptionsRequired.value, isFalse);

      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();

      expect(gate.privacyOptionsRequired.value, isTrue);
      expect(gateway.calls, isNot(contains('form')));
      await gate.showPrivacyOptions();
      expect(gateway.calls.last, 'privacyForm');

      gateway.privacyRequired = false;
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      expect(gate.privacyOptionsRequired.value, isFalse);
    });
  });

  group('rule 10: network waits', () {
    test('a tap with ads allowed never waits on a pending update', () async {
      await pastFirstConnect();
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      // Ads are allowed. A later update is never started, so none is pending.
      gateway
        ..updateGate = Completer<void>()
        ..calls.clear();
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);

      expect(await gate.beforeConnect(_signedOut), isTrue);
      await _drain();
      expect(gateway.calls, isNot(contains('update')));
      expect(gateway.calls, isNot(contains('form')));
      expect(gateway.calls.first, 'preload');
      expect(gateway.calls, contains('show'));
    });

    test('a first tap never waits on a pending update', () async {
      gateway
        ..allowAds = false
        ..updateGate = Completer<void>();
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();

      expect(await gate.beforeConnect(_signedOut), isTrue);
      expect(gateway.calls, ['update']);

      gateway.updateGate!.complete();
    });
  });

  group('a preference store that throws', () {
    /// Installs a store that fails as configured. A cached ad waits.
    Future<void> failing({required bool read, required bool write}) async {
      SharedPreferencesAsyncPlatform.instance = _FailingPreferences(
        readThrows: read,
        writeThrows: write,
      );
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      await _drain();
      expect(gateway.isReady, isTrue);
      gateway.calls.clear();
    }

    test('on read and write proceeds as the first connect', () async {
      await failing(read: true, write: true);

      expect(await gate.beforeConnect(_signedOut), isTrue);
      expect(gateway.calls, isEmpty);
    });

    test('on read alone proceeds as the first connect, with no ad and no '
        'form', () async {
      await failing(read: true, write: false);

      expect(await gate.beforeConnect(_signedOut), isTrue);
      expect(gateway.calls, isEmpty);
    });

    test('on write alone proceeds as the first connect', () async {
      await failing(read: false, write: true);

      expect(await gate.beforeConnect(_signedOut), isTrue);
      expect(gateway.calls, isEmpty);
    });
  });

  group('the pending update bound', () {
    test('a tap past the bound proceeds with no ad and no form, and the '
        'update runs on', () {
      fakeAsync((async) {
        gateway
          ..allowAds = false
          ..updateGate = Completer<void>();
        unawaited(pastFirstConnect());
        async.flushMicrotasks();
        var down = true;
        gate.preload(_signedOut, source: _entry, tunnelDown: () => down);
        async.flushMicrotasks();

        bool? proceeded;
        unawaited(
          gate.beforeConnect(_signedOut).then((value) => proceeded = value),
        );
        async.elapse(gate.pendingUpdateWait - const Duration(seconds: 1));
        expect(proceeded, isNull);
        async.elapse(const Duration(seconds: 1));
        expect(proceeded, isTrue);
        expect(gateway.calls, ['update']);

        // The connect brings the tunnel up. The update lands later, runs the
        // privacy read, and starts no load.
        down = false;
        gateway.allowAds = true;
        gateway.updateGate!.complete();
        async.flushMicrotasks();
        expect(gateway.calls, ['update', 'privacy']);
      });
    });

    test('an update that lands after a first-connect tap brought the tunnel '
        'up starts no load', () async {
      gateway.updateGate = Completer<void>();
      var down = true;
      gate.preload(_signedOut, source: _entry, tunnelDown: () => down);
      await _drain();

      expect(await gate.beforeConnect(_signedOut), isTrue);
      down = false;
      gateway.updateGate!.complete();
      await _drain();
      await _drain();

      expect(gateway.calls, ['update', 'privacy']);
      expect(gateway.isReady, isFalse);
    });

    test('the bound is five seconds', () {
      expect(gate.pendingUpdateWait, const Duration(seconds: 5));
    });
  });

  group('rule 8: the tunnel', () {
    test('a preload while the tunnel is up starts nothing', () async {
      gate.preload(_signedOut, source: _entry, tunnelDown: () => false);
      await _drain();

      expect(gateway.calls, isEmpty);
      expect(gateway.isReady, isFalse);
    });
  });

  group('rule 11: a resume during a show', () {
    /// Caches an ad past the first connect and holds the next show open.
    void cachedAndHeld(FakeAsync async) {
      unawaited(pastFirstConnect());
      gate.preload(_signedOut, source: _entry, tunnelDown: () => true);
      async.flushMicrotasks();
      gateway
        ..calls.clear()
        ..showGate = Completer<void>();
    }

    test('a show open past the grace ends as abandoned and cancels, and the '
        'next tap runs fresh', () {
      fakeAsync((async) {
        cachedAndHeld(async);
        bool? proceeded;
        unawaited(
          gate.beforeConnect(_signedOut).then((value) => proceeded = value),
        );
        async.flushMicrotasks();
        expect(gateway.calls, ['show']);

        gate.onAppResumed();
        async.elapse(gate.resumeGrace - const Duration(milliseconds: 1));
        expect(proceeded, isNull);
        async.elapse(const Duration(milliseconds: 1));

        expect(proceeded, isFalse);
        expect(gateway.calls, ['show', 'abandon']);
        expect(gateway.showsSettled, 1);

        // Rule 5: no ad is cached, so the fresh tap starts a load and
        // proceeds.
        gateway
          ..calls.clear()
          ..showGate = null;
        bool? next;
        unawaited(gate.beforeConnect(_signedOut).then((value) => next = value));
        async.flushMicrotasks();
        expect(next, isTrue);
        expect(gateway.calls, ['preload']);

        // Rule 6: the tap after it shows the cached ad.
        gateway.calls.clear();
        unawaited(gate.beforeConnect(_signedOut).then((value) => next = value));
        async.flushMicrotasks();
        expect(next, isTrue);
        expect(gateway.calls, ['show']);
      });
    });

    test('a close within the grace proceeds and abandons nothing', () {
      fakeAsync((async) {
        cachedAndHeld(async);
        bool? proceeded;
        unawaited(
          gate.beforeConnect(_signedOut).then((value) => proceeded = value),
        );
        async.flushMicrotasks();

        gate.onAppResumed();
        async.elapse(const Duration(milliseconds: 500));
        gateway.showGate!.complete();
        async.flushMicrotasks();
        async.elapse(gate.resumeGrace);

        expect(proceeded, isTrue);
        expect(gateway.calls, ['show']);
      });
    });

    test('a close before the resume proceeds and abandons nothing', () {
      fakeAsync((async) {
        cachedAndHeld(async);
        bool? proceeded;
        unawaited(
          gate.beforeConnect(_signedOut).then((value) => proceeded = value),
        );
        async.flushMicrotasks();
        gateway.showGate!.complete();
        async.flushMicrotasks();

        gate.onAppResumed();
        async.elapse(gate.resumeGrace * 2);

        expect(proceeded, isTrue);
        expect(gateway.calls, ['show']);
      });
    });

    test('a resume with no show in flight does nothing', () {
      fakeAsync((async) {
        cachedAndHeld(async);
        gate.onAppResumed();
        async.elapse(gate.resumeGrace * 2);
        expect(gateway.calls, isEmpty);

        // A later show is not abandoned by the earlier resume.
        bool? proceeded;
        unawaited(
          gate.beforeConnect(_signedOut).then((value) => proceeded = value),
        );
        async.elapse(gate.resumeGrace * 2);
        expect(proceeded, isNull);
        gateway.showGate!.complete();
        async.flushMicrotasks();
        expect(proceeded, isTrue);
        expect(gateway.calls, ['show']);
      });
    });

    test('a close after the abandon settles the show once', () {
      fakeAsync((async) {
        cachedAndHeld(async);
        final results = <bool>[];
        unawaited(gate.beforeConnect(_signedOut).then(results.add));
        async.flushMicrotasks();
        gate.onAppResumed();
        async.elapse(gate.resumeGrace);
        expect(results, [false]);

        gateway.showGate!.complete();
        async.flushMicrotasks();
        async.elapse(gate.resumeGrace);

        expect(results, [false]);
        expect(gateway.showsSettled, 1);
        expect(gateway.calls, ['show', 'abandon']);
      });
    });

    test('an abandon the gateway cannot honour waits on the close', () {
      fakeAsync((async) {
        cachedAndHeld(async);
        gateway.abandonEndsShow = false;
        bool? proceeded;
        unawaited(
          gate.beforeConnect(_signedOut).then((value) => proceeded = value),
        );
        async.flushMicrotasks();
        gate.onAppResumed();
        async.elapse(gate.resumeGrace);

        // The gateway had nothing to abandon. The show settles on its close.
        expect(gateway.calls, ['show', 'abandon']);
        expect(proceeded, isNull);
        gateway.showGate!.complete();
        async.flushMicrotasks();
        expect(proceeded, isTrue);
      });
    });

    test('an app hidden inside the grace cancels it', () {
      fakeAsync((async) {
        cachedAndHeld(async);
        bool? proceeded;
        unawaited(
          gate.beforeConnect(_signedOut).then((value) => proceeded = value),
        );
        async.flushMicrotasks();

        gate.onAppResumed();
        async.elapse(const Duration(seconds: 1));
        gate.onAppHidden();
        async.elapse(gate.resumeGrace * 2);
        expect(proceeded, isNull);
        expect(gateway.calls, ['show']);

        // The user closes the ad they returned to.
        gateway.showGate!.complete();
        async.flushMicrotasks();
        expect(proceeded, isTrue);
      });
    });

    test('a second resume inside the grace does not restart it', () {
      fakeAsync((async) {
        cachedAndHeld(async);
        bool? proceeded;
        unawaited(
          gate.beforeConnect(_signedOut).then((value) => proceeded = value),
        );
        async.flushMicrotasks();

        gate.onAppResumed();
        async.elapse(const Duration(seconds: 2));
        gate.onAppResumed();
        async.elapse(gate.resumeGrace - const Duration(seconds: 2));

        expect(proceeded, isFalse);
        expect(gateway.calls, ['show', 'abandon']);
      });
    });

    test('a tap inside the grace abandons at once', () {
      fakeAsync((async) {
        cachedAndHeld(async);
        bool? proceeded;
        unawaited(
          gate.beforeConnect(_signedOut).then((value) => proceeded = value),
        );
        async.flushMicrotasks();

        gate.onAppResumed();
        async.elapse(const Duration(milliseconds: 500));
        expect(gate.abandonOnTap(), isTrue);
        async.flushMicrotasks();
        expect(proceeded, isFalse);

        async.elapse(gate.resumeGrace * 2);
        expect(gateway.calls, ['show', 'abandon']);
      });
    });

    test('a tap with no grace running abandons nothing', () {
      fakeAsync((async) {
        cachedAndHeld(async);
        expect(gate.abandonOnTap(), isFalse);

        bool? proceeded;
        unawaited(
          gate.beforeConnect(_signedOut).then((value) => proceeded = value),
        );
        async.flushMicrotasks();
        expect(gate.abandonOnTap(), isFalse);
        gateway.showGate!.complete();
        async.flushMicrotasks();

        expect(proceeded, isTrue);
        expect(gateway.calls, ['show']);
      });
    });

    for (final switching in [true, false]) {
      test('a ${switching ? 'switch' : 'tap'} whose show the user leaves, '
          'abandoned after the return, '
          '${switching ? 'proceeds' : 'cancels'} with no second show and no '
          'load', () {
        fakeAsync((async) {
          cachedAndHeld(async);
          bool? proceeded;
          unawaited(
            gate
                .beforeConnect(_signedOut, switching: switching)
                .then((value) => proceeded = value),
          );
          async.flushMicrotasks();
          expect(gateway.calls, ['show']);

          // Home while the ad shows. No grace runs while the app is away.
          gate.onAppHidden();
          async.elapse(const Duration(seconds: 30));
          expect(proceeded, isNull);

          // The launcher brings the app back without the ad.
          gate.onAppResumed();
          async.elapse(gate.resumeGrace);

          expect(proceeded, switching);
          expect(gateway.calls, ['show', 'abandon']);
          expect(gateway.showsSettled, 1);
        });
      });
    }

    test('the grace is three seconds', () {
      expect(gate.resumeGrace, const Duration(seconds: 3));
    });
  });
}
