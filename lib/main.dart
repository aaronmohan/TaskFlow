import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/storage_service.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'services/thingspeak_service.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/iot_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent storage
  final storageService = await StorageService.init();

  runApp(
    TaskFlowApp(storageService: storageService),
  );
}

class TaskFlowApp extends StatelessWidget {
  final StorageService storageService;

  const TaskFlowApp({super.key, required this.storageService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 1. Service Layer
        Provider<StorageService>.value(value: storageService),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<TaskService>(create: (_) => TaskService()),
        Provider<ThingSpeakService>(create: (_) => ThingSpeakService()),

        // 2. Provider / State Management Layer
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(storageService),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (ctx) => AuthProvider(
            ctx.read<AuthService>(),
            storageService,
          ),
        ),
        ChangeNotifierProvider<TaskProvider>(
          create: (ctx) => TaskProvider(
            ctx.read<TaskService>(),
            storageService,
          ),
        ),
        ChangeNotifierProvider<IoTProvider>(
          create: (ctx) => IoTProvider(
            ctx.read<ThingSpeakService>(),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'TaskFlow',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF4F46E5),
                brightness: Brightness.light,
                surface: Colors.white,
                surfaceContainerLowest: Colors.white,
                surfaceContainerLow: const Color(0xFFF8FAFC),
                surfaceContainer: const Color(0xFFF1F5F9),
                surfaceContainerHigh: const Color(0xFFE2E8F0),
                surfaceContainerHighest: const Color(0xFFCBD5E1),
                onSurface: const Color(0xFF0F172A),
                onSurfaceVariant: const Color(0xFF64748B),
                outline: const Color(0xFFCBD5E1),
                outlineVariant: const Color(0xFFE2E8F0),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Color(0xFFF8FAFC),
                surfaceTintColor: Colors.transparent,
                iconTheme: IconThemeData(color: Color(0xFF0F172A)),
                titleTextStyle: TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Colors.white,
                elevation: 0,
                indicatorColor: const Color(0xFFEEF2FF),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(color: Color(0xFF4F46E5), size: 24);
                  }
                  return const IconThemeData(color: Color(0xFF64748B), size: 24);
                }),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      color: Color(0xFF4F46E5),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    );
                  }
                  return const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  );
                }),
              ),
              navigationRailTheme: const NavigationRailThemeData(
                backgroundColor: Colors.white,
                elevation: 0,
                indicatorColor: Color(0xFFEEF2FF),
                selectedIconTheme: IconThemeData(color: Color(0xFF4F46E5), size: 24),
                unselectedIconTheme: IconThemeData(color: Color(0xFF64748B), size: 24),
                selectedLabelTextStyle: TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                ),
              ),
              chipTheme: ChipThemeData(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
                selectedColor: const Color(0xFFEEF2FF),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                },
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFF0F172A),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6366F1),
                brightness: Brightness.dark,
                surface: const Color(0xFF1E293B),
                surfaceContainerLowest: const Color(0xFF0B1120),
                surfaceContainerLow: const Color(0xFF0F172A),
                surfaceContainer: const Color(0xFF1E293B),
                surfaceContainerHigh: const Color(0xFF334155),
                surfaceContainerHighest: const Color(0xFF475569),
                onSurface: const Color(0xFFF8FAFC),
                onSurfaceVariant: const Color(0xFF94A3B8),
                outline: const Color(0xFF475569),
                outlineVariant: const Color(0xFF334155),
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: false,
                elevation: 0,
                scrolledUnderElevation: 0,
                backgroundColor: Color(0xFF0F172A),
                surfaceTintColor: Colors.transparent,
                iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
                titleTextStyle: TextStyle(
                  color: Color(0xFFF8FAFC),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                ),
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF1E293B),
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFF334155), width: 1),
                ),
              ),
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: const Color(0xFF1E293B),
                elevation: 0,
                indicatorColor: const Color(0xFF312E81),
                iconTheme: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const IconThemeData(color: Color(0xFF818CF8), size: 24);
                  }
                  return const IconThemeData(color: Color(0xFF94A3B8), size: 24);
                }),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      color: Color(0xFF818CF8),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    );
                  }
                  return const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  );
                }),
              ),
              navigationRailTheme: const NavigationRailThemeData(
                backgroundColor: Color(0xFF1E293B),
                elevation: 0,
                indicatorColor: Color(0xFF312E81),
                selectedIconTheme: IconThemeData(color: Color(0xFF818CF8), size: 24),
                unselectedIconTheme: IconThemeData(color: Color(0xFF94A3B8), size: 24),
                selectedLabelTextStyle: TextStyle(
                  color: Color(0xFF818CF8),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF334155)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
                ),
              ),
              chipTheme: ChipThemeData(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                side: const BorderSide(color: Color(0xFF334155)),
                selectedColor: const Color(0xFF312E81),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                },
              ),
            ),
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
