/// Falhas do subsistema de criptografia.
///
/// São exceções tipadas para que camadas superiores possam distinguir, por
/// exemplo, "senha mestra incorreta" de "dado corrompido" sem inspecionar
/// strings. Nenhuma delas carrega material sensível (senha/chave/plaintext).
sealed class CryptoFailure implements Exception {
  const CryptoFailure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// A verificação de integridade (MAC do AES-GCM) falhou.
///
/// Indica senha mestra incorreta, dado adulterado ou corrompido. Não é
/// possível — nem seguro — diferenciar essas causas aqui.
final class AuthenticationFailure extends CryptoFailure {
  const AuthenticationFailure([super.message = 'Falha de autenticação/integridade.']);
}

/// Um payload cifrado está malformado (tamanho/estrutura inválidos).
final class MalformedCiphertextFailure extends CryptoFailure {
  const MalformedCiphertextFailure([super.message = 'Ciphertext malformado.']);
}

/// Parâmetros de entrada inválidos (ex.: tamanho de chave incorreto).
final class InvalidCryptoInputFailure extends CryptoFailure {
  const InvalidCryptoInputFailure(super.message);
}
