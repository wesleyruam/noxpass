import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/core/crypto/crypto_failure.dart';
import 'package:noxpass/core/crypto/kdf_params.dart';
import 'package:noxpass/features/backup/domain/backup_service.dart';
import 'package:noxpass/features/vault/domain/entities/secret.dart';
import 'package:noxpass/features/vault/domain/entities/secret_payload.dart';
import 'package:noxpass/features/vault/domain/entities/secret_type.dart';

void main() {
  final service = BackupService();
  const params = KdfParams.insecureTestOnly;

  Secret sample() => Secret(
        id: 'x',
        type: SecretType.password,
        title: 'GitHub',
        isFavorite: true,
        tags: const ['dev', 'trabalho'],
        payload: const SecretPayload({
          SecretPayload.username: 'wesley',
          SecretPayload.password: 'senha-secreta',
        }),
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

  group('BackupService', () {
    test('round-trip export/import preserva os dados', () async {
      final bytes = await service.export([sample()], 'senha-backup', params: params);
      final drafts = await service.import(bytes, 'senha-backup');

      expect(drafts, hasLength(1));
      final d = drafts.single;
      expect(d.title, 'GitHub');
      expect(d.type, SecretType.password);
      expect(d.isFavorite, isTrue);
      expect(d.tags, containsAll(['dev', 'trabalho']));
      expect(d.payload[SecretPayload.password], 'senha-secreta');
    });

    test('o conteúdo do backup é opaco (não vaza texto puro)', () async {
      final bytes = await service.export([sample()], 'senha-backup', params: params);
      final asText = utf8.decode(bytes);
      expect(asText.contains('senha-secreta'), isFalse);
      expect(asText.contains('wesley'), isFalse);
      // O envelope em si é JSON legível (salt/params não são sensíveis).
      expect(asText.contains('noxpass.backup'), isTrue);
    });

    test('senha de backup incorreta falha a autenticação', () async {
      final bytes = await service.export([sample()], 'certa', params: params);
      expect(
        () => service.import(bytes, 'errada'),
        throwsA(isA<AuthenticationFailure>()),
      );
    });

    test('arquivo malformado é rejeitado', () async {
      final garbage = Uint8List.fromList(utf8.encode('não sou um backup'));
      expect(
        () => service.import(garbage, 'qualquer'),
        throwsA(isA<BackupFormatException>()),
      );
    });
  });
}
