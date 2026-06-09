import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/bbox_polygon.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class BboxPolygonShowcase extends StatefulWidget {
  const BboxPolygonShowcase({super.key});

  @override
  State<BboxPolygonShowcase> createState() => _BboxPolygonShowcaseState();
}

class _BboxPolygonShowcaseState extends State<BboxPolygonShowcase> {
  static const _defaultMin = LatLng(35.0, -10.0);
  static const _defaultMax = LatLng(60.0, 30.0);

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
    final lng1 = _minPoint.longitude < _maxPoint.longitude
        ? _minPoint.longitude
        : _maxPoint.longitude;
    final lat1 = _minPoint.latitude < _maxPoint.latitude
        ? _minPoint.latitude
        : _maxPoint.latitude;
    final lng2 = _minPoint.longitude < _maxPoint.longitude
        ? _maxPoint.longitude
        : _minPoint.longitude;
    final lat2 = _minPoint.latitude < _maxPoint.latitude
        ? _maxPoint.latitude
        : _minPoint.latitude;

    final box = turf.BBox(lng1, lat1, lng2, lat2);
    final poly = bboxPolygon(box);
    final ring = poly.geometry!.coordinates.first;
    final corners = ring
        .map((p) => LatLng(p.lat.toDouble(), p.lng.toDouble()))
        .toList();

    return ShowcaseFrame(
      hint: 'Drag the min/max points — the polygon snaps to a rectangle',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: corners,
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
              points: corners,
              color: ShowcaseColors.mint.withOpacity(0.18),
              borderColor: ShowcaseColors.mint.withOpacity(0.9),
              borderStrokeWidth: 2.5,
            ),
          ]),
          fm.MarkerLayer(markers: [
            _handle(0, _minPoint, ShowcaseColors.lime, 'min'),
            _handle(1, _maxPoint, ShowcaseColors.coral, 'max'),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ResultBox(label: 'minX', value: lng1.toStringAsFixed(3)),
            const SizedBox(width: 6),
            ResultBox(label: 'minY', value: lat1.toStringAsFixed(3)),
            const SizedBox(width: 6),
            ResultBox(label: 'maxX', value: lng2.toStringAsFixed(3)),
            const SizedBox(width: 6),
            ResultBox(label: 'maxY', value: lat2.toStringAsFixed(3)),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'Feature<Polygon>'),
          kv('vertices', '${corners.length}'),
          kv(
            'bbox',
            '[${lng1.toStringAsFixed(2)}, ${lat1.toStringAsFixed(2)}, '
                '${lng2.toStringAsFixed(2)}, ${lat2.toStringAsFixed(2)}]',
            glow: true,
          ),
        ],
        callRows: [
          kv('fn', 'bboxPolygon(bbox)'),
        ],
      ),
    );
  }

  fm.Marker _handle(int idx, LatLng pt, Color color, String label) {
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
        child: Tooltip(
          message: label,
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
              idx == 0 ? Icons.south_west : Icons.north_east,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
