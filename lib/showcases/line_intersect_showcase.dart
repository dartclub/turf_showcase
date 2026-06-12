import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/line_intersect.dart';
import 'package:turf/helpers.dart' as turf;

class LineIntersectShowcase extends StatefulWidget {
  const LineIntersectShowcase({super.key});

  @override
  State<LineIntersectShowcase> createState() => _LineIntersectShowcaseState();
}

class _LineIntersectShowcaseState extends State<LineIntersectShowcase> {
  // colours
  static const ink    = Color(0xFF0F1117);
  static const card   = Color(0xFF1C2333);
  static const cage   = Color(0xFF30363D);
  static const dim    = Color(0xFF8B949E);
  static const bright = Color(0xFFE6EDF3);
  static const mint   = Color(0xFF1EBF77);
  static const sun    = Color(0xFFFFD33D);
  static const line1Color = Color(0xFF58A6FF);
  static const line2Color = Color(0xFFD2A8FF);
  static const noIntersectColor = Color(0xFFF85149);

  late fm.MapController mapCtrl;

  // line 1: two endpoints
  static const _defaultL1A = LatLng(50.0,  2.0);
  static const _defaultL1B = LatLng(48.0, 16.0);

  // line 2: two endpoints
  static const _defaultL2A = LatLng(52.0,  5.0);
  static const _defaultL2B = LatLng(46.0, 13.0);

  late LatLng l1a, l1b, l2a, l2b;

  // dragging index: 0=l1a, 1=l1b, 2=l2a, 3=l2b
  int? dragging;

  @override
  void initState() {
    super.initState();
    mapCtrl = fm.MapController();
    l1a = _defaultL1A;
    l1b = _defaultL1B;
    l2a = _defaultL2A;
    l2b = _defaultL2B;
  }

  void _reset() => setState(() {
        l1a = _defaultL1A;
        l1b = _defaultL1B;
        l2a = _defaultL2A;
        l2b = _defaultL2B;
      });

  // build turf LineString from two LatLng points
  turf.Feature<turf.LineString> _toLine(LatLng a, LatLng b) =>
      turf.Feature<turf.LineString>(
        geometry: turf.LineString(coordinates: [
          turf.Position(a.longitude, a.latitude),
          turf.Position(b.longitude, b.latitude),
        ]),
      );

  // compute intersection
  List<LatLng> get intersections {
    final result = lineIntersect(_toLine(l1a, l1b), _toLine(l2a, l2b));
    return result.features.map((f) {
      final coords = f.geometry!.coordinates;
      return LatLng(coords.lat.toDouble(), coords.lng.toDouble());
    }).toList();
  }

