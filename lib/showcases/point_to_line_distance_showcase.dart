import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/point_to_line_distance.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class PointToLineDistanceShowcase extends StatefulWidget {
  const PointToLineDistanceShowcase({super.key});

  @override
  State<PointToLineDistanceShowcase> createState() =>
      _PointToLineDistanceShowcaseState();
}

class _PointToLineDistanceShowcaseState
    extends State<PointToLineDistanceShowcase> {
  static const _defaultPoint = LatLng(40.0, -73.5);
  static List<LatLng> get _defaultLine => const [
        LatLng(39.0, -75.0),
        LatLng(41.0, -74.0),
        LatLng(42.0, -73.0),
      ];

  late LatLng _point;
  late List<LatLng> _line;
  bool _draggingPoint = false;
  int? _draggingVertex;
  turf.Unit _unit = turf.Unit.kilometers;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _point = _defaultPoint;
    _line = List.from(_defaultLine);
  }

  double get _distance {
    final lineGeom = turf.LineString(
      coordinates: _line
          .map((p) => turf.Position(p.longitude, p.latitude))
          .toList(),
    );
    final ptGeom = turf.Point(
      coordinates: turf.Position(_point.longitude, _point.latitude),
    );
    return pointToLineDistance(ptGeom, lineGeom, unit: _unit).toDouble();
  }

  String get _unitLabel {
    switch (_unit) {
      case turf.Unit.kilometers:
        return 'km';
      case turf.Unit.miles:
        return 'mi';
      case turf.Unit.meters:
        return 'm';
      case turf.Unit.nauticalmiles:
        return 'nmi';
      default:
        return 'km';
    }
  }

  void _onPointDrag(DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_point) + d.delta);
    setState(() => _point = next);
  }

  void _onVertexDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_line[idx]) + d.delta);
    setState(() => _line[idx] = next);
  }

  void _reset() => setState(() {
        _point = _defaultPoint;
        _line = List.from(_defaultLine);
      });

  @override
  Widget build(BuildContext context) {
    return ShowcaseFrame(
      hint: 'Drag the green point or any line vertex to change the distance',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [_point, ..._line],
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
              point: _point,
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _draggingPoint = true),
                onPanUpdate: _onPointDrag,
                onPanEnd: (_) => setState(() => _draggingPoint = false),
                child: Container(
                  decoration: BoxDecoration(
                    color: ShowcaseColors.lime,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: _draggingPoint ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ShowcaseColors.lime.withOpacity(0.5),
                        blurRadius: 10,
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
              value: '${_distance.toStringAsFixed(3)} $_unitLabel',
              icon: Icons.straighten,
            ),
            const SizedBox(width: 10),
            _unitDropdown(),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'double'),
          kv('value', _distance.toStringAsFixed(4), glow: true),
          kv('unit', _unitLabel),
        ],
        callRows: [
          kv('fn', 'pointToLineDistance(pt, line)'),
          kv('vertices', '${_line.length}'),
        ],
      ),
    );
  }

  Widget _unitDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ShowcaseColors.ink,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ShowcaseColors.cage),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<turf.Unit>(
          value: _unit,
          isDense: true,
          dropdownColor: ShowcaseColors.ink,
          icon: const Icon(Icons.arrow_drop_down,
              color: ShowcaseColors.dim, size: 16),
          style: const TextStyle(
            color: ShowcaseColors.bright,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
          items: const [
            DropdownMenuItem(value: turf.Unit.kilometers, child: Text('km')),
            DropdownMenuItem(value: turf.Unit.miles, child: Text('mi')),
            DropdownMenuItem(value: turf.Unit.meters, child: Text('m')),
            DropdownMenuItem(value: turf.Unit.nauticalmiles, child: Text('nmi')),
          ],
          onChanged: (u) {
            if (u == null) return;
            setState(() => _unit = u);
          },
        ),
      ),
    );
  }
}
