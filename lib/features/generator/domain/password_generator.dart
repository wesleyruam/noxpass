import '../../../core/crypto/secure_random.dart';

/// Opções do gerador de senhas.
class PasswordGeneratorOptions {
  const PasswordGeneratorOptions({
    this.length = 20,
    this.useLower = true,
    this.useUpper = true,
    this.useDigits = true,
    this.useSymbols = true,
    this.avoidAmbiguous = false,
  });

  final int length;
  final bool useLower;
  final bool useUpper;
  final bool useDigits;
  final bool useSymbols;

  /// Remove caracteres visualmente ambíguos (0/O, 1/l/I, etc.).
  final bool avoidAmbiguous;

  bool get hasAnyClass => useLower || useUpper || useDigits || useSymbols;

  PasswordGeneratorOptions copyWith({
    int? length,
    bool? useLower,
    bool? useUpper,
    bool? useDigits,
    bool? useSymbols,
    bool? avoidAmbiguous,
  }) {
    return PasswordGeneratorOptions(
      length: length ?? this.length,
      useLower: useLower ?? this.useLower,
      useUpper: useUpper ?? this.useUpper,
      useDigits: useDigits ?? this.useDigits,
      useSymbols: useSymbols ?? this.useSymbols,
      avoidAmbiguous: avoidAmbiguous ?? this.avoidAmbiguous,
    );
  }
}

/// Gera senhas aleatórias usando a CSPRNG do app.
///
/// Simples e determinístico em interface (não em saída): dado o conjunto de
/// classes, sorteia caracteres de forma uniforme e sem viés de módulo.
class PasswordGenerator {
  const PasswordGenerator([this._random = const SecureRandom()]);

  final SecureRandom _random;

  static const String _lower = 'abcdefghijklmnopqrstuvwxyz';
  static const String _upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const String _digits = '0123456789';
  static const String _symbols = '!@#\$%&*()-_=+[]{};:,.?';

  /// Caracteres facilmente confundidos entre si.
  static const String _ambiguous = 'Il1O0o';

  String generate(PasswordGeneratorOptions options) {
    if (!options.hasAnyClass) {
      throw ArgumentError('Selecione ao menos uma classe de caracteres.');
    }
    if (options.length <= 0) {
      throw ArgumentError.value(options.length, 'length', 'deve ser positivo');
    }

    final alphabet = StringBuffer()
      ..write(options.useLower ? _lower : '')
      ..write(options.useUpper ? _upper : '')
      ..write(options.useDigits ? _digits : '')
      ..write(options.useSymbols ? _symbols : '');
    var chars = alphabet.toString();
    if (options.avoidAmbiguous) {
      chars = chars.split('').where((c) => !_ambiguous.contains(c)).join();
    }
    if (chars.isEmpty) {
      throw ArgumentError('Nenhum caractere disponível com essas opções.');
    }

    final buffer = StringBuffer();
    for (var i = 0; i < options.length; i++) {
      buffer.write(chars[_uniformIndex(chars.length)]);
    }
    return buffer.toString();
  }

  /// Índice uniforme em [0, max) sem viés de módulo (rejeição de amostra).
  int _uniformIndex(int max) {
    final limit = 256 - (256 % max);
    while (true) {
      final byte = _random.nextBytes(1)[0];
      if (byte < limit) return byte % max;
    }
  }
}
