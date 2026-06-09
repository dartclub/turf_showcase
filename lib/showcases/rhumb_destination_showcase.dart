import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/destination.dart' as ds;
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class RhumbDestinationShowcase extends StatefulWidget {
  const RhumbDestinationShowcase({super.key});

  @override
  State<RhumbDestinationShowcase> createState() =>
      _RhumbDestinationShowcaseState();
}

class _RhumbDestinationShowcaseState extends State<RhumbDestinationShowcase> {
  static const _defaultOrigin = LatLng(39.984, -75.343);

  late LatLng _origin;
  double _bearing = 90;
  double _distance = 50;
  turf.Unit _unit = turf.Unit.miles;
  bool _draggingOrigin = false;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _origin = _defaultOrigin;
  }

  LatLng get _dest {
    final originGeom = turf.Point(
      coordinates: turf.Position(_origin.longitude, _origin.latitude),
    );
    final result = ds.rhumbDestination(originGeom, _distance, _bearing, unit: _unit);
    final coords = result.geometry!.coordinates;
    return LatLng(coords.lat.toDouble(), coords.lng.toDouble());
  }

  String get _unitLabel {
    switch (_unit) {
      case turf.Unit.kilometers:
        return 'km';
      case turf.Unit.miles:
        return 'mi';
      case turf.Unit.meters:
        return 'm';
      case turf.Unit.nauticalmiles:
        return 'nmi';
      default:
        return 'km';
    }
  }

  void _onOriginDrag(DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_origin) + d.delta);
    setState(() => _origin = next);
  }

  void _reset() => setState(() {
        _origin = _defaultOrigin;
        _bearing = 90;
        _distance = 50;
        _unit = turf.Unit.miles;
      });

  @override
  Widget build(BuildContext context) {
    final dest = _dest;
    return ShowcaseFrame(
      hint:
          'Travels along a rhumb line — constant bearing, not the shortest geodesic',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [_origin, dest],
            padding: const EdgeInsets.all(80),
          ),
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
          ),
        ),
        children: [
          darkTileLayer(),
          fm.PolylineLayer(polylines: [
            fm.Polyline(
              points: [_origin, dest],
              color: ShowcaseColors.violet.withOpacity(0.85),
              strokeWidth: 3,
            ),
          ]),
          fm.MarkerLayer(markers: [
            fm.Marker(
              point: dest,
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
                child: const Icon(Icons.flag, color: Colors.black87, size: 20),
              ),
            ),
            fm.Marker(
              point: _origin,
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _draggingOrigin = true),
                onPanUpdate: _onOriginDrag,
                onPanEnd: (_) => setState(() => _draggingOrigin = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: ShowcaseColors.lime,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: _draggingOrigin ? 3 : 2),
                    boxShadow: [
                      BoxShadow(
                        color: ShowcaseColors.lime.withOpacity(_draggingOrigin ? 0.6 : 0.4),
                        blurRadius: _draggingOrigin ? 14 : 8,
                        spreadRadius: _draggingOrigin ? 2 : 1,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.my_location, color: Colors.white, size: 18),
                ),
              ),
            ),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            const Text('bearing',
                style: TextStyle(
                  color: ShowcaseColors.dim,
                  fontFamily: 'monospace',
                  fontSize: 12,
                )),
            const SizedBox(width: 10),
            ResultBox(label: '°', value: _bearing.toStringAsFixed(0)),
            Expanded(
              child: Slider(
                value: _bearing,
                min: -180,
                max: 180,
                onChanged: (v) => setState(() => _bearing = v),
                activeColor: ShowcaseColors.mint,
                inactiveColor: ShowcaseColors.cage,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('distance',
                style: TextStyle(
                  color: ShowcaseColors.dim,
                  fontFamily: 'monospace',
                  fontSize: 12,
                )),
            const SizedBox(width: 10),
            ResultBox(label: _unitLabel, value: _distance.toStringAsFixed(0)),
            Expanded(
              child: Slider(
                value: _distance,
                min: 1,
                max: _unit == turf.Unit.meters ? 500000 : 500,
                onChanged: (v) => setState(() => _distance = v),
                activeColor: ShowcaseColors.mint,
                inactiveColor: ShowcaseColors.cage,
              ),
            ),
            _unitDropdown(),
            const SizedBox(width: 8),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'Feature<Point>'),
          kv('lat', dest.latitude.toStringAsFixed(6), glow: true),
          kv('lng', dest.longitude.toStringAsFixed(6), glow: true),
        ],
        callRows: [
          kv('fn', 'rhumbDestination(origin, distance, bearing, unit)'),
          kv('origin', '${_origin.longitude.toStringAsFixed(3)}, ${_origin.latitude.toStringAsFixed(3)}'),
          kv('bearing', '${_bearing.toStringAsFixed(1)}°'),
          kv('distance', '${_distance.toStringAsFixed(1)} $_unitLabel'),
        ],
      ),
    );
  }

  Widget _unitDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: ShowcaseColors.ink,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ShowcaseColors.cage),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<turf.Unit>(
          value: _unit,
          isDense: true,
          dropdownColor: ShowcaseColors.ink,
          icon: const Icon(Icons.arrow_drop_down,
              color: ShowcaseColors.dim, size: 16),
          style: const TextStyle(
            color: ShowcaseColors.bright,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
          items: const [
            DropdownMenuItem(value: turf.Unit.kilometers, child: Text('km')),
            DropdownMenuItem(value: turf.Unit.miles, child: Text('mi')),
            DropdownMenuItem(value: turf.Unit.meters, child: Text('m')),
            DropdownMenuItem(value: turf.Unit.nauticalmiles, child: Text('nmi')),
          ],
          onChanged: (u) {
            if (u == null) return;
            setState(() => _unit = u);
          },
        ),
      ),
    );
  }
}
