import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/polygon_to_line.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class PolygonToLineShowcase extends StatefulWidget {
  const PolygonToLineShowcase({super.key});

  @override
  State<PolygonToLineShowcase> createState() => _PolygonToLineShowcaseState();
}

class _PolygonToLineShowcaseState extends State<PolygonToLineShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(-30, 125),
        LatLng(-30, 145),
        LatLng(-20, 145),
        LatLng(-20, 125),
      ];

  late List<LatLng> _corners;
  bool _showLine = true;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _corners = List.from(_defaults);
  }

  List<LatLng> get _line {
    final ring = [
      ..._corners.map((c) => turf.Position(c.longitude, c.latitude)),
      turf.Position(_corners.first.longitude, _corners.first.latitude),
    ];
    final poly = turf.Feature<turf.Polygon>(
      geometry: turf.Polygon(coordinates: [ring]),
    );
    final result = polygonToLine(poly);
    if (result is turf.Feature) {
      final geom = result.geometry as turf.LineString;
      return geom.coordinates
          .map((p) => LatLng(p.lat.toDouble(), p.lng.toDouble()))
          .toList();
    }
    return [];
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_corners[idx]) + d.delta);
    setState(() => _corners[idx] = next);
  }

  void _reset() => setState(() => _corners = List.from(_defaults));

  @override
  Widget build(BuildContext context) {
    final line = _line;
    return ShowcaseFrame(
      hint: 'Toggle to swap between the input polygon and the output line',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: _corners,
            padding: const EdgeInsets.all(70),
          ),
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
          ),
        ),
        children: [
          darkTileLayer(),
          if (!_showLine)
            fm.PolygonLayer(polygons: [
              fm.Polygon(
                points: _corners,
                color: ShowcaseColors.sky.withOpacity(0.2),
                borderColor: ShowcaseColors.sky.withOpacity(0.85),
                borderStrokeWidth: 2.5,
              ),
            ]),
          if (_showLine)
            fm.PolylineLayer(polylines: [
              fm.Polyline(
                points: line,
                color: ShowcaseColors.mint.withOpacity(0.9),
                strokeWidth: 4,
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
            ChipBadge(
              text: 'polygon ${_corners.length}',
              color: ShowcaseColors.sky,
              icon: Icons.hexagon_outlined,
            ),
            const SizedBox(width: 8),
            ChipBadge(
              text: 'line ${line.length}',
              color: ShowcaseColors.mint,
              icon: Icons.timeline,
            ),
            const SizedBox(width: 14),
            Switch(
              value: _showLine,
              onChanged: (v) => setState(() => _showLine = v),
              activeColor: ShowcaseColors.mint,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            const Text(
              'show line',
              style: TextStyle(
                color: ShowcaseColors.dim,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'Feature<LineString>'),
          kv('vertices', '${line.length}', glow: true),
        ],
        callRows: [
          kv('fn', 'polygonToLine(poly)'),
          kv('input', '${_corners.length} ring vertices'),
        ],
      ),
    );
  }
}
