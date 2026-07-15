import 'package:flutter/material.dart';

import '../../domain/entities/secret_type.dart';

/// Ícone Material representativo de cada [SecretType].
IconData iconForSecretType(SecretType type) => switch (type) {
      SecretType.password => Icons.password,
      SecretType.appPassword => Icons.apps,
      SecretType.bankAccount => Icons.account_balance,
      SecretType.card => Icons.credit_card,
      SecretType.wifi => Icons.wifi,
      SecretType.ssh => Icons.terminal,
      SecretType.gpg => Icons.vpn_key,
      SecretType.apiToken => Icons.api,
      SecretType.license => Icons.workspace_premium,
      SecretType.certificate => Icons.verified_user,
      SecretType.recoveryCodes => Icons.confirmation_number,
      SecretType.privateKey => Icons.key,
      SecretType.secureNote => Icons.sticky_note_2,
      SecretType.identity => Icons.badge,
      SecretType.document => Icons.description,
      SecretType.custom => Icons.category,
    };

/// Rótulo amigável (pt-BR) de cada [SecretType], para exibição na UI.
String labelForSecretType(SecretType type) => switch (type) {
      SecretType.password => 'Senha',
      SecretType.appPassword => 'Senha de aplicativo',
      SecretType.bankAccount => 'Conta bancária',
      SecretType.card => 'Cartão',
      SecretType.wifi => 'Wi-Fi',
      SecretType.ssh => 'Acesso SSH',
      SecretType.gpg => 'Chave GPG',
      SecretType.apiToken => 'Token de API',
      SecretType.license => 'Licença',
      SecretType.certificate => 'Certificado',
      SecretType.recoveryCodes => 'Códigos de recuperação',
      SecretType.privateKey => 'Chave privada',
      SecretType.secureNote => 'Nota segura',
      SecretType.identity => 'Identidade',
      SecretType.document => 'Documento',
      SecretType.custom => 'Personalizado',
    };

/// Descrição curta do que cada tipo guarda, exibida no seletor.
String descriptionForSecretType(SecretType type) => switch (type) {
      SecretType.password => 'Login de site ou serviço',
      SecretType.appPassword => 'Senha específica de um app',
      SecretType.bankAccount => 'Dados de conta e agência',
      SecretType.card => 'Cartão de crédito ou débito',
      SecretType.wifi => 'Rede e senha do Wi-Fi',
      SecretType.ssh => 'Credenciais de servidor',
      SecretType.gpg => 'Chave de criptografia GPG',
      SecretType.apiToken => 'Chave de acesso a API',
      SecretType.license => 'Chave de software',
      SecretType.certificate => 'Certificado digital',
      SecretType.recoveryCodes => 'Códigos de backup 2FA',
      SecretType.privateKey => 'Chave privada genérica',
      SecretType.secureNote => 'Texto livre protegido',
      SecretType.identity => 'Documento de identidade',
      SecretType.document => 'Outro documento sensível',
      SecretType.custom => 'Qualquer outro segredo',
    };
