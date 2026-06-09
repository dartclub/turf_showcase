import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/boolean.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class BooleanConcaveShowcase extends StatefulWidget {
  const BooleanConcaveShowcase({super.key});

  @override
  State<BooleanConcaveShowcase> createState() => _BooleanConcaveShowcaseState();
}

class _BooleanConcaveShowcaseState extends State<BooleanConcaveShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(0, 0),
        LatLng(1, 0),
        LatLng(0.5, 0.5),
        LatLng(1, 1),
        LatLng(0, 1),
      ];

  late List<LatLng> _corners;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _corners = List.from(_defaults);
  }

  bool get _isConcave {
    final ring = [
      ..._corners.map((c) => turf.Position(c.longitude, c.latitude)),
      turf.Position(_corners.first.longitude, _corners.first.latitude),
    ];
    final poly = turf.Polygon(coordinates: [ring]);
    if (_corners.length < 4) return false;
    return booleanConcave(poly);
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_corners[idx]) + d.delta);
    setState(() => _corners[idx] = next);
  }

  @override
  Widget build(BuildContext context) {
    final concave = _isConcave;
    final color = concave ? ShowcaseColors.coral : ShowcaseColors.mint;
    return ShowcaseFrame(
      hint: 'Drag the inner vertex outward to make the polygon convex',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: _corners,
            padding: const EdgeInsets.all(80),
          ),
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
          ),
        ),
        children: [
          darkTileLayer(),
          fm.PolygonLayer(polygons: [
            fm.Polygon(
              points: _corners,
              color: color.withOpacity(0.18),
              borderColor: color.withOpacity(0.9),
              borderStrokeWidth: 2.5,
            ),
          ]),
          fm.MarkerLayer(
            markers: _corners.asMap().entries.map((e) {
              final isActive = _draggingIndex == e.key;
              return fm.Marker(
                point: e.value,
                width: 28,
                height: 28,
                alignment: Alignment.center,
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _draggingIndex = e.key),
                  onPanUpdate: (d) => _onDrag(e.key, d),
                  onPanEnd: (_) => setState(() => _draggingIndex = null),
                  child: DraggableHandleMarker(active: isActive, size: 24),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ResultBox(
              label: 'concave',
              value: concave.toString(),
              color: color,
              icon: concave ? Icons.warning_amber : Icons.check_circle_outline,
            ),
            const Spacer(),
            ResetButton(onTap: () => setState(() => _corners = List.from(_defaults))),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'bool'),
          kv('value', concave.toString(), glow: true),
        ],
        callRows: [
          kv('fn', 'booleanConcave(polygon)'),
          kv('vertices', '${_corners.length}'),
        ],
      ),
    );
  }
}
