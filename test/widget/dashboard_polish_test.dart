import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_provider_starter/models/task.dart';
import 'package:flutter_provider_starter/providers/auth_provider.dart';
import 'package:flutter_provider_starter/providers/task_provider.dart';
import 'package:flutter_provider_starter/providers/theme_provider.dart';
import 'package:flutter_provider_starter/screens/dashboard_screen.dart';
import 'package:flutter_provider_starter/screens/main_navigation_screen.dart';
import 'package:flutter_provider_starter/services/auth_service.dart';
import 'package:flutter_provider_starter/services/task_service.dart';

class FakeTaskService extends TaskService {
  List<Task> tasksToReturn;
  FakeTaskService({this.tasksToReturn = const []});

  @override
  Future<List<Task>> fetchTasks({required String token}) async {
    return tasksToReturn;
  }
}

void main() {
  late AuthService authService;
  late FakeTaskService fakeTaskService;
  late AuthProvider authProvider;
  late TaskProvider taskProvider;

  setUp(() {
    authService = AuthService();
    fakeTaskService = FakeTaskService();
    authProvider = AuthProvider(authService);
    taskProvider = TaskProvider(fakeTaskService);
  });

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('Dashboard renders personalized greeting, subtitle, and compact stat cards',
      (WidgetTester tester) async {
    fakeTaskService.tasksToReturn = [
      Task(
        id: '1',
        title: 'Complete Flutter Project',
        description: 'Finish polish',
        completed: false,
        priority: TaskPriority.high,
      ),
    ];

    await tester.pumpWidget(
      createTestWidget(
        DashboardScreen(onNavigateToTasks: () {}),
      ),
    );
    await tester.pumpAndSettle();

    // Verify personalized header
    expect(find.textContaining('Aaron 👋'), findsOneWidget);
    expect(find.text("Here's what's happening with your tasks today."), findsOneWidget);

    // Verify statistics cards
    expect(find.text('Total Tasks'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('High Priority'), findsOneWidget);

    // Verify Recent Tasks section and View All
    expect(find.text('Recent Tasks'), findsOneWidget);
    expect(find.text('View All'), findsOneWidget);
  });

  testWidgets('Dashboard renders empty state when tasks list is empty', (WidgetTester tester) async {
    fakeTaskService.tasksToReturn = [];

    await tester.pumpWidget(
      createTestWidget(
        DashboardScreen(onNavigateToTasks: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No tasks yet'), findsOneWidget);
    expect(
      find.text('Create your first task and start getting organized.'),
      findsOneWidget,
    );
    expect(find.text('Create Task'), findsOneWidget);
  });

  testWidgets('Dashboard renders at most 3 recent tasks when multiple tasks exist',
      (WidgetTester tester) async {
    fakeTaskService.tasksToReturn = [
      Task(id: '1', title: 'Task 1', description: 'Desc 1', priority: TaskPriority.low),
      Task(id: '2', title: 'Task 2', description: 'Desc 2', priority: TaskPriority.medium),
      Task(id: '3', title: 'Task 3', description: 'Desc 3', priority: TaskPriority.high),
      Task(id: '4', title: 'Task 4', description: 'Desc 4', priority: TaskPriority.medium),
      Task(id: '5', title: 'Task 5', description: 'Desc 5', priority: TaskPriority.low),
    ];

    await tester.pumpWidget(
      createTestWidget(
        DashboardScreen(onNavigateToTasks: () {}),
      ),
    );
    await tester.pumpAndSettle();

    // Should find the first 3 recent tasks
    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('Task 3'), findsOneWidget);
    // Task 4 and 5 should not be displayed in the 3 recent tasks
    expect(find.text('Task 4'), findsNothing);
    expect(find.text('Task 5'), findsNothing);
  });

  group('Responsive Layout Testing across resolutions', () {
    const resolutions = [
      Size(1920, 1080),
      Size(1440, 900),
      Size(1024, 768),
      Size(768, 1024),
      Size(390, 844),
    ];

    for (final size in resolutions) {
      testWidgets('Renders MainNavigationScreen cleanly at ${size.width}x${size.height}',
          (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestWidget(const MainNavigationScreen()),
        );
        await tester.pumpAndSettle();

        // No overflow errors
        expect(tester.takeException(), isNull);

        // Verify navigation destinations exist
        expect(find.text('Home'), findsWidgets);
        expect(find.text('Tasks'), findsWidgets);
        expect(find.text('Profile'), findsWidgets);

        // Verify wide screen uses NavigationRail, mobile uses NavigationBar
        if (size.width >= 720) {
          expect(find.byType(NavigationRail), findsOneWidget);
        } else {
          expect(find.byType(NavigationBar), findsOneWidget);
        }
      });
    }
  });
}
