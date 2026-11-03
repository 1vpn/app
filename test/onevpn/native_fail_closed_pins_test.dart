// Pins the native fail-closed hold in the VPN service. A start that fails
// over an established TUN holds that TUN with no core running. The
// failedClosed census fixes where the hold is set, read, and cleared.
// startTun and runTun replace a held TUN only after the new one is up.
// releaseTun clears the hold and is pinned whole with its call sites.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/kotlin_source.dart';

const _servicePath =
    'android/app/src/main/kotlin/net/yuandev/onexray/vpn/OneVpnService.kt';

/// The service's failStart, normalized. An established TUN fails
/// closed: the core stops, the TUN stays up, and the not-running status
/// carries the reason. A stop that ran during the core stop owns the
/// teardown. The hold is therefore set only when the start is still
/// current.
/// Only a start that never established a TUN releases and stops the
/// service.
const _pinnedFailStart =
    r'private fun failStart(message: String, error: Exception, '
    r'generation: Int? = null) '
    r'{ if (generation != null && generation != startGeneration.get()) '
    r'{ XLog.d("$message ignored for stale start generation=$generation") '
    r'XLog.d(error) return } XLog.e(message, error) '
    r'val reason = error.message ?: error.toString() '
    r'if (tunnel != null && !released.get()) '
    r'{ try { stopXray() } catch (e: Exception) '
    r'{ XLog.d("OneVpnService: failStart stopXray exception") XLog.d(e) } '
    r'if ((generation != null && generation != startGeneration.get()) '
    r'|| released.get()) return '
    r'running = false failedClosed = true '
    r'sendStatusBroadcast(false, reason) return } '
    r'if (!releaseTun(reason)) sendStatusBroadcast(false, reason) '
    r'stopSelf() }';

/// The service's startTun, normalized. A held TUN is taken as the one
/// to replace, and the start runs over it without a release. Any start
/// clears the hold flag after it claims the resources, so a stale flag
/// never outlives the next start.
const _pinnedStartTun =
    r'private fun startTun(startId: Int) '
    r'{ XLog.d("OneVpnService: startTun $startId") '
    r'val held = if (failedClosed) tunnel else null '
    r'if (!released.compareAndSet(true, false) && held == null) '
    r'{ XLog.d("OneVpnService: startTun ignored because VPN resources '
    r'are active") return } failedClosed = false '
    r'val generation = startGeneration.incrementAndGet() '
    r'try { showNotification(startId) val model = readStartRequest() '
    r'runTun(model, generation, held) } catch (e: Exception) '
    r'{ failStart("OneVpnService: startTun failed", e, generation) } }';

/// The service's releaseTun, normalized. The tunnel-down hook runs once
/// per release, before the core stops. It clears the hold with the rest
/// of the teardown and always broadcasts.
const _pinnedReleaseTun =
    r'private fun releaseTun(error: String? = null): Boolean '
    r'{ if (!released.compareAndSet(false, true)) { return false } '
    r'OneVpnServiceDelegate.onTunnelDown() '
    r'startGeneration.incrementAndGet() '
    r'XLog.d("OneVpnService: releaseTun") '
    r'stopForeground(STOP_FOREGROUND_REMOVE) try { stopXray() } '
    r'catch (e: Exception) '
    r'{ XLog.d("OneVpnService: releaseTun stopXray exception") XLog.d(e) } '
    r'try { LibXray.resetDNS() } catch (e: Exception) '
    r'{ XLog.d("OneVpnService: releaseTun resetDNS exception") XLog.d(e) } '
    r'try { tunnel?.close() } catch (e: Exception) '
    r'{ XLog.d("OneVpnService: releaseTun close tunnel exception") '
    r'XLog.d(e) } tunnel = null if (controller.vpn === this) controller.vpn = null '
    r'running = false '
    r'failedClosed = false sendStatusBroadcast(false, error) return true }';

