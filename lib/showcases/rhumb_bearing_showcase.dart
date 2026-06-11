import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/bearing.dart' as bg;
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class RhumbBearingShowcase extends StatefulWidget {
  const RhumbBearingShowcase({super.key});

  @override
  State<RhumbBearingShowcase> createState() => _RhumbBearingShowcaseState();
}

class _RhumbBearingShowcaseState extends State<RhumbBearingShowcase> {
  static const _defaultStart = LatLng(39.984, -75.343);
  static const _defaultEnd = LatLng(39.123, -75.534);

  late LatLng _start;
  late LatLng _end;
  bool _finalBearing = false;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _start = _defaultStart;
    _end = _defaultEnd;
  }

  double get _bearingDeg {
    final s = turf.Point(coordinates: turf.Position(_start.longitude, _start.latitude));
    final e = turf.Point(coordinates: turf.Position(_end.longitude, _end.latitude));
    return bg.rhumbBearing(s, e, kFinal: _finalBearing).toDouble();
  }

  String get _compass {
    final n = ((_bearingDeg + 360) % 360);
    const dirs = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return dirs[((n + 22.5) ~/ 45) % 8];
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final base = idx == 0 ? _start : _end;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(base) + d.delta);
    setState(() {
      if (idx == 0) {
        _start = next;
      } else {
        _end = next;
      }
    });
  }

  void _reset() => setState(() {
        _start = _defaultStart;
        _end = _defaultEnd;
      });

  @override
  Widget build(BuildContext context) {
    return ShowcaseFrame(
      hint: 'A rhumb line keeps a constant compass bearing across the map',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [_start, _end],
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
              points: [_start, _end],
              color: ShowcaseColors.violet.withOpacity(0.85),
              strokeWidth: 3,
            ),
          ]),
          fm.MarkerLayer(markers: [
            _handle(0, _start, ShowcaseColors.lime, Icons.flag),
            _handle(1, _end, ShowcaseColors.coral, Icons.location_on),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ResultBox(
              label: 'bearing',
              value: '${_bearingDeg.toStringAsFixed(2)}°  ($_compass)',
              icon: Icons.explore,
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ShowcaseColors.ink,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ShowcaseColors.cage),
              ),
              child: Row(
                children: [
                  Switch(
                    value: _finalBearing,
                    onChanged: (v) => setState(() => _finalBearing = v),
                    activeColor: ShowcaseColors.mint,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'final',
                    style: TextStyle(
                      color: ShowcaseColors.dim,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'double'),
          kv('value', '${_bearingDeg.toStringAsFixed(4)}°', glow: true),
          kv('compass', _compass),
        ],
        callRows: [
          kv('fn', 'rhumbBearing(start, end)'),
          kv('start', '${_start.longitude.toStringAsFixed(3)}, ${_start.latitude.toStringAsFixed(3)}'),
          kv('end', '${_end.longitude.toStringAsFixed(3)}, ${_end.latitude.toStringAsFixed(3)}'),
          kv('final_', _finalBearing.toString()),
        ],
      ),
    );
  }

  fm.Marker _handle(int idx, LatLng pt, Color color, IconData icon) {
    final isActive = _draggingIndex == idx;
    return fm.Marker(
      point: pt,
      width: 40,
      height: 40,
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
          child: Icon(icon, color: Colors.white, size: isActive ? 20 : 18),
        ),
      ),
    );
  }
}
