import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/core/crypto/kdf_params.dart';

void main() {
  group('KdfParams', () {
    test('json roundtrip preserva todos os campos', () {
      const original = KdfParams.owaspDefault;
      final restored = KdfParams.fromJson(original.toJson());
      expect(restored, original);
    });

    test('string json roundtrip', () {
      const original = KdfParams(
        memoryBlocks: 32768,
        iterations: 3,
        parallelism: 2,
        hashLength: 32,
      );
      expect(KdfParams.fromJsonString(original.toJsonString()), original);
    });

    test('igualdade por valor', () {
      expect(
        const KdfParams(memoryBlocks: 1, iterations: 1, parallelism: 1, hashLength: 32),
        const KdfParams(memoryBlocks: 1, iterations: 1, parallelism: 1, hashLength: 32),
      );
    });
  });
}
