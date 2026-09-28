import 'package:flutter/material.dart';

import '../../../data/repositories/levels_repository.dart';
import '../../../models/level.dart';
import '../view_models/levels_view_models.dart';
import 'level_widgets.dart';

class HistoricalDayScreen extends StatelessWidget {
  const HistoricalDayScreen({
    super.key,
    required this.repository,
    required this.levelId,
    required this.attemptId,
    required this.dayId,
  });
  final LevelsRepository repository;
  final String levelId;
  final String attemptId;
  final String dayId;

  @override
  Widget build(
    BuildContext context,
  ) => ViewModelBuilder<ResourceViewModel<LevelAttemptDay>>(
    create: () => ResourceViewModel(
      () => repository.day(levelId, attemptId, dayId),
      changes: repository.changes,
    ),
    load: (model) => model.load(),
    builder: (context, model) {
      final day = model.data;
      return Scaffold(
        appBar: AppBar(title: const Text('Historical day detail')),
        body: LoadState(
          model: model,
          retry: model.load,
          hasData: day != null,
          child: day == null
              ? const SizedBox.shrink()
              : ContentList(
                  children: [
                    Text(
                      'Day ${day.dayNumber}',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(day.date),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: StatusChip(day.status),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'These are the original requirements recorded for this day. This view is read-only.',
                    ),
                    const SizedBox(height: 16),
                    if (day.itemResults.isEmpty)
                      const Text('No requirement results were recorded.'),
                    for (final result in day.itemResults)
                      Card(
                        child: ListTile(
                          leading: Icon(switch (result.status) {
                            'PASSED' => Icons.check_circle_outline,
                            'FAILED' => Icons.cancel_outlined,
                            _ => Icons.hourglass_empty,
                          }),
                          title: Text(result.titleSnapshot),
                          subtitle: Text(
                            '${result.typeSnapshot.label} · ${statusLabel(result.status)}',
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
