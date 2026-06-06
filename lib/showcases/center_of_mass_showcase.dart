import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/center_of_mass.dart';
import 'package:turf/helpers.dart' as turf;

class CenterOfMassShowcase extends StatefulWidget {
  const CenterOfMassShowcase({super.key});

  @override
  State<CenterOfMassShowcase> createState() => _CenterOfMassShowcaseState();
}

class _CenterOfMassShowcaseState extends State<CenterOfMassShowcase> {
  // colours
  static const ink    = Color(0xFF0F1117);
  static const card   = Color(0xFF1C2333);
  static const cage   = Color(0xFF30363D);
  static const dim    = Color(0xFF8B949E);
  static const bright = Color(0xFFE6EDF3);
  static const mint   = Color(0xFF1EBF77);
  static const sun    = Color(0xFFFFD33D);
  static const sky    = Color(0xFF58A6FF);
  static const coral  = Color(0xFFF85149);

  // default shape: wonky hexagon over central Europe
  static List<LatLng> get _defaultCorners => [
    const LatLng(51.5,  2.0),
    const LatLng(53.0, 13.5),
    const LatLng(50.0, 20.0),
    const LatLng(45.5, 16.0),
    const LatLng(44.0,  7.0),
    const LatLng(47.5,  1.5),
  ];

  late List<LatLng> corners;
  late final fm.MapController mapCtrl;
  int? dragging;

  final _mapKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    mapCtrl = fm.MapController();
    corners = List.from(_defaultCorners);
  }

  // compute center of mass from current corners
  LatLng get centerDot {
    final ring = [
      ...corners.map((c) => turf.Position(c.longitude, c.latitude)),
      turf.Position(corners.first.longitude, corners.first.latitude),
    ];
    final poly = turf.Feature<turf.Polygon>(
      geometry: turf.Polygon(coordinates: [ring]),
    );
    final result = centerOfMass(poly);
    final coords = result.geometry!.coordinates;
    return LatLng(coords.lat.toDouble(), coords.lng.toDouble());
  }

  void _resetShape() => setState(() => corners = List.from(_defaultCorners));

  // drag: flutter_map v8 uses camera.latLngToScreenOffset / screenOffsetToLatLng
  void _onCornerDrag(int idx, DragUpdateDetails drag) {
    final camera = mapCtrl.camera;
    final currentOffset = camera.latLngToScreenOffset(corners[idx]);
    final newOffset = currentOffset + drag.delta;
    setState(() => corners[idx] = camera.screenOffsetToLatLng(newOffset));
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

  // header bar
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
            'Drag the corner handles to reshape the polygon',
            style: TextStyle(color: dim.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // the map
  Widget _mapSection() {
    return SizedBox(
      key: _mapKey,
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
            // filled polygon
            fm.PolygonLayer(
              polygons: [
                fm.Polygon(
                  points: corners,
                  color: sky.withOpacity(0.15),
                  borderColor: sky.withOpacity(0.7),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            // center of mass marker
            fm.MarkerLayer(
              markers: [
                fm.Marker(
                  point: centerDot,
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.7, end: 1.0),
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
                            color: sun.withOpacity(0.55),
                            blurRadius: 14,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.center_focus_strong,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // draggable corner handles
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
                    onPanUpdate: (d) => _onCornerDrag(i, d),
                    onPanEnd: (_) => setState(() => dragging = null),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isActive
                            ? coral.withOpacity(0.9)
                            : sky.withOpacity(0.85),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: isActive ? 2.5 : 1.5,
                        ),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: coral.withOpacity(0.5),
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

  // coords strip and reset button
  Widget _infoStrip() {
    final com = centerDot;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: cage)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // vertex list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: sky.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'vertices',
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
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: corners.asMap().entries.map((e) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: ink,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: cage),
                      ),
                      child: Text(
                        '${e.key + 1}  '
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
          // result and reset
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: const BoxDecoration(
                      color: sun,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'center of mass',
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: sun.withOpacity(0.4)),
                ),
                child: Text(
                  'lat ${com.latitude.toStringAsFixed(4)}\n'
                  'lng ${com.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(
                    color: sun,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _resetShape,
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
                        'Reset shape',
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

  // result panel matching along/flip style
  Widget _resultFooter() {
    final com = centerDot;
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
              _row('type', 'Feature<Point>'),
              _row('lat', com.latitude.toStringAsFixed(6), glow: true),
              _row('lng', com.longitude.toStringAsFixed(6), glow: true),
            ]),
          ),
          Container(width: 1, height: 60, color: cage),
          const SizedBox(width: 16),
          Expanded(
            child: _col('Call', [
              _row('fn', 'centerOfMass(polygon)'),
              _row('vertices', '${corners.length}'),
              _row('mutate', 'false'),
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