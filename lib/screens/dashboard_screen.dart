import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/stat_card.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback onNavigateToTasks;

  const DashboardScreen({super.key, required this.onNavigateToTasks});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  void _loadTasks() {
    final token = context.read<AuthProvider>().token;
    context.read<TaskProvider>().fetchTasks(token);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final taskProvider = context.watch<TaskProvider>();
    final userName = auth.currentUser?.name ?? 'Aaron';
    final token = auth.token;
    final recentTasks = taskProvider.allTasks.take(3).toList();

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isDesktop = width >= 840;
            final crossAxisCount = isDesktop ? 4 : (width < 340 ? 1 : 2);

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: RefreshIndicator(
                  onRefresh: () async => _loadTasks(),
                  child: CustomScrollView(
                    slivers: [
                      // Header Sliver
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Personalized Greeting Header
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${_getGreeting()}, $userName 👋',
                                          style: theme.textTheme.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Here's what's happening with your tasks today.",
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton.filledTonal(
                                    tooltip: 'Create Task',
                                    icon: const Icon(Icons.add),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const TaskFormScreen(),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Responsive Statistics Grid
                              GridView(
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: 84,
                                ),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  StatCard(
                                    title: 'Total Tasks',
                                    count: taskProvider.totalCount,
                                    icon: Icons.assignment_outlined,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                  StatCard(
                                    title: 'Completed',
                                    count: taskProvider.completedCount,
                                    icon: Icons.check_circle_outline,
                                    color: const Color(0xFF10B981),
                                  ),
                                  StatCard(
                                    title: 'Pending',
                                    count: taskProvider.pendingCount,
                                    icon: Icons.pending_actions_outlined,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                  StatCard(
                                    title: 'High Priority',
                                    count: taskProvider.highPriorityCount,
                                    icon: Icons.priority_high_outlined,
                                    color: const Color(0xFFEF4444),
                                  ),
                                ],
                              ),

                              // Today's Progress Section
                              if (taskProvider.totalCount > 0) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: theme.brightness == Brightness.dark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: theme.brightness == Brightness.dark
                                          ? const Color(0xFF334155)
                                          : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Today's Progress",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: theme.brightness == Brightness.dark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            '${taskProvider.completedCount} of ${taskProvider.totalCount} tasks completed',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: theme.colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: taskProvider.totalCount > 0
                                              ? taskProvider.completedCount / taskProvider.totalCount
                                              : 0.0,
                                          minHeight: 6,
                                          backgroundColor: theme.brightness == Brightness.dark
                                              ? const Color(0xFF334155)
                                              : const Color(0xFFE2E8F0),
                                          color: const Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),

                              // Section Header
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Recent Tasks',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: widget.onNavigateToTasks,
                                    child: const Text('View All'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Content Sliver
                      if (taskProvider.isLoading && taskProvider.allTasks.isEmpty)
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (taskProvider.allTasks.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.task_alt,
                                      size: 56,
                                      color: theme.colorScheme.primary.withAlpha(180),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No tasks yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Create your first task and start getting organized.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 20),
                                  FilledButton.icon(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const TaskFormScreen(),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Create Task'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final task = recentTasks[index];
                                return TaskCard(
                                  task: task,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TaskDetailsScreen(taskId: task.id),
                                      ),
                                    );
                                  },
                                  onToggleComplete: () {
                                    taskProvider.toggleTaskCompletion(token, task);
                                  },
                                );
                              },
                              childCount: recentTasks.length,
                            ),
                          ),
                        ),

                      const SliverToBoxAdapter(
                        child: SizedBox(height: 80),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
