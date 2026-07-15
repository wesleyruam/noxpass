import '../entities/secret.dart';

/// Contrato de persistência dos segredos.
///
/// Trabalha sempre com entidades **decifradas** — a cifra/decifra por campo é
/// detalhe de implementação da camada de dados, invisível para o domínio.
abstract interface class SecretsRepository {
  /// Cria um novo segredo e o retorna já com id/timestamps.
  Future<Secret> create(SecretDraft draft);

  /// Atualiza um segredo existente, gerando um snapshot de histórico da versão
  /// anterior. Retorna a versão atualizada.
  Future<Secret> update(String id, SecretDraft draft);

  Future<Secret?> getById(String id);

  /// Segredos ativos (fora da lixeira), opcionalmente filtrados por [query]
  /// (busca no título), ordenados por atualização mais recente.
  Future<List<Secret>> getActive({String? query});

  /// Fluxo reativo dos segredos ativos (para a UI se atualizar sozinha).
  Stream<List<Secret>> watchActive();

  Future<List<Secret>> getFavorites();

  Future<void> setFavorite(String id, {required bool value});

  /// Move para a lixeira (soft delete).
  Future<void> moveToTrash(String id);

  /// Restaura um item da lixeira.
  Future<void> restore(String id);

  Future<List<Secret>> getTrash();

  /// Remove definitivamente um item (cascateia tags e histórico).
  Future<void> deletePermanently(String id);

  /// Apaga em definitivo os itens cuja permanência na lixeira excedeu
  /// [retention] (padrão: 30 dias). Retorna a quantidade removida.
  Future<int> purgeExpiredTrash({Duration retention});

  /// Histórico de um segredo, do mais recente ao mais antigo.
  Future<List<SecretVersionSnapshot>> getVersions(String secretId);
}
