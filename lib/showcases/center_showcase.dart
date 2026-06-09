import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/center.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class CenterShowcase extends StatefulWidget {
  const CenterShowcase({super.key});

  @override
  State<CenterShowcase> createState() => _CenterShowcaseState();
}

class _CenterShowcaseState extends State<CenterShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(40.0, -75.0),
        LatLng(41.0, -73.0),
        LatLng(42.5, -76.0),
        LatLng(43.0, -78.0),
      ];

  late List<LatLng> _points;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _points = List.from(_defaults);
  }

  LatLng get _center {
    final fc = turf.FeatureCollection(
      features: _points
          .map((p) => turf.Feature<turf.Point>(
                geometry: turf.Point(coordinates: turf.Position(p.longitude, p.latitude)),
              ))
          .toList(),
    );
    final c = center(fc);
    return LatLng(
      c.geometry!.coordinates.lat.toDouble(),
      c.geometry!.coordinates.lng.toDouble(),
    );
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_points[idx]) + d.delta);
    setState(() => _points[idx] = next);
  }

  void _addPoint() {
    final last = _points.last;
    setState(() => _points.add(LatLng(last.latitude + 1, last.longitude + 1)));
  }

  void _removePoint() {
    if (_points.length <= 2) return;
    setState(() => _points.removeLast());
  }

  void _reset() => setState(() => _points = List.from(_defaults));

  @override
  Widget build(BuildContext context) {
    final c = _center;
    return ShowcaseFrame(
      hint: 'center returns the midpoint of the bbox of all input points',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [..._points, c],
            padding: const EdgeInsets.all(70),
          ),
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
          ),
        ),
        children: [
          darkTileLayer(),
          fm.MarkerLayer(markers: [
            ..._points.asMap().entries.map((e) {
              final isActive = _draggingIndex == e.key;
              return fm.Marker(
                point: e.value,
                width: 30,
                height: 30,
                alignment: Alignment.center,
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _draggingIndex = e.key),
                  onPanUpdate: (d) => _onDrag(e.key, d),
                  onPanEnd: (_) => setState(() => _draggingIndex = null),
                  child: DraggableHandleMarker(active: isActive),
                ),
              );
            }),
            fm.Marker(
              point: c,
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: ShowcaseColors.sun,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: ShowcaseColors.sun.withOpacity(0.6),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.center_focus_strong,
                    color: Colors.black87, size: 20),
              ),
            ),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ResultBox(
              label: 'center',
              value: '${c.latitude.toStringAsFixed(3)}, ${c.longitude.toStringAsFixed(3)}',
              icon: Icons.center_focus_strong,
            ),
            const SizedBox(width: 8),
            _btn(Icons.add, 'Add', _addPoint),
            const SizedBox(width: 6),
            _btn(Icons.remove, 'Remove',
                _points.length > 2 ? _removePoint : null),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'Feature<Point>'),
          kv('lat', c.latitude.toStringAsFixed(6), glow: true),
          kv('lng', c.longitude.toStringAsFixed(6), glow: true),
        ],
        callRows: [
          kv('fn', 'center(fc)'),
          kv('points', '${_points.length}'),
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
