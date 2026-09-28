import 'package:flutter/material.dart';
import '../../../data/repositories/productivity_repository.dart';
import '../../../models/level.dart';
import '../../levels/view_models/levels_view_models.dart';
import '../../levels/views/level_widgets.dart';

Color tagColor(String? hex) => Color(
  int.tryParse('ff${(hex ?? '#5260c7').replaceAll('#', '')}', radix: 16) ??
      0xff5260c7,
);

class TagLabel extends StatelessWidget {
  const TagLabel(this.tag, {super.key});
  final Json tag;
  @override
  Widget build(BuildContext context) {
    final color = tagColor(tag['color'] as String?);
    return Chip(
      label: Text(tag['label'] as String),
      avatar: CircleAvatar(backgroundColor: color, radius: 5),
      backgroundColor: color.withValues(alpha: .14),
    );
  }
}

class TaskCatalog extends StatelessWidget {
  const TaskCatalog({super.key, required this.repository, required this.tags});
  final ProductivityRepository repository;
  final bool tags;
  String get path => tags ? '/tags' : '/task-lists';
  @override
  Widget build(BuildContext context) =>
      ViewModelBuilder<ResourceViewModel<List<Json>>>(
        create: () => ResourceViewModel(() => repository.all(path)),
        load: (m) => m.load(),
        builder: (context, model) {
          Future<void> edit([Json? item]) async {
            final saved = await showDialog<bool>(
              context: context,
              builder: (_) =>
                  CatalogEditor(repository: repository, tags: tags, item: item),
            );
            if (saved == true) await model.load();
          }

          return Scaffold(
            appBar: AppBar(title: Text(tags ? 'Tags' : 'Task lists')),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: model.busy ? null : () => edit(),
              icon: const Icon(Icons.add),
              label: Text(tags ? 'Create tag' : 'Create list'),
            ),
            body: LoadState(
              model: model,
              retry: model.load,
              hasData: model.data != null,
              child: ContentList(
                children: [
                  Text(
                    tags
                        ? 'Give your work some color.'
                        : 'A place for every task.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  if (model.data?.isEmpty == true)
                    EmptyMessage(
                      title: tags ? 'No tags yet' : 'No lists yet',
                      message: tags
                          ? 'Create reusable tags for your tasks.'
                          : 'Create a list to organize your tasks.',
                    ),
                  for (final item in model.data ?? <Json>[])
                    Card(
                      child: ListTile(
                        leading: Icon(
                          tags ? Icons.label_outline : Icons.folder_outlined,
                          color: tags
                              ? tagColor(item['color'] as String?)
                              : Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(item[tags ? 'label' : 'name'] as String),
                        subtitle: Align(
                          alignment: Alignment.centerLeft,
                          child: StatusChip(item['status'] as String),
                        ),
                        onTap: model.busy ? null : () => edit(item),
                        trailing: IconButton(
                          tooltip: item['status'] == 'ARCHIVED'
                              ? 'Restore'
                              : 'Archive',
                          onPressed: model.busy
                              ? null
                              : () => model.mutate(() async {
                                  await repository.request(
                                    'PATCH',
                                    '$path/${item['id']}',
                                    body: {
                                      'status': item['status'] == 'ARCHIVED'
                                          ? 'ACTIVE'
                                          : 'ARCHIVED',
                                    },
                                  );
                                }),
                          icon: Icon(
                            item['status'] == 'ARCHIVED'
                                ? Icons.unarchive_outlined
                                : Icons.archive_outlined,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          );
        },
      );
}

class CatalogEditor extends StatefulWidget {
  const CatalogEditor({
    super.key,
    required this.repository,
    required this.tags,
    this.item,
  });
  final ProductivityRepository repository;
  final bool tags;
  final Json? item;
  @override
  State<CatalogEditor> createState() => _CatalogEditorState();
}

class _CatalogEditorState extends State<CatalogEditor> {
  late final name = TextEditingController(
    text: widget.item?[widget.tags ? 'label' : 'name'] as String?,
  );
  late String color = widget.item?['color'] as String? ?? '#5260C7';
  final form = GlobalKey<FormState>();
  bool busy = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final path = widget.tags ? '/tags' : '/task-lists';
      await widget.repository.request(
        widget.item == null ? 'POST' : 'PATCH',
        '$path${widget.item == null ? '' : '/${widget.item!['id']}'}',
        body: {
          widget.tags ? 'label' : 'name': name.text.trim(),
          if (widget.tags) 'color': color,
        },
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: Text(
        '${widget.item == null ? 'Create' : 'Edit'} ${widget.tags ? 'tag' : 'list'}',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                enabled: !busy,
                maxLength: widget.tags ? 50 : 100,
                decoration: InputDecoration(
                  labelText: widget.tags ? 'Label' : 'Name',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a name.' : null,
              ),
              if (widget.tags)
                Wrap(
                  spacing: 8,
                  children: [
                    for (final hex in {
                      '#5260C7',
                      '#167D87',
                      '#C23C64',
                      '#B26B00',
                      '#7745B5',
                      '#237B45',
                      '#627082',
                      color,
                    })
                      ChoiceChip(
                        label: Text(
                          hex == color ? '✓' : '●',
                          style: TextStyle(color: tagColor(hex)),
                        ),
                        selected: color == hex,
                        showCheckmark: false,
                        onSelected: busy
                            ? null
                            : (_) => setState(() => color = hex),
                      ),
                  ],
                ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: busy ? null : save,
          child: Text(busy ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}
