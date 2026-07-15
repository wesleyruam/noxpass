import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../routes/splash_gate.dart';
import '../widgets/logo_build_animation.dart';

/// Tela de abertura: toca a animação de construção da logo e, ao final,
/// libera o [splashGateProvider] para o roteador seguir ao cofre.
///
/// Fundo sempre escuro ("Cofre à noite") — é o momento de marca do app.
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  static const Color _bg = Color(0xFF0E0E15);
  bool _showWordmark = false;

  void _onAnimationDone() {
    if (!mounted) return;
    setState(() => _showWordmark = true);
    // Segura um instante com a logo pronta + nome, então libera a navegação.
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) ref.read(splashGateProvider.notifier).state = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LogoBuildAnimation(size: 190, onCompleted: _onAnimationDone),
            const SizedBox(height: 8),
            AnimatedOpacity(
              opacity: _showWordmark ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOut,
              child: const Column(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Nox',
                          style: TextStyle(color: Color(0xFF9B8CFF)),
                        ),
                        TextSpan(
                          text: 'Pass',
                          style: TextStyle(color: Color(0xFFECECF3)),
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'SUA PRIVACIDADE. SEU CONTROLE.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9A9AAE),
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
