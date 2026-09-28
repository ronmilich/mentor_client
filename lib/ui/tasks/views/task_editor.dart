import 'package:flutter/material.dart';
import '../../../data/repositories/productivity_repository.dart';
import '../../../models/level.dart';
import '../../levels/views/level_widgets.dart';
import 'task_catalog.dart';

class TaskEditor extends StatefulWidget {
  const TaskEditor({
    super.key,
    required this.repository,
    required this.lists,
    required this.tags,
    this.task,
  });
  final ProductivityRepository repository;
  final List<Json> lists, tags;
  final Json? task;
  @override
  State<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<TaskEditor> {
  final form = GlobalKey<FormState>();
  late final title = TextEditingController(
    text: widget.task?['title'] as String?,
  );
  late final description = TextEditingController(
    text: widget.task?['description'] as String?,
  );
  late final estimate = TextEditingController(
    text: widget.task?['estimatedDurationMinutes']?.toString(),
  );
  late List<Json> lists = [...widget.lists], tags = [...widget.tags];
  late String? listId =
      widget.task?['listId'] as String? ??
      lists.where((e) => e['status'] == 'ACTIVE').firstOrNull?['id'] as String?;
  late String priority = widget.task?['priority'] as String? ?? 'NORMAL';
  late String? dueDate = widget.task?['dueDate'] as String?;
  late Set<String> selectedTags = {
    for (final tag in widget.task?['tags'] as List? ?? []) tag['id'] as String,
  };
  bool busy = false, dirty = false;
  String? error;
  @override
  void dispose() {
    title.dispose();
    description.dispose();
    estimate.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.request(
        widget.task == null ? 'POST' : 'PATCH',
        '/tasks${widget.task == null ? '' : '/${widget.task!['id']}'}',
        body: {
          'title': title.text.trim(),
          'description': description.text.trim().isEmpty
              ? null
              : description.text.trim(),
          if (widget.task == null || listId != widget.task!['listId'])
            'listId': listId,
          'priority': priority,
          'dueDate': dueDate,
          'estimatedDurationMinutes': estimate.text.trim().isEmpty
              ? null
              : int.parse(estimate.text.trim()),
          'tagIds': selectedTags.toList(),
        },
      );
      if (mounted) {
        setState(() {
          dirty = false;
          busy = false;
        });
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> createCatalog(bool isTag) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CatalogEditor(repository: widget.repository, tags: isTag),
    );
    if (saved != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final items = await widget.repository.all(
        isTag ? '/tags' : '/task-lists',
      );
      if (!mounted) return;
      setState(() {
        if (isTag) {
          tags = items;
        } else {
          lists = items;
          listId ??=
              lists.where((e) => e['status'] == 'ACTIVE').firstOrNull?['id']
                  as String?;
        }
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy && !dirty,
    onPopInvokedWithResult: (didPop, result) async {
      if (didPop || busy) return;
      final discard = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Discard task changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard == true && context.mounted) {
        setState(() => dirty = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) Navigator.pop(context);
        });
      }
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'New task' : 'Edit task'),
      ),
      body: Form(
        key: form,
        onChanged: () {
          if (!dirty) setState(() => dirty = true);
        },
        child: ContentList(
          keepChildrenMounted: true,
          children: [
            if (busy) const LinearProgressIndicator(),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            TextFormField(
              controller: title,
              enabled: !busy,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Give your task a title.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: description,
              enabled: !busy,
              minLines: 3,
              maxLines: 6,
              maxLength: 20000,
              decoration: const InputDecoration(
                labelText: 'Description',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('list-$listId-${lists.length}'),
              initialValue: listId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'List'),
              items: [
                for (final list in lists.where(
                  (e) => e['status'] == 'ACTIVE' || e['id'] == listId,
                ))
                  DropdownMenuItem(
                    value: list['id'] as String,
                    child: Text(
                      '${list['name']}${list['status'] == 'ARCHIVED' ? ' (archived)' : ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (v) => setState(() {
                      listId = v;
                      dirty = true;
                    }),
              validator: (v) => v == null ? 'Create or choose a list.' : null,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: busy ? null : () => createCatalog(false),
                icon: const Icon(Icons.add),
                label: const Text('Create list'),
              ),
            ),
            DropdownButtonFormField<String>(
              initialValue: priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: [
                for (final p in ['LOW', 'NORMAL', 'HIGH'])
                  DropdownMenuItem(
                    value: p,
                    child: Text(
                      p == 'NORMAL'
                          ? 'Normal'
                          : p == 'LOW'
                          ? 'Low'
                          : 'High',
                    ),
                  ),
              ],
              onChanged: busy
                  ? null
                  : (v) => setState(() {
                      priority = v!;
                      dirty = true;
                    }),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate == null
                                ? DateTime.now()
                                : DateTime.parse(dueDate!),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2200),
                          );
                          if (picked != null && mounted) {
                            setState(() {
                              dueDate = calendarDate(picked);
                              dirty = true;
                            });
                          }
                        },
                  icon: const Icon(Icons.event),
                  label: Text(dueDate ?? 'Set due date'),
                ),
                if (dueDate != null)
                  IconButton(
                    tooltip: 'Clear due date',
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            dueDate = null;
                            dirty = true;
                          }),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: estimate,
              enabled: !busy,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Estimated duration (minutes)',
                hintText: 'Optional',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final number = int.tryParse(v.trim());
                return number == null || number < 0 || number > 2147483647
                    ? 'Enter a nonnegative whole number of minutes.'
                    : null;
              },
            ),
            const SizedBox(height: 24),
            Text('Tags', style: Theme.of(context).textTheme.titleMedium),
            Wrap(
              spacing: 8,
              children: [
                for (final tag in tags.where(
                  (e) =>
                      e['status'] == 'ACTIVE' || selectedTags.contains(e['id']),
                ))
                  FilterChip(
                    label: Text(tag['label'] as String),
                    avatar: CircleAvatar(
                      radius: 5,
                      backgroundColor: tagColor(tag['color'] as String?),
                    ),
                    selected: selectedTags.contains(tag['id']),
                    onSelected: busy
                        ? null
                        : (selected) => setState(() {
                            selected
                                ? selectedTags.add(tag['id'] as String)
                                : selectedTags.remove(tag['id']);
                            dirty = true;
                          }),
                  ),
                TextButton.icon(
                  onPressed: busy ? null : () => createCatalog(true),
                  icon: const Icon(Icons.add),
                  label: const Text('Create tag'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: busy ? null : save,
              child: Text(
                busy
                    ? 'Saving…'
                    : widget.task == null
                    ? 'Create task'
                    : 'Save changes',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
