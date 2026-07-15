import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Algoritmo de hash do TOTP (padrão: SHA-1).
enum TotpAlgorithm {
  sha1,
  sha256,
  sha512;

  static TotpAlgorithm fromName(String name) => switch (name.toUpperCase()) {
        'SHA256' => TotpAlgorithm.sha256,
        'SHA512' => TotpAlgorithm.sha512,
        _ => TotpAlgorithm.sha1,
      };

  MacAlgorithm get hmac => switch (this) {
        TotpAlgorithm.sha1 => Hmac.sha1(),
        TotpAlgorithm.sha256 => Hmac.sha256(),
        TotpAlgorithm.sha512 => Hmac.sha512(),
      };
}

/// Configuração de um gerador TOTP (RFC 6238).
class TotpConfig {
  const TotpConfig({
    required this.secret,
    this.digits = 6,
    this.period = 30,
    this.algorithm = TotpAlgorithm.sha1,
    this.label,
    this.issuer,
  });

  /// Segredo compartilhado já decodificado.
  final Uint8List secret;
  final int digits;
  final int period;
  final TotpAlgorithm algorithm;
  final String? label;
  final String? issuer;

  /// Cria a partir de um segredo em Base32 (formato usado pelos sites).
  factory TotpConfig.fromSecret(
    String base32Secret, {
    int digits = 6,
    int period = 30,
    TotpAlgorithm algorithm = TotpAlgorithm.sha1,
    String? label,
    String? issuer,
  }) {
    return TotpConfig(
      secret: base32Decode(base32Secret),
      digits: digits,
      period: period,
      algorithm: algorithm,
      label: label,
      issuer: issuer,
    );
  }

  /// Interpreta uma URI `otpauth://totp/...`.
  factory TotpConfig.fromOtpauthUri(String uri) {
    final parsed = Uri.parse(uri.trim());
    if (parsed.scheme != 'otpauth' || parsed.host != 'totp') {
      throw const FormatException('URI otpauth inválida.');
    }
    final q = parsed.queryParameters;
    final secret = q['secret'];
    if (secret == null || secret.isEmpty) {
      throw const FormatException('otpauth sem secret.');
    }
    final label = parsed.pathSegments.isNotEmpty
        ? Uri.decodeComponent(parsed.pathSegments.first)
        : null;
    return TotpConfig.fromSecret(
      secret,
      digits: int.tryParse(q['digits'] ?? '') ?? 6,
      period: int.tryParse(q['period'] ?? '') ?? 30,
      algorithm: TotpAlgorithm.fromName(q['algorithm'] ?? 'SHA1'),
      label: label,
      issuer: q['issuer'],
    );
  }

  /// Aceita tanto `otpauth://` quanto um segredo Base32 puro. Devolve `null`
  /// se a entrada não for um TOTP válido.
  static TotpConfig? tryParse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    try {
      if (trimmed.toLowerCase().startsWith('otpauth://')) {
        return TotpConfig.fromOtpauthUri(trimmed);
      }
      return TotpConfig.fromSecret(trimmed);
    } catch (_) {
      return null;
    }
  }
}

/// Gera códigos TOTP/HOTP (RFC 6238 / RFC 4226) — tudo local, sem rede.
class TotpGenerator {
  const TotpGenerator();

  /// Código atual (ou no instante [at]).
  Future<String> generate(TotpConfig config, {DateTime? at}) {
    final seconds = _epochSeconds(at);
    final counter = seconds ~/ config.period;
    return _hotp(config, counter);
  }

  /// Segundos restantes até o código mudar.
  int secondsRemaining(TotpConfig config, {DateTime? at}) {
    final seconds = _epochSeconds(at);
    return config.period - (seconds % config.period);
  }

  int _epochSeconds(DateTime? at) =>
      (at ?? DateTime.now()).toUtc().millisecondsSinceEpoch ~/ 1000;

  Future<String> _hotp(TotpConfig config, int counter) async {
    final counterBytes = Uint8List(8);
    var value = counter;
    for (var i = 7; i >= 0; i--) {
      counterBytes[i] = value & 0xff;
      value >>= 8;
    }

    final mac = await config.algorithm.hmac.calculateMac(
      counterBytes,
      secretKey: SecretKey(config.secret),
    );
    final hash = mac.bytes;

    // Truncamento dinâmico (RFC 4226 §5.3).
    final offset = hash[hash.length - 1] & 0x0f;
    final binary = ((hash[offset] & 0x7f) << 24) |
        ((hash[offset + 1] & 0xff) << 16) |
        ((hash[offset + 2] & 0xff) << 8) |
        (hash[offset + 3] & 0xff);

    final otp = binary % math.pow(10, config.digits).toInt();
    return otp.toString().padLeft(config.digits, '0');
  }
}

/// Decodifica Base32 (RFC 4648), ignorando espaços e padding.
Uint8List base32Decode(String input) {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  final clean = input.toUpperCase().replaceAll(RegExp(r'[\s=]'), '');
  if (clean.isEmpty) throw const FormatException('Base32 vazio.');

  var bits = 0;
  var value = 0;
  final output = <int>[];
  for (final unit in clean.codeUnits) {
    final index = alphabet.indexOf(String.fromCharCode(unit));
    if (index < 0) throw FormatException('Caractere Base32 inválido: $unit');
    value = (value << 5) | index;
    bits += 5;
    if (bits >= 8) {
      output.add((value >> (bits - 8)) & 0xff);
      bits -= 8;
    }
  }
  return Uint8List.fromList(output);
}
