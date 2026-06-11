import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/polygon_smooth.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class PolygonSmoothShowcase extends StatefulWidget {
  const PolygonSmoothShowcase({super.key});

  @override
  State<PolygonSmoothShowcase> createState() => _PolygonSmoothShowcaseState();
}

class _PolygonSmoothShowcaseState extends State<PolygonSmoothShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(0, 11),
        LatLng(4, 22),
        LatLng(0, 31),
        LatLng(11, 31),
        LatLng(15, 21),
        LatLng(11, 11),
      ];

  late List<LatLng> _corners;
  int _iterations = 3;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _corners = List.from(_defaults);
  }

  List<LatLng> get _smoothed {
    final ring = [
      ..._corners.map((c) => turf.Position(c.longitude, c.latitude)),
      turf.Position(_corners.first.longitude, _corners.first.latitude),
    ];
    final poly = turf.Feature<turf.Polygon>(
      geometry: turf.Polygon(coordinates: [ring]),
    );
    final fc = polygonSmooth(poly, iterations: _iterations);
    final first = fc.features.first;
    final geom = first.geometry as turf.Polygon;
    return geom.coordinates.first
        .map((p) => LatLng(p.lat.toDouble(), p.lng.toDouble()))
        .toList();
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_corners[idx]) + d.delta);
    setState(() => _corners[idx] = next);
  }

  void _reset() => setState(() {
        _corners = List.from(_defaults);
        _iterations = 3;
      });

  @override
  Widget build(BuildContext context) {
    final smoothed = _smoothed;
    return ShowcaseFrame(
      hint: 'Chaikin smoothing — drag corners or change iterations',
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
          fm.PolygonLayer(polygons: [
            fm.Polygon(
              points: _corners,
              color: ShowcaseColors.coral.withOpacity(0.06),
              borderColor: ShowcaseColors.coral.withOpacity(0.55),
              borderStrokeWidth: 1.5,
              pattern: fm.StrokePattern.dashed(segments: const [8.0, 6.0]),
            ),
            fm.Polygon(
              points: smoothed,
              color: ShowcaseColors.mint.withOpacity(0.18),
              borderColor: ShowcaseColors.mint.withOpacity(0.9),
              borderStrokeWidth: 2.5,
            ),
          ]),
          fm.MarkerLayer(
            markers: _corners.asMap().entries.map((e) {
              final isActive = _draggingIndex == e.key;
              return fm.Marker(
                point: e.value,
                width: 28,
                height: 28,
                alignment: Alignment.center,
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _draggingIndex = e.key),
                  onPanUpdate: (d) => _onDrag(e.key, d),
                  onPanEnd: (_) => setState(() => _draggingIndex = null),
                  child: DraggableHandleMarker(active: isActive, size: 24),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            const Text('iterations',
                style: TextStyle(
                  color: ShowcaseColors.dim,
                  fontFamily: 'monospace',
                  fontSize: 12,
                )),
            const SizedBox(width: 10),
            ResultBox(label: 'n', value: _iterations.toString()),
            Expanded(
              child: Slider(
                value: _iterations.toDouble(),
                min: 0,
                max: 6,
                divisions: 6,
                onChanged: (v) => setState(() => _iterations = v.round()),
                activeColor: ShowcaseColors.mint,
                inactiveColor: ShowcaseColors.cage,
              ),
            ),
            const SizedBox(width: 8),
            ResetButton(onTap: _reset),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              ChipBadge(
                text: 'input ${_corners.length}',
                color: ShowcaseColors.coral,
              ),
              const SizedBox(width: 8),
              ChipBadge(
                text: 'smoothed ${smoothed.length}',
                color: ShowcaseColors.mint,
              ),
            ],
          ),
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'FeatureCollection'),
          kv('features', '1'),
          kv('vertices', '${smoothed.length}', glow: true),
        ],
        callRows: [
          kv('fn', 'polygonSmooth(poly, iterations)'),
          kv('input', '${_corners.length} vertices'),
          kv('iterations', '$_iterations'),
        ],
      ),
    );
  }
}