  void _onDrag(int idx, DragUpdateDetails drag) {
    final camera = mapCtrl.camera;
    LatLng current;
    switch (idx) {
      case 0: current = l1a; break;
      case 1: current = l1b; break;
      case 2: current = l2a; break;
      default: current = l2b;
    }
    final offset = camera.latLngToScreenOffset(current);
    final moved = camera.screenOffsetToLatLng(offset + drag.delta);
    setState(() {
      switch (idx) {
        case 0: l1a = moved; break;
        case 1: l1b = moved; break;
        case 2: l2a = moved; break;
        default: l2b = moved;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pts = intersections;
    final hasIntersection = pts.isNotEmpty;
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
          _mapSection(pts, hasIntersection),
          _infoStrip(pts, hasIntersection),
          _resultFooter(pts, hasIntersection),
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
            'Drag the endpoints to move the lines',
            style: TextStyle(color: dim.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // the map
  Widget _mapSection(List<LatLng> pts, bool hasIntersection) {
    return SizedBox(
      height: 420,
      child: ClipRect(
        child: fm.FlutterMap(
          mapController: mapCtrl,
          options: fm.MapOptions(
            initialCameraFit: fm.CameraFit.coordinates(
              coordinates: [l1a, l1b, l2a, l2b],
              padding: const EdgeInsets.all(60),
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
            // line 1
            fm.PolylineLayer(
              polylines: [
                fm.Polyline(
                  points: [l1a, l1b],
                  color: line1Color,
                  strokeWidth: 2.5,
                ),
              ],
            ),
            // line 2
            fm.PolylineLayer(
              polylines: [
                fm.Polyline(
                  points: [l2a, l2b],
                  color: line2Color,
                  strokeWidth: 2.5,
                ),
              ],
            ),
            // intersection dot
            if (hasIntersection)
              fm.MarkerLayer(
                markers: pts.map((pt) => fm.Marker(
                  point: pt,
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.5, end: 1.0),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    builder: (_, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      decoration: BoxDecoration(
                        color: sun,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: sun.withOpacity(0.6),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.black87,
                        size: 16,
                      ),
                    ),
                  ),
                )).toList(),
              ),
            // endpoint handles
            fm.MarkerLayer(
              markers: [
                _handle(0, l1a, line1Color, '1A'),
                _handle(1, l1b, line1Color, '1B'),
                _handle(2, l2a, line2Color, '2A'),
                _handle(3, l2b, line2Color, '2B'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  fm.Marker _handle(int idx, LatLng pt, Color color, String label) {
    final isActive = dragging == idx;
    return fm.Marker(
      point: pt,
      width: 48,
      height: 48,
      alignment: Alignment.center,
      child: GestureDetector(
        onPanStart: (_) => setState(() => dragging = idx),
        onPanUpdate: (d) => _onDrag(idx, d),
        onPanEnd: (_) => setState(() => dragging = null),
        child: Tooltip(
          message: label,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isActive ? color : color.withOpacity(0.75),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: isActive ? 2.5 : 1.5,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // info strip
  Widget _infoStrip(List<LatLng> pts, bool hasIntersection) {
    final statusColor = hasIntersection ? mint : noIntersectColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: cage)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // line legend
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _lineLegend(line1Color, 'Line 1',
                    '(${l1a.latitude.toStringAsFixed(1)}, ${l1a.longitude.toStringAsFixed(1)}) → (${l1b.latitude.toStringAsFixed(1)}, ${l1b.longitude.toStringAsFixed(1)})'),
                const SizedBox(height: 8),
                _lineLegend(line2Color, 'Line 2',
                    '(${l2a.latitude.toStringAsFixed(1)}, ${l2a.longitude.toStringAsFixed(1)}) → (${l2b.latitude.toStringAsFixed(1)}, ${l2b.longitude.toStringAsFixed(1)})'),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // status badge + reset
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasIntersection ? Icons.check_circle : Icons.cancel,
                      color: statusColor,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      hasIntersection ? 'intersecting' : 'no intersection',
                      style: TextStyle(
                        color: statusColor,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _reset,
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
    );
  }

  Widget _lineLegend(Color color, String label, String coords) {
    return Row(
      children: [
        Container(
          width: 24, height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            coords,
            style: const TextStyle(
              color: dim,
              fontFamily: 'monospace',
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // result panel
  Widget _resultFooter(List<LatLng> pts, bool hasIntersection) {
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
              _row('type', 'FeatureCollection<Point>'),
              _row('count', '${pts.length} point(s)', glow: hasIntersection),
              if (hasIntersection) ...[
                _row('lat', pts.first.latitude.toStringAsFixed(6), glow: true),
                _row('lng', pts.first.longitude.toStringAsFixed(6), glow: true),
              ] else
                _row('intersects', 'false', glow: false),
            ]),
          ),
          Container(width: 1, height: 80, color: cage),
          const SizedBox(width: 16),
          Expanded(
            child: _col('Call', [
              _row('fn', 'lineIntersect(line1, line2)'),
              _row('line1', 'Feature<LineString>'),
              _row('line2', 'Feature<LineString>'),
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