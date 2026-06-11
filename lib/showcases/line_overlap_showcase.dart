import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/line_overlap.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class LineOverlapShowcase extends StatefulWidget {
  const LineOverlapShowcase({super.key});

  @override
  State<LineOverlapShowcase> createState() => _LineOverlapShowcaseState();
}

class _LineOverlapShowcaseState extends State<LineOverlapShowcase> {
  static List<LatLng> get _line1Default => const [
        LatLng(0, 115),
        LatLng(0, 125),
        LatLng(5, 125),
      ];
  static List<LatLng> get _line2Default => const [
        LatLng(0, 120),
        LatLng(0, 130),
      ];

  late List<LatLng> _line1;
  late List<LatLng> _line2;
  double _tolerance = 0;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _line1 = List.from(_line1Default);
    _line2 = List.from(_line2Default);
  }

  List<List<LatLng>> get _overlaps {
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
    final fc = lineOverlap(l1, l2, tolerance: _tolerance);
    return fc.features.map((f) {
      final g = f.geometry!;
      return g.coordinates
          .map((p) => LatLng(p.lat.toDouble(), p.lng.toDouble()))
          .toList();
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
        _tolerance = 0;
      });

  @override
  Widget build(BuildContext context) {
    final overlaps = _overlaps;
    return ShowcaseFrame(
      hint: 'Yellow segments are the parts where the two lines overlap',
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
              color: ShowcaseColors.sky.withOpacity(0.7),
              strokeWidth: 6,
            ),
            fm.Polyline(
              points: _line2,
              color: ShowcaseColors.coral.withOpacity(0.7),
              strokeWidth: 4,
            ),
            ...overlaps.map((seg) => fm.Polyline(
                  points: seg,
                  color: ShowcaseColors.sun.withOpacity(0.95),
                  strokeWidth: 4,
                )),
          ]),
          fm.MarkerLayer(markers: [
            ..._line1.asMap().entries.map((e) => _vertex(0, e.key, e.value)),
            ..._line2.asMap().entries.map((e) => _vertex(1, e.key, e.value)),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ChipBadge(text: 'line1', color: ShowcaseColors.sky, icon: Icons.timeline),
            const SizedBox(width: 6),
            ChipBadge(text: 'line2', color: ShowcaseColors.coral, icon: Icons.timeline),
            const SizedBox(width: 12),
            ResultBox(
              label: 'overlaps',
              value: overlaps.length.toString(),
              icon: Icons.merge_type,
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('tolerance',
                style: TextStyle(
                  color: ShowcaseColors.dim,
                  fontFamily: 'monospace',
                  fontSize: 12,
                )),
            const SizedBox(width: 10),
            ResultBox(label: 'km', value: _tolerance.toStringAsFixed(2)),
            Expanded(
              child: Slider(
                value: _tolerance,
                min: 0,
                max: 100,
                onChanged: (v) => setState(() => _tolerance = v),
                activeColor: ShowcaseColors.mint,
                inactiveColor: ShowcaseColors.cage,
              ),
            ),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'FeatureCollection<LineString>'),
          kv('overlaps', overlaps.length.toString(), glow: true),
        ],
        callRows: [
          kv('fn', 'lineOverlap(l1, l2)'),
          kv('tolerance', '${_tolerance.toStringAsFixed(2)} km'),
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
