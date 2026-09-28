import 'package:flutter/material.dart';
import '../../../data/repositories/productivity_repository.dart';

class JournalCalendar extends StatefulWidget {
  const JournalCalendar({super.key, required this.dates, required this.onSelected});
  final Set<String> dates;
  final ValueChanged<DateTime> onSelected;
  @override
  State<JournalCalendar> createState() => _JournalCalendarState();
}

class _JournalCalendarState extends State<JournalCalendar> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final offset = (month.weekday % 7 - localizations.firstDayOfWeekIndex + 7) % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final today = DateUtils.dateOnly(DateTime.now());
    return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
      Row(children: [IconButton(tooltip: 'Previous month', onPressed: month.year <= 1900 && month.month == 1 ? null : () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left)), Expanded(child: Text(localizations.formatMonthYear(month), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)), IconButton(tooltip: 'Next month', onPressed: month.year == today.year && month.month == today.month ? null : () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right))]),
      Row(children: [for (var day = 0; day < 7; day++) Expanded(child: Center(child: Text(localizations.narrowWeekdays[(day + localizations.firstDayOfWeekIndex) % 7])))]),
      for (var week = 0; week < ((offset + days) / 7).ceil(); week++) Row(children: [
        for (var weekday = 0; weekday < 7; weekday++) Expanded(child: Builder(builder: (context) {
          final day = week * 7 + weekday - offset + 1;
          if (day < 1 || day > days) return const SizedBox(height: 48);
          final date = DateTime(month.year, month.month, day);
          final hasEntry = widget.dates.contains(calendarDate(date));
          final current = DateUtils.isSameDay(date, today);
          return Semantics(label: '${localizations.formatFullDate(date)}${hasEntry ? ', journal entry' : ''}', child: TextButton(onPressed: date.isAfter(today) ? null : () => widget.onSelected(date), style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(32, 48), backgroundColor: current ? Theme.of(context).colorScheme.primaryContainer : null), child: Column(mainAxisSize: MainAxisSize.min, children: [Text('$day'), const SizedBox(height: 2), Container(width: 5, height: 5, decoration: BoxDecoration(shape: BoxShape.circle, color: hasEntry ? Theme.of(context).colorScheme.primary : Colors.transparent))])));
        })),
      ]),
      const SizedBox(height: 8), const Text('● Journal entry', style: TextStyle(fontSize: 12)),
    ])));
  }
}
