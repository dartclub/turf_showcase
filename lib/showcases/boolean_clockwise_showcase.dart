import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/boolean.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class BooleanClockwiseShowcase extends StatefulWidget {
  const BooleanClockwiseShowcase({super.key});

  @override
  State<BooleanClockwiseShowcase> createState() => _BooleanClockwiseShowcaseState();
}

class _BooleanClockwiseShowcaseState extends State<BooleanClockwiseShowcase> {
  static List<LatLng> get _cwDefault => const [
        LatLng(0, 0),
        LatLng(1, 0),
        LatLng(1, 1),
        LatLng(0, 1),
        LatLng(0, 0),
      ];

  late List<LatLng> _vertices;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _vertices = List.from(_cwDefault);
  }

  bool get _isClockwise {
    final coords = _vertices
        .map((v) => turf.Position(v.longitude, v.latitude))
        .toList();
    if (coords.length < 4) return false;
    final line = turf.LineString(coordinates: coords);
    return booleanClockwise(line);
  }

  void _reverse() => setState(() => _vertices = _vertices.reversed.toList());

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_vertices[idx]) + d.delta);
    setState(() => _vertices[idx] = next);
  }

  @override
  Widget build(BuildContext context) {
    final cw = _isClockwise;
    final color = cw ? ShowcaseColors.mint : ShowcaseColors.coral;
    return ShowcaseFrame(
      hint: 'Numbers show vertex order — green = clockwise, red = counter-CW',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: _vertices,
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
              points: _vertices,
              color: color.withOpacity(0.85),
              strokeWidth: 4,
            ),
          ]),
          fm.MarkerLayer(
            markers: _vertices.asMap().entries.map((e) {
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: ShowcaseColors.sky.withOpacity(0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: isActive ? 3 : 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${e.key + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
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
              label: 'clockwise',
              value: cw.toString(),
              color: color,
              icon: cw ? Icons.rotate_right : Icons.rotate_left,
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: _reverse,
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ShowcaseColors.sun.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ShowcaseColors.sun.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.swap_horiz, color: ShowcaseColors.sun, size: 13),
                    SizedBox(width: 5),
                    Text('Reverse winding',
                        style: TextStyle(
                          color: ShowcaseColors.sun,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ResetButton(onTap: () => setState(() => _vertices = List.from(_cwDefault))),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'bool'),
          kv('value', cw.toString(), glow: true),
        ],
        callRows: [
          kv('fn', 'booleanClockwise(line)'),
          kv('vertices', '${_vertices.length}'),
        ],
      ),
    );
  }
}
