import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/bearing.dart';
import 'package:turf/helpers.dart' as turf;

class BearingShowcase extends StatefulWidget {
  const BearingShowcase({super.key});

  @override
  State<BearingShowcase> createState() => _BearingShowcaseState();
}

class _BearingShowcaseState extends State<BearingShowcase> {
  // colours
  static const ink      = Color(0xFF0F1117);
  static const card     = Color(0xFF1C2333);
  static const cage     = Color(0xFF30363D);
  static const dim      = Color(0xFF8B949E);
  static const bright   = Color(0xFFE6EDF3);
  static const mint     = Color(0xFF1EBF77);
  static const sun      = Color(0xFFFFD33D);
  static const startColor = Color(0xFF3FB950);
  static const endColor   = Color(0xFFF85149);

  late fm.MapController mapCtrl;

  // default points: London → Berlin
  LatLng startPt = const LatLng(51.5074, -0.1278);
  LatLng endPt   = const LatLng(52.5200, 13.4050);

  int? dragging; // 0 = start, 1 = end

  @override
  void initState() {
    super.initState();
    mapCtrl = fm.MapController();
  }

  // compute bearing using turf
  num get bearingDeg {
    final start = turf.Point(
        coordinates: turf.Position(startPt.longitude, startPt.latitude));
    final end = turf.Point(
        coordinates: turf.Position(endPt.longitude, endPt.latitude));
    return bearing(start, end);
  }

  // compass direction label
  String get compassLabel {
    final b = bearingDeg % 360;
    if (b >= 337.5 || b < 22.5) return 'N';
    if (b < 67.5) return 'NE';
    if (b < 112.5) return 'E';
    if (b < 157.5) return 'SE';
    if (b < 202.5) return 'S';
    if (b < 247.5) return 'SW';
    if (b < 292.5) return 'W';
    return 'NW';
  }

  void _onDrag(int idx, DragUpdateDetails drag) {
    final camera = mapCtrl.camera;
    final current = idx == 0
        ? camera.latLngToScreenOffset(startPt)
        : camera.latLngToScreenOffset(endPt);
    final moved = current + drag.delta;
    final newLatLng = camera.screenOffsetToLatLng(moved);
    setState(() {
      if (idx == 0) {
        startPt = newLatLng;
      } else {
        endPt = newLatLng;
      }
    });
  }

  void _reset() => setState(() {
        startPt = const LatLng(51.5074, -0.1278);
        endPt = const LatLng(52.5200, 13.4050);
      });

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
          _controls(),
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
            'Drag the points to update the bearing',
            style: TextStyle(color: dim.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // the map
  Widget _mapSection() {
    final b = bearingDeg;
    return SizedBox(
      height: 420,
      child: ClipRect(
        child: fm.FlutterMap(
          mapController: mapCtrl,
          options: fm.MapOptions(
            initialCameraFit: fm.CameraFit.coordinates(
              coordinates: [startPt, endPt],
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
            // line between points
            fm.PolylineLayer(
              polylines: [
                fm.Polyline(
                  points: [startPt, endPt],
                  color: sun.withOpacity(0.6),
                  strokeWidth: 2,
                  pattern: fm.StrokePattern.dashed(segments: [8, 5]),
                ),
              ],
            ),
            // compass rose overlay at midpoint
            fm.MarkerLayer(
              markers: [
                fm.Marker(
                  point: LatLng(
                    (startPt.latitude + endPt.latitude) / 2,
                    (startPt.longitude + endPt.longitude) / 2,
                  ),
                  width: 80,
                  height: 80,
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: b * math.pi / 180,
                    child: CustomPaint(
                      size: const Size(80, 80),
                      painter: _CompassPainter(color: sun),
                    ),
                  ),
                ),
              ],
            ),
            // start and end markers
            fm.MarkerLayer(
              markers: [
                _buildDraggableMarker(0, startPt, startColor, 'Start'),
                _buildDraggableMarker(1, endPt, endColor, 'End'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  fm.Marker _buildDraggableMarker(
      int idx, LatLng pt, Color color, String label) {
    final isActive = dragging == idx;
    return fm.Marker(
      point: pt,
      width: 80,
      height: 60,
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onPanStart: (_) => setState(() => dragging = idx),
        onPanUpdate: (d) => _onDrag(idx, d),
        onPanEnd: (_) => setState(() => dragging = null),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // label
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ink.withOpacity(0.85),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: isActive ? color : cage,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? color : dim,
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 2),
            // dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: isActive ? 18 : 14,
              height: isActive ? 18 : 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.5),
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
  }

  // bearing info + reset
  Widget _controls() {
    final b = bearingDeg;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: cage)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // start coords
          Expanded(
            child: _coordChip(
              label: 'start',
              color: startColor,
              lat: startPt.latitude,
              lng: startPt.longitude,
            ),
          ),
          const SizedBox(width: 12),
          // bearing display
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: sun.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: sun.withOpacity(0.35)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${b.toStringAsFixed(1)}°',
                      style: const TextStyle(
                        color: sun,
                        fontFamily: 'monospace',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      compassLabel,
                      style: TextStyle(
                        color: sun.withOpacity(0.7),
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // end coords
          Expanded(
            child: _coordChip(
              label: 'end',
              color: endColor,
              lat: endPt.latitude,
              lng: endPt.longitude,
            ),
          ),
          const SizedBox(width: 12),
          // reset
          InkWell(
            onTap: _reset,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: cage),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.refresh, color: dim, size: 14),
                  SizedBox(width: 5),
                  Text(
                    'Reset',
                    style: TextStyle(
                      color: dim,
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
    );
  }

  Widget _coordChip({
    required String label,
    required Color color,
    required double lat,
    required double lng,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'lat ${lat.toStringAsFixed(3)}',
            style: const TextStyle(
              color: bright,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
          Text(
            'lng ${lng.toStringAsFixed(3)}',
            style: const TextStyle(
              color: bright,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // result panel
  Widget _resultFooter() {
    final b = bearingDeg;
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
              _row('type', 'num'),
              _row('bearing', '${b.toStringAsFixed(4)}°', glow: true),
              _row('direction', compassLabel, glow: true),
            ]),
          ),
          Container(width: 1, height: 60, color: cage),
          const SizedBox(width: 16),
          Expanded(
            child: _col('Call', [
              _row('fn', 'bearing(start, end)'),
              _row('start', 'Point(${startPt.longitude.toStringAsFixed(2)}, ${startPt.latitude.toStringAsFixed(2)})'),
              _row('end', 'Point(${endPt.longitude.toStringAsFixed(2)}, ${endPt.latitude.toStringAsFixed(2)})'),
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

// compass arrow painter
class _CompassPainter extends CustomPainter {
  final Color color;
  const _CompassPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 6;

    // circle
    canvas.drawCircle(Offset(cx, cy), r, paint);

    // arrow pointing up (north before rotation)
    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path()
      ..moveTo(cx, cy - r + 4)
      ..lineTo(cx - 6, cy + 4)
      ..lineTo(cx, cy - 2)
      ..lineTo(cx + 6, cy + 4)
      ..close();

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(_CompassPainter old) => old.color != color;
}