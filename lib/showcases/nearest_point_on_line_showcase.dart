import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/nearest_point_on_line.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class NearestPointOnLineShowcase extends StatefulWidget {
  const NearestPointOnLineShowcase({super.key});

  @override
  State<NearestPointOnLineShowcase> createState() =>
      _NearestPointOnLineShowcaseState();
}

class _NearestPointOnLineShowcaseState
    extends State<NearestPointOnLineShowcase> {
  static List<LatLng> get _defaultLine => const [
        LatLng(38.878605, -77.031669),
        LatLng(38.880000, -77.030500),
        LatLng(38.881946, -77.029609),
        LatLng(38.884000, -77.028400),
      ];
  static const _defaultPt = LatLng(38.884017, -77.037076);

  late List<LatLng> _line;
  late LatLng _target;
  bool _draggingTarget = false;
  int? _draggingVertex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _line = List.from(_defaultLine);
    _target = _defaultPt;
  }

  Map<String, dynamic> get _result {
    final lineGeom = turf.LineString(
      coordinates:
          _line.map((p) => turf.Position(p.longitude, p.latitude)).toList(),
    );
    final ptGeom = turf.Point(
      coordinates: turf.Position(_target.longitude, _target.latitude),
    );
    final res = nearestPointOnLine(lineGeom, ptGeom, turf.Unit.kilometers);
    final coords = res.geometry!.coordinates;
    final dist = (res.properties?['dist'] as num?)?.toDouble() ?? 0;
    return {
      'point': LatLng(coords.lat.toDouble(), coords.lng.toDouble()),
      'dist': dist,
    };
  }

  void _onTargetDrag(DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_target) + d.delta);
    setState(() => _target = next);
  }

  void _onVertexDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_line[idx]) + d.delta);
    setState(() => _line[idx] = next);
  }

  void _reset() => setState(() {
        _line = List.from(_defaultLine);
        _target = _defaultPt;
      });

  @override
  Widget build(BuildContext context) {
    final r = _result;
    final snapped = r['point'] as LatLng;
    final dist = r['dist'] as double;
    return ShowcaseFrame(
      hint: 'Drag the green point or any line vertex',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [..._line, _target],
            padding: const EdgeInsets.all(70),
          ),
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
          ),
        ),
        children: [
          darkTileLayer(),
          fm.PolylineLayer(polylines: [
            fm.Polyline(
              points: _line,
              color: ShowcaseColors.mint.withOpacity(0.85),
              strokeWidth: 4,
            ),
            fm.Polyline(
              points: [_target, snapped],
              color: ShowcaseColors.sun.withOpacity(0.85),
              strokeWidth: 2,
              pattern: fm.StrokePattern.dashed(segments: const [8.0, 6.0]),
            ),
          ]),
          fm.MarkerLayer(markers: [
            ..._line.asMap().entries.map((e) {
              final isActive = _draggingVertex == e.key;
              return fm.Marker(
                point: e.value,
                width: 26,
                height: 26,
                alignment: Alignment.center,
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _draggingVertex = e.key),
                  onPanUpdate: (d) => _onVertexDrag(e.key, d),
                  onPanEnd: (_) => setState(() => _draggingVertex = null),
                  child: DraggableHandleMarker(active: isActive, size: 22),
                ),
              );
            }),
            fm.Marker(
              point: snapped,
              width: 38,
              height: 38,
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: ShowcaseColors.sun,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: ShowcaseColors.sun.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.location_searching,
                    color: Colors.black87, size: 16),
              ),
            ),
            fm.Marker(
              point: _target,
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _draggingTarget = true),
                onPanUpdate: _onTargetDrag,
                onPanEnd: (_) => setState(() => _draggingTarget = false),
                child: Container(
                  decoration: BoxDecoration(
                    color: ShowcaseColors.lime,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: _draggingTarget ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ShowcaseColors.lime.withOpacity(0.5),
                        blurRadius: _draggingTarget ? 14 : 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.my_location,
                      color: Colors.white, size: 18),
                ),
              ),
            ),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ResultBox(
              label: 'distance',
              value: '${dist.toStringAsFixed(3)} km',
              icon: Icons.straighten,
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'Feature<Point>'),
          kv('lat', snapped.latitude.toStringAsFixed(6), glow: true),
          kv('lng', snapped.longitude.toStringAsFixed(6), glow: true),
          kv('dist', '${dist.toStringAsFixed(4)} km'),
        ],
        callRows: [
          kv('fn', 'nearestPointOnLine(line, pt)'),
          kv('vertices', '${_line.length}'),
        ],
      ),
    );
  }
}
