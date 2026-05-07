import 'geometry_demos.dart';
import 'line_demos.dart';
import 'measurement_demos.dart';
import 'transform_demos.dart';
import 'turf_demo.dart';

/// Master list of every showcased turf operation. Order matters: it determines
/// the order they appear in the sidebar.
List<TurfDemo> allDemos() => [
      ...measurementDemos(),
      ...geometryDemos(),
      ...transformDemos(),
      ...lineDemos(),
    ];

/// Demos grouped by category, preserving the insertion order of [allDemos].
Map<String, List<TurfDemo>> demosByCategory() {
  final map = <String, List<TurfDemo>>{};
  for (final demo in allDemos()) {
    map.putIfAbsent(demo.category, () => []).add(demo);
  }
  return map;
}
