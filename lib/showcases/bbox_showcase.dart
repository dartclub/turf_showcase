import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/bbox.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class BboxShowcase extends StatefulWidget {
  const BboxShowcase({super.key});

  @override
  State<BboxShowcase> createState() => _BboxShowcaseState();
}

class _BboxShowcaseState extends State<BboxShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(48.86, 2.35),
        LatLng(50.85, 4.35),
        LatLng(52.52, 13.40),
        LatLng(45.46, 9.19),
      ];

  late List<LatLng> _vertices;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _vertices = List.from(_defaults);
  }

  turf.BBox get _bbox {
    final coords = _vertices
        .map((v) => turf.Position(v.longitude, v.latitude))
        .toList();
    final fc = turf.FeatureCollection(
      features: coords
          .map((p) => turf.Feature<turf.Point>(
                geometry: turf.Point(coordinates: p),
              ))
          .toList(),
    );
    return bbox(fc);
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_vertices[idx]) + d.delta);
    setState(() => _vertices[idx] = next);
  }

  void _reset() => setState(() => _vertices = List.from(_defaults));

  @override
  Widget build(BuildContext context) {
    final box = _bbox;
    final minX = box[0]!.toDouble();
    final minY = box[1]!.toDouble();
    final maxX = box[2]!.toDouble();
    final maxY = box[3]!.toDouble();
    final corners = [
      LatLng(minY, minX),
      LatLng(minY, maxX),
      LatLng(maxY, maxX),
      LatLng(maxY, minX),
    ];
    return ShowcaseFrame(
      hint: 'Drag the points — the yellow rectangle is the bounding box',
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
          fm.PolygonLayer(polygons: [
            fm.Polygon(
              points: corners,
              color: ShowcaseColors.sun.withOpacity(0.12),
              borderColor: ShowcaseColors.sun.withOpacity(0.85),
              borderStrokeWidth: 2,
              pattern: fm.StrokePattern.dashed(segments: const [10.0, 6.0]),
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
                  child: DraggableHandleMarker(active: isActive),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ResultBox(label: 'minX', value: minX.toStringAsFixed(3)),
            const SizedBox(width: 6),
            ResultBox(label: 'minY', value: minY.toStringAsFixed(3)),
            const SizedBox(width: 6),
            ResultBox(label: 'maxX', value: maxX.toStringAsFixed(3)),
            const SizedBox(width: 6),
            ResultBox(label: 'maxY', value: maxY.toStringAsFixed(3)),
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
            '[${minX.toStringAsFixed(3)}, ${minY.toStringAsFixed(3)}, '
                '${maxX.toStringAsFixed(3)}, ${maxY.toStringAsFixed(3)}]',
            glow: true,
          ),
        ],
        callRows: [
          kv('fn', 'bbox(geojson)'),
          kv('points', '${_vertices.length}'),
        ],
      ),
    );
  }
}
