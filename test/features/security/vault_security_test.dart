import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/features/security/domain/vault_security.dart';
import 'package:noxpass/features/vault/domain/entities/secret.dart';
import 'package:noxpass/features/vault/domain/entities/secret_payload.dart';
import 'package:noxpass/features/vault/domain/entities/secret_type.dart';

void main() {
  Secret secret({
    required String id,
    String? password,
    bool favorite = false,
  }) {
    return Secret(
      id: id,
      type: SecretType.password,
      title: id,
      isFavorite: favorite,
      payload: SecretPayload({
        SecretPayload.password: ?password,
      }),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  group('analyzeVault', () {
    test('cofre vazio não tem problemas', () {
      final report = analyzeVault(const []);
      expect(report.total, 0);
      expect(report.hasIssues, isFalse);
    });

    test('detecta senhas fracas', () {
      final report = analyzeVault([
        secret(id: 'a', password: '123'),
        secret(id: 'b', password: r'P@ssw0rd1234567!'),
      ]);
      expect(report.weakCount, 1);
      expect(report.weakSecrets.single.id, 'a');
    });

    test('agrupa senhas reutilizadas', () {
      final report = analyzeVault([
        secret(id: 'a', password: 'reutilizada'),
        secret(id: 'b', password: 'reutilizada'),
        secret(id: 'c', password: 'unica-diferente'),
      ]);
      expect(report.reusedGroups, hasLength(1));
      expect(report.reusedGroups.single.map((s) => s.id), containsAll(['a', 'b']));
      expect(report.reusedCount, 2);
    });

    test('conta favoritos e ignora segredos sem senha', () {
      final report = analyzeVault([
        secret(id: 'a', favorite: true),
        secret(id: 'b', password: r'F0rte#Senha!2026'),
      ]);
      expect(report.favorites, 1);
      expect(report.total, 2);
      expect(report.hasIssues, isFalse);
    });
  });
}
