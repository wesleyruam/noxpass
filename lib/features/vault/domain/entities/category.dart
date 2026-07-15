/// Uma categoria de segredos (bucket nomeado, opcionalmente com ícone/cor).
///
/// Metadado não sensível — vive em texto puro no banco cifrado, para permitir
/// agrupar e filtrar sem decifrar payloads.
class Category {
  const Category({
    required this.id,
    required this.name,
    this.icon,
    this.colorValue,
    this.isBuiltIn = false,
    this.sortOrder = 0,
  });

  final String id;
  final String name;

  /// Nome de um ícone Material (ver `categoryIconFor`).
  final String? icon;

  /// Cor persistida (ARGB). Quando nula, a UI deriva uma cor do nome.
  final int? colorValue;

  /// Categorias nativas semeadas na criação do cofre não podem ser apagadas.
  final bool isBuiltIn;

  final int sortOrder;
}
