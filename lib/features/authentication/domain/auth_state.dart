/// Situação do cofre em relação ao acesso.
enum VaultStatus {
  /// Nenhuma senha mestra cadastrada ainda (primeiro uso).
  unregistered,

  /// Cofre existe, porém travado (exige a senha mestra).
  locked,

  /// Cofre destravado — sessão ativa.
  unlocked,
}

/// Estado de autenticação exposto à UI e ao roteador.
class AuthState {
  const AuthState(this.status, {this.error});

  final VaultStatus status;

  /// Mensagem transitória (ex.: "senha incorreta") — não é um erro fatal.
  final String? error;

  bool get isUnlocked => status == VaultStatus.unlocked;

  AuthState copyWith({VaultStatus? status, String? error}) =>
      AuthState(status ?? this.status, error: error);
}
