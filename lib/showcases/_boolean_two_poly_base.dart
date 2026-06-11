import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

typedef TwoPolyPredicate = bool Function(
    turf.Feature<turf.Polygon> a, turf.Feature<turf.Polygon> b);

class TwoPolygonBooleanShowcase extends StatefulWidget {
  final String label;
  final String hint;
  final String fnSignature;
  final TwoPolyPredicate predicate;
  final List<LatLng> defaultA;
  final List<LatLng> defaultB;

  const TwoPolygonBooleanShowcase({
    super.key,
    required this.label,
    required this.hint,
    required this.fnSignature,
    required this.predicate,
    required this.defaultA,
    required this.defaultB,
  });

  @override
  State<TwoPolygonBooleanShowcase> createState() =>
      _TwoPolygonBooleanShowcaseState();
}

class _TwoPolygonBooleanShowcaseState extends State<TwoPolygonBooleanShowcase> {
  late List<LatLng> _a;
  late List<LatLng> _b;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _a = List.from(widget.defaultA);
    _b = List.from(widget.defaultB);
  }

  turf.Feature<turf.Polygon> _toFeature(List<LatLng> ring) {
    final coords = [
      ...ring.map((c) => turf.Position(c.longitude, c.latitude)),
      turf.Position(ring.first.longitude, ring.first.latitude),
    ];
    return turf.Feature<turf.Polygon>(
      geometry: turf.Polygon(coordinates: [coords]),
    );
  }

  bool get _result {
    try {
      return widget.predicate(_toFeature(_a), _toFeature(_b));
    } catch (_) {
      return false;
    }
  }

  void _onDrag(int gi, int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final list = gi == 0 ? _a : _b;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(list[idx]) + d.delta);
    setState(() {
      if (gi == 0) {
        _a[idx] = next;
      } else {
        _b[idx] = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final res = _result;
    final color = res ? ShowcaseColors.mint : ShowcaseColors.coral;
    return ShowcaseFrame(
      hint: widget.hint,
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [..._a, ..._b],
            padding: const EdgeInsets.all(70),
          ),
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
          ),
        ),
        children: [
          darkTileLayer(),
          fm.PolygonLayer(polygons: [
            fm.Polygon(
              points: _a,
              color: ShowcaseColors.sky.withOpacity(0.2),
              borderColor: ShowcaseColors.sky.withOpacity(0.85),
              borderStrokeWidth: 2.5,
            ),
            fm.Polygon(
              points: _b,
              color: ShowcaseColors.coral.withOpacity(0.2),
              borderColor: ShowcaseColors.coral.withOpacity(0.85),
              borderStrokeWidth: 2.5,
            ),
          ]),
          fm.MarkerLayer(markers: [
            ..._a.asMap().entries.map((e) => _vertex(0, e.key, e.value)),
            ..._b.asMap().entries.map((e) => _vertex(1, e.key, e.value)),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ChipBadge(
              text: 'feature1',
              color: ShowcaseColors.sky,
              icon: Icons.hexagon_outlined,
            ),
            const SizedBox(width: 6),
            ChipBadge(
              text: 'feature2',
              color: ShowcaseColors.coral,
              icon: Icons.hexagon_outlined,
            ),
            const SizedBox(width: 12),
            ResultBox(
              label: widget.label,
              value: res.toString(),
              color: color,
              icon: res ? Icons.check_circle : Icons.cancel,
            ),
            const Spacer(),
            ResetButton(onTap: () => setState(() {
                  _a = List.from(widget.defaultA);
                  _b = List.from(widget.defaultB);
                })),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'bool'),
          kv('value', res.toString(), glow: true),
        ],
        callRows: [
          kv('fn', widget.fnSignature),
          kv('feature1', '${_a.length} pts'),
          kv('feature2', '${_b.length} pts'),
        ],
      ),
    );
  }

  fm.Marker _vertex(int gi, int idx, LatLng pt) {
    final isActive = _draggingIndex == idx + gi * 1000;
    return fm.Marker(
      point: pt,
      width: 24,
      height: 24,
      alignment: Alignment.center,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _draggingIndex = idx + gi * 1000),
        onPanUpdate: (d) => _onDrag(gi, idx, d),
        onPanEnd: (_) => setState(() => _draggingIndex = null),
        child: DraggableHandleMarker(active: isActive, size: 22),
      ),
    );
  }
}
