import 'package:flutter/material.dart';

import '../../../data/repositories/productivity_repository.dart';
import '../../../models/level.dart';
import '../../core/app_theme.dart';
import '../../core/sign_in_gate.dart';
import '../../levels/view_models/levels_view_models.dart';
import '../../levels/views/level_widgets.dart';
import 'task_catalog.dart';
import 'task_editor.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key, required this.repository});
  final ProductivityRepository repository;

  @override
  Widget build(BuildContext context) => SignInGate(
    repository: repository,
    title: 'Tasks',
    child: TaskBoard(repository: repository),
  );
}

class TaskBoardModel extends AsyncViewModel {
  TaskBoardModel(this.repository);
  final ProductivityRepository repository;
  List<Json> tasks = [], lists = [], tags = [];
  bool loaded = false;
  Future<bool> load() => run(() async {
    final data = await Future.wait([
      repository.all('/tasks'),
      repository.all('/task-lists'),
      repository.all('/tags'),
    ]);
    tasks = data[0];
    lists = data[1];
    tags = data[2];
    loaded = true;
  });
}

bool taskActive(Json task) =>
    ['NOT_STARTED', 'IN_PROGRESS'].contains(task['status']);
bool taskOverdue(Json task) =>
    taskActive(task) &&
    task['dueDate'] != null &&
    (task['dueDate'] as String).compareTo(calendarDate(DateTime.now())) < 0;

class TaskBoard extends StatefulWidget {
  const TaskBoard({super.key, required this.repository});
  final ProductivityRepository repository;
  @override
  State<TaskBoard> createState() => _TaskBoardState();
}

