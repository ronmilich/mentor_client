import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/levels_repository.dart';
import '../../../models/level.dart';
import '../view_models/levels_view_models.dart';
import 'level_widgets.dart';
import 'current_attempt_day.dart';

class AttemptDetailScreen extends StatelessWidget {
  const AttemptDetailScreen({
    super.key,
    required this.repository,
    required this.levelId,
    required this.attemptId,
  });
  final LevelsRepository repository;
  final String levelId;
  final String attemptId;

  @override
  Widget build(
    BuildContext context,
  ) => ViewModelBuilder<ResourceViewModel<LevelAttempt>>(
    create: () => ResourceViewModel(
      () => repository.attempt(levelId, attemptId),
      changes: repository.changes,
    ),
    load: (model) => model.load(),
    builder: (context, model) {
      final attempt = model.data;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Attempt detail'),
          actions: [
            IconButton(
              tooltip: 'Refresh attempt',
              onPressed: model.busy ? null : model.load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: LoadState(
          model: model,
          retry: model.load,
          hasData: attempt != null,
          child: attempt == null
              ? const SizedBox.shrink()
              : ContentList(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusChip(attempt.status),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${attempt.completedDays} of ${attempt.requiredDays} days completed',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: attempt.requiredDays > 0
                          ? (attempt.completedDays / attempt.requiredDays)
                                .clamp(0.0, 1.0)
                          : 0,
                    ),
                    const SizedBox(height: 16),
                    Text('Started ${displayDate(attempt.startedAt)}'),
                    if (attempt.endedAt != null)
                      Text('Ended ${displayDate(attempt.endedAt!)}'),
                    if (attempt.failedOnDay != null)
                      Text('Failed on Day ${attempt.failedOnDay}'),
                    const SizedBox(height: 24),
                    CurrentAttemptDay(
                      attempt: attempt,
                      busy: model.busy,
                      onUpdate: (result, status) => model.mutate(() async {
                        await repository.updateItemResult(
                          levelId,
                          attemptId,
                          attempt.currentDay!.id,
                          result.id,
                          status,
                        );
                      }),
                      onFinalize: () => model.mutate(() async {
                        await repository.finalizeDay(
                          levelId,
                          attemptId,
                          attempt.currentDay!.id,
                        );
                      }),
                      onNextDay: () => model.mutate(() async {
                        await repository.startNextDay(levelId, attemptId);
                      }),
                    ),
                    Text(
                      'Recorded days',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (attempt.days.isEmpty)
                      const EmptyMessage(
                        title: 'No recorded days',
                        message: 'Days will appear here as they are recorded.',
                      ),
                    for (final day in attempt.days)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${day.dayNumber}'),
                          ),
                          title: Text('Day ${day.dayNumber}'),
                          subtitle: Text(
                            '${day.date} · ${statusLabel(day.status)}',
                          ),
                          trailing: StatusChip(day.status),
                          onTap: () => context.push(
                            '/levels/$levelId/attempts/$attemptId/days/${day.id}',
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      );
    },
  );
}
