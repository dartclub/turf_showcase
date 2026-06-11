import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/line_intersect.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class LineIntersectShowcase extends StatefulWidget {
  const LineIntersectShowcase({super.key});

  @override
  State<LineIntersectShowcase> createState() => _LineIntersectShowcaseState();
}

class _LineIntersectShowcaseState extends State<LineIntersectShowcase> {
  static List<LatLng> get _line1Default => const [
        LatLng(37.770, -122.435),
        LatLng(37.778, -122.420),
      ];
  static List<LatLng> get _line2Default => const [
        LatLng(37.775, -122.434),
        LatLng(37.775, -122.421),
      ];

  late List<LatLng> _line1;
  late List<LatLng> _line2;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _line1 = List.from(_line1Default);
    _line2 = List.from(_line2Default);
  }

  List<LatLng> get _intersections {
    final l1 = turf.Feature<turf.LineString>(
      geometry: turf.LineString(
        coordinates: _line1.map((p) => turf.Position(p.longitude, p.latitude)).toList(),
      ),
    );
    final l2 = turf.Feature<turf.LineString>(
      geometry: turf.LineString(
        coordinates: _line2.map((p) => turf.Position(p.longitude, p.latitude)).toList(),
      ),
    );
    final fc = lineIntersect(l1, l2);
    return fc.features.map((f) {
      final c = f.geometry!.coordinates;
      return LatLng(c.lat.toDouble(), c.lng.toDouble());
    }).toList();
  }

  void _onDrag(int gi, int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final base = gi == 0 ? _line1[idx] : _line2[idx];
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(base) + d.delta);
    setState(() {
      if (gi == 0) {
        _line1[idx] = next;
      } else {
        _line2[idx] = next;
      }
    });
  }

  void _reset() => setState(() {
        _line1 = List.from(_line1Default);
        _line2 = List.from(_line2Default);
      });

  @override
  Widget build(BuildContext context) {
    final hits = _intersections;
    return ShowcaseFrame(
      hint: 'Drag any vertex — yellow dots mark each intersection point',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [..._line1, ..._line2],
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
              points: _line1,
              color: ShowcaseColors.sky.withOpacity(0.85),
              strokeWidth: 4,
            ),
            fm.Polyline(
              points: _line2,
              color: ShowcaseColors.coral.withOpacity(0.85),
              strokeWidth: 4,
            ),
          ]),
          fm.MarkerLayer(markers: [
            ...hits.map((p) => fm.Marker(
                  point: p,
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      color: ShowcaseColors.sun,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: ShowcaseColors.sun.withOpacity(0.6),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child:
                        const Icon(Icons.close, color: Colors.black87, size: 16),
                  ),
                )),
            ..._line1.asMap().entries.map((e) => _vertex(0, e.key, e.value)),
            ..._line2.asMap().entries.map((e) => _vertex(1, e.key, e.value)),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ChipBadge(
              text: 'line1',
              color: ShowcaseColors.sky,
              icon: Icons.timeline,
            ),
            const SizedBox(width: 6),
            ChipBadge(
              text: 'line2',
              color: ShowcaseColors.coral,
              icon: Icons.timeline,
            ),
            const SizedBox(width: 12),
            ResultBox(
              label: 'intersections',
              value: hits.length.toString(),
              icon: Icons.close,
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'FeatureCollection<Point>'),
          kv('features', hits.length.toString(), glow: true),
        ],
        callRows: [
          kv('fn', 'lineIntersect(line1, line2)'),
          kv('line1', '${_line1.length} pts'),
          kv('line2', '${_line2.length} pts'),
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
