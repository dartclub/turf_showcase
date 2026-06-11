import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/boolean.dart';
import 'package:turf/helpers.dart' as turf;

class BooleanPointInPolygonShowcase extends StatefulWidget {
  const BooleanPointInPolygonShowcase({super.key});

  @override
  State<BooleanPointInPolygonShowcase> createState() =>
      _BooleanPointInPolygonShowcaseState();
}

class _BooleanPointInPolygonShowcaseState
    extends State<BooleanPointInPolygonShowcase> {
  // colours
  static const ink    = Color(0xFF0F1117);
  static const card   = Color(0xFF1C2333);
  static const cage   = Color(0xFF30363D);
  static const dim    = Color(0xFF8B949E);
  static const bright = Color(0xFFE6EDF3);
  static const mint   = Color(0xFF1EBF77);
  static const sun    = Color(0xFFFFD33D);
  static const inside  = Color(0xFF3FB950);
  static const outside = Color(0xFFF85149);
  static const sky    = Color(0xFF58A6FF);

  late fm.MapController mapCtrl;

  // default polygon over central Europe
  static List<LatLng> get _defaultCorners => [
    const LatLng(51.5,  5.0),
    const LatLng(53.0, 15.0),
    const LatLng(48.0, 18.0),
    const LatLng(44.0, 12.0),
    const LatLng(46.0,  4.0),
  ];

  // default point inside the polygon
  static const _defaultPoint = LatLng(49.0, 10.0);

  late List<LatLng> corners;
  late LatLng testPoint;
  int? dragging; // 0..n-1 = corner index, 99 = test point

  @override
  void initState() {
    super.initState();
    mapCtrl = fm.MapController();
    corners = List.from(_defaultCorners);
    testPoint = _defaultPoint;
  }

  void _reset() => setState(() {
        corners = List.from(_defaultCorners);
        testPoint = _defaultPoint;
      });

  // check if test point is inside polygon using turf
  bool get isInside {
    final ring = [
      ...corners.map((c) => turf.Position(c.longitude, c.latitude)),
      turf.Position(corners.first.longitude, corners.first.latitude),
    ];
    final poly = turf.Feature<turf.Polygon>(
      geometry: turf.Polygon(coordinates: [ring]),
    );
    final pt = turf.Position(testPoint.longitude, testPoint.latitude);
    return booleanPointInPolygon(pt, poly);
  }

  void _onDrag(int idx, DragUpdateDetails drag) {
    final camera = mapCtrl.camera;
    if (idx == 99) {
      final current = camera.latLngToScreenOffset(testPoint);
      final moved = current + drag.delta;
      setState(() => testPoint = camera.screenOffsetToLatLng(moved));
    } else {
      final current = camera.latLngToScreenOffset(corners[idx]);
      final moved = current + drag.delta;
      setState(() => corners[idx] = camera.screenOffsetToLatLng(moved));
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = isInside;
    return Container(
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cage),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(result),
          _mapSection(result),
          _infoStrip(result),
          _resultFooter(result),
        ],
      ),
    );
  }

  // header
  Widget _topBar(bool result) {
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
            'Drag the point or reshape the polygon',
            style: TextStyle(color: dim.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // the map
  Widget _mapSection(bool result) {
    final dotColor = result ? inside : outside;
    return SizedBox(
      height: 420,
      child: ClipRect(
        child: fm.FlutterMap(
          mapController: mapCtrl,
          options: fm.MapOptions(
            initialCameraFit: fm.CameraFit.coordinates(
              coordinates: corners,
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
            // polygon fill changes colour based on result
            fm.PolygonLayer(
              polygons: [
                fm.Polygon(
                  points: corners,
                  color: dotColor.withOpacity(0.08),
                  borderColor: dotColor.withOpacity(0.5),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            // test point
            fm.MarkerLayer(
              markers: [
                fm.Marker(
                  point: testPoint,
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onPanStart: (_) => setState(() => dragging = 99),
                    onPanUpdate: (d) => _onDrag(99, d),
                    onPanEnd: (_) => setState(() => dragging = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: dotColor.withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.circle,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // draggable polygon corners
            fm.MarkerLayer(
              markers: corners.asMap().entries.map((entry) {
                final i = entry.key;
                final pt = entry.value;
                final isActive = dragging == i;
                return fm.Marker(
                  point: pt,
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onPanStart: (_) => setState(() => dragging = i),
                    onPanUpdate: (d) => _onDrag(i, d),
                    onPanEnd: (_) => setState(() => dragging = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isActive
                            ? sun.withOpacity(0.9)
                            : sky.withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: isActive ? 2.5 : 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: sun.withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: Icon(
                        Icons.open_with,
                        color: Colors.white,
                        size: isActive ? 16 : 13,
                      ),
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

  // result strip
  Widget _infoStrip(bool result) {
    final dotColor = result ? inside : outside;
    final label = result ? 'inside polygon' : 'outside polygon';
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: cage)),
      ),
      child: Row(
        children: [
          // point coords
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'test point',
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
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: dotColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    'lat ${testPoint.latitude.toStringAsFixed(4)}\n'
                    'lng ${testPoint.longitude.toStringAsFixed(4)}',
                    style: TextStyle(
                      color: dotColor,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // result badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: dotColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: dotColor.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Icon(
                  result ? Icons.check_circle : Icons.cancel,
                  color: dotColor,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  result ? 'true' : 'false',
                  style: TextStyle(
                    color: dotColor,
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    color: dotColor.withOpacity(0.7),
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // reset
          Column(
            children: [
              InkWell(
                onTap: _reset,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
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

  // result panel
  Widget _resultFooter(bool result) {
    final dotColor = result ? inside : outside;
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
              _row('type', 'bool'),
              _row('value', result ? 'true' : 'false',
                  color: dotColor),
              _row('status', result ? 'inside' : 'outside',
                  color: dotColor),
            ]),
          ),
          Container(width: 1, height: 60, color: cage),
          const SizedBox(width: 16),
          Expanded(
            child: _col('Call', [
              _row('fn', 'booleanPointInPolygon(pt, poly)'),
              _row('point', 'Position(${testPoint.longitude.toStringAsFixed(2)}, ${testPoint.latitude.toStringAsFixed(2)})'),
              _row('vertices', '${corners.length}'),
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

  Widget _row(String key, String val, {Color? color}) {
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
                    color: color ?? bright,
                    fontFamily: 'monospace',
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}