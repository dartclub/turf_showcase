import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/line_slice.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class LineSliceShowcase extends StatefulWidget {
  const LineSliceShowcase({super.key});

  @override
  State<LineSliceShowcase> createState() => _LineSliceShowcaseState();
}

class _LineSliceShowcaseState extends State<LineSliceShowcase> {
  static List<LatLng> get _lineDefault => const [
        LatLng(38.878605, -77.031669),
        LatLng(38.881946, -77.029609),
        LatLng(38.884084, -77.020339),
        LatLng(38.885821, -77.025661),
        LatLng(38.892368, -77.019824),
      ];
  static const _startDefault = LatLng(38.881946, -77.029609);
  static const _stopDefault = LatLng(38.885821, -77.025661);

  late List<LatLng> _line;
  late LatLng _start;
  late LatLng _stop;
  bool _draggingStart = false;
  bool _draggingStop = false;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _line = List.from(_lineDefault);
    _start = _startDefault;
    _stop = _stopDefault;
  }

  List<LatLng> get _slice {
    final lineFeat = turf.Feature<turf.LineString>(
      geometry: turf.LineString(
        coordinates: _line.map((p) => turf.Position(p.longitude, p.latitude)).toList(),
      ),
    );
    final startFeat = turf.Feature<turf.Point>(
      geometry: turf.Point(coordinates: turf.Position(_start.longitude, _start.latitude)),
    );
    final stopFeat = turf.Feature<turf.Point>(
      geometry: turf.Point(coordinates: turf.Position(_stop.longitude, _stop.latitude)),
    );
    final result = lineSlice(startFeat, stopFeat, lineFeat);
    return result.geometry!.coordinates
        .map((p) => LatLng(p.lat.toDouble(), p.lng.toDouble()))
        .toList();
  }

  void _onDragStart(DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_start) + d.delta);
    setState(() => _start = next);
  }

  void _onDragStop(DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_stop) + d.delta);
    setState(() => _stop = next);
  }

  void _reset() => setState(() {
        _line = List.from(_lineDefault);
        _start = _startDefault;
        _stop = _stopDefault;
      });

  @override
  Widget build(BuildContext context) {
    final slice = _slice;
    return ShowcaseFrame(
      hint: 'Drag start/stop — the slice snaps to the nearest line segment',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: _line,
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
              points: _line,
              color: ShowcaseColors.dim.withOpacity(0.6),
              strokeWidth: 3,
            ),
            fm.Polyline(
              points: slice,
              color: ShowcaseColors.mint.withOpacity(0.95),
              strokeWidth: 5,
            ),
          ]),
          fm.MarkerLayer(markers: [
            fm.Marker(
              point: _start,
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _draggingStart = true),
                onPanUpdate: _onDragStart,
                onPanEnd: (_) => setState(() => _draggingStart = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: ShowcaseColors.lime,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: _draggingStart ? 3 : 2),
                  ),
                  child: const Icon(Icons.flag, color: Colors.white, size: 16),
                ),
              ),
            ),
            fm.Marker(
              point: _stop,
              width: 36,
              height: 36,
              alignment: Alignment.center,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _draggingStop = true),
                onPanUpdate: _onDragStop,
                onPanEnd: (_) => setState(() => _draggingStop = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: ShowcaseColors.coral,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: _draggingStop ? 3 : 2),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                ),
              ),
            ),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ChipBadge(text: 'start', color: ShowcaseColors.lime, icon: Icons.flag),
            const SizedBox(width: 8),
            ChipBadge(text: 'stop', color: ShowcaseColors.coral, icon: Icons.location_on),
            const SizedBox(width: 12),
            ResultBox(
              label: 'slice vertices',
              value: slice.length.toString(),
              icon: Icons.content_cut,
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'Feature<LineString>'),
          kv('vertices', slice.length.toString(), glow: true),
        ],
        callRows: [
          kv('fn', 'lineSlice(start, stop, line)'),
          kv('input', '${_line.length} vertices'),
        ],
      ),
    );
  }
}