/// The releaseTun census, each line paired with the line above it, in
/// file order: onDestroy, stopTun, the declaration, and failStart's
/// release of a start that never established a TUN. A new caller
/// releases the TUN on a path the hold does not know.
const _releaseTunCensus = [
  '} | releaseTun()',
  'OneVpnServiceDelegate.markUserStop(this) | if (!releaseTun()) {',
  '} | private fun releaseTun(error: String? = null): Boolean {',
  '} | if (!releaseTun(reason)) sendStatusBroadcast(false, reason)',
];

/// The failedClosed census, each line paired with the line above it, in
/// file order:
///
/// - the declaration
/// - the status read
/// - the retry-start guard
/// - the start guard
/// - the replacement read in startTun
/// - the clear in startTun
/// - the clear in releaseTun
/// - the one set in failStart
///
/// A held TUN reads disconnected while no core runs. A connect from any
/// view therefore reaches the start that replaces it. A network retry
/// start passes only over a held TUN.
const _failedClosedCensus = [
  '@Volatile | private var failedClosed = false',
  'val status = when { | failedClosed && !running -> VpnStatus.DISCONNECTED',
  'if (intent != null && intent.action == ACTION_START) { | '
      'if (OneVpnServiceDelegate.dropsStart(intent, failedClosed && tunnel != '
      'null)) return START_NOT_STICKY',
  '} | if (!running && (tunnel == null || failedClosed)) {',
  '// A held TUN stays up until runTun establishes its replacement. '
      '| val held = if (failedClosed) tunnel else null',
  '} | failedClosed = false',
  'running = false | failedClosed = false',
  'running = false | failedClosed = true',
];

/// Every line of [path] containing [needle], in file order. Each is
/// paired with its nearest preceding non-blank line as `context | line`,
/// both trimmed.
List<String> _lineCensus(String path, String needle) {
  final lines = File(path).readAsLinesSync();
  final census = <String>[];
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index].trim();
    if (!line.contains(needle)) {
      continue;
    }
    var context = '';
    for (var back = index - 1; back >= 0; back--) {
      final preceding = lines[back].trim();
      if (preceding.isNotEmpty) {
        context = preceding;
        break;
      }
    }
    census.add('$context | $line');
  }
  return census;
}

void main() {
  test('failStart holds an established TUN with no core', () {
    final body = normalizedKotlinMethod(_servicePath, 'private fun failStart(');

    // Anti-vacuity guard. The hold branch returns before the release.
    final hold = body.indexOf('failedClosed = true');
    expect(hold, isNot(-1));
    expect(hold, lessThan(body.indexOf('releaseTun(reason)')));

    expect(body, _pinnedFailStart);
  });

  test('the held TUN state is set, read, and cleared at the census', () {
    expect(_lineCensus(_servicePath, 'failedClosed'), _failedClosedCensus);
  });

  test('startTun replaces a held TUN and clears a stale hold', () {
    final body = normalizedKotlinMethod(_servicePath, 'private fun startTun(');

    // Anti-vacuity guard. The flag clears after the claim, before work.
    final claim = body.indexOf('released.compareAndSet(true, false)');
    final clear = body.indexOf('failedClosed = false');
    expect(claim, isNot(-1));
    expect(claim, lessThan(clear));
    expect(clear, lessThan(body.indexOf('runTun(')));

    expect(body, _pinnedStartTun);
  });

  test('runTun closes a held TUN only after establish', () {
    final body = normalizedKotlinMethod(_servicePath, 'private fun runTun(');

    final establish = body.indexOf('builder.establish()');
    expect(establish, isNot(-1));
    expect(establish, lessThan(body.indexOf('held?.close()')));
  });

  test('releaseTun performs exactly the pinned statements', () {
    final body = normalizedKotlinMethod(
      _servicePath,
      'private fun releaseTun(',
    );

    // Anti-vacuity guard. The extraction reached the hold clear.
    expect(body, contains('failedClosed = false'));

    expect(body, _pinnedReleaseTun);
  });

  test('releaseTun is declared once and called from exactly the census', () {
    expect(_lineCensus(_servicePath, 'releaseTun('), _releaseTunCensus);
  });
}
