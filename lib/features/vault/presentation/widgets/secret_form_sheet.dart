import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/security/password_strength_meter.dart';
import '../../../../shared/theme/nox_colors.dart';
import '../../../generator/presentation/password_generator_sheet.dart';
import '../../../totp/domain/totp.dart';
import '../../data/vault_providers.dart';
import '../../domain/entities/secret.dart';
import '../../domain/entities/secret_payload.dart';
import '../../domain/entities/secret_type.dart';
import '../secrets_providers.dart';
import 'secret_category_field.dart';
import 'secret_type_field.dart';
import 'tag_editor.dart';

/// Folha (bottom sheet) para criar ou editar um segredo.
///
/// Abra com [show]. Retorna após salvar; a lista se atualiza sozinha via
/// stream.
class SecretFormSheet extends ConsumerStatefulWidget {
  const SecretFormSheet({this.existing, super.key});

  final Secret? existing;

  static Future<void> show(BuildContext context, {Secret? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => SecretFormSheet(existing: existing),
    );
  }

  @override
  ConsumerState<SecretFormSheet> createState() => _SecretFormSheetState();
}

class _SecretFormSheetState extends ConsumerState<SecretFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _url;
  late final TextEditingController _notes;
  late final TextEditingController _totp;
  late SecretType _type;
  late bool _isFavorite;
  late List<String> _tags;
  late String? _categoryId;
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _type = s?.type ?? SecretType.password;
    _isFavorite = s?.isFavorite ?? false;
    _tags = List<String>.from(s?.tags ?? const <String>[]);
    _categoryId = s?.categoryId;
    _title = TextEditingController(text: s?.title ?? '');
    _username = TextEditingController(text: s?.payload[SecretPayload.username] ?? '');
    _password = TextEditingController(text: s?.payload[SecretPayload.password] ?? '');
    _url = TextEditingController(text: s?.payload[SecretPayload.url] ?? '');
    _notes = TextEditingController(text: s?.payload[SecretPayload.notes] ?? '');
    _totp = TextEditingController(text: s?.payload[SecretPayload.totp] ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _password.dispose();
    _url.dispose();
    _notes.dispose();
    _totp.dispose();
    super.dispose();
  }

  /// Tags distintas já usadas no cofre, para sugerir no editor.
  List<String> _tagSuggestions() {
    final secrets = ref.read(secretsListProvider).valueOrNull ?? const [];
    final seen = <String, String>{}; // chave normalizada -> exibição
    for (final secret in secrets) {
      for (final tag in secret.tags) {
        seen.putIfAbsent(tag.toLowerCase(), () => tag);
      }
    }
    final result = seen.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return result;
  }

  Future<void> _generate() async {
    final generated = await PasswordGeneratorSheet.show(context);
    if (generated == null) return;
    setState(() {
      _password.text = generated;
      _obscure = false;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = SecretPayload({
      if (_username.text.isNotEmpty) SecretPayload.username: _username.text,
      if (_password.text.isNotEmpty) SecretPayload.password: _password.text,
      if (_url.text.trim().isNotEmpty) SecretPayload.url: _url.text.trim(),
      if (_notes.text.trim().isNotEmpty) SecretPayload.notes: _notes.text.trim(),
      if (_totp.text.trim().isNotEmpty) SecretPayload.totp: _totp.text.trim(),
    });
    final existing = widget.existing;
    final draft = SecretDraft(
      type: _type,
      title: _title.text.trim(),
      payload: payload,
      isFavorite: _isFavorite,
      tags: _tags,
      categoryId: _categoryId,
      // Preserva campos que ainda não têm UI de edição.
      iconRef: existing?.iconRef,
    );

    try {
      final repo = ref.read(secretsRepositoryProvider);
      if (widget.existing == null) {
        await repo.create(draft);
      } else {
        await repo.update(widget.existing!.id, draft);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Editar segredo' : 'Novo segredo',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: _isFavorite
                        ? 'Remover dos favoritos'
                        : 'Adicionar aos favoritos',
                    onPressed: () => setState(() => _isFavorite = !_isFavorite),
                    icon: Icon(
                      _isFavorite ? Icons.star : Icons.star_border,
                      color: _isFavorite ? context.nox.warn : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SecretTypeField(
                value: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
              const SizedBox(height: 12),
              SecretCategoryField(
                categoryId: _categoryId,
                onChanged: (id) => setState(() => _categoryId = id),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Título',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe um título.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _username,
                decoration: const InputDecoration(
                  labelText: 'Usuário / e-mail',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Gerar senha forte',
                        icon: const Icon(Icons.casino_outlined),
                        onPressed: _generate,
                      ),
                      IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ],
                  ),
                ),
              ),
              if (_password.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                PasswordStrengthMeter(password: _password.text),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _url,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _totp,
                decoration: const InputDecoration(
                  labelText: 'Chave 2FA (TOTP)',
                  helperText: 'Segredo Base32 ou URI otpauth://',
                  prefixIcon: Icon(Icons.timer_outlined),
                ),
                validator: (value) {
                  final v = (value ?? '').trim();
                  if (v.isNotEmpty && TotpConfig.tryParse(v) == null) {
                    return 'Chave 2FA inválida.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  prefixIcon: Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),
              TagEditor(
                tags: _tags,
                suggestions: _tagSuggestions(),
                onChanged: (tags) => setState(() => _tags = tags),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Salvar alterações' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
