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
