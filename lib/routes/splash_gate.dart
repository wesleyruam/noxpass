import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Portão da splash animada: `false` enquanto a animação de abertura toca,
/// `true` quando ela termina (ou é pulada). O roteador só deixa a splash
/// depois que este portão abre — assim a animação nunca é cortada.
final splashGateProvider = StateProvider<bool>((ref) => false);
