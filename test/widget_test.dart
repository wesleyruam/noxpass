import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/app.dart';
import 'package:noxpass/core/crypto/vault_key_material.dart';
import 'package:noxpass/features/authentication/data/auth_data_providers.dart';
import 'package:noxpass/features/authentication/data/vault_material_store.dart';

/// Sem material salvo: o app deve levar ao cadastro da senha mestra.
class _EmptyMaterialStore implements VaultMaterialStore {
  @override
  Future<void> clear() async {}
  @override
  Future<bool> exists() async => false;
  @override
  Future<VaultKeyMaterial?> read() async => null;
  @override
  Future<void> write(VaultKeyMaterial material) async {}
}

void main() {
  testWidgets('primeiro uso roteia da splash para a criação do cofre',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vaultMaterialStoreProvider.overrideWithValue(_EmptyMaterialStore()),
        ],
        child: const NoxPassApp(),
      ),
    );

    // Deixa a verificação assíncrona resolver e o redirecionamento ocorrer
    // (evita pumpAndSettle por causa do spinner infinito da splash).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Defina sua senha mestra'), findsOneWidget);
    expect(find.text('Criar cofre'), findsWidgets);
  });
}
