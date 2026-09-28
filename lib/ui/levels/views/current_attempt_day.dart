import 'package:flutter/material.dart';

import '../../../data/repositories/levels_repository.dart';
import '../../../models/level.dart';
import 'level_widgets.dart';

class CurrentAttemptDay extends StatelessWidget {
  const CurrentAttemptDay({
    super.key,
    required this.attempt,
    required this.busy,
    required this.onUpdate,
    required this.onFinalize,
    required this.onNextDay,
  });

  final LevelAttempt attempt;
  final bool busy;
  final void Function(LevelAttemptItemResult, String) onUpdate;
  final VoidCallback onFinalize;
  final VoidCallback onNextDay;

  @override
  Widget build(BuildContext context) {
    final day = attempt.currentDay;
    if (day == null || attempt.status != 'IN_PROGRESS') {
      return const SizedBox.shrink();
    }
    final editable = day.status == 'IN_PROGRESS';
    final ready =
        day.itemResults.isNotEmpty &&
        day.itemResults.every((item) => item.status != 'PENDING');
    final canStartNextDay =
        LevelsRepository.localDate().compareTo(day.date) > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Day ${day.dayNumber} / ${attempt.requiredDays}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text('${day.date} · ${statusLabel(day.status)}'),
        const SizedBox(height: 8),
        if (editable)
          const Text(
            'Update each requirement, then finalize the day. You can change results until you finalize.',
          ),
        for (final result in day.itemResults)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    result.titleSnapshot,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    result.typeSnapshot == LevelItemType.avoid
                        ? 'Avoid · Passed means you avoided this.'
                        : 'Do · Passed means you completed this.',
                  ),
                  const SizedBox(height: 12),
                  if (editable)
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          key: ValueKey(result.id),
                          value: result.status,
                          isExpanded: true,
                          isDense: true,
                          items: [
                            for (final status in [
                              'PENDING',
                              'PASSED',
                              'FAILED',
                            ])
                              DropdownMenuItem(
                                value: status,
                                child: Text(statusLabel(status)),
                              ),
                          ],
                          onChanged: busy
                              ? null
                              : (status) {
                                  if (status != null &&
                                      status != result.status) {
                                    onUpdate(result, status);
                                  }
                                },
                        ),
                      ),
                    )
                  else
                    Text(statusLabel(result.status)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        if (editable) ...[
          Text(
            ready
                ? (day.itemResults.any((item) => item.status == 'FAILED')
                      ? 'Finalizing will fail this day and end the attempt.'
                      : 'Finalizing will complete this day${day.dayNumber == attempt.requiredDays ? ' and the attempt' : ''}.')
                : 'Set every item to Passed or Failed to finalize.',
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: busy || !ready ? null : onFinalize,
            icon: const Icon(Icons.done_all),
            label: const Text('Finalize day'),
          ),
        ] else if (day.status == 'COMPLETED' &&
            day.dayNumber < attempt.requiredDays) ...[
          if (!canStartNextDay)
            const Text(
              'Your day is complete. Start the next day on a later date.',
            ),
          FilledButton.icon(
            onPressed: busy || !canStartNextDay ? null : onNextDay,
            icon: const Icon(Icons.play_arrow),
            label: Text('Start day ${day.dayNumber + 1}'),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
