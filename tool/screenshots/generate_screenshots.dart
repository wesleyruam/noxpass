@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/features/authentication/presentation/pages/splash_page.dart';
import 'package:noxpass/features/generator/presentation/password_generator_sheet.dart';
import 'package:noxpass/features/security/presentation/pages/security_report_page.dart';
import 'package:noxpass/features/vault/data/vault_providers.dart';
import 'package:noxpass/features/vault/domain/entities/category.dart';
import 'package:noxpass/features/vault/domain/entities/secret.dart';
import 'package:noxpass/features/vault/domain/entities/secret_payload.dart';
import 'package:noxpass/features/vault/domain/entities/secret_type.dart';
import 'package:noxpass/features/vault/domain/repositories/secrets_repository.dart';
import 'package:noxpass/features/vault/presentation/pages/categories_page.dart';
import 'package:noxpass/features/vault/presentation/pages/home_page.dart';
import 'package:noxpass/features/vault/presentation/widgets/secret_detail_sheet.dart';
import 'package:noxpass/shared/theme/app_theme.dart';

// Gera as screenshots do README com DADOS FICTÍCIOS, 100% headless (golden
// tests). Rode com: flutter test --update-goldens --tags screenshots
//   test/screenshots/screenshot_test.dart
// Os PNGs saem em test/screenshots/goldens/.

const _date = _FixedDate();

/// Tela do dispositivo simulado (iPhone-ish), dpr 3.
const Size _logicalSize = Size(390, 844);

/// Tema dark do app, mas com a família 'Roboto' forçada nos estilos de texto
/// dos botões — no golden, o texto dos botões ignorava a família ambiente e
/// virava caixas. Fora do teste, isso não é necessário.
ThemeData _screenshotTheme({bool light = false}) {
  final base = light ? AppTheme.light() : AppTheme.dark();
  TextStyle w(double? size) =>
      TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w600, fontSize: size);
  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style
          ?.copyWith(textStyle: WidgetStatePropertyAll(w(15))),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style
          ?.copyWith(textStyle: WidgetStatePropertyAll(w(null))),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style
          ?.copyWith(textStyle: WidgetStatePropertyAll(w(null))),
    ),
  );
}

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  setUpAll(() async {
    // Fontes reais do sistema para o texto renderizar (sem elas, viram caixas).
    // Um único peso por família evita ambiguidade de matching (o peso extra
    // fazia o texto dos botões, pedido em w600, virar caixas); o negrito é
    // sintetizado quando necessário.
    await _loadFont('Roboto', '/usr/share/fonts/TTF/DejaVuSans.ttf');
    await _loadFont(
        'DejaVu Sans Mono', '/usr/share/fonts/TTF/DejaVuSansMono.ttf');
    // Fonte dos ícones Material (sem ela, os ícones viram quadrados).
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
        '/home/wesleyruan/development/flutter';
    await _loadFont(
      'MaterialIcons',
      '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget child, {
    List<Override> overrides = const [],
    bool light = false,
  }) async {
    tester.view.physicalSize = _logicalSize * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: _screenshotTheme(light: light),
          home: child,
        ),
      ),
    );
    // Deixa streams/estado assentarem sem pumpAndSettle (há timers infinitos).
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    // Garante que micro-animações (anel de saúde ~900ms, crossfade da lista)
    // terminem antes de capturar o estado final.
    await tester.pump(const Duration(milliseconds: 1000));
  }

  Future<void> capture(WidgetTester tester, String name) async {
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/$name.png'),
    );
  }

  final repoOverride =
      secretsRepositoryProvider.overrideWithValue(_DemoRepository());

  testWidgets('splash', (tester) async {
    await pumpScreen(tester, const SplashPage());
    await tester.pump(const Duration(milliseconds: 4200));
    await tester.pump(const Duration(milliseconds: 1000));
    await capture(tester, 'splash');
  });

  testWidgets('home', (tester) async {
    await pumpScreen(tester, const HomePage(), overrides: [repoOverride]);
    await capture(tester, 'home');
  });

  testWidgets('home_light', (tester) async {
    await pumpScreen(tester, const HomePage(),
        overrides: [repoOverride], light: true);
    await capture(tester, 'home_light');
  });

  testWidgets('security', (tester) async {
    await pumpScreen(tester, const SecurityReportPage(),
        overrides: [repoOverride]);
    await capture(tester, 'security');
  });

  testWidgets('categories', (tester) async {
    await pumpScreen(tester, const CategoriesPage(), overrides: [repoOverride]);
    await capture(tester, 'categories');
  });

  testWidgets('detail', (tester) async {
    await pumpScreen(
      tester,
      _SheetHost(child: SecretDetailSheet(secret: _demoSecrets.first)),
      overrides: [repoOverride],
    );
    await capture(tester, 'detail');
  });

  testWidgets('generator', (tester) async {
    await pumpScreen(
      tester,
      const _SheetHost(child: PasswordGeneratorSheet()),
      overrides: [repoOverride],
    );
    await capture(tester, 'generator');
  });
}

