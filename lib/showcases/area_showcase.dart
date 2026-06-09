import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/area.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class AreaShowcase extends StatefulWidget {
  const AreaShowcase({super.key});

  @override
  State<AreaShowcase> createState() => _AreaShowcaseState();
}

class _AreaShowcaseState extends State<AreaShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(40.0, -75.0),
        LatLng(40.0, -73.0),
        LatLng(41.5, -73.0),
        LatLng(41.5, -75.0),
      ];

  late List<LatLng> _corners;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _corners = List.from(_defaults);
  }

  double get _areaSqMeters {
    final ring = [
      ..._corners.map((c) => turf.Position(c.longitude, c.latitude)),
      turf.Position(_corners.first.longitude, _corners.first.latitude),
    ];
    final poly = turf.Feature<turf.Polygon>(
      geometry: turf.Polygon(coordinates: [ring]),
    );
    return area(poly)?.toDouble() ?? 0;
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_corners[idx]) + d.delta);
    setState(() => _corners[idx] = next);
  }

  void _reset() => setState(() => _corners = List.from(_defaults));

  String get _displayArea {
    final m2 = _areaSqMeters;
    if (m2.abs() >= 1e6) return '${(m2 / 1e6).toStringAsFixed(2)} km²';
    return '${m2.toStringAsFixed(2)} m²';
  }

  @override
  Widget build(BuildContext context) {
    return ShowcaseFrame(
      hint: 'Drag the corners to reshape the polygon and see the area update',
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
              color: ShowcaseColors.sky.withOpacity(0.18),
              borderColor: ShowcaseColors.sky.withOpacity(0.7),
              borderStrokeWidth: 2,
            ),
          ]),
          fm.MarkerLayer(
            markers: _corners.asMap().entries.map((e) {
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
            ResultBox(
              label: 'area',
              value: _displayArea,
              icon: Icons.grid_view,
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'double'),
          kv('m²', _areaSqMeters.toStringAsFixed(2), glow: true),
          kv('km²', (_areaSqMeters / 1e6).toStringAsFixed(4), glow: true),
        ],
        callRows: [
          kv('fn', 'area(polygon)'),
          kv('vertices', '${_corners.length}'),
        ],
      ),
    );
  }
}
