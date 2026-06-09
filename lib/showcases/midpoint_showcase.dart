import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/midpoint.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class MidpointShowcase extends StatefulWidget {
  const MidpointShowcase({super.key});

  @override
  State<MidpointShowcase> createState() => _MidpointShowcaseState();
}

class _MidpointShowcaseState extends State<MidpointShowcase> {
  static const _defaultA = LatLng(-37.771257, 144.834823);
  static const _defaultB = LatLng(-37.830937, 145.142440);

  late LatLng _a;
  late LatLng _b;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _a = _defaultA;
    _b = _defaultB;
  }

  LatLng get _mid {
    final pa = turf.Point(coordinates: turf.Position(_a.longitude, _a.latitude));
    final pb = turf.Point(coordinates: turf.Position(_b.longitude, _b.latitude));
    final m = midpoint(pa, pb);
    return LatLng(
      m.coordinates.lat.toDouble(),
      m.coordinates.lng.toDouble(),
    );
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final base = idx == 0 ? _a : _b;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(base) + d.delta);
    setState(() {
      if (idx == 0) {
        _a = next;
      } else {
        _b = next;
      }
    });
  }

  void _reset() => setState(() {
        _a = _defaultA;
        _b = _defaultB;
      });

  @override
  Widget build(BuildContext context) {
    final mid = _mid;
    return ShowcaseFrame(
      hint: 'Drag either point — the midpoint follows along the great circle',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [_a, _b],
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
              points: [_a, _b],
              color: ShowcaseColors.sky.withOpacity(0.7),
              strokeWidth: 2.5,
              pattern: fm.StrokePattern.dashed(segments: const [8.0, 6.0]),
            ),
          ]),
          fm.MarkerLayer(markers: [
            fm.Marker(
              point: mid,
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
                child: const Icon(Icons.adjust, color: Colors.black87, size: 20),
              ),
            ),
            _handle(0, _a, ShowcaseColors.lime),
            _handle(1, _b, ShowcaseColors.coral),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ResultBox(
              label: 'midpoint',
              value: '${mid.latitude.toStringAsFixed(4)}, ${mid.longitude.toStringAsFixed(4)}',
              icon: Icons.adjust,
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'Feature<Point>'),
          kv('lat', mid.latitude.toStringAsFixed(6), glow: true),
          kv('lng', mid.longitude.toStringAsFixed(6), glow: true),
        ],
        callRows: [
          kv('fn', 'midpoint(p1, p2)'),
          kv('p1', '${_a.longitude.toStringAsFixed(3)}, ${_a.latitude.toStringAsFixed(3)}'),
          kv('p2', '${_b.longitude.toStringAsFixed(3)}, ${_b.latitude.toStringAsFixed(3)}'),
        ],
      ),
    );
  }

  fm.Marker _handle(int idx, LatLng pt, Color color) {
    final isActive = _draggingIndex == idx;
    return fm.Marker(
      point: pt,
      width: 36,
      height: 36,
      alignment: Alignment.center,
      child: GestureDetector(
        onPanStart: (_) => setState(() => _draggingIndex = idx),
        onPanUpdate: (d) => _onDrag(idx, d),
        onPanEnd: (_) => setState(() => _draggingIndex = null),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: isActive ? 3 : 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isActive ? 0.6 : 0.4),
                blurRadius: isActive ? 14 : 8,
                spreadRadius: isActive ? 2 : 1,
              ),
            ],
          ),
          child: Icon(
            idx == 0 ? Icons.flag : Icons.location_on,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}
