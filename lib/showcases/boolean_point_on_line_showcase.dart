import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/boolean.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class BooleanPointOnLineShowcase extends StatefulWidget {
  const BooleanPointOnLineShowcase({super.key});

  @override
  State<BooleanPointOnLineShowcase> createState() =>
      _BooleanPointOnLineShowcaseState();
}

class _BooleanPointOnLineShowcaseState
    extends State<BooleanPointOnLineShowcase> {
  static List<LatLng> get _lineDefault => const [
        LatLng(38.878605, -77.031669),
        LatLng(38.881946, -77.029609),
      ];
  static const _ptDefault = LatLng(38.880275, -77.030639);

  late List<LatLng> _line;
  late LatLng _point;
  bool _ignoreEndVertices = false;
  bool _draggingPoint = false;
  int? _draggingLineIdx;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _line = List.from(_lineDefault);
    _point = _ptDefault;
  }

  bool get _onLine {
    final pt = turf.Point(coordinates: turf.Position(_point.longitude, _point.latitude));
    final line = turf.LineString(
      coordinates: _line.map((p) => turf.Position(p.longitude, p.latitude)).toList(),
    );
    return booleanPointOnLine(pt, line, ignoreEndVertices: _ignoreEndVertices);
  }

  void _onPointDrag(DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_point) + d.delta);
    setState(() => _point = next);
  }

  void _onLineDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_line[idx]) + d.delta);
    setState(() => _line[idx] = next);
  }

  void _reset() => setState(() {
        _line = List.from(_lineDefault);
        _point = _ptDefault;
      });

  @override
  Widget build(BuildContext context) {
    final on = _onLine;
    final color = on ? ShowcaseColors.mint : ShowcaseColors.coral;
    return ShowcaseFrame(
      hint: 'Drag the point precisely onto the line for true',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [..._line, _point],
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
              color: ShowcaseColors.sky.withOpacity(0.9),
              strokeWidth: 4,
            ),
          ]),
          fm.MarkerLayer(markers: [
            ..._line.asMap().entries.map((e) {
              final isActive = _draggingLineIdx == e.key;
              return fm.Marker(
                point: e.value,
                width: 26,
                height: 26,
                alignment: Alignment.center,
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _draggingLineIdx = e.key),
                  onPanUpdate: (d) => _onLineDrag(e.key, d),
                  onPanEnd: (_) => setState(() => _draggingLineIdx = null),
                  child: DraggableHandleMarker(active: isActive, size: 22),
                ),
              );
            }),
            fm.Marker(
              point: _point,
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _draggingPoint = true),
                onPanUpdate: _onPointDrag,
                onPanEnd: (_) => setState(() => _draggingPoint = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: _draggingPoint ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    on ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
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
              label: 'onLine',
              value: on.toString(),
              color: color,
              icon: on ? Icons.check_circle : Icons.cancel,
            ),
            const SizedBox(width: 14),
            Switch(
              value: _ignoreEndVertices,
              onChanged: (v) => setState(() => _ignoreEndVertices = v),
              activeColor: ShowcaseColors.mint,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            const Text(
              'ignoreEndVertices',
              style: TextStyle(
                color: ShowcaseColors.dim,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'bool'),
          kv('value', on.toString(), glow: true),
        ],
        callRows: [
          kv('fn', 'booleanPointOnLine(pt, line)'),
          kv('ignoreEndVertices', _ignoreEndVertices.toString()),
        ],
      ),
    );
  }
}
