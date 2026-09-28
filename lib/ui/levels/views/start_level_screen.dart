import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/levels_repository.dart';
import '../view_models/levels_view_models.dart';
import 'level_widgets.dart';

class StartLevelScreen extends StatelessWidget {
  const StartLevelScreen({
    super.key,
    required this.repository,
    required this.levelId,
    this.restart = false,
  });
  final LevelsRepository repository;
  final String levelId;
  final bool restart;

  @override
  Widget build(BuildContext context) => ViewModelBuilder<StartLevelViewModel>(
    create: () => StartLevelViewModel(repository, levelId, restart: restart),
    load: (model) => model.load(),
    builder: (context, model) {
      final level = model.level;
      final canStart =
          level != null &&
          level.activeItems.isNotEmpty &&
          (restart ? level.activeAttempt != null : level.activeAttempt == null);
      return Scaffold(
        appBar: AppBar(
          title: Text(restart ? 'Restart level' : 'Start level confirmation'),
        ),
        body: LoadState(
          model: model,
          retry: model.load,
          hasData: level != null,
          child: level == null
              ? const SizedBox.shrink()
              : ContentList(
                  children: [
                    Icon(
                      restart ? Icons.restart_alt : Icons.flag_outlined,
                      size: 56,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      restart ? 'A fresh start' : 'Ready to begin?',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      level.title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      restart
                          ? 'Your current attempt will be marked abandoned and kept in history. A new attempt begins at Day 1 today.'
                          : 'Your attempt begins at Day 1 today, with ${level.requiredDays} required days.',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This attempt will use the current level requirements:',
                    ),
                    for (final item in level.activeItems)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.title),
                        subtitle: Text(item.type.label),
                      ),
                    if (!canStart)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Refresh the level and check its active attempt and requirements before continuing.',
                        ),
                      ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: model.busy || !canStart
                          ? null
                          : () async {
                              if (await model.confirm() && context.mounted) {
                                context.pop(true);
                              }
                            },
                      child: Text(
                        model.busy
                            ? 'Starting…'
                            : restart
                            ? 'Confirm restart'
                            : 'Start level',
                      ),
                    ),
                    TextButton(
                      onPressed: model.busy ? null : () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
        ),
      );
    },
  );
}
