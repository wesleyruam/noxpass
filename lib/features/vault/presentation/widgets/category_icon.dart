import 'package:flutter/material.dart';

/// Mapeia o nome de ícone persistido de uma categoria para um [IconData].
///
/// Um mapa explícito (em vez de lookup dinâmico) mantém o tree-shaking de
/// ícones do Flutter funcionando. Cobre os ícones das categorias nativas
/// (ver `kBuiltInCategories`) com fallback para uma pasta.
IconData categoryIconFor(String? name) {
  switch (name) {
    case 'public':
      return Icons.public;
    case 'account_balance':
      return Icons.account_balance;
    case 'group':
      return Icons.group;
    case 'mail':
      return Icons.mail_outline;
    case 'code':
      return Icons.code;
    case 'terminal':
      return Icons.terminal;
    case 'api':
      return Icons.api;
    case 'dns':
      return Icons.dns;
    case 'credit_card':
      return Icons.credit_card;
    case 'wifi':
      return Icons.wifi;
    case 'description':
      return Icons.description;
    case 'badge':
      return Icons.badge;
    case 'apps':
      return Icons.apps;
    case 'category':
      return Icons.category;
    default:
      return Icons.folder_outlined;
  }
}
