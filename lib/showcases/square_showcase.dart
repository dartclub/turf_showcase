import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/square.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class SquareShowcase extends StatefulWidget {
  const SquareShowcase({super.key});

  @override
  State<SquareShowcase> createState() => _SquareShowcaseState();
}

class _SquareShowcaseState extends State<SquareShowcase> {
  static const _defaultMin = LatLng(0.0, 0.0);
  static const _defaultMax = LatLng(5.0, 10.0);

  late LatLng _minPoint;
  late LatLng _maxPoint;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _minPoint = _defaultMin;
    _maxPoint = _defaultMax;
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final base = idx == 0 ? _minPoint : _maxPoint;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(base) + d.delta);
    setState(() {
      if (idx == 0) {
        _minPoint = next;
      } else {
        _maxPoint = next;
      }
    });
  }

  void _reset() => setState(() {
        _minPoint = _defaultMin;
        _maxPoint = _defaultMax;
      });

  @override
  Widget build(BuildContext context) {
    final lng1 = _minPoint.longitude < _maxPoint.longitude ? _minPoint.longitude : _maxPoint.longitude;
    final lat1 = _minPoint.latitude < _maxPoint.latitude ? _minPoint.latitude : _maxPoint.latitude;
    final lng2 = _minPoint.longitude < _maxPoint.longitude ? _maxPoint.longitude : _minPoint.longitude;
    final lat2 = _minPoint.latitude < _maxPoint.latitude ? _maxPoint.latitude : _minPoint.latitude;

    final input = turf.BBox(lng1, lat1, lng2, lat2);
    final sq = square(input);

    final inputCorners = [
      LatLng(lat1, lng1),
      LatLng(lat1, lng2),
      LatLng(lat2, lng2),
      LatLng(lat2, lng1),
    ];
    final sqCorners = [
      LatLng(sq[1]!.toDouble(), sq[0]!.toDouble()),
      LatLng(sq[1]!.toDouble(), sq[2]!.toDouble()),
      LatLng(sq[3]!.toDouble(), sq[2]!.toDouble()),
      LatLng(sq[3]!.toDouble(), sq[0]!.toDouble()),
    ];

    return ShowcaseFrame(
      hint: 'Blue input bbox + green minimum-square output',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [...inputCorners, ...sqCorners],
            padding: const EdgeInsets.all(60),
          ),
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
          ),
        ),
        children: [
          darkTileLayer(),
          fm.PolygonLayer(polygons: [
            fm.Polygon(
              points: sqCorners,
              color: ShowcaseColors.mint.withOpacity(0.12),
              borderColor: ShowcaseColors.mint.withOpacity(0.85),
              borderStrokeWidth: 2.5,
              pattern: fm.StrokePattern.dashed(segments: const [10.0, 6.0]),
            ),
            fm.Polygon(
              points: inputCorners,
              color: ShowcaseColors.sky.withOpacity(0.18),
              borderColor: ShowcaseColors.sky.withOpacity(0.85),
              borderStrokeWidth: 2,
            ),
          ]),
          fm.MarkerLayer(markers: [
            _handle(0, _minPoint, ShowcaseColors.lime),
            _handle(1, _maxPoint, ShowcaseColors.coral),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ResultBox(label: 'in', value: '${(lng2 - lng1).abs().toStringAsFixed(2)}×${(lat2 - lat1).abs().toStringAsFixed(2)}'),
            const SizedBox(width: 8),
            ResultBox(
              label: 'sq',
              value: '${(sq[2]! - sq[0]!).abs().toStringAsFixed(2)}×${(sq[3]! - sq[1]!).abs().toStringAsFixed(2)}',
              color: ShowcaseColors.mint,
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'BBox'),
          kv(
            'value',
            '[${sq[0]!.toStringAsFixed(3)}, ${sq[1]!.toStringAsFixed(3)}, '
                '${sq[2]!.toStringAsFixed(3)}, ${sq[3]!.toStringAsFixed(3)}]',
            glow: true,
          ),
        ],
        callRows: [
          kv('fn', 'square(bbox)'),
          kv(
            'input',
            '[${lng1.toStringAsFixed(2)}, ${lat1.toStringAsFixed(2)}, '
                '${lng2.toStringAsFixed(2)}, ${lat2.toStringAsFixed(2)}]',
          ),
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
                color: color.withOpacity(0.5),
                blurRadius: isActive ? 14 : 8,
                spreadRadius: isActive ? 2 : 1,
              ),
            ],
          ),
          child: Icon(
            idx == 0 ? Icons.south_west : Icons.north_east,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
    );
  }
}
