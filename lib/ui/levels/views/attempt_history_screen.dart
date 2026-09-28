import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/levels_repository.dart';
import '../../../models/level.dart';
import '../view_models/levels_view_models.dart';
import 'level_widgets.dart';

class AttemptHistoryScreen extends StatelessWidget {
  const AttemptHistoryScreen({
    super.key,
    required this.repository,
    required this.levelId,
  });
  final LevelsRepository repository;
  final String levelId;

  @override
  Widget build(
    BuildContext context,
  ) => ViewModelBuilder<ResourceViewModel<List<LevelAttempt>>>(
    create: () => ResourceViewModel(
      () => repository.attempts(levelId),
      changes: repository.changes,
    ),
    load: (model) => model.load(),
    builder: (context, model) => Scaffold(
      appBar: AppBar(
        title: const Text('Attempt history'),
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            onPressed: model.busy ? null : model.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LoadState(
        model: model,
        retry: model.load,
        hasData: model.data != null,
        child: ContentList(
          children: [
            const Text(
              'Every attempt is part of your progress. Open one to review its recorded days.',
            ),
            const SizedBox(height: 16),
            if (model.data?.isEmpty == true)
              const EmptyMessage(
                title: 'No attempts yet',
                message: 'Start this level to begin your first attempt.',
              ),
            for (final (index, attempt)
                in (model.data ?? <LevelAttempt>[]).indexed)
              Card(
                child: ListTile(
                  title: Text('Attempt ${(model.data?.length ?? 0) - index}'),
                  subtitle: Text(
                    '${displayDate(attempt.startedAt)} · ${statusLabel(attempt.status)}\n${attempt.completedDays} / ${attempt.requiredDays} days completed',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      context.push('/levels/$levelId/attempts/${attempt.id}'),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
