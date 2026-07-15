import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/security/password_strength_meter.dart';
import '../../../generator/domain/password_generator.dart';
import '../../data/vault_providers.dart';
import '../../domain/entities/secret.dart';
import '../../domain/entities/secret_payload.dart';
import '../../domain/entities/secret_type.dart';

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
  late SecretType _type;
  bool _obscure = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _type = s?.type ?? SecretType.password;
    _title = TextEditingController(text: s?.title ?? '');
    _username = TextEditingController(text: s?.payload[SecretPayload.username] ?? '');
    _password = TextEditingController(text: s?.payload[SecretPayload.password] ?? '');
    _url = TextEditingController(text: s?.payload[SecretPayload.url] ?? '');
    _notes = TextEditingController(text: s?.payload[SecretPayload.notes] ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _password.dispose();
    _url.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _generate() {
    final generated = const PasswordGenerator().generate(
      const PasswordGeneratorOptions(),
    );
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
    });
    final draft = SecretDraft(type: _type, title: _title.text.trim(), payload: payload);

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
              Text(
                isEditing ? 'Editar segredo' : 'Novo segredo',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<SecretType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo'),
                items: SecretType.values
                    .map((t) => DropdownMenuItem(value: t, child: Text(t.name)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
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
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  prefixIcon: Icon(Icons.notes),
                ),
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
