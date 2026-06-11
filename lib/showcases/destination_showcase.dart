import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/destination.dart';
import 'package:turf/helpers.dart' as turf;

class DestinationShowcase extends StatefulWidget {
  const DestinationShowcase({super.key});

  @override
  State<DestinationShowcase> createState() => _DestinationShowcaseState();
}

class _DestinationShowcaseState extends State<DestinationShowcase> {
  // colours
  static const ink      = Color(0xFF0F1117);
  static const card     = Color(0xFF1C2333);
  static const cage     = Color(0xFF30363D);
  static const dim      = Color(0xFF8B949E);
  static const bright   = Color(0xFFE6EDF3);
  static const mint     = Color(0xFF1EBF77);
  static const sun      = Color(0xFFFFD33D);
  static const originColor = Color(0xFF3FB950);
  static const destColor   = Color(0xFF58A6FF);

  late fm.MapController mapCtrl;

  // default origin: London
  LatLng originPt = const LatLng(51.5074, -0.1278);
  bool draggingOrigin = false;

  // controls
  double bearingVal = 90.0;
  double distanceVal = 500.0;
  turf.Unit unit = turf.Unit.kilometers;

  @override
  void initState() {
    super.initState();
    mapCtrl = fm.MapController();
  }

  void _reset() => setState(() {
        originPt = const LatLng(51.5074, -0.1278);
        bearingVal = 90.0;
        distanceVal = 500.0;
        unit = turf.Unit.kilometers;
      });

  // compute destination using turf
  LatLng get destPt {
    final origin = turf.Point(
      coordinates: turf.Position(originPt.longitude, originPt.latitude),
    );
    final result = destination(origin, distanceVal, bearingVal, unit);
    return LatLng(
      result.coordinates.lat.toDouble(),
      result.coordinates.lng.toDouble(),
    );
  }

  // compass direction label
  String get compassLabel {
    final b = bearingVal % 360;
    if (b >= 337.5 || b < 22.5) return 'N';
    if (b < 67.5) return 'NE';
    if (b < 112.5) return 'E';
    if (b < 157.5) return 'SE';
    if (b < 202.5) return 'S';
    if (b < 247.5) return 'SW';
    if (b < 292.5) return 'W';
    return 'NW';
  }

  void _onOriginDrag(DragUpdateDetails drag) {
    final camera = mapCtrl.camera;
    final current = camera.latLngToScreenOffset(originPt);
    final moved = current + drag.delta;
    setState(() => originPt = camera.screenOffsetToLatLng(moved));
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
            'Drag the origin, adjust bearing and distance',
            style: TextStyle(color: dim.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // the map
  Widget _mapSection() {
    final dp = destPt;
    return SizedBox(
      height: 420,
      child: ClipRect(
        child: fm.FlutterMap(
          mapController: mapCtrl,
          options: fm.MapOptions(
            initialCameraFit: fm.CameraFit.coordinates(
              coordinates: [originPt, dp],
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
            // line from origin to destination
            fm.PolylineLayer(
              polylines: [
                fm.Polyline(
                  points: [originPt, dp],
                  color: sun.withOpacity(0.5),
                  strokeWidth: 2,
                  pattern: fm.StrokePattern.dashed(segments: [8, 5]),
                ),
              ],
            ),
            // bearing arrow indicator at origin
            fm.MarkerLayer(
              markers: [
                fm.Marker(
                  point: originPt,
                  width: 60,
                  height: 60,
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: bearingVal * math.pi / 180,
                    child: Icon(
                      Icons.navigation,
                      color: sun.withOpacity(0.7),
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
            // origin marker
            fm.MarkerLayer(
              markers: [
                fm.Marker(
                  point: originPt,
                  width: 80,
                  height: 60,
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onPanStart: (_) => setState(() => draggingOrigin = true),
                    onPanUpdate: _onOriginDrag,
                    onPanEnd: (_) => setState(() => draggingOrigin = false),
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
                              color: draggingOrigin ? originColor : cage,
                            ),
                          ),
                          child: Text(
                            'Origin',
                            style: TextStyle(
                              color: draggingOrigin ? originColor : dim,
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: draggingOrigin ? 18 : 14,
                          height: draggingOrigin ? 18 : 14,
                          decoration: BoxDecoration(
                            color: originColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: draggingOrigin
                                ? [
                                    BoxShadow(
                                      color: originColor.withOpacity(0.5),
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
                ),
                // destination marker
                fm.Marker(
                  point: dp,
                  width: 80,
                  height: 60,
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: ink.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: destColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          'Destination',
                          style: TextStyle(
                            color: destColor,
                            fontFamily: 'monospace',
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.8, end: 1.0),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        builder: (_, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: destColor,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: destColor.withOpacity(0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // sliders + unit selector
  Widget _controls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: cage)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // sliders
          Expanded(
            child: Column(
              children: [
                // bearing slider
                _slider(
                  label: 'bearing',
                  value: bearingVal,
                  min: 0,
                  max: 360,
                  divisions: 72,
                  display: '${bearingVal.toStringAsFixed(0)}° $compassLabel',
                  onChanged: (v) => setState(() => bearingVal = v),
                ),
                const SizedBox(height: 10),
                // distance slider
                _slider(
                  label: 'distance',
                  value: distanceVal,
                  min: 50,
                  max: 2000,
                  divisions: 39,
                  display:
                      '${distanceVal.toStringAsFixed(0)} ${unit == turf.Unit.kilometers ? 'km' : 'mi'}',
                  onChanged: (v) => setState(() => distanceVal = v),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // unit selector + reset
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // unit toggle
              Container(
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: cage),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _unitBtn('km', turf.Unit.kilometers),
                    _unitBtn('mi', turf.Unit.miles),
                  ],
                ),
              ),
              const SizedBox(height: 10),
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
                      Icon(Icons.refresh, color: dim, size: 13),
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
        ],
      ),
    );
  }

  Widget _unitBtn(String label, turf.Unit u) {
    final active = unit == u;
    return InkWell(
      onTap: () => setState(() => unit = u),
      borderRadius: BorderRadius.circular(5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? mint.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: active ? mint.withOpacity(0.4) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? mint : dim,
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              color: dim,
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: mint,
              inactiveTrackColor: cage,
              thumbColor: mint,
              overlayColor: mint.withOpacity(0.15),
              trackHeight: 2,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 80,
          child: Text(
            display,
            style: const TextStyle(
              color: sun,
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // result panel
  Widget _resultFooter() {
    final dp = destPt;
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
              _row('type', 'Point'),
              _row('lat', dp.latitude.toStringAsFixed(6), glow: true),
              _row('lng', dp.longitude.toStringAsFixed(6), glow: true),
            ]),
          ),
          Container(width: 1, height: 60, color: cage),
          const SizedBox(width: 16),
          Expanded(
            child: _col('Call', [
              _row('fn', 'destination(origin, distance, bearing)'),
              _row('distance',
                  '${distanceVal.toStringAsFixed(0)} ${unit == turf.Unit.kilometers ? 'km' : 'mi'}'),
              _row('bearing', '${bearingVal.toStringAsFixed(1)}° $compassLabel'),
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