import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/transform.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class TransformRotateShowcase extends StatefulWidget {
  const TransformRotateShowcase({super.key});

  @override
  State<TransformRotateShowcase> createState() => _TransformRotateShowcaseState();
}

class _TransformRotateShowcaseState extends State<TransformRotateShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(29.0, 0.0),
        LatLng(29.0, 3.5),
        LatLng(32.0, 2.5),
      ];

  late List<LatLng> _corners;
  double _angle = 45;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _corners = List.from(_defaults);
  }

  List<LatLng> get _rotated {
    final ring = [
      ..._corners.map((c) => turf.Position(c.longitude, c.latitude)),
      turf.Position(_corners.first.longitude, _corners.first.latitude),
    ];
    final poly = turf.Feature<turf.Polygon>(
      geometry: turf.Polygon(coordinates: [ring]),
    );
    final result = transformRotate(poly, _angle) as turf.Feature<turf.Polygon>;
    return result.geometry!.coordinates.first
        .map((p) => LatLng(p.lat.toDouble(), p.lng.toDouble()))
        .take(_corners.length)
        .toList();
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_corners[idx]) + d.delta);
    setState(() => _corners[idx] = next);
  }

  void _reset() => setState(() {
        _corners = List.from(_defaults);
        _angle = 45;
      });

  @override
  Widget build(BuildContext context) {
    final rotated = _rotated;
    return ShowcaseFrame(
      hint: 'Slide to rotate around the polygon centroid',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [..._corners, ...rotated],
            padding: const EdgeInsets.all(70),
          ),
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
          ),
        ),
        children: [
          darkTileLayer(),
          fm.PolygonLayer(polygons: [
            fm.Polygon(
              points: _corners,
              color: ShowcaseColors.coral.withOpacity(0.07),
              borderColor: ShowcaseColors.coral.withOpacity(0.5),
              borderStrokeWidth: 1.5,
              pattern: fm.StrokePattern.dashed(segments: const [8.0, 6.0]),
            ),
            fm.Polygon(
              points: rotated,
              color: ShowcaseColors.mint.withOpacity(0.2),
              borderColor: ShowcaseColors.mint.withOpacity(0.9),
              borderStrokeWidth: 2.5,
            ),
          ]),
          fm.MarkerLayer(
            markers: _corners.asMap().entries.map((e) {
              final isActive = _draggingIndex == e.key;
              return fm.Marker(
                point: e.value,
                width: 26,
                height: 26,
                alignment: Alignment.center,
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _draggingIndex = e.key),
                  onPanUpdate: (d) => _onDrag(e.key, d),
                  onPanEnd: (_) => setState(() => _draggingIndex = null),
                  child: DraggableHandleMarker(active: isActive, size: 22),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            const Text('angle',
                style: TextStyle(
                  color: ShowcaseColors.dim,
                  fontFamily: 'monospace',
                  fontSize: 12,
                )),
            const SizedBox(width: 10),
            ResultBox(label: '°', value: _angle.toStringAsFixed(0)),
            Expanded(
              child: Slider(
                value: _angle,
                min: -180,
                max: 180,
                onChanged: (v) => setState(() => _angle = v),
                activeColor: ShowcaseColors.mint,
                inactiveColor: ShowcaseColors.cage,
              ),
            ),
            const SizedBox(width: 8),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'GeoJSONObject'),
          kv('vertices', '${rotated.length}', glow: true),
          kv('rotated by', '${_angle.toStringAsFixed(2)}°'),
        ],
        callRows: [
          kv('fn', 'transformRotate(geo, angle)'),
          kv('vertices', '${_corners.length}'),
          kv('mutate', 'false'),
        ],
      ),
    );
  }
}
