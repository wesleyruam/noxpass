import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/features/totp/domain/totp.dart';

void main() {
  const generator = TotpGenerator();

  DateTime atEpoch(int seconds) =>
      DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

  TotpConfig config(String asciiSeed, TotpAlgorithm algo) => TotpConfig(
        secret: Uint8List.fromList(utf8.encode(asciiSeed)),
        digits: 8,
        period: 30,
        algorithm: algo,
      );

  group('TOTP — vetores oficiais da RFC 6238', () {
    // Apêndice B da RFC 6238 (8 dígitos).
    const sha1 = '12345678901234567890';
    const sha256 = '12345678901234567890123456789012';
    const sha512 =
        '1234567890123456789012345678901234567890123456789012345678901234';

    final cases = <(int, TotpAlgorithm, String, String)>[
      (59, TotpAlgorithm.sha1, sha1, '94287082'),
      (1111111109, TotpAlgorithm.sha1, sha1, '07081804'),
      (1111111111, TotpAlgorithm.sha1, sha1, '14050471'),
      (1234567890, TotpAlgorithm.sha1, sha1, '89005924'),
      (2000000000, TotpAlgorithm.sha1, sha1, '69279037'),
      (20000000000, TotpAlgorithm.sha1, sha1, '65353130'),
      (59, TotpAlgorithm.sha256, sha256, '46119246'),
      (59, TotpAlgorithm.sha512, sha512, '90693936'),
    ];

    for (final (time, algo, seed, expected) in cases) {
      test('T=$time ${algo.name} => $expected', () async {
        final code = await generator.generate(config(seed, algo), at: atEpoch(time));
        expect(code, expected);
      });
    }
  });

  group('secondsRemaining', () {
    test('reflete a posição dentro do período de 30s', () {
      final c = TotpConfig(secret: Uint8List(20));
      expect(generator.secondsRemaining(c, at: atEpoch(0)), 30);
      expect(generator.secondsRemaining(c, at: atEpoch(10)), 20);
      expect(generator.secondsRemaining(c, at: atEpoch(29)), 1);
    });
  });

  group('base32Decode', () {
    test('decodifica corretamente (vetor RFC 4648)', () {
      expect(utf8.decode(base32Decode('MZXW6YTBOI')), 'foobar');
    });

    test('ignora espaços e caixa', () {
      expect(base32Decode('mzxw 6ytb oi'), base32Decode('MZXW6YTBOI'));
    });

    test('rejeita caracteres inválidos', () {
      expect(() => base32Decode('MZXW6!!!'), throwsFormatException);
    });
  });

  group('TotpConfig.tryParse', () {
    test('aceita segredo Base32', () {
      final c = TotpConfig.tryParse('JBSWY3DPEHPK3PXP');
      expect(c, isNotNull);
      expect(c!.digits, 6);
      expect(c.period, 30);
    });

    test('interpreta otpauth:// com parâmetros', () {
      final c = TotpConfig.tryParse(
        'otpauth://totp/GitHub:wesley?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&digits=8&period=60&algorithm=SHA256',
      );
      expect(c, isNotNull);
      expect(c!.issuer, 'GitHub');
      expect(c.label, 'GitHub:wesley');
      expect(c.digits, 8);
      expect(c.period, 60);
      expect(c.algorithm, TotpAlgorithm.sha256);
    });

    test('devolve null para entrada inválida', () {
      expect(TotpConfig.tryParse('não é totp !!!'), isNull);
      expect(TotpConfig.tryParse(''), isNull);
    });

    test('gera um código de 6 dígitos a partir de um segredo Base32', () async {
      final c = TotpConfig.tryParse('JBSWY3DPEHPK3PXP')!;
      final code = await generator.generate(c, at: atEpoch(1000));
      expect(code, hasLength(6));
      expect(int.tryParse(code), isNotNull);
    });
  });
}
