import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/length.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class LengthShowcase extends StatefulWidget {
  const LengthShowcase({super.key});

  @override
  State<LengthShowcase> createState() => _LengthShowcaseState();
}

class _LengthShowcaseState extends State<LengthShowcase> {
  static List<LatLng> get _defaults => const [
        LatLng(-32, 115),
        LatLng(-22, 131),
        LatLng(-25, 143),
      ];

  late List<LatLng> _vertices;
  turf.Unit _unit = turf.Unit.kilometers;
  int? _draggingIndex;
  late final fm.MapController _mapCtrl;

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _vertices = List.from(_defaults);
  }

  double get _length {
    final coords = _vertices
        .map((v) => turf.Position(v.longitude, v.latitude))
        .toList();
    final feature = turf.Feature<turf.LineString>(
      geometry: turf.LineString(coordinates: coords),
    );
    return length(feature, _unit).toDouble();
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
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_vertices[idx]) + d.delta);
    setState(() => _vertices[idx] = next);
  }

  void _addVertex() {
    final last = _vertices.last;
    setState(() => _vertices.add(LatLng(last.latitude + 5, last.longitude + 5)));
  }

  void _removeVertex() {
    if (_vertices.length <= 2) return;
    setState(() => _vertices.removeLast());
  }

  void _reset() => setState(() => _vertices = List.from(_defaults));

  @override
  Widget build(BuildContext context) {
    return ShowcaseFrame(
      hint: 'Drag vertices, add or remove to change the line length',
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
              color: ShowcaseColors.mint.withOpacity(0.85),
              strokeWidth: 4,
              borderColor: Colors.black54,
              borderStrokeWidth: 1,
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
            ResultBox(
              label: 'length',
              value: '${_length.toStringAsFixed(2)} $_unitLabel',
              icon: Icons.straighten,
            ),
            const SizedBox(width: 10),
            _unitDropdown(),
            const SizedBox(width: 10),
            _vertexButton(Icons.add, 'Add', _addVertex),
            const SizedBox(width: 6),
            _vertexButton(Icons.remove, 'Remove',
                _vertices.length > 2 ? _removeVertex : null),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'double'),
          kv('value', _length.toStringAsFixed(4), glow: true),
          kv('unit', _unitLabel),
        ],
        callRows: [
          kv('fn', 'length(line, unit)'),
          kv('vertices', '${_vertices.length}'),
        ],
      ),
    );
  }

  Widget _vertexButton(IconData icon, String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: ShowcaseColors.ink,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: enabled ? ShowcaseColors.cage : ShowcaseColors.cage.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: enabled
                    ? ShowcaseColors.bright
                    : ShowcaseColors.dim),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  color: enabled ? ShowcaseColors.bright : ShowcaseColors.dim,
                  fontSize: 11,
                  fontFamily: 'monospace',
                )),
          ],
        ),
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
