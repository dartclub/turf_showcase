import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/length.dart';
import 'package:turf/line_slice_along.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class LineSliceAlongShowcase extends StatefulWidget {
  const LineSliceAlongShowcase({super.key});

  @override
  State<LineSliceAlongShowcase> createState() =>
      _LineSliceAlongShowcaseState();
}

class _LineSliceAlongShowcaseState extends State<LineSliceAlongShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(-32, 115),
        LatLng(-22, 131),
        LatLng(-25, 143),
      ];

  late List<LatLng> _vertices;
  double _startDist = 100;
  double _stopDist = 750;
  turf.Unit _unit = turf.Unit.miles;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _vertices = List.from(_defaults);
  }

  turf.Feature<turf.LineString> get _lineFeat => turf.Feature<turf.LineString>(
        geometry: turf.LineString(
          coordinates:
              _vertices.map((p) => turf.Position(p.longitude, p.latitude)).toList(),
        ),
      );

  double get _totalLength => length(_lineFeat, _unit).toDouble();

  List<LatLng> get _slice {
    final start = _startDist.clamp(0, _stopDist).toDouble();
    final stop = _stopDist.clamp(start, _totalLength).toDouble();
    if (stop <= start) return [];
    final result = lineSliceAlong(_lineFeat, start, stop, _unit);
    return result.geometry!.coordinates
        .map((p) => LatLng(p.lat.toDouble(), p.lng.toDouble()))
        .toList();
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

  void _reset() => setState(() {
        _vertices = List.from(_defaults);
        _startDist = 100;
        _stopDist = 750;
        _unit = turf.Unit.miles;
      });

  @override
  Widget build(BuildContext context) {
    final slice = _slice;
    final total = _totalLength;
    if (_stopDist > total) _stopDist = total;
    if (_startDist > _stopDist) _startDist = _stopDist;
    return ShowcaseFrame(
      hint: 'Two distance sliders carve a sub-line out of the route',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: _vertices,
            padding: const EdgeInsets.all(60),
          ),
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
          ),
        ),
        children: [
          darkTileLayer(),
          fm.PolylineLayer(polylines: [
            fm.Polyline(
              points: _vertices,
              color: ShowcaseColors.dim.withOpacity(0.55),
              strokeWidth: 3,
            ),
            if (slice.isNotEmpty)
              fm.Polyline(
                points: slice,
                color: ShowcaseColors.mint.withOpacity(0.95),
                strokeWidth: 5,
              ),
          ]),
          if (slice.isNotEmpty)
            fm.MarkerLayer(markers: [
              dotMarker(
                point: slice.first,
                color: ShowcaseColors.lime,
                icon: Icons.flag,
              ),
              dotMarker(
                point: slice.last,
                color: ShowcaseColors.coral,
                icon: Icons.location_on,
              ),
            ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            const Text('start', style: TextStyle(color: ShowcaseColors.dim, fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(width: 10),
            ResultBox(label: _unitLabel, value: _startDist.toStringAsFixed(0)),
            Expanded(
              child: Slider(
                value: _startDist.clamp(0, total).toDouble(),
                min: 0,
                max: total,
                onChanged: (v) => setState(() {
                  _startDist = v;
                  if (_startDist > _stopDist) _stopDist = _startDist;
                }),
                activeColor: ShowcaseColors.lime,
                inactiveColor: ShowcaseColors.cage,
              ),
            ),
          ],
        ),
        Row(
          children: [
            const Text('stop', style: TextStyle(color: ShowcaseColors.dim, fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(width: 14),
            ResultBox(label: _unitLabel, value: _stopDist.toStringAsFixed(0), color: ShowcaseColors.coral),
            Expanded(
              child: Slider(
                value: _stopDist.clamp(0, total).toDouble(),
                min: 0,
                max: total,
                onChanged: (v) => setState(() {
                  _stopDist = v;
                  if (_stopDist < _startDist) _startDist = _stopDist;
                }),
                activeColor: ShowcaseColors.coral,
                inactiveColor: ShowcaseColors.cage,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              ChipBadge(text: 'total ${total.toStringAsFixed(0)} $_unitLabel', color: ShowcaseColors.sky),
              const SizedBox(width: 8),
              ChipBadge(text: 'slice ${(_stopDist - _startDist).toStringAsFixed(0)} $_unitLabel', color: ShowcaseColors.mint),
              const Spacer(),
              _unitDropdown(),
              const SizedBox(width: 8),
              ResetButton(onTap: _reset),
            ],
          ),
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'Feature<LineString>'),
          kv('vertices', slice.length.toString(), glow: true),
          kv('length', '${(_stopDist - _startDist).toStringAsFixed(2)} $_unitLabel'),
        ],
        callRows: [
          kv('fn', 'lineSliceAlong(line, startDist, stopDist, unit)'),
          kv('startDist', '${_startDist.toStringAsFixed(2)} $_unitLabel'),
          kv('stopDist', '${_stopDist.toStringAsFixed(2)} $_unitLabel'),
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
            setState(() {
              final ratio = _stopDist / _totalLength;
              final startRatio = _startDist / _totalLength;
              _unit = u;
              _stopDist = ratio * _totalLength;
              _startDist = startRatio * _totalLength;
            });
          },
        ),
      ),
    );
  }
}
