// Pins the fork token architecture. Colors and hand-built corners route
// through the token layer. brand.dart is the one reference tier a widget
// never imports. color.dart carries no fork edit.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// [source] with whole-line // comments and /* */ blocks stripped, so a
/// commented example cannot satisfy or trip a pin.
String _stripComments(String source) => source
    .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
    .replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');

/// Every fork Dart file, path-normalized and sorted.
List<({String path, String source})> _forkFiles() {
  final files = <({String path, String source})>[];
  for (final entity in Directory('lib/onevpn').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    files.add((
      path: entity.path.replaceAll(r'\', '/'),
      source: entity.readAsStringSync(),
    ));
  }
  files.sort((a, b) => a.path.compareTo(b.path));
  return files;
}

const _sha256K = [
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, //
  0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
  0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
  0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
  0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
  0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
  0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
  0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
  0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
];

/// The SHA-256 digest of [message] as lowercase hex. It matches
/// `shasum -a 256`, so an upstream sync recomputes the pin from a shell.
String _sha256Hex(List<int> message) {
  const mask = 0xFFFFFFFF;
  int rotr(int x, int n) => ((x >> n) | (x << (32 - n))) & mask;

  final bitLength = message.length * 8;
  final padded = [...message, 0x80];
  while (padded.length % 64 != 56) {
    padded.add(0);
  }
  for (var shift = 56; shift >= 0; shift -= 8) {
    padded.add((bitLength >> shift) & 0xFF);
  }

  final h = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, //
    0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
  ];
  final w = List<int>.filled(64, 0);
  for (var chunk = 0; chunk < padded.length; chunk += 64) {
    for (var i = 0; i < 16; i++) {
      final j = chunk + i * 4;
      w[i] =
          (padded[j] << 24) |
          (padded[j + 1] << 16) |
          (padded[j + 2] << 8) |
          padded[j + 3];
    }
    for (var i = 16; i < 64; i++) {
      final s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3);
      final s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = (w[i - 16] + s0 + w[i - 7] + s1) & mask;
    }
    var a = h[0], b = h[1], c = h[2], d = h[3];
    var e = h[4], f = h[5], g = h[6], hh = h[7];
    for (var i = 0; i < 64; i++) {
      final s1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25);
      final ch = (e & f) ^ (~e & mask & g);
      final t1 = (hh + s1 + ch + _sha256K[i] + w[i]) & mask;
      final s0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22);
      final maj = (a & b) ^ (a & c) ^ (b & c);
      final t2 = (s0 + maj) & mask;
      hh = g;
      g = f;
      f = e;
      e = (d + t1) & mask;
      d = c;
      c = b;
      b = a;
      a = (t1 + t2) & mask;
    }
    for (final (i, v) in [a, b, c, d, e, f, g, hh].indexed) {
      h[i] = (h[i] + v) & mask;
    }
  }
  return h.map((v) => v.toRadixString(16).padLeft(8, '0')).join();
}

const _brandPath = 'lib/onevpn/theme/brand.dart';
const _palettesPath = 'lib/onevpn/theme/palettes.dart';
const _colorDartPath = 'lib/pages/theme/color.dart';

void main() {
  test(
    'brand.dart is the only fork file with bare color or radius literals',
    () {
      final files = _forkFiles();
      expect(files, isNotEmpty);
      expect(files.any((f) => f.path == _brandPath), isTrue);

      final offenders = <String>[];
      for (final file in files) {
        if (file.path == _brandPath) continue;
        final source = _stripComments(file.source);
        if (source.contains('Color(0x')) {
          offenders.add('${file.path}: a bare Color(0x..) literal');
        }
        if (RegExp(r'BorderRadius\.circular\(\s*\d').hasMatch(source)) {
          offenders.add('${file.path}: a bare-number BorderRadius.circular');
        }
      }
      expect(offenders, isEmpty, reason: offenders.join('\n'));
    },
  );

  test('brand.dart holds the literals the pin exempts', () {
    final brand = _stripComments(File(_brandPath).readAsStringSync());
    expect(brand, contains('Color(0x'));
  });

  test('no fork widget imports brand.dart or palettes.dart', () {
    final offenders = <String>[];
    for (final file in _forkFiles()) {
      if (file.path.contains('lib/onevpn/theme/')) continue;
      if (file.source.contains('onevpn/theme/brand.dart')) {
        offenders.add('${file.path} imports brand.dart');
      }
      if (file.source.contains('onevpn/theme/palettes.dart')) {
        offenders.add('${file.path} imports palettes.dart');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));

    // The exemption covers a live import: the palette layer reads the
    // reference tier.
    expect(
      File(_palettesPath).readAsStringSync(),
      contains('onevpn/theme/brand.dart'),
    );
  });

  group('color.dart carries no fork edit', () {
    test('the brand blue never leaks into the upstream palette', () {
      final source = File(_colorDartPath).readAsStringSync();
      expect(source, isNot(contains('0xFF106CD5')));
      expect(source, isNot(contains('onevpn')));
    });

    test('the upstream primary values stand unedited', () {
      final source = File(_colorDartPath).readAsStringSync();
      expect(source, contains('primary: Color(0xFF1F6AF9)'));
      expect(source, contains('primary: Color(0xFF69A5FF)'));
    });

    test('the source stays byte-identical to the pinned upstream', () {
      // Bump only on a genuine upstream sync. A fork edit never moves it.
      const upstreamSha256 =
          '211fee6f17b1292a49983f8248b4c171774ac4711301bbfe9af1a23ae0b27e72';
      expect(
        _sha256Hex(File(_colorDartPath).readAsBytesSync()),
        upstreamSha256,
        reason: 'color.dart differs from the pinned upstream bytes.',
      );
    });

    test('the digest matches the FIPS 180-4 test vectors', () {
      expect(
        _sha256Hex(const []),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(
        _sha256Hex('abc'.codeUnits),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
      expect(
        _sha256Hex(
          'abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'.codeUnits,
        ),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
    });
  });
}
