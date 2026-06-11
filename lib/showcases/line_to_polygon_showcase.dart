import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/line_to_polygon.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class LineToPolygonShowcase extends StatefulWidget {
  const LineToPolygonShowcase({super.key});

  @override
  State<LineToPolygonShowcase> createState() => _LineToPolygonShowcaseState();
}

class _LineToPolygonShowcaseState extends State<LineToPolygonShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(-30, 125),
        LatLng(-30, 145),
        LatLng(-20, 145),
        LatLng(-20, 125),
      ];

  late List<LatLng> _vertices;
  bool _autoComplete = true;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _vertices = List.from(_defaults);
  }

  List<LatLng>? get _polygonRing {
    final coords =
        _vertices.map((v) => turf.Position(v.longitude, v.latitude)).toList();
    final line = turf.Feature<turf.LineString>(
      geometry: turf.LineString(coordinates: coords),
    );
    if (_vertices.length < 3) return null;
    try {
      final result = lineToPolygon(line, autoComplete: _autoComplete);
      final poly = result.geometry as turf.Polygon;
      return poly.coordinates.first
          .map((p) => LatLng(p.lat.toDouble(), p.lng.toDouble()))
          .toList();
    } catch (_) {
      return null;
    }
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_vertices[idx]) + d.delta);
    setState(() => _vertices[idx] = next);
  }

  void _addVertex() {
    final last = _vertices.last;
    setState(() => _vertices.add(LatLng(last.latitude + 3, last.longitude + 3)));
  }

  void _removeVertex() {
    if (_vertices.length <= 3) return;
    setState(() => _vertices.removeLast());
  }

  void _reset() => setState(() {
        _vertices = List.from(_defaults);
        _autoComplete = true;
      });

  @override
  Widget build(BuildContext context) {
    final ring = _polygonRing;
    return ShowcaseFrame(
      hint: 'Drag vertices — line auto-closes into a polygon',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: _vertices,
            padding: const EdgeInsets.all(70),
          ),
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
          ),
        ),
        children: [
          darkTileLayer(),
          if (ring != null)
            fm.PolygonLayer(polygons: [
              fm.Polygon(
                points: ring,
                color: ShowcaseColors.mint.withOpacity(0.18),
                borderColor: ShowcaseColors.mint.withOpacity(0.85),
                borderStrokeWidth: 2.5,
              ),
            ]),
          fm.PolylineLayer(polylines: [
            fm.Polyline(
              points: _vertices,
              color: ShowcaseColors.coral.withOpacity(0.85),
              strokeWidth: 3,
            ),
          ]),
          fm.MarkerLayer(
            markers: _vertices.asMap().entries.map((e) {
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
              text: 'line ${_vertices.length}',
              color: ShowcaseColors.coral,
              icon: Icons.timeline,
            ),
            const SizedBox(width: 8),
            ChipBadge(
              text: 'polygon ${ring?.length ?? 0}',
              color: ShowcaseColors.mint,
              icon: Icons.hexagon_outlined,
            ),
            const SizedBox(width: 14),
            Switch(
              value: _autoComplete,
              onChanged: (v) => setState(() => _autoComplete = v),
              activeColor: ShowcaseColors.mint,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            const Text(
              'autoComplete',
              style: TextStyle(
                color: ShowcaseColors.dim,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            _btn(Icons.add, 'Add', _addVertex),
            const SizedBox(width: 6),
            _btn(Icons.remove, 'Remove',
                _vertices.length > 3 ? _removeVertex : null),
            const SizedBox(width: 8),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'Feature<Polygon>'),
          kv('vertices', '${ring?.length ?? 0}', glow: true),
        ],
        callRows: [
          kv('fn', 'lineToPolygon(line)'),
          kv('input', '${_vertices.length} pts'),
          kv('autoComplete', _autoComplete.toString()),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: ShowcaseColors.ink,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: enabled
                ? ShowcaseColors.cage
                : ShowcaseColors.cage.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: enabled
                    ? ShowcaseColors.bright
                    : ShowcaseColors.dim),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  color: enabled ? ShowcaseColors.bright : ShowcaseColors.dim,
                  fontSize: 11,
                  fontFamily: 'monospace',
                )),
          ],
        ),
      ),
    );
  }
}
