import 'dart:convert';

/// Parâmetros de custo do Argon2id.
///
/// São persistidos junto do cofre (não são sensíveis) para que a mesma chave
/// possa ser re-derivada no desbloqueio, mesmo que os defaults do app mudem
/// em versões futuras.
class KdfParams {
  const KdfParams({
    required this.memoryBlocks,
    required this.iterations,
    required this.parallelism,
    required this.hashLength,
  });

  /// Cria a partir de um mapa persistido. Lança [FormatException] se inválido.
  factory KdfParams.fromJson(Map<String, dynamic> json) {
    return KdfParams(
      memoryBlocks: json['m'] as int,
      iterations: json['t'] as int,
      parallelism: json['p'] as int,
      hashLength: json['len'] as int,
    );
  }

  factory KdfParams.fromJsonString(String source) =>
      KdfParams.fromJson(jsonDecode(source) as Map<String, dynamic>);

  /// Número de blocos de 1 kB de memória (custo de memória do Argon2id).
  final int memoryBlocks;

  /// Número de iterações (custo de tempo).
  final int iterations;

  /// Grau de paralelismo.
  final int parallelism;

  /// Comprimento da chave derivada, em bytes.
  final int hashLength;

  /// Defaults alinhados à recomendação da OWASP (m=19 MiB, t=2, p=1).
  ///
  /// Devem ser recalibrados por benchmark no dispositivo antes de produção.
  static const KdfParams owaspDefault = KdfParams(
    memoryBlocks: 19456,
    iterations: 2,
    parallelism: 1,
    hashLength: 32,
  );

  /// Parâmetros propositalmente baratos — uso exclusivo em testes.
  static const KdfParams insecureTestOnly = KdfParams(
    memoryBlocks: 256,
    iterations: 1,
    parallelism: 1,
    hashLength: 32,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'm': memoryBlocks,
        't': iterations,
        'p': parallelism,
        'len': hashLength,
      };

  String toJsonString() => jsonEncode(toJson());

  @override
  bool operator ==(Object other) =>
      other is KdfParams &&
      other.memoryBlocks == memoryBlocks &&
      other.iterations == iterations &&
      other.parallelism == parallelism &&
      other.hashLength == hashLength;

  @override
  int get hashCode =>
      Object.hash(memoryBlocks, iterations, parallelism, hashLength);
}
