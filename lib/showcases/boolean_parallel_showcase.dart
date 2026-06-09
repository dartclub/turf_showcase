import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/boolean.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class BooleanParallelShowcase extends StatefulWidget {
  const BooleanParallelShowcase({super.key});

  @override
  State<BooleanParallelShowcase> createState() => _BooleanParallelShowcaseState();
}

class _BooleanParallelShowcaseState extends State<BooleanParallelShowcase> {
  static List<LatLng> get _l1Default => const [
        LatLng(0, 0),
        LatLng(1, 0),
      ];
  static List<LatLng> get _l2Default => const [
        LatLng(0, 1),
        LatLng(1, 1),
      ];

  late List<LatLng> _line1;
  late List<LatLng> _line2;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _line1 = List.from(_l1Default);
    _line2 = List.from(_l2Default);
  }

  bool get _parallel {
    if (_line1.length < 2 || _line2.length < 2) return false;
    final l1 = turf.LineString(
      coordinates: _line1.map((p) => turf.Position(p.longitude, p.latitude)).toList(),
    );
    final l2 = turf.LineString(
      coordinates: _line2.map((p) => turf.Position(p.longitude, p.latitude)).toList(),
    );
    return booleanParallel(l1, l2);
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

  @override
  Widget build(BuildContext context) {
    final res = _parallel;
    final color = res ? ShowcaseColors.mint : ShowcaseColors.coral;
    return ShowcaseFrame(
      hint: 'Drag a vertex to change the slope of either line',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [..._line1, ..._line2],
            padding: const EdgeInsets.all(80),
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
              color: ShowcaseColors.sky.withOpacity(0.9),
              strokeWidth: 4,
            ),
            fm.Polyline(
              points: _line2,
              color: ShowcaseColors.coral.withOpacity(0.9),
              strokeWidth: 4,
            ),
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
              label: 'parallel',
              value: res.toString(),
              color: color,
              icon: res ? Icons.check_circle : Icons.cancel,
            ),
            const Spacer(),
            ResetButton(onTap: () => setState(() {
                  _line1 = List.from(_l1Default);
                  _line2 = List.from(_l2Default);
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
          kv('fn', 'booleanParallel(l1, l2)'),
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
