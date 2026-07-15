import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // O plugin cryptography_flutter registra as implementações nativas de
  // criptografia (AES-GCM, Argon2id etc.) automaticamente, com fallback
  // para Dart puro quando não houver suporte nativo.
  runApp(const ProviderScope(child: NoxPassApp()));
}
