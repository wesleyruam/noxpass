import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';

/// Categorias nativas do NoxPass, semeadas quando o cofre é criado.
///
/// (nome, ícone Material) — a ordem define `sortOrder`.
const List<(String, String)> kBuiltInCategories = [
  ('Sites', 'public'),
  ('Bancos', 'account_balance'),
  ('Redes Sociais', 'group'),
  ('E-mail', 'mail'),
  ('Desenvolvimento', 'code'),
  ('SSH', 'terminal'),
  ('APIs', 'api'),
  ('Servidores', 'dns'),
  ('Cartões', 'credit_card'),
  ('Wi-Fi', 'wifi'),
  ('Documentos', 'description'),
  ('Identidades', 'badge'),
  ('Softwares', 'apps'),
  ('Outros', 'category'),
];

/// Insere as categorias nativas em um cofre recém-criado.
Future<void> seedBuiltInCategories(
  AppDatabase db, {
  Uuid uuid = const Uuid(),
  DateTime Function() clock = DateTime.now,
}) async {
  final now = clock();
  await db.batch((batch) {
    for (var i = 0; i < kBuiltInCategories.length; i++) {
      final (name, icon) = kBuiltInCategories[i];
      batch.insert(
        db.categories,
        CategoriesCompanion.insert(
          id: uuid.v4(),
          name: name,
          icon: Value(icon),
          isBuiltIn: const Value(true),
          sortOrder: Value(i),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  });
}
