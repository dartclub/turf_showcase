import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/boolean.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class BooleanPointInPolygonShowcase extends StatefulWidget {
  const BooleanPointInPolygonShowcase({super.key});

  @override
  State<BooleanPointInPolygonShowcase> createState() =>
      _BooleanPointInPolygonShowcaseState();
}

class _BooleanPointInPolygonShowcaseState
    extends State<BooleanPointInPolygonShowcase> {
  static List<LatLng> get _polyDefault => const [
        LatLng(41, -81),
        LatLng(41, -72),
        LatLng(47, -72),
        LatLng(47, -81),
      ];
  static const _ptDefault = LatLng(44, -77);

  late List<LatLng> _poly;
  late LatLng _point;
  bool _ignoreBoundary = false;
  bool _draggingPoint = false;
  int? _draggingPolyIdx;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _poly = List.from(_polyDefault);
    _point = _ptDefault;
  }

  bool get _inside {
    final ring = [
      ..._poly.map((c) => turf.Position(c.longitude, c.latitude)),
      turf.Position(_poly.first.longitude, _poly.first.latitude),
    ];
    final polyFeat = turf.Feature<turf.Polygon>(
      geometry: turf.Polygon(coordinates: [ring]),
    );
    return booleanPointInPolygon(
      turf.Position(_point.longitude, _point.latitude),
      polyFeat,
      ignoreBoundary: _ignoreBoundary,
    );
  }

  void _onPointDrag(DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_point) + d.delta);
    setState(() => _point = next);
  }

  void _onPolyDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_poly[idx]) + d.delta);
    setState(() => _poly[idx] = next);
  }

  void _reset() => setState(() {
        _poly = List.from(_polyDefault);
        _point = _ptDefault;
      });

  @override
  Widget build(BuildContext context) {
    final inside = _inside;
    final color = inside ? ShowcaseColors.mint : ShowcaseColors.coral;
    return ShowcaseFrame(
      hint: 'Drag the point in or out of the polygon',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [..._poly, _point],
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
              points: _poly,
              color: ShowcaseColors.sky.withOpacity(0.18),
              borderColor: ShowcaseColors.sky.withOpacity(0.85),
              borderStrokeWidth: 2.5,
            ),
          ]),
          fm.MarkerLayer(markers: [
            ..._poly.asMap().entries.map((e) {
              final isActive = _draggingPolyIdx == e.key;
              return fm.Marker(
                point: e.value,
                width: 26,
                height: 26,
                alignment: Alignment.center,
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _draggingPolyIdx = e.key),
                  onPanUpdate: (d) => _onPolyDrag(e.key, d),
                  onPanEnd: (_) => setState(() => _draggingPolyIdx = null),
                  child: DraggableHandleMarker(active: isActive, size: 22),
                ),
              );
            }),
            fm.Marker(
              point: _point,
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _draggingPoint = true),
                onPanUpdate: _onPointDrag,
                onPanEnd: (_) => setState(() => _draggingPoint = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: _draggingPoint ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.6),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    inside ? Icons.check : Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
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
              label: 'inside',
              value: inside.toString(),
              color: color,
              icon: inside ? Icons.check_circle : Icons.cancel,
            ),
            const SizedBox(width: 14),
            Switch(
              value: _ignoreBoundary,
              onChanged: (v) => setState(() => _ignoreBoundary = v),
              activeColor: ShowcaseColors.mint,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 4),
            const Text(
              'ignoreBoundary',
              style: TextStyle(
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
          kv('type', 'bool'),
          kv('value', inside.toString(), glow: true),
        ],
        callRows: [
          kv('fn', 'booleanPointInPolygon(pt, poly)'),
          kv('ignoreBoundary', _ignoreBoundary.toString()),
        ],
      ),
    );
  }
}
