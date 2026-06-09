import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/envelope.dart';
import 'package:turf/helpers.dart' as turf;

class EnvelopeShowcase extends StatefulWidget {
  const EnvelopeShowcase({super.key});

  @override
  State<EnvelopeShowcase> createState() => _EnvelopeShowcaseState();
}

class _EnvelopeShowcaseState extends State<EnvelopeShowcase> {
  // colours
  static const ink      = Color(0xFF0F1117);
  static const card     = Color(0xFF1C2333);
  static const cage     = Color(0xFF30363D);
  static const dim      = Color(0xFF8B949E);
  static const bright   = Color(0xFFE6EDF3);
  static const mint     = Color(0xFF1EBF77);
  static const sun      = Color(0xFFFFD33D);
  static const sky      = Color(0xFF58A6FF);
  static const coral    = Color(0xFFF85149);

  // default pins: Paris, Berlin, Madrid, Rome
  static List<LatLng> get _defaultPins => [
    const LatLng(48.8566,  2.3522),  // Paris
    const LatLng(52.5200, 13.4050),  // Berlin
    const LatLng(40.4168, -3.7038),  // Madrid
    const LatLng(41.9028, 12.4964),  // Rome
  ];

  static const _pinLabels = ['Paris', 'Berlin', 'Madrid', 'Rome'];

  late List<LatLng> pins;
  late final fm.MapController mapCtrl;
  int? dragging;

  @override
  void initState() {
    super.initState();
    mapCtrl = fm.MapController();
    pins = List.from(_defaultPins);
  }

  void _resetPins() => setState(() => pins = List.from(_defaultPins));

  void _addPin() {
    if (pins.length >= 8) return;
    // add a new pin near the center of current pins
    final avgLat = pins.map((p) => p.latitude).reduce((a, b) => a + b) / pins.length;
    final avgLng = pins.map((p) => p.longitude).reduce((a, b) => a + b) / pins.length;
    setState(() => pins.add(LatLng(
      avgLat + (pins.length % 2 == 0 ? 3.0 : -3.0),
      avgLng + (pins.length % 2 == 0 ? 4.0 : -4.0),
    )));
  }

  void _removePin(int idx) {
    if (pins.length <= 2) return;
    setState(() => pins.removeAt(idx));
  }

  // compute the envelope rectangle corners from current pins
  List<LatLng> get envelopeCorners {
    final points = turf.FeatureCollection<turf.Point>(
      features: pins.map((p) => turf.Feature<turf.Point>(
        geometry: turf.Point(coordinates: turf.Position(p.longitude, p.latitude)),
      )).toList(),
    );
    final result = envelope(points);
    final coords = result.geometry!.coordinates.first;
    return coords.map((pos) => LatLng(
      pos.lat.toDouble(),
      pos.lng.toDouble(),
    )).toList();
  }

  // bbox values for result panel
  Map<String, double> get bboxValues {
    final lngs = pins.map((p) => p.longitude).toList();
    final lats = pins.map((p) => p.latitude).toList();
    return {
      'minLng': lngs.reduce((a, b) => a < b ? a : b),
      'minLat': lats.reduce((a, b) => a < b ? a : b),
      'maxLng': lngs.reduce((a, b) => a > b ? a : b),
      'maxLat': lats.reduce((a, b) => a > b ? a : b),
    };
  }

