import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/task_card.dart';
import 'task_details_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refresh() {
    final token = context.read<AuthProvider>().token;
    context.read<TaskProvider>().fetchTasks(token);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = context.watch<TaskProvider>();
    final token = context.read<AuthProvider>().token;
    final filteredTasks = taskProvider.filteredTasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Tasks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Search Field
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => taskProvider.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              taskProvider.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerLowest,
                  ),
                ),
              ),

          // Horizontal Filter Chips (Status & Priority)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: TaskFilter.values.map((filter) {
                final isSelected = taskProvider.selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter.label),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (_) => taskProvider.setFilter(filter),
                  ),
                );
              }).toList(),
            ),
          ),

          // Horizontal Filter Chips (Categories)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: FilterChip(
                    avatar: Icon(
                      Icons.category_outlined,
                      size: 14,
                      color: taskProvider.selectedCategory == null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    label: const Text('All Categories'),
                    selected: taskProvider.selectedCategory == null,
                    showCheckmark: false,
                    onSelected: (_) => taskProvider.setCategoryFilter(null),
                  ),
                ),
                ...TaskCategory.values.map((cat) {
                  final isSelected = taskProvider.selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: FilterChip(
                      label: Text(cat.label),
                      selected: isSelected,
                      showCheckmark: false,
                      onSelected: (_) =>
                          taskProvider.setCategoryFilter(isSelected ? null : cat),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Main Task List / Empty State / Error State
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: Builder(
                builder: (context) {
                  if (taskProvider.isLoading && taskProvider.allTasks.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (taskProvider.errorMessage != null && taskProvider.allTasks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.wifi_off_outlined,
                              size: 48,
                              color: Colors.redAccent,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              taskProvider.errorMessage!,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.tonalIcon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (filteredTasks.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_outlined,
                              size: 56,
                              color: theme.colorScheme.outlineVariant,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No tasks found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              taskProvider.searchQuery.isNotEmpty
                                  ? 'No tasks match "${taskProvider.searchQuery}".'
                                  : 'There are no tasks in this category.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
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
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  ),
  floatingActionButton: FloatingActionButton(
        tooltip: 'Create Task',
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TaskFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
