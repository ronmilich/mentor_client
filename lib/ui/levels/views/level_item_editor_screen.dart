import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/levels_repository.dart';
import '../../../models/level.dart';
import '../view_models/levels_view_models.dart';
import 'level_widgets.dart';

class LevelItemEditorScreen extends StatefulWidget {
  const LevelItemEditorScreen({
    super.key,
    required this.repository,
    required this.levelId,
    this.itemId,
  });
  final LevelsRepository repository;
  final String levelId;
  final String? itemId;
  @override
  State<LevelItemEditorScreen> createState() => _LevelItemEditorScreenState();
}

class _LevelItemEditorScreenState extends State<LevelItemEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _order = TextEditingController(text: '0');
  LevelItemType _type = LevelItemType.doItem;
  bool _active = true;
  bool _ready = false;
  late final LevelItemEditorViewModel model;

  @override
  void initState() {
    super.initState();
    model = LevelItemEditorViewModel(
      widget.repository,
      widget.levelId,
      widget.itemId,
    );
    _load();
  }

  Future<void> _load() async {
    if (!await model.load() || !mounted) return;
    final item = model.item;
    if (item != null) {
      _title.text = item.title;
      _description.text = item.description ?? '';
      _order.text = '${item.sortOrder}';
      _type = item.type;
      _active = item.isActive;
    }
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _order.dispose();
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(
          widget.itemId == null ? 'Add level item' : 'Edit level item',
        ),
      ),
      body: LoadState(
        model: model,
        retry: _ready ? null : _load,
        hasData: _ready,
        child: !_ready
            ? const SizedBox.shrink()
            : Form(
                key: _form,
                child: ContentList(
                  keepChildrenMounted: true,
                  children: [
                    TextFormField(
                      controller: _title,
                      enabled: !model.busy,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Requirement',
                        hintText: 'Read for 20 minutes',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Enter a requirement.'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<LevelItemType>(
                      segments: const [
                        ButtonSegment(
                          value: LevelItemType.doItem,
                          label: Text('Do'),
                          icon: Icon(Icons.check),
                        ),
                        ButtonSegment(
                          value: LevelItemType.avoid,
                          label: Text('Avoid'),
                          icon: Icon(Icons.block),
                        ),
                      ],
                      selected: {_type},
                      onSelectionChanged: model.busy
                          ? null
                          : (values) => setState(() => _type = values.single),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _description,
                      enabled: !model.busy,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _order,
                      enabled: !model.busy,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Display order',
                        helperText: 'Lower numbers appear first.',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => smallIntValidator(value, min: 0),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Active requirement'),
                      subtitle: const Text(
                        'Inactive items are excluded from new attempts.',
                      ),
                      value: _active,
                      onChanged: model.busy
                          ? null
                          : (value) => setState(() => _active = value),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: model.busy
                          ? null
                          : () async {
                              if (!_form.currentState!.validate()) return;
                              final saved = await model.save({
                                'title': _title.text.trim(),
                                'description': _description.text.trim().isEmpty
                                    ? null
                                    : _description.text.trim(),
                                'type': _type.value,
                                'sortOrder': int.parse(_order.text.trim()),
                                'isActive': _active,
                              });
                              if (saved && context.mounted) context.pop(true);
                            },
                      child: Text(model.busy ? 'Saving…' : 'Save item'),
                    ),
                  ],
                ),
              ),
      ),
    ),
  );
}
