import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/centroid.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class CentroidShowcase extends StatefulWidget {
  const CentroidShowcase({super.key});

  @override
  State<CentroidShowcase> createState() => _CentroidShowcaseState();
}

class _CentroidShowcaseState extends State<CentroidShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(45.0, 10.0),
        LatLng(45.0, 14.0),
        LatLng(48.0, 14.0),
        LatLng(50.0, 11.0),
        LatLng(48.0, 9.0),
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

  LatLng get _centroid {
    final ring = [
      ..._corners.map((c) => turf.Position(c.longitude, c.latitude)),
      turf.Position(_corners.first.longitude, _corners.first.latitude),
    ];
    final poly = turf.Feature<turf.Polygon>(
      geometry: turf.Polygon(coordinates: [ring]),
    );
    final c = centroid(poly);
    return LatLng(
      c.geometry!.coordinates.lat.toDouble(),
      c.geometry!.coordinates.lng.toDouble(),
    );
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_corners[idx]) + d.delta);
    setState(() => _corners[idx] = next);
  }

  void _reset() => setState(() => _corners = List.from(_defaults));

  @override
  Widget build(BuildContext context) {
    final c = _centroid;
    return ShowcaseFrame(
      hint: 'centroid is the unweighted mean of all vertices',
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
              color: ShowcaseColors.sky.withOpacity(0.15),
              borderColor: ShowcaseColors.sky.withOpacity(0.7),
              borderStrokeWidth: 2,
            ),
          ]),
          fm.MarkerLayer(markers: [
            fm.Marker(
              point: c,
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: ShowcaseColors.sun,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: ShowcaseColors.sun.withOpacity(0.6),
                      blurRadius: 14,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.adjust,
                    color: Colors.black87, size: 20),
              ),
            ),
            ..._corners.asMap().entries.map((e) {
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
            }),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ResultBox(
              label: 'centroid',
              value: '${c.latitude.toStringAsFixed(3)}, ${c.longitude.toStringAsFixed(3)}',
              icon: Icons.adjust,
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'Feature<Point>'),
          kv('lat', c.latitude.toStringAsFixed(6), glow: true),
          kv('lng', c.longitude.toStringAsFixed(6), glow: true),
        ],
        callRows: [
          kv('fn', 'centroid(polygon)'),
          kv('vertices', '${_corners.length}'),
        ],
      ),
    );
  }
}
