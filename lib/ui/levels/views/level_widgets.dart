import 'package:flutter/material.dart';

import '../view_models/levels_view_models.dart';

class ViewModelBuilder<T extends AsyncViewModel> extends StatefulWidget {
  const ViewModelBuilder({
    super.key,
    required this.create,
    required this.load,
    required this.builder,
  });
  final T Function() create;
  final Future<bool> Function(T) load;
  final Widget Function(BuildContext, T) builder;

  @override
  State<ViewModelBuilder<T>> createState() => _ViewModelBuilderState<T>();
}

class _ViewModelBuilderState<T extends AsyncViewModel>
    extends State<ViewModelBuilder<T>> {
  late final T model;
  @override
  void initState() {
    super.initState();
    model = widget.create();
    widget.load(model);
  }

  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) => widget.builder(context, model),
  );
}

class LoadState extends StatelessWidget {
  const LoadState({
    super.key,
    required this.model,
    required this.retry,
    required this.child,
    this.hasData = true,
  });
  final AsyncViewModel model;
  final VoidCallback? retry;
  final Widget child;
  final bool hasData;

  @override
  Widget build(BuildContext context) {
    if (model.busy && !hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      children: [
        if (model.busy) const LinearProgressIndicator(),
        if (model.error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  model.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                if (retry != null)
                  TextButton(
                    onPressed: model.busy ? null : retry,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}

class ContentList extends StatelessWidget {
  const ContentList({
    super.key,
    required this.children,
    this.keepChildrenMounted = false,
  });
  final List<Widget> children;

  /// Forms must validate every field, including those outside the viewport.
  final bool keepChildrenMounted;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: keepChildrenMounted
            ? [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ]
            : children,
      ),
    ),
  );
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.title,
    required this.message,
    this.action,
  });
  final String title;
  final String message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(
      children: [
        const Icon(Icons.layers_outlined, size: 48),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        if (action != null)
          Padding(padding: const EdgeInsets.only(top: 20), child: action!),
      ],
    ),
  );
}

String statusLabel(String value) => switch (value) {
  'NOT_STARTED' => 'Not started',
  'IN_PROGRESS' => 'In progress',
  'COMPLETED' => 'Completed',
  'FAILED' => 'Failed',
  'ABANDONED' => 'Abandoned',
  'PENDING' => 'Pending',
  'PASSED' => 'Passed',
  _ =>
    value
        .toLowerCase()
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' '),
};

String displayDate(DateTime date) {
  final local = date.toLocal();
  return '${local.day}/${local.month}/${local.year}';
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Chip(
      backgroundColor: color.withValues(alpha: dark ? .25 : .12),
      labelStyle: TextStyle(
        color: dark ? Color.lerp(color, Colors.white, .5) : color,
        fontWeight: FontWeight.w700,
      ),
      avatar: Icon(
        Icons.circle,
        color: dark ? Color.lerp(color, Colors.white, .5) : color,
        size: 8,
      ),
      side: BorderSide.none,
      label: Text(statusLabel(status)),
      visualDensity: VisualDensity.compact,
    );
  }
}

Color statusColor(String status) => switch (status) {
  'IN_PROGRESS' => const Color(0xff245FCA),
  'ACTIVE' => const Color(0xff087F8C),
  'COMPLETED' => const Color(0xff217443),
  'PASSED' || 'SUBMITTED_SUCCESS' => const Color(0xff167563),
  'FAILED' || 'SUBMITTED_FAILURE' => const Color(0xffBC3045),
  'NOT_STARTED' => const Color(0xff65758B),
  'PENDING' => const Color(0xff9B6A06),
  'CANCELLED' => const Color(0xffA54A23),
  'ARCHIVED' => const Color(0xff665677),
  'ABANDONED' => const Color(0xff956149),
  'PAUSED' => const Color(0xff7647B8),
  'DRAFT' => const Color(0xff536579),
  'AUTO_COMPLETED' => const Color(0xff247B2C),
  'AUTO_FAILED' => const Color(0xffA22B65),
  'AUTO_FINALIZED' => const Color(0xff3B7890),
  'OPEN' => const Color(0xff3974A4),
  'OVERDUE' => const Color(0xffB33054),
  'HIGH' => const Color(0xffA46112),
  _ => const Color(0xff627082),
};

String? smallIntValidator(String? value, {int min = 1}) {
  final number = int.tryParse(value?.trim() ?? '');
  return number == null || number < min || number > 32767
      ? 'Enter a whole number from $min to 32767.'
      : null;
}
