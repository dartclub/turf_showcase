import 'package:flutter/material.dart';

/// Single parameter row of a [TurfDemo].
class TurfParameter {
  const TurfParameter({
    required this.name,
    required this.type,
    required this.required,
    required this.description,
    this.defaultValue,
  });

  /// Parameter identifier as it appears in the Dart signature.
  final String name;

  /// Dart type rendered exactly as you would write it (`Point`,
  /// `Feature<LineString>`, `Map<String, dynamic>?`, etc.).
  final String type;

  /// `true` for required positional/named parameters, `false` for optional ones.
  final bool required;

  /// Default value as it would appear in source (e.g. `Unit.kilometers`).
  /// Use `null` when the parameter has no default.
  final String? defaultValue;

  /// Short, prose description of the parameter.
  final String description;
}

/// Documentation entry for a single turf_dart operation.
class TurfDemo {
  const TurfDemo({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.description,
    required this.parameters,
  });

  final String id;

  /// Public Dart symbol, e.g. `distance`, `bboxPolygon`.
  final String name;

  /// Top-level grouping shown in the breadcrumb / sidebar.
  final String category;

  final IconData icon;

  /// Short, dartdoc-sourced description of the operation.
  final String description;

  /// Ordered list of parameters accepted by the operation.
  final List<TurfParameter> parameters;
}
