import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/features/backup/domain/restore_plan.dart';
import 'package:noxpass/features/vault/domain/entities/secret.dart';
import 'package:noxpass/features/vault/domain/entities/secret_payload.dart';
import 'package:noxpass/features/vault/domain/entities/secret_type.dart';

Secret _secret(
  String id,
  String title, {
  String username = 'user',
  String password = 'senha',
  SecretType type = SecretType.password,
}) {
  return Secret(
    id: id,
    type: type,
    title: title,
    payload: SecretPayload({
      SecretPayload.username: username,
      SecretPayload.password: password,
    }),
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

SecretDraft _draft(
  String title, {
  String username = 'user',
  String password = 'senha',
  SecretType type = SecretType.password,
}) {
  return SecretDraft(
    type: type,
    title: title,
    payload: SecretPayload({
      SecretPayload.username: username,
      SecretPayload.password: password,
    }),
  );
}

void main() {
  const planner = RestorePlanner();

  group('RestorePlanner.plan', () {
    test('item inexistente é classificado como novo (adicionar)', () {
      final plan = planner.plan([_draft('GitHub')], []);
      expect(plan.addedCount, 1);
      expect(plan.conflictCount, 0);
      expect(plan.items.single.kind, RestoreItemKind.added);
      expect(plan.items.single.resolution, RestoreResolution.duplicate);
    });

    test('mesma chave e mesmo conteúdo é idêntico (ignorar)', () {
      final existing = [_secret('1', 'GitHub')];
      final plan = planner.plan([_draft('GitHub')], existing);
      expect(plan.identicalCount, 1);
      expect(plan.items.single.kind, RestoreItemKind.identical);
      expect(plan.items.single.resolution, RestoreResolution.skip);
    });

    test(
      'mesma chave e conteúdo diferente é conflito (padrão não sobrescreve)',
      () {
        final existing = [_secret('1', 'GitHub', password: 'antiga')];
        final plan = planner.plan([
          _draft('GitHub', password: 'nova'),
        ], existing);
        expect(plan.conflictCount, 1);
        final item = plan.items.single;
        expect(item.kind, RestoreItemKind.conflict);
        expect(item.existing!.id, '1');
        expect(item.resolution, RestoreResolution.duplicate);
      },
    );

    test('a chave ignora maiúsculas e espaços no título/usuário', () {
      final existing = [_secret('1', 'GitHub', username: 'Wesley')];
      final plan = planner.plan([
        _draft('  github ', username: 'wesley '),
      ], existing);
      expect(plan.conflictCount + plan.identicalCount, 1);
      expect(plan.addedCount, 0);
    });

    test('mesmo título mas tipo diferente não colide', () {
      final existing = [_secret('1', 'Cofre', type: SecretType.password)];
      final plan = planner.plan([
        _draft('Cofre', type: SecretType.secureNote),
      ], existing);
      expect(plan.addedCount, 1);
      expect(plan.conflictCount, 0);
    });
  });
}