class _TaskBoardState extends State<TaskBoard> {
  String filter = 'Active', query = '', listId = '', tagId = '';
  @override
  Widget build(BuildContext context) => ViewModelBuilder<TaskBoardModel>(
    create: () => TaskBoardModel(widget.repository),
    load: (m) => m.load(),
    builder: (context, model) {
      Future<void> open(Widget page) async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                SessionPage(repository: widget.repository, child: page),
          ),
        );
        if (mounted) await model.load();
      }

      final visible = model.tasks
          .where(
            (task) =>
                (listId.isEmpty || task['listId'] == listId) &&
                (tagId.isEmpty ||
                    (task['tags'] as List).any((tag) => tag['id'] == tagId)) &&
                '${task['title']} ${task['description'] ?? ''}'
                    .toLowerCase()
                    .contains(query.toLowerCase()) &&
                switch (filter) {
                  'Today' =>
                    taskActive(task) &&
                        task['dueDate'] == calendarDate(DateTime.now()),
                  'Active' => taskActive(task),
                  'Overdue' => taskOverdue(task),
                  'Completed' => task['status'] == 'COMPLETED',
                  'Cancelled' => task['status'] == 'CANCELLED',
                  'Archived' => task['status'] == 'ARCHIVED',
                  _ => true,
                },
          )
          .toList();
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tasks'),
          actions: [
            IconButton(
              tooltip: 'Refresh tasks',
              onPressed: model.busy ? null : model.load,
              icon: const Icon(Icons.refresh),
            ),
            PopupMenuButton<String>(
              tooltip: 'Task options',
              onSelected: (value) {
                if (value == 'logout') {
                  widget.repository.signOut();
                } else {
                  open(
                    TaskCatalog(
                      repository: widget.repository,
                      tags: value == 'tags',
                    ),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'lists', child: Text('Manage lists')),
                PopupMenuItem(value: 'tags', child: Text('Manage tags')),
                PopupMenuItem(value: 'logout', child: Text('Sign out')),
              ],
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: model.busy || !model.loaded
              ? null
              : () => open(
                  TaskEditor(
                    repository: widget.repository,
                    lists: model.lists,
                    tags: model.tags,
                  ),
                ),
          icon: const Icon(Icons.add),
          label: const Text('Add task'),
        ),
        body: LoadState(
          model: model,
          retry: model.load,
          hasData: model.loaded,
          child: RefreshIndicator(
            onRefresh: () async {
              await model.load();
            },
            child: ContentList(
              children: [
                FeatureBanner(
                  title: 'Small steps. Real progress.',
                  subtitle:
                      '${model.tasks.where(taskActive).length} active · ${model.tasks.where((e) => e['status'] == 'COMPLETED').length} completed · ${model.tasks.where(taskOverdue).length} overdue',
                  icon: Icons.check_circle_outline,
                ),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search tasks',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => query = v),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final value in [
                      'Today',
                      'Active',
                      'Overdue',
                      'Completed',
                      'Cancelled',
                      'Archived',
                      'All',
                    ])
                      FilterChip(
                        label: Text(value),
                        selected: filter == value,
                        onSelected: (_) => setState(() => filter = value),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: listId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'List'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All lists')),
                    for (final list in model.lists)
                      DropdownMenuItem(
                        value: list['id'] as String,
                        child: Text(
                          '${list['name']}${list['status'] == 'ARCHIVED' ? ' (archived)' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => listId = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tagId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Tag'),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('All tags')),
                    for (final tag in model.tags)
                      DropdownMenuItem(
                        value: tag['id'] as String,
                        child: Text(
                          tag['label'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => tagId = v!),
                ),
                const SizedBox(height: 16),
                if (model.loaded && visible.isEmpty)
                  EmptyMessage(
                    title: model.tasks.isEmpty
                        ? 'Room for your next step'
                        : 'No matching tasks',
                    message: model.tasks.isEmpty
                        ? 'Add a task and turn your plans into progress.'
                        : 'Try another filter or search.',
                  ),
                for (final task in visible)
                  Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => open(
                        TaskDetail(
                          repository: widget.repository,
                          id: task['id'] as String,
                          lists: model.lists,
                          tags: model.tags,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task['title'] as String,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(task['list']?['name'] as String? ?? 'Task'),
                            Wrap(
                              spacing: 8,
                              children: [
                                StatusChip(task['status'] as String),
                                if (taskOverdue(task))
                                  const StatusChip('OVERDUE'),
                                if (task['priority'] == 'HIGH')
                                  const StatusChip('HIGH'),
                                for (final tag in task['tags'] as List)
                                  TagLabel(tag as Json),
                              ],
                            ),
                            if (task['dueDate'] != null ||
                                task['estimatedDurationMinutes'] != null)
                              Text(
                                [
                                  if (task['dueDate'] != null)
                                    'Due ${task['dueDate']}',
                                  if (task['estimatedDurationMinutes'] != null)
                                    '${task['estimatedDurationMinutes']} min estimate',
                                ].join(' · '),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class TaskDetail extends StatelessWidget {
  const TaskDetail({
    super.key,
    required this.repository,
    required this.id,
    required this.lists,
    required this.tags,
  });
  final ProductivityRepository repository;
  final String id;
  final List<Json> lists, tags;
  @override
  Widget build(
    BuildContext context,
  ) => ViewModelBuilder<ResourceViewModel<Json>>(
    create: () => ResourceViewModel(
      () async => await repository.request('GET', '/tasks/$id') as Json,
    ),
    load: (m) => m.load(),
    builder: (context, model) {
      final task = model.data;
      Future<void> status(String next) async {
        if (next == 'CANCELLED') {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancel this task?'),
              content: const Text(
                'The task stays in your history and can be reopened.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Keep task'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Cancel task'),
                ),
              ],
            ),
          );
          if (confirmed != true) return;
        }
        await model.mutate(() async {
          await repository.request(
            'PATCH',
            '/tasks/$id/status',
            body: {'status': next},
          );
        });
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Task detail'),
          actions: [
            if (task != null && task['status'] != 'ARCHIVED')
              IconButton(
                tooltip: 'Edit task',
                icon: const Icon(Icons.edit_outlined),
                onPressed: model.busy
                    ? null
                    : () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SessionPage(repository: repository, child: TaskEditor(
                              repository: repository,
                              lists: lists,
                              tags: tags,
                              task: task,
                            )),
                          ),
                        );
                        await model.load();
                      },
              ),
          ],
        ),
        body: LoadState(
          model: model,
          retry: model.load,
          hasData: task != null,
          child: task == null
              ? const SizedBox.shrink()
              : ContentList(
                  children: [
                    Text(
                      task['title'] as String,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        StatusChip(task['status'] as String),
                        for (final tag in task['tags'] as List)
                          TagLabel(tag as Json),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('List: ${task['list']?['name'] ?? '—'}'),
                            const SizedBox(height: 8),
                            Text('Priority: ${task['priority']}'),
                            const SizedBox(height: 8),
                            Text('Due: ${task['dueDate'] ?? 'No due date'}'),
                            const SizedBox(height: 8),
                            Text(
                              'Estimate: ${task['estimatedDurationMinutes'] == null ? 'Not set' : '${task['estimatedDurationMinutes']} minutes'}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(task['description'] as String? ?? 'No description'),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (taskActive(task)) ...[
                          if (task['status'] == 'NOT_STARTED')
                            FilledButton.icon(
                              onPressed: model.busy
                                  ? null
                                  : () => status('IN_PROGRESS'),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start task'),
                            ),
                          FilledButton.icon(
                            onPressed: model.busy
                                ? null
                                : () => status('COMPLETED'),
                            icon: const Icon(Icons.check),
                            label: const Text('Complete task'),
                          ),
                          OutlinedButton(
                            onPressed: model.busy
                                ? null
                                : () => status('CANCELLED'),
                            child: const Text('Cancel task'),
                          ),
                        ],
                        if (!taskActive(task))
                          FilledButton(
                            onPressed: model.busy
                                ? null
                                : () => status('NOT_STARTED'),
                            child: const Text('Reopen task'),
                          ),
                        if (task['status'] != 'ARCHIVED')
                          OutlinedButton.icon(
                            onPressed: model.busy
                                ? null
                                : () => status('ARCHIVED'),
                            icon: const Icon(Icons.archive_outlined),
                            label: const Text('Archive'),
                          ),
                      ],
                    ),
                  ],
                ),
        ),
      );
    },
  );
}
