import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/levels_repository.dart';
import '../../../models/level.dart';
import '../view_models/levels_view_models.dart';
import 'level_widgets.dart';

class LevelDetailScreen extends StatelessWidget {
  const LevelDetailScreen({
    super.key,
    required this.repository,
    required this.levelId,
  });
  final LevelsRepository repository;
  final String levelId;

  @override
  Widget build(
    BuildContext context,
  ) => ViewModelBuilder<ResourceViewModel<Level>>(
    create: () => ResourceViewModel(
      () => repository.level(levelId),
      changes: repository.changes,
    ),
    load: (model) => model.load(),
    builder: (context, model) {
      final level = model.data;
      Future<void> open(String suffix) async {
        await context.push('/levels/$levelId/$suffix');
        if (context.mounted) await model.load();
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Level detail'),
          actions: [
            IconButton(
              tooltip: 'Refresh level',
              onPressed: model.busy ? null : model.load,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: 'Edit level',
              onPressed: level == null ? null : () => open('edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        body: LoadState(
          model: model,
          retry: model.load,
          hasData: level != null,
          child: level == null
              ? const SizedBox.shrink()
              : ContentList(
                  children: [
                    Text(
                      'LEVEL ${level.number}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      level.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    if (level.description?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(level.description!),
                      ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text('${level.requiredDays} required days'),
                        ),
                        Chip(
                          label: Text(
                            '${level.maxFailedAttempts} allowed failed attempts',
                          ),
                        ),
                        if (level.activeAttempt != null)
                          const StatusChip('IN_PROGRESS'),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Daily requirements',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    if (level.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Add at least one active requirement before starting.',
                        ),
                      ),
                    for (final item in level.items)
                      Card(
                        child: ListTile(
                          leading: Icon(
                            item.type == LevelItemType.doItem
                                ? Icons.check_circle_outline
                                : Icons.block,
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.type.label}${item.isActive ? '' : ' · Inactive'}${item.description?.isNotEmpty == true ? '\n${item.description}' : ''}',
                          ),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () => open('edit'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit level and requirements'),
                    ),
                    const SizedBox(height: 24),
                    if (level.activeAttempt == null)
                      FilledButton.icon(
                        onPressed: level.activeItems.isEmpty
                            ? null
                            : () => open('start'),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start level'),
                      )
                    else ...[
                      FilledButton.icon(
                        onPressed: () =>
                            open('attempts/${level.activeAttempt!.id}'),
                        icon: const Icon(Icons.insights),
                        label: const Text('View current attempt'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => open('restart'),
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Restart level'),
                      ),
                    ],
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => open('attempts'),
                      icon: const Icon(Icons.history),
                      label: const Text('Attempt history'),
                    ),
                  ],
                ),
        ),
      );
    },
  );
}
