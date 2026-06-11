import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:turf/boolean.dart';

import '_boolean_two_poly_base.dart';

class BooleanDisjointShowcase extends StatelessWidget {
  const BooleanDisjointShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    return TwoPolygonBooleanShowcase(
      label: 'disjoint',
      hint: 'True when the two shapes share no points',
      fnSignature: 'booleanDisjoint(f1, f2)',
      predicate: (a, b) => booleanDisjoint(a, b),
      defaultA: const [
        LatLng(0, 0),
        LatLng(0, 4),
        LatLng(4, 4),
        LatLng(4, 0),
      ],
      defaultB: const [
        LatLng(6, 6),
        LatLng(6, 10),
        LatLng(10, 10),
        LatLng(10, 6),
      ],
    );
  }
}
