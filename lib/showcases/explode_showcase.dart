import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/explode.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class ExplodeShowcase extends StatefulWidget {
  const ExplodeShowcase({super.key});

  @override
  State<ExplodeShowcase> createState() => _ExplodeShowcaseState();
}

class _ExplodeShowcaseState extends State<ExplodeShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(45, 5),
        LatLng(48, 8),
        LatLng(50, 12),
        LatLng(52, 15),
        LatLng(48, 18),
        LatLng(45, 14),
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

  List<LatLng> get _exploded {
    final ring = [
      ..._corners.map((c) => turf.Position(c.longitude, c.latitude)),
      turf.Position(_corners.first.longitude, _corners.first.latitude),
    ];
    final poly = turf.Feature<turf.Polygon>(
      geometry: turf.Polygon(coordinates: [ring]),
    );
    final fc = explode(poly);
    return fc.features.map((f) {
      final c = f.geometry!.coordinates;
      return LatLng(c.lat.toDouble(), c.lng.toDouble());
    }).toList();
  }

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_corners[idx]) + d.delta);
    setState(() => _corners[idx] = next);
  }

  void _reset() => setState(() => _corners = List.from(_defaults));

  @override
  Widget build(BuildContext context) {
    final pts = _exploded;
    return ShowcaseFrame(
      hint: 'Each yellow dot is one Feature<Point> in the exploded result',
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
              color: ShowcaseColors.sky.withOpacity(0.12),
              borderColor: ShowcaseColors.sky.withOpacity(0.7),
              borderStrokeWidth: 2,
            ),
          ]),
          fm.MarkerLayer(
            markers: pts.map((p) {
              return fm.Marker(
                point: p,
                width: 22,
                height: 22,
                alignment: Alignment.center,
                child: Container(
                  decoration: BoxDecoration(
                    color: ShowcaseColors.sun,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: ShowcaseColors.sun.withOpacity(0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
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
            ChipBadge(
              text: 'polygon vertices ${_corners.length}',
              color: ShowcaseColors.sky,
              icon: Icons.hexagon_outlined,
            ),
            const SizedBox(width: 8),
            ChipBadge(
              text: 'point features ${pts.length}',
              color: ShowcaseColors.sun,
              icon: Icons.scatter_plot,
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'FeatureCollection<Point>'),
          kv('features', '${pts.length}', glow: true),
        ],
        callRows: [
          kv('fn', 'explode(geojson)'),
          kv('input', 'Polygon w/ ${_corners.length} pts'),
        ],
      ),
    );
  }
}
