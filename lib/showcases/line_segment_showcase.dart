import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/line_segment.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class LineSegmentShowcase extends StatefulWidget {
  const LineSegmentShowcase({super.key});

  @override
  State<LineSegmentShowcase> createState() => _LineSegmentShowcaseState();
}

class _LineSegmentShowcaseState extends State<LineSegmentShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(0, 0),
        LatLng(0, 10),
        LatLng(10, 10),
        LatLng(10, 0),
      ];

  late List<LatLng> _corners;
  bool _polygon = true;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _corners = List.from(_defaults);
  }

  List<List<LatLng>> get _segments {
    final coords = _corners.map((c) => turf.Position(c.longitude, c.latitude)).toList();
    final geo = _polygon
        ? turf.Feature<turf.Polygon>(
            geometry: turf.Polygon(coordinates: [
              [...coords, coords.first],
            ]),
          )
        : turf.Feature<turf.LineString>(
            geometry: turf.LineString(coordinates: coords),
          );
    final fc = lineSegment(geo);
    return fc.features.map((f) {
      return f.geometry!.coordinates
          .map((p) => LatLng(p.lat.toDouble(), p.lng.toDouble()))
          .toList();
    }).toList();
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_corners[idx]) + d.delta);
    setState(() => _corners[idx] = next);
  }

  void _reset() => setState(() {
        _corners = List.from(_defaults);
        _polygon = true;
      });

  @override
  Widget build(BuildContext context) {
    final segs = _segments;
    final palette = [
      ShowcaseColors.mint,
      ShowcaseColors.sun,
      ShowcaseColors.coral,
      ShowcaseColors.violet,
      ShowcaseColors.sky,
    ];
    return ShowcaseFrame(
      hint: 'Each colour is one 2-vertex segment of the input',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: _corners,
            padding: const EdgeInsets.all(70),
          ),
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
          ),
        ),
        children: [
          darkTileLayer(),
          fm.PolylineLayer(
            polylines: segs.asMap().entries.map((e) {
              final color = palette[e.key % palette.length];
              return fm.Polyline(
                points: e.value,
                color: color,
                strokeWidth: 5,
              );
            }).toList(),
          ),
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
            ChipBadge(
              text: 'segments ${segs.length}',
              color: ShowcaseColors.mint,
              icon: Icons.linear_scale,
            ),
            const SizedBox(width: 14),
            Switch(
              value: _polygon,
              onChanged: (v) => setState(() => _polygon = v),
              activeColor: ShowcaseColors.mint,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            Text(
              _polygon ? 'input: polygon' : 'input: line',
              style: const TextStyle(
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
          kv('type', 'FeatureCollection<LineString>'),
          kv('segments', segs.length.toString(), glow: true),
        ],
        callRows: [
          kv('fn', 'lineSegment(geojson)'),
          kv('input', _polygon ? 'Polygon' : 'LineString'),
          kv('vertices', '${_corners.length}'),
        ],
      ),
    );
  }
}
