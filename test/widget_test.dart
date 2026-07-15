import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noxpass/app.dart';

void main() {
  testWidgets('app inicializa e mostra a marca NoxPass', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: NoxPassApp()));
    await tester.pumpAndSettle();

    expect(find.text('NoxPass'), findsOneWidget);
    expect(find.text('Sua privacidade. Seu controle. Suas senhas.'), findsOneWidget);
    expect(find.text('Criar cofre'), findsOneWidget);
  });
}
