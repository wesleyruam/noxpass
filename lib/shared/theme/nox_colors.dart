import 'package:flutter/material.dart';

/// Tokens de cor do NoxPass que o [ColorScheme] do Material não cobre
/// (superfícies em camadas, bordas, texto esmaecido e cores semânticas).
///
/// Exposta como [ThemeExtension] para acompanhar claro/escuro e o `lerp` das
/// animações de tema. Consuma via `context.nox`.
@immutable
class NoxColors extends ThemeExtension<NoxColors> {
  const NoxColors({
    required this.surface2,
    required this.surface3,
    required this.border,
    required this.textDim,
    required this.textFaint,
    required this.accentStrong,
    required this.warn,
    required this.ok,
  });

  /// Segunda camada de superfície (campos, trilhos).
  final Color surface2;

  /// Terceira camada (chips de fundo, trilhas de progresso).
  final Color surface3;

  /// Cor de borda hairline dos cartões e campos.
  final Color border;

  /// Texto secundário.
  final Color textDim;

  /// Texto terciário / metadados.
  final Color textFaint;

  /// Variante mais forte do acento (gradientes, estados pressionados).
  final Color accentStrong;

  /// Semântico: atenção (reutilizadas, força média).
  final Color warn;

  /// Semântico: ok (senhas fortes).
  final Color ok;

  static const NoxColors _dark = NoxColors(
    surface2: Color(0xFF1E1E2A),
    surface3: Color(0xFF262634),
    border: Color(0xFF2A2A3A),
    textDim: Color(0xFF9A9AAE),
    textFaint: Color(0xFF6C6C80),
    accentStrong: Color(0xFF7C6CF6),
    warn: Color(0xFFE8A860),
    ok: Color(0xFF57C99A),
  );

  static const NoxColors _light = NoxColors(
    surface2: Color(0xFFFAFAFE),
    surface3: Color(0xFFF0F0F7),
    border: Color(0xFFE6E6F0),
    textDim: Color(0xFF5B5B70),
    textFaint: Color(0xFF8A8AA0),
    accentStrong: Color(0xFF574AC7),
    warn: Color(0xFFC0803A),
    ok: Color(0xFF2FA878),
  );

  static NoxColors of(Brightness brightness) =>
      brightness == Brightness.dark ? _dark : _light;

  @override
  NoxColors copyWith({
    Color? surface2,
    Color? surface3,
    Color? border,
    Color? textDim,
    Color? textFaint,
    Color? accentStrong,
    Color? warn,
    Color? ok,
  }) {
    return NoxColors(
      surface2: surface2 ?? this.surface2,
      surface3: surface3 ?? this.surface3,
      border: border ?? this.border,
      textDim: textDim ?? this.textDim,
      textFaint: textFaint ?? this.textFaint,
      accentStrong: accentStrong ?? this.accentStrong,
      warn: warn ?? this.warn,
      ok: ok ?? this.ok,
    );
  }

  @override
  NoxColors lerp(ThemeExtension<NoxColors>? other, double t) {
    if (other is! NoxColors) return this;
    return NoxColors(
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      border: Color.lerp(border, other.border, t)!,
      textDim: Color.lerp(textDim, other.textDim, t)!,
      textFaint: Color.lerp(textFaint, other.textFaint, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      warn: Color.lerp(warn, other.warn, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
    );
  }
}

/// Açúcar sintático para ler os tokens estendidos e a fonte monoespaçada.
extension NoxThemeX on BuildContext {
  /// Tokens de cor estendidos do NoxPass.
  NoxColors get nox => Theme.of(this).extension<NoxColors>()!;

  /// Estilo monoespaçado para segredos, códigos e metadados técnicos.
  ///
  /// Usa a família monoespaçada de cada plataforma (sem empacotar fontes).
  TextStyle mono({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamilyFallback: const [
        'RobotoMono',
        'DejaVu Sans Mono',
        'Menlo',
        'Consolas',
        'Courier New',
        'monospace',
      ],
      fontFeatures: const [FontFeature.tabularFigures()],
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }
}

/// Paleta curada para os "tiles" de inicial dos segredos.
///
/// A cor é escolhida de forma estável a partir do título, então o mesmo item
/// mantém sempre a mesma cor entre sessões. Todas têm contraste suficiente
/// para texto branco.
abstract final class NoxTilePalette {
  static const List<Color> _colors = [
    Color(0xFF7A2BF5), // violeta
    Color(0xFFC7452F), // vermelho tijolo
    Color(0xFF2E9E6B), // verde
    Color(0xFFE08A2B), // âmbar
    Color(0xFF2B6BE0), // azul
    Color(0xFF33384A), // grafite
    Color(0xFF1E2530), // ardósia
    Color(0xFFB0338A), // magenta
  ];

  static Color forSeed(String seed) {
    if (seed.isEmpty) return _colors.last;
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _colors[hash % _colors.length];
  }

  /// Iniciais de até 2 letras para o tile (ex.: "GitHub" -> "GH").
  static String initials(String title) {
    final words = title.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) {
      final w = words.first;
      return (w.length >= 2 ? w.substring(0, 2) : w).toUpperCase();
    }
    return (words.first[0] + words.elementAt(1)[0]).toUpperCase();
  }
}
