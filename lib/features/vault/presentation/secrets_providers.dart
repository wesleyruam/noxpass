import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/vault_providers.dart';
import '../domain/entities/category.dart';
import '../domain/entities/secret.dart';

/// Fluxo reativo dos segredos ativos do cofre destravado.
///
/// `autoDispose`: quando o cofre trava e ninguém observa, o stream é liberado.
final secretsListProvider = StreamProvider.autoDispose<List<Secret>>((ref) {
  final repository = ref.watch(secretsRepositoryProvider);
  return repository.watchActive();
});

/// Itens na lixeira (carregados sob demanda; invalidar após restaurar/apagar).
final trashProvider = FutureProvider.autoDispose<List<Secret>>((ref) {
  return ref.watch(secretsRepositoryProvider).getTrash();
});

/// Fluxo reativo das categorias do cofre.
final categoriesProvider = StreamProvider.autoDispose<List<Category>>((ref) {
  return ref.watch(secretsRepositoryProvider).watchCategories();
});
