import 'package:flutter/material.dart';

import 'demos/registry.dart';
import 'demos/turf_demo.dart';
import 'widgets/demo_detail.dart';

class ShowcaseHome extends StatefulWidget {
  const ShowcaseHome({super.key});

  @override
  State<ShowcaseHome> createState() => _ShowcaseHomeState();
}

class _ShowcaseHomeState extends State<ShowcaseHome> {
  final List<TurfDemo> _demos = allDemos();
  late final Map<String, List<TurfDemo>> _grouped = demosByCategory();
  late TurfDemo _selected = _demos.first;
  String _query = '';

  Iterable<TurfDemo> get _filteredDemos {
    if (_query.trim().isEmpty) return _demos;
    final q = _query.toLowerCase();
    return _demos.where(
      (d) =>
          d.name.toLowerCase().contains(q) ||
          d.description.toLowerCase().contains(q) ||
          d.category.toLowerCase().contains(q),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                SizedBox(width: 320, child: _Sidebar(state: this)),
                const VerticalDivider(width: 1),
                Expanded(child: DemoDetail(demo: _selected)),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const _AppTitle()),
          drawer: SizedBox(width: 320, child: Drawer(child: _Sidebar(state: this))),
          body: DemoDetail(demo: _selected),
        );
      },
    );
  }

  void _select(TurfDemo demo) {
    setState(() => _selected = demo);
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.hasDrawer ?? false) {
      Navigator.of(context).maybePop();
    }
  }

  void _updateQuery(String q) {
    setState(() => _query = q);
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.state});
  final _ShowcaseHomeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = state._filteredDemos.toList();
    final showAll = state._query.trim().isEmpty;
    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              16 + MediaQuery.of(context).padding.top,
              16,
              8,
            ),
            color: theme.colorScheme.surfaceContainerHigh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AppTitle(),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'search operations…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: theme.textTheme.bodyMedium,
                  onChanged: state._updateQuery,
                ),
              ],
            ),
          ),
          Expanded(
            child: showAll
                ? _GroupedList(state: state)
                : _FlatList(state: state, demos: filtered),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.surfaceContainerHigh,
            child: Row(
              children: [
                Icon(
                  Icons.public_rounded,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'turf 0.0.10 · geotypes 0.0.2',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupedList extends StatelessWidget {
  const _GroupedList({required this.state});
  final _ShowcaseHomeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = state._grouped.entries.toList();
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final entry = entries[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
              child: Text(
                entry.key.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            for (final demo in entry.value)
              _DemoTile(demo: demo, state: state),
          ],
        );
      },
    );
  }
}

class _FlatList extends StatelessWidget {
  const _FlatList({required this.state, required this.demos});
  final _ShowcaseHomeState state;
  final List<TurfDemo> demos;

  @override
  Widget build(BuildContext context) {
    if (demos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'no operations match "${state._query}"',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: demos.length,
      itemBuilder: (_, i) => _DemoTile(demo: demos[i], state: state),
    );
  }
}

class _DemoTile extends StatelessWidget {
  const _DemoTile({required this.demo, required this.state});
  final TurfDemo demo;
  final _ShowcaseHomeState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = state._selected.id == demo.id;
    return InkWell(
      onTap: () => state._select(demo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
              : null,
          border: Border(
            left: BorderSide(
              width: 3,
              color: selected ? theme.colorScheme.primary : Colors.transparent,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              demo.icon,
              size: 18,
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    demo.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: selected ? theme.colorScheme.primary : null,
                    ),
                  ),
                  Text(
                    demo.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTitle extends StatelessWidget {
  const _AppTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.public_rounded,
            size: 18,
            color: theme.colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'turf_dart',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'showcase',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
