import 'package:flutter_test/flutter_test.dart';
import 'package:gilda_medical_app/main.dart';
import 'package:provider/provider.dart';
import 'package:gilda_medical_app/services/auth_service.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => AuthService())],
        child: const GildaMedicalApp(),
      ),
    );
    expect(find.byType(GildaMedicalApp), findsOneWidget);
  });
}
