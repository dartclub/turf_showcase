import 'package:flutter/material.dart';

import '../demos/turf_demo.dart';

class DemoDetail extends StatelessWidget {
  const DemoDetail({super.key, required this.demo});

  final TurfDemo demo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 880),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Breadcrumb(demo: demo),
                    const SizedBox(height: 18),
                    _Description(demo: demo),
                    const SizedBox(height: 28),
                    _ParametersTable(parameters: demo.parameters),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.demo});
  final TurfDemo demo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(demo.icon, size: 22, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          demo.category,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Flexible(
          child: SelectableText(
            demo.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _Description extends StatelessWidget {
  const _Description({required this.demo});
  final TurfDemo demo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SelectableText(
      demo.description,
      style: theme.textTheme.bodyLarge?.copyWith(
        height: 1.5,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}

class _ParametersTable extends StatelessWidget {
  const _ParametersTable({required this.parameters});
  final List<TurfParameter> parameters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (parameters.isEmpty) {
      return _EmptyTableState(theme: theme);
    }
    final headerStyle = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      letterSpacing: 0.8,
      fontWeight: FontWeight.w600,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 4),
          child: Text(
            'PARAMETERS',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: IntrinsicColumnWidth(),
              2: IntrinsicColumnWidth(),
              3: IntrinsicColumnWidth(),
              4: FlexColumnWidth(),
            },
            border: TableBorder(
              horizontalInside: BorderSide(
                color: theme.colorScheme.outlineVariant,
                width: 1,
              ),
            ),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
                children: [
                  _HeaderCell('NAME', style: headerStyle),
                  _HeaderCell('TYPE', style: headerStyle),
                  _HeaderCell('REQUIRED', style: headerStyle),
                  _HeaderCell('DEFAULT', style: headerStyle),
                  _HeaderCell('DESCRIPTION', style: headerStyle),
                ],
              ),
              for (final p in parameters) _row(context, p),
            ],
          ),
        ),
      ],
    );
  }

  TableRow _row(BuildContext context, TurfParameter p) {
    final theme = Theme.of(context);
    return TableRow(
      children: [
        _BodyCell(
          child: SelectableText(
            p.name,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _BodyCell(
          child: SelectableText(
            p.type,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        _BodyCell(child: _RequiredChip(required: p.required)),
        _BodyCell(
          child: SelectableText(
            p.defaultValue ?? '—',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12.5,
              color: p.defaultValue == null
                  ? theme.colorScheme.onSurfaceVariant
                  : theme.colorScheme.onSurface,
            ),
          ),
        ),
        _BodyCell(
          child: SelectableText(
            p.description,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {this.style});
  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Text(text, style: style),
    );
  }
}

class _BodyCell extends StatelessWidget {
  const _BodyCell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: child,
    );
  }
}

class _RequiredChip extends StatelessWidget {
  const _RequiredChip({required this.required});
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = required
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = required
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: required
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Text(
        required ? 'required' : 'optional',
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyTableState extends StatelessWidget {
  const _EmptyTableState({required this.theme});
  final ThemeData theme;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'this operation takes no parameters',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
