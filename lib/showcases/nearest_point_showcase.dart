import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/nearest_point.dart';
import 'package:turf/helpers.dart' as turf;

class NearestPointShowcase extends StatefulWidget {
  const NearestPointShowcase({super.key});

  @override
  State<NearestPointShowcase> createState() => _NearestPointShowcaseState();
}

class _NearestPointShowcaseState extends State<NearestPointShowcase> {
  // colours
  static const ink     = Color(0xFF0F1117);
  static const card    = Color(0xFF1C2333);
  static const cage    = Color(0xFF30363D);
  static const dim     = Color(0xFF8B949E);
  static const bright  = Color(0xFFE6EDF3);
  static const mint    = Color(0xFF1EBF77);
  static const sun     = Color(0xFFFFD33D);
  static const sky     = Color(0xFF58A6FF);
  static const coral   = Color(0xFFF85149);

  late fm.MapController mapCtrl;

  // fixed candidate pins over Europe
  static const _pinLabels = [
    'Paris', 'Berlin', 'Rome', 'Madrid', 'Vienna', 'Warsaw'
  ];

  static List<LatLng> get _defaultPins => [
    const LatLng(48.8566,  2.3522),   // Paris
    const LatLng(52.5200, 13.4050),   // Berlin
    const LatLng(41.9028, 12.4964),   // Rome
    const LatLng(40.4168, -3.7038),   // Madrid
    const LatLng(48.2082, 16.3738),   // Vienna
    const LatLng(52.2297, 21.0122),   // Warsaw
  ];

  static const _defaultRef = LatLng(50.0, 8.0);

  late List<LatLng> pins;
  late LatLng refPoint;
  bool draggingRef = false;

  @override
  void initState() {
    super.initState();
    mapCtrl = fm.MapController();
    pins = List.from(_defaultPins);
    refPoint = _defaultRef;
  }

  void _reset() => setState(() {
        pins = List.from(_defaultPins);
        refPoint = _defaultRef;
      });

  // find nearest pin index using turf
  int get nearestIdx {
    final ref = turf.Feature<turf.Point>(
      geometry: turf.Point(
        coordinates: turf.Position(refPoint.longitude, refPoint.latitude),
      ),
    );
    final candidates = turf.FeatureCollection<turf.Point>(
      features: pins.map((p) => turf.Feature<turf.Point>(
        geometry: turf.Point(
          coordinates: turf.Position(p.longitude, p.latitude),
        ),
      )).toList(),
    );
    final result = nearestPoint(ref, candidates);
    final resultLat = result.geometry!.coordinates.lat.toDouble();
    final resultLng = result.geometry!.coordinates.lng.toDouble();
    return pins.indexWhere(
      (p) =>
          (p.latitude - resultLat).abs() < 0.0001 &&
          (p.longitude - resultLng).abs() < 0.0001,
    );
  }

  void _onRefDrag(DragUpdateDetails drag) {
    final camera = mapCtrl.camera;
    final current = camera.latLngToScreenOffset(refPoint);
    final moved = current + drag.delta;
    setState(() => refPoint = camera.screenOffsetToLatLng(moved));
  }

  @override
  Widget build(BuildContext context) {
    final nearest = nearestIdx;
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
          _mapSection(nearest),
          _infoStrip(nearest),
          _resultFooter(nearest),
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
            'Drag the reference point to find the nearest pin',
            style: TextStyle(color: dim.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // the map
  Widget _mapSection(int nearest) {
    return SizedBox(
      height: 420,
      child: ClipRect(
        child: fm.FlutterMap(
          mapController: mapCtrl,
          options: fm.MapOptions(
            initialCameraFit: fm.CameraFit.coordinates(
              coordinates: [...pins, refPoint],
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
            // line from ref to nearest pin
            fm.PolylineLayer(
              polylines: [
                fm.Polyline(
                  points: [refPoint, pins[nearest]],
                  color: sun.withOpacity(0.5),
                  strokeWidth: 1.5,
                  pattern: fm.StrokePattern.dashed(segments: [6, 4]),
                ),
              ],
            ),
            // candidate pins
            fm.MarkerLayer(
              markers: pins.asMap().entries.map((entry) {
                final i = entry.key;
                final pt = entry.value;
                final isNearest = i == nearest;
                return fm.Marker(
                  point: pt,
                  width: 80,
                  height: 56,
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // label
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isNearest
                              ? sun.withOpacity(0.15)
                              : ink.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: isNearest ? sun : cage,
                          ),
                        ),
                        child: Text(
                          _pinLabels[i],
                          style: TextStyle(
                            color: isNearest ? sun : dim,
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // dot
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: isNearest ? 18 : 12,
                        height: isNearest ? 18 : 12,
                        decoration: BoxDecoration(
                          color: isNearest ? sun : sky.withOpacity(0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isNearest ? Colors.white : sky.withOpacity(0.3),
                            width: isNearest ? 2.5 : 1.5,
                          ),
                          boxShadow: isNearest
                              ? [
                                  BoxShadow(
                                    color: sun.withOpacity(0.6),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            // draggable reference point
            fm.MarkerLayer(
              markers: [
                fm.Marker(
                  point: refPoint,
                  width: 80,
                  height: 56,
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onPanStart: (_) => setState(() => draggingRef = true),
                    onPanUpdate: _onRefDrag,
                    onPanEnd: (_) => setState(() => draggingRef = false),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ink.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: draggingRef ? coral : cage,
                            ),
                          ),
                          child: Text(
                            'Reference',
                            style: TextStyle(
                              color: draggingRef ? coral : dim,
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: draggingRef ? 20 : 16,
                          height: draggingRef ? 20 : 16,
                          decoration: BoxDecoration(
                            color: coral,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: coral.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.white,
                            size: 10,
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
      ),
    );
  }

  // info strip
  Widget _infoStrip(int nearest) {
    final nearestPt = pins[nearest];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: cage)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // candidate pins list
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
                      'candidate pins',
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
                  children: pins.asMap().entries.map((e) {
                    final isNearest = e.key == nearest;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isNearest ? sun.withOpacity(0.08) : ink,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isNearest ? sun.withOpacity(0.5) : cage,
                        ),
                      ),
                      child: Text(
                        _pinLabels[e.key],
                        style: TextStyle(
                          color: isNearest ? sun : dim,
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: isNearest
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // nearest result
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
                    'nearest',
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
                  '${_pinLabels[nearest]}\n'
                  'lat ${nearestPt.latitude.toStringAsFixed(4)}\n'
                  'lng ${nearestPt.longitude.toStringAsFixed(4)}',
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

  // result panel
  Widget _resultFooter(int nearest) {
    final nearestPt = pins[nearest];
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
              _row('name', _pinLabels[nearest], glow: true),
              _row('lat', nearestPt.latitude.toStringAsFixed(6), glow: true),
              _row('lng', nearestPt.longitude.toStringAsFixed(6), glow: true),
            ]),
          ),
          Container(width: 1, height: 80, color: cage),
          const SizedBox(width: 16),
          Expanded(
            child: _col('Call', [
              _row('fn', 'nearestPoint(ref, points)'),
              _row('ref', 'Position(${refPoint.longitude.toStringAsFixed(2)}, ${refPoint.latitude.toStringAsFixed(2)})'),
              _row('candidates', '${pins.length} points'),
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