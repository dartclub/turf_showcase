import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/boolean.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class BooleanCrossesShowcase extends StatefulWidget {
  const BooleanCrossesShowcase({super.key});

  @override
  State<BooleanCrossesShowcase> createState() => _BooleanCrossesShowcaseState();
}

class _BooleanCrossesShowcaseState extends State<BooleanCrossesShowcase> {
  static List<LatLng> get _lineDefault => const [
        LatLng(2, 2),
        LatLng(4, 4),
      ];
  static List<LatLng> get _polyDefault => const [
        LatLng(3, 1),
        LatLng(3, 3),
        LatLng(5, 3),
        LatLng(5, 1),
      ];

  late List<LatLng> _line;
  late List<LatLng> _poly;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _line = List.from(_lineDefault);
    _poly = List.from(_polyDefault);
  }

  bool get _crosses {
    final lineFeat = turf.Feature<turf.LineString>(
      geometry: turf.LineString(
        coordinates: _line.map((p) => turf.Position(p.longitude, p.latitude)).toList(),
      ),
    );
    final polyRing = [
      ..._poly.map((p) => turf.Position(p.longitude, p.latitude)),
      turf.Position(_poly.first.longitude, _poly.first.latitude),
    ];
    final polyFeat = turf.Feature<turf.Polygon>(
      geometry: turf.Polygon(coordinates: [polyRing]),
    );
    try {
      return booleanCrosses(lineFeat, polyFeat);
    } catch (_) {
      return false;
    }
  }

  void _onDrag(int gi, int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final base = gi == 0 ? _line[idx] : _poly[idx];
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(base) + d.delta);
    setState(() {
      if (gi == 0) {
        _line[idx] = next;
      } else {
        _poly[idx] = next;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final res = _crosses;
    final color = res ? ShowcaseColors.mint : ShowcaseColors.coral;
    return ShowcaseFrame(
      hint: 'A line crosses a polygon when only part of the line is inside',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [..._line, ..._poly],
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
              points: _poly,
              color: ShowcaseColors.coral.withOpacity(0.18),
              borderColor: ShowcaseColors.coral.withOpacity(0.85),
              borderStrokeWidth: 2.5,
            ),
          ]),
          fm.PolylineLayer(polylines: [
            fm.Polyline(
              points: _line,
              color: ShowcaseColors.sky.withOpacity(0.9),
              strokeWidth: 4,
            ),
          ]),
          fm.MarkerLayer(markers: [
            ..._line.asMap().entries.map((e) => _vertex(0, e.key, e.value)),
            ..._poly.asMap().entries.map((e) => _vertex(1, e.key, e.value)),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ChipBadge(text: 'line', color: ShowcaseColors.sky, icon: Icons.timeline),
            const SizedBox(width: 6),
            ChipBadge(text: 'polygon', color: ShowcaseColors.coral, icon: Icons.hexagon_outlined),
            const SizedBox(width: 12),
            ResultBox(
              label: 'crosses',
              value: res.toString(),
              color: color,
              icon: res ? Icons.check_circle : Icons.cancel,
            ),
            const Spacer(),
            ResetButton(onTap: () => setState(() {
                  _line = List.from(_lineDefault);
                  _poly = List.from(_polyDefault);
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
          kv('fn', 'booleanCrosses(line, poly)'),
        ],
      ),
    );
  }

  fm.Marker _vertex(int gi, int idx, LatLng pt) {
    final isActive = _draggingIndex == idx + gi * 100;
    return fm.Marker(
      point: pt,
      width: 24,
      height: 24,
      alignment: Alignment.center,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _draggingIndex = idx + gi * 100),
        onPanUpdate: (d) => _onDrag(gi, idx, d),
        onPanEnd: (_) => setState(() => _draggingIndex = null),
        child: DraggableHandleMarker(active: isActive, size: 22),
      ),
    );
  }
}
