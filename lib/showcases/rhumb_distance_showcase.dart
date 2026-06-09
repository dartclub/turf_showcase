import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/distance.dart' as ds;
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class RhumbDistanceShowcase extends StatefulWidget {
  const RhumbDistanceShowcase({super.key});

  @override
  State<RhumbDistanceShowcase> createState() => _RhumbDistanceShowcaseState();
}

class _RhumbDistanceShowcaseState extends State<RhumbDistanceShowcase> {
  static const _defaultFrom = LatLng(39.984, -75.343);
  static const _defaultTo = LatLng(39.123, -75.534);

  late LatLng _from;
  late LatLng _to;
  turf.Unit _unit = turf.Unit.kilometers;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _from = _defaultFrom;
    _to = _defaultTo;
  }

  double get _distance {
    final f = turf.Point(coordinates: turf.Position(_from.longitude, _from.latitude));
    final t = turf.Point(coordinates: turf.Position(_to.longitude, _to.latitude));
    return ds.rhumbDistance(f, t, _unit).toDouble();
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

  void _onDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final base = idx == 0 ? _from : _to;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(base) + d.delta);
    setState(() {
      if (idx == 0) {
        _from = next;
      } else {
        _to = next;
      }
    });
  }

  void _reset() => setState(() {
        _from = _defaultFrom;
        _to = _defaultTo;
      });

  @override
  Widget build(BuildContext context) {
    return ShowcaseFrame(
      hint: 'Rhumb distance follows a constant compass bearing',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [_from, _to],
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
              points: [_from, _to],
              color: ShowcaseColors.violet.withOpacity(0.85),
              strokeWidth: 3,
            ),
          ]),
          fm.MarkerLayer(markers: [
            _handle(0, _from, ShowcaseColors.lime, Icons.flag),
            _handle(1, _to, ShowcaseColors.coral, Icons.location_on),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ResultBox(
              label: 'distance',
              value: '${_distance.toStringAsFixed(2)} $_unitLabel',
              icon: Icons.straighten,
            ),
            const SizedBox(width: 10),
            _unitDropdown(),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'double'),
          kv('value', _distance.toStringAsFixed(4), glow: true),
          kv('unit', _unitLabel),
        ],
        callRows: [
          kv('fn', 'rhumbDistance(from, to, unit)'),
          kv('from', '${_from.longitude.toStringAsFixed(3)}, ${_from.latitude.toStringAsFixed(3)}'),
          kv('to', '${_to.longitude.toStringAsFixed(3)}, ${_to.latitude.toStringAsFixed(3)}'),
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

  fm.Marker _handle(int idx, LatLng pt, Color color, IconData icon) {
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
          child: Icon(icon, color: Colors.white, size: isActive ? 20 : 18),
        ),
      ),
    );
  }
}
