import 'secret_payload.dart';
import 'secret_type.dart';

/// Um item do cofre, já **decifrado**, como visto pela camada de domínio/UI.
///
/// Só existe em memória com o cofre destravado. A persistência guarda o
/// [payload] cifrado; a fronteira do repositório faz cifra/decifra.
class Secret {
  const Secret({
    required this.id,
    required this.type,
    required this.title,
    required this.payload,
    required this.createdAt,
    required this.updatedAt,
    this.categoryId,
    this.isFavorite = false,
    this.iconRef,
    this.tags = const <String>[],
    this.deletedAt,
  });

  final String id;
  final SecretType type;
  final String title;
  final SecretPayload payload;
  final String? categoryId;
  final bool isFavorite;
  final String? iconRef;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Null = ativo; preenchido = na lixeira desde a data indicada.
  final DateTime? deletedAt;

  bool get isInTrash => deletedAt != null;
}

/// Dados de entrada para criar/atualizar um segredo (sem id/timestamps —
/// atribuídos pelo repositório).
class SecretDraft {
  const SecretDraft({
    required this.type,
    required this.title,
    required this.payload,
    this.categoryId,
    this.isFavorite = false,
    this.iconRef,
    this.tags = const <String>[],
  });

  final SecretType type;
  final String title;
  final SecretPayload payload;
  final String? categoryId;
  final bool isFavorite;
  final String? iconRef;
  final List<String> tags;
}

/// Snapshot de histórico de um segredo (payload já decifrado).
class SecretVersionSnapshot {
  const SecretVersionSnapshot({
    required this.id,
    required this.secretId,
    required this.title,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String secretId;
  final String title;
  final SecretPayload payload;
  final DateTime createdAt;
}
