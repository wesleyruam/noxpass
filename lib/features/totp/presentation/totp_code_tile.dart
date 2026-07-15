import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/theme/nox_colors.dart';
import '../domain/totp.dart';

/// Exibe o código TOTP atual de um segredo, atualizado a cada segundo, com um
/// anel de contagem regressiva. Não renderiza nada se a chave for inválida.
class TotpCodeTile extends StatefulWidget {
  const TotpCodeTile({required this.rawSecret, this.onCopy, super.key});

  /// Segredo armazenado (Base32 ou `otpauth://`).
  final String rawSecret;
  final void Function(String code)? onCopy;

  @override
  State<TotpCodeTile> createState() => _TotpCodeTileState();
}

class _TotpCodeTileState extends State<TotpCodeTile> {
  static const _generator = TotpGenerator();

  TotpConfig? _config;
  String _code = '';
  int _remaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _config = TotpConfig.tryParse(widget.rawSecret);
    if (_config != null) {
      _refresh();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final config = _config!;
    final code = await _generator.generate(config);
    if (!mounted) return;
    setState(() {
      _code = code;
      _remaining = _generator.secondsRemaining(config);
    });
  }

  /// '123456' -> '123 456' para leitura mais fácil.
  String get _formatted {
    if (_code.length < 6) return _code;
    final mid = _code.length ~/ 2;
    return '${_code.substring(0, mid)} ${_code.substring(mid)}';
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    if (config == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final nox = context.nox;
    final accent = theme.colorScheme.primary;
    // Fica vermelho nos segundos finais para sinalizar a expiração.
    final ringColor = _remaining <= 5 ? theme.colorScheme.error : accent;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: nox.surface2,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: nox.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Código 2FA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: nox.textFaint,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _code.isEmpty ? '——— ———' : _formatted,
                  style: context.mono(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 34,
            height: 34,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _remaining / config.period,
                  strokeWidth: 3,
                  color: ringColor,
                  backgroundColor: nox.surface3,
                ),
                Text(
                  '$_remaining',
                  style: context.mono(fontSize: 11, color: nox.textDim),
                ),
              ],
            ),
          ),
          if (widget.onCopy != null)
            IconButton(
              tooltip: 'Copiar código',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.copy_outlined, size: 20, color: nox.textDim),
              onPressed: _code.isEmpty ? null : () => widget.onCopy!(_code),
            ),
        ],
      ),
    );
  }
}
