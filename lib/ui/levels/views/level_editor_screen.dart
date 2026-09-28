import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/levels_repository.dart';
import '../view_models/levels_view_models.dart';
import 'level_widgets.dart';

class LevelEditorScreen extends StatefulWidget {
  const LevelEditorScreen({
    super.key,
    required this.repository,
    this.levelId,
    this.userId = '',
  });
  final LevelsRepository repository;
  final String? levelId;
  final String userId;
  @override
  State<LevelEditorScreen> createState() => _LevelEditorScreenState();
}

class _LevelEditorScreenState extends State<LevelEditorScreen> {
  final _form = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _days = TextEditingController(text: '10');
  final _failures = TextEditingController(text: '3');
  late final LevelEditorViewModel model;
  bool _ready = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    model = LevelEditorViewModel(
      widget.repository,
      id: widget.levelId,
      userId: widget.userId,
    );
    _load();
  }

  Future<void> _load() async {
    final loaded = await model.load();
    if (!mounted || !loaded) return;
    final level = model.level;
    if (level != null) {
      _number.text = '${level.number}';
      _name.text = level.name ?? '';
      _description.text = level.description ?? '';
      _days.text = '${level.requiredDays}';
      _failures.text = '${level.maxFailedAttempts}';
    }
    setState(() {
      _ready = true;
      _dirty = false;
    });
  }

  @override
  void dispose() {
    for (final controller in [_number, _name, _description, _days, _failures]) {
      controller.dispose();
    }
    model.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    if (!_form.currentState!.validate()) return false;
    final success = await model.save({
      'number': int.parse(_number.text.trim()),
      'name': _name.text.trim().isEmpty ? null : _name.text.trim(),
      'description': _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      'requiredDays': int.parse(_days.text.trim()),
      'maxFailedAttempts': int.parse(_failures.text.trim()),
    });
    if (mounted && success) setState(() => _dirty = false);
    return success;
  }

  Future<void> _editItem(String itemId) async {
    if (_dirty && !await _save()) return;
    if (!mounted) return;
    await context.push('/levels/${model.id}/edit/items/$itemId');
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.levelId == null ? 'Create level' : 'Edit level'),
        ),
        body: LoadState(
          model: model,
          retry: _ready ? null : _load,
          hasData: _ready,
          child: !_ready
              ? const SizedBox.shrink()
              : Form(
                  key: _form,
                  onChanged: () {
                    if (!_dirty) setState(() => _dirty = true);
                  },
                  child: ContentList(
                    keepChildrenMounted: true,
                    children: [
                      Text(
                        'Make the requirements clear',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _number,
                        enabled: !model.busy,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Level number',
                          border: OutlineInputBorder(),
                        ),
                        validator: smallIntValidator,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _name,
                        enabled: !model.busy,
                        maxLength: 100,
                        decoration: const InputDecoration(
                          labelText: 'Name (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _days,
                        enabled: !model.busy,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Required days',
                          border: OutlineInputBorder(),
                        ),
                        validator: smallIntValidator,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _failures,
                        enabled: !model.busy,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Maximum failed attempts',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => smallIntValidator(value, min: 0),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: model.busy || model.userId.isEmpty
                            ? null
                            : () async {
                                if (await _save() && context.mounted) {
                                  if (widget.levelId == null) {
                                    context.go('/levels/${model.id}/edit');
                                  } else {
                                    context.pop(true);
                                  }
                                }
                              },
                        child: Text(
                          model.busy
                              ? 'Saving…'
                              : widget.levelId == null
                              ? 'Create level'
                              : 'Save changes',
                        ),
                      ),
                      if (model.userId.isEmpty)
                        const Text(
                          'Choose a profile from Levels before creating a level.',
                        ),
                      const SizedBox(height: 24),
                      Text(
                        'Daily requirements',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (model.id == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'Create the level, then add things to do or avoid.',
                          ),
                        )
                      else ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Changes apply to the level definition. Recorded days keep their original requirements.',
                        ),
                        for (final item in model.level?.items ?? [])
                          Card(
                            child: ListTile(
                              title: Text(item.title),
                              subtitle: Text(
                                '${item.type.label}${item.isActive ? '' : ' · Inactive'}',
                              ),
                              trailing: const Icon(Icons.edit_outlined),
                              onTap: model.busy
                                  ? null
                                  : () => _editItem(item.id),
                            ),
                          ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: model.busy ? null : () => _editItem('new'),
                          icon: const Icon(Icons.add),
                          label: Text(
                            _dirty
                                ? 'Save changes & add item'
                                : 'Add level item',
                          ),
                        ),
                        if (_dirty)
                          const Text(
                            'Opening an item also saves the level changes above.',
                          ),
                      ],
                    ],
                  ),
                ),
        ),
      );
    },
  );
}
