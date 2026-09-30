import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_provider_starter/main.dart';
import 'package:flutter_provider_starter/services/storage_service.dart';

void main() {
  testWidgets('TaskFlowApp smoke test renders SplashScreen and branding', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storageService = await StorageService.init();

    await tester.pumpWidget(TaskFlowApp(storageService: storageService));

    // SplashScreen renders initially
    expect(find.text('TaskFlow'), findsOneWidget);
    expect(find.text('Organize your work. Stay on track.'), findsOneWidget);

    // Advance timer for session check splash screen
    await tester.pumpAndSettle();

    // Routes to LoginScreen when unauthenticated
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Email Address'), findsOneWidget);
  });
}