/// Emula visualmente uma folha modal: conteúdo ancorado embaixo, com pegador,
/// sobre um leve scrim.
class _SheetHost extends StatelessWidget {
  const _SheetHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E15),
      body: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: Color(0x88000000))),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(26)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A3A4A),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Flexible(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Dados fictícios --------------------------------------------------------

const _catSites = 'c-sites';
const _catBancos = 'c-bancos';
const _catDev = 'c-dev';
const _catEmail = 'c-email';

final List<Category> _demoCategories = [
  const Category(id: _catSites, name: 'Sites', icon: 'public', sortOrder: 0),
  const Category(
      id: _catBancos, name: 'Bancos', icon: 'account_balance', sortOrder: 1),
  const Category(id: _catEmail, name: 'E-mail', icon: 'mail', sortOrder: 2),
  const Category(
      id: _catDev, name: 'Desenvolvimento', icon: 'code', sortOrder: 3),
];

Secret _secret(
  String id,
  SecretType type,
  String title,
  Map<String, String> payload, {
  String? categoryId,
  bool favorite = false,
  List<String> tags = const [],
}) {
  return Secret(
    id: id,
    type: type,
    title: title,
    payload: SecretPayload(payload),
    categoryId: categoryId,
    isFavorite: favorite,
    tags: tags,
    createdAt: _date.value,
    updatedAt: _date.value,
  );
}

final List<Secret> _demoSecrets = [
  _secret(
    's-gh',
    SecretType.appPassword,
    'GitHub',
    {
      SecretPayload.username: 'wesley@dev',
      SecretPayload.password: 'g7\$Kp2!mZ9xQwv',
      SecretPayload.url: 'https://github.com',
      SecretPayload.totp: 'JBSWY3DPEHPK3PXP',
    },
    categoryId: _catDev,
    favorite: true,
    tags: ['trabalho', 'dev'],
  ),
  _secret(
    's-gmail',
    SecretType.password,
    'Gmail',
    {
      SecretPayload.username: 'wesley.ruam@gmail.com',
      SecretPayload.password: 'F5r#tYb8LmN2pQ',
      SecretPayload.totp: 'JBSWY3DPEHPK3PXP',
    },
    categoryId: _catEmail,
    tags: ['pessoal'],
  ),
  _secret(
    's-nubank',
    SecretType.bankAccount,
    'Nubank',
    {
      SecretPayload.username: 'conta 4821',
      SecretPayload.password: 'Xk9\$vRn2Tqz7Ha',
    },
    categoryId: _catBancos,
    favorite: true,
  ),
  _secret(
    's-server',
    SecretType.ssh,
    'Servidor de produção',
    {
      SecretPayload.username: 'root@10.0.0.4',
      SecretPayload.password: '123456',
    },
    categoryId: _catDev,
    tags: ['infra'],
  ),
  _secret(
    's-reddit',
    SecretType.password,
    'Reddit',
    {
      SecretPayload.username: 'wesley',
      SecretPayload.password: 'password',
      SecretPayload.url: 'https://reddit.com',
    },
    categoryId: _catSites,
  ),
  _secret(
    's-twitter',
    SecretType.password,
    'Twitter',
    {
      SecretPayload.username: 'wesley',
      SecretPayload.password: 'password',
      SecretPayload.url: 'https://twitter.com',
    },
    categoryId: _catSites,
  ),
];

class _FixedDate {
  const _FixedDate();
  DateTime get value => DateTime(2026, 7, 1, 9, 30);
}

/// Repositório fictício em memória para as screenshots. Só os métodos usados
/// pelas telas capturadas são implementados; os demais não são chamados.
class _DemoRepository implements SecretsRepository {
  @override
  Stream<List<Secret>> watchActive() => Stream.value(_demoSecrets);

  @override
  Future<List<Secret>> getActive({String? query}) async => _demoSecrets;

  @override
  Future<List<Secret>> getFavorites() async =>
      _demoSecrets.where((s) => s.isFavorite).toList();

  @override
  Stream<List<Category>> watchCategories() => Stream.value(_demoCategories);

  @override
  Future<Secret?> getById(String id) async =>
      _demoSecrets.firstWhere((s) => s.id == id);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} não usado no demo');
}