  void _onPinDrag(int idx, DragUpdateDetails drag) {
    final camera = mapCtrl.camera;
    final current = camera.latLngToScreenOffset(pins[idx]);
    final moved = current + drag.delta;
    setState(() => pins[idx] = camera.screenOffsetToLatLng(moved));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cage),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(),
          _mapSection(),
          _infoStrip(),
          _resultFooter(),
        ],
      ),
    );
  }

  // header
  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: cage)),
      ),
      child: Row(
        children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(color: mint, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          const Text(
            'Example interactive map',
            style: TextStyle(color: bright, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            'Drag the pins — the envelope resizes to fit',
            style: TextStyle(color: dim.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // the map
  Widget _mapSection() {
    final corners = envelopeCorners;
    return SizedBox(
      height: 420,
      child: ClipRect(
        child: fm.FlutterMap(
          mapController: mapCtrl,
          options: fm.MapOptions(
            initialCameraFit: fm.CameraFit.coordinates(
              coordinates: pins,
              padding: const EdgeInsets.all(80),
            ),
            interactionOptions: const fm.InteractionOptions(
              flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
            ),
          ),
          children: [
            fm.TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.example.turf_showcase',
            ),
            // envelope rectangle
            fm.PolygonLayer(
              polygons: [
                fm.Polygon(
                  points: corners,
                  color: sun.withOpacity(0.08),
                  borderColor: sun.withOpacity(0.6),
                  borderStrokeWidth: 1.5,
                  pattern: fm.StrokePattern.dashed(segments: [6, 4]),
                ),
              ],
            ),
            // draggable pins
            fm.MarkerLayer(
              markers: pins.asMap().entries.map((entry) {
                final i = entry.key;
                final pt = entry.value;
                final isActive = dragging == i;
                final label = i < _pinLabels.length
                    ? _pinLabels[i]
                    : 'Pin ${i + 1}';
                return fm.Marker(
                  point: pt,
                  width: 80,
                  height: 60,
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onPanStart: (_) => setState(() => dragging = i),
                    onPanUpdate: (d) => _onPinDrag(i, d),
                    onPanEnd: (_) => setState(() => dragging = null),
                    onLongPress: () => _removePin(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // label
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ink.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: isActive
                                  ? coral.withOpacity(0.6)
                                  : cage,
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: isActive ? coral : dim,
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // pin dot
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: isActive ? 18 : 14,
                          height: isActive ? 18 : 14,
                          decoration: BoxDecoration(
                            color: isActive ? coral : sky,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: coral.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // pins list + add/reset buttons
  Widget _infoStrip() {
    final bbox = bboxValues;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: cage)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // pin list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: sky.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'pins (${pins.length}/8)  ·  long press to remove',
                      style: const TextStyle(
                        color: dim,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: pins.asMap().entries.map((e) {
                    final label = e.key < _pinLabels.length
                        ? _pinLabels[e.key]
                        : 'Pin ${e.key + 1}';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: cage),
                      ),
                      child: Text(
                        '$label  '
                        '${e.value.latitude.toStringAsFixed(2)}, '
                        '${e.value.longitude.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: bright,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // envelope bbox + buttons
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: sun.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'envelope bbox',
                    style: TextStyle(
                      color: dim,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: sun.withOpacity(0.4)),
                ),
                child: Text(
                  'minLng ${bbox['minLng']!.toStringAsFixed(2)}\n'
                  'minLat ${bbox['minLat']!.toStringAsFixed(2)}\n'
                  'maxLng ${bbox['maxLng']!.toStringAsFixed(2)}\n'
                  'maxLat ${bbox['maxLat']!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: sun,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // add pin
                  if (pins.length < 8)
                    InkWell(
                      onTap: _addPin,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: sky.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: sky.withOpacity(0.35)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, color: sky, size: 13),
                            SizedBox(width: 5),
                            Text(
                              'Add pin',
                              style: TextStyle(
                                color: sky,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // reset
                  InkWell(
                    onTap: _resetPins,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: mint.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: mint.withOpacity(0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.refresh, color: mint, size: 13),
                          SizedBox(width: 5),
                          Text(
                            'Reset',
                            style: TextStyle(
                              color: mint,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // result panel
  Widget _resultFooter() {
    final bbox = bboxValues;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: cage)),
        color: ink,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _col('Result', [
              _row('type', 'Feature<Polygon>'),
              _row('minLng', bbox['minLng']!.toStringAsFixed(4), glow: true),
              _row('minLat', bbox['minLat']!.toStringAsFixed(4), glow: true),
              _row('maxLng', bbox['maxLng']!.toStringAsFixed(4), glow: true),
              _row('maxLat', bbox['maxLat']!.toStringAsFixed(4), glow: true),
            ]),
          ),
          Container(width: 1, height: 80, color: cage),
          const SizedBox(width: 16),
          Expanded(
            child: _col('Call', [
              _row('fn', 'envelope(geojson)'),
              _row('input', 'FeatureCollection<Point>'),
              _row('pins', '${pins.length}'),
              _row('returns', 'bbox polygon'),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _col(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: dim,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        ...rows,
      ],
    );
  }

  Widget _row(String key, String val, {bool glow = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(key,
                style: const TextStyle(
                    color: dim, fontFamily: 'monospace', fontSize: 12)),
          ),
          Expanded(
            child: Text(val,
                style: TextStyle(
                    color: glow ? sun : bright,
                    fontFamily: 'monospace',
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}