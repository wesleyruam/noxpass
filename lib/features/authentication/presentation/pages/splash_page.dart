import 'package:flutter/material.dart';

import '../../../../shared/widgets/noxpass_logo.dart';

/// Tela exibida enquanto se verifica se já existe um cofre cadastrado.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NoxPassWordmark(shieldSize: 88),
            SizedBox(height: 40),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
