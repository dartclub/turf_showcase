import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/to_wgs84.dart';
import 'package:turf/helpers.dart' as turf;

class GeoToWgs84Showcase extends StatefulWidget {
  const GeoToWgs84Showcase({super.key});

  @override
  State<GeoToWgs84Showcase> createState() => _GeoToWgs84ShowcaseState();
}

class _GeoToWgs84ShowcaseState extends State<GeoToWgs84Showcase> {
  // colours
  static const ink      = Color(0xFF0F1117);
  static const card     = Color(0xFF1C2333);
  static const cage     = Color(0xFF30363D);
  static const dim      = Color(0xFF8B949E);
  static const bright   = Color(0xFFE6EDF3);
  static const mint     = Color(0xFF1EBF77);
  static const sun      = Color(0xFFFFD33D);
  static const errorRed = Color(0xFFFF7B72);
  static const inputPurple = Color(0xFFD2A8FF);

  late final TextEditingController xCtrl;
  late final TextEditingController yCtrl;
  late final fm.MapController mapCtrl;

  // valid parsed values (Mercator x/y)
  double mercX = -7903683.85;
  double mercY =  5012341.66;

  String? xError;
  String? yError;

  bool get allGood => xError == null && yError == null;

  // valid Mercator ranges
  static const xMin = -20037508.34;
  static const xMax =  20037508.34;
  static const yMin = -20048966.10;
  static const yMax =  20048966.10;

  @override
  void initState() {
    super.initState();
    mapCtrl = fm.MapController();
    xCtrl = TextEditingController(text: '-7903683.85');
    yCtrl = TextEditingController(text: '5012341.66');
  }

  @override
  void dispose() {
    xCtrl.dispose();
    yCtrl.dispose();
    super.dispose();
  }

  void checkX(String val) {
    final n = double.tryParse(val);
    setState(() {
      if (n == null) {
        xError = 'must be a number';
      } else if (n < xMin || n > xMax) {
        xError = 'x: −20037508 to 20037508';
      } else {
        xError = null;
        mercX = n;
        _moveMap();
      }
    });
  }

  void checkY(String val) {
    final n = double.tryParse(val);
    setState(() {
      if (n == null) {
        yError = 'must be a number';
      } else if (n < yMin || n > yMax) {
        yError = 'y: −20048966 to 20048966';
      } else {
        yError = null;
        mercY = n;
        _moveMap();
      }
    });
  }

  void _moveMap() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted || !allGood) return;
      final pos = wgs84Result;
      mapCtrl.move(LatLng(pos['lat']!, pos['lng']!), mapCtrl.camera.zoom);
    });
  }

  // input point in Mercator space
  turf.Feature<turf.Point> get inputPoint => turf.Feature<turf.Point>(
        geometry: turf.Point(coordinates: turf.Position(mercX, mercY)),
      );

  // run the conversion — output is WGS84 lng/lat
  Map<String, double> get wgs84Result {
    final result = geoToWgs84(inputPoint);
    final pt = result as turf.Feature<turf.Point>;
    final coords = pt.geometry!.coordinates;
    return {
      'lng': coords.lng.toDouble(),
      'lat': coords.lat.toDouble(),
    };
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
            'Enter Mercator coordinates to see the WGS84 output',
            style: TextStyle(color: dim.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // map showing the converted WGS84 result point
  Widget _mapSection() {
    final pos = allGood ? wgs84Result : null;
    return SizedBox(
      height: 380,
      child: ClipRect(
        child: fm.FlutterMap(
          mapController: mapCtrl,
          options: fm.MapOptions(
            initialCenter: LatLng(
              pos?['lat'] ?? 41.0,
              pos?['lng'] ?? -71.0,
            ),
            initialZoom: 4,
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
            if (pos != null)
              fm.MarkerLayer(
                markers: [
                  // result marker
                  fm.Marker(
                    point: LatLng(pos['lat']!, pos['lng']!),
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.6, end: 1.0),
                      duration: const Duration(milliseconds: 350),
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
                          Icons.location_on,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // callout bubble showing the WGS84 lng/lat on the map
                  fm.Marker(
                    point: LatLng(pos['lat']!, pos['lng']!),
                    width: 200,
                    height: 56,
                    alignment: Alignment.topCenter,
                    child: Transform.translate(
                      offset: const Offset(0, -62),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: ink,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: sun.withOpacity(0.4)),
                        ),
                        child: Text(
                          'lng: ${pos['lng']!.toStringAsFixed(4)}\n'
                          'lat: ${pos['lat']!.toStringAsFixed(4)}',
                          style: const TextStyle(
                            color: sun,
                            fontFamily: 'monospace',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
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

  // input fields
  Widget _controls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: cage)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // range hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: mint.withOpacity(0.07),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: mint.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: mint.withOpacity(0.7), size: 13),
                const SizedBox(width: 7),
                const Text(
                  'x: ±20037508   ·   y: ±20048966  (EPSG:3857)',
                  style: TextStyle(
                    color: dim,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // mercator inputs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mercator input  (EPSG:3857)',
                      style: TextStyle(
                        color: dim,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _field(
                          label: 'x',
                          ctrl: xCtrl,
                          error: xError,
                          onChanged: checkX,
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: _field(
                          label: 'y',
                          ctrl: yCtrl,
                          error: yError,
                          onChanged: checkY,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // wgs84 output
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WGS84 output',
                      style: TextStyle(
                        color: dim,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Builder(builder: (_) {
                      final pos = allGood ? wgs84Result : null;
                      return Row(
                        children: [
                          Expanded(child: _outputField(
                            label: 'lng',
                            value: pos != null
                                ? pos['lng']!.toStringAsFixed(4)
                                : '—',
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: _outputField(
                            label: 'lat',
                            value: pos != null
                                ? pos['lat']!.toStringAsFixed(4)
                                : '—',
                          )),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController ctrl,
    required String? error,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: error != null ? errorRed.withOpacity(0.6) : cage,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: error != null ? errorRed.withOpacity(0.4) : cage,
                    ),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: error != null ? errorRed : dim,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: ctrl,
                  onChanged: onChanged,
                  style: TextStyle(
                    color: error != null ? errorRed : inputPurple,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*')),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Text(
            error,
            style: const TextStyle(
              color: errorRed,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }

  Widget _outputField({required String label, required String value}) {
    return Container(
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: allGood ? sun.withOpacity(0.4) : cage,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: allGood ? sun.withOpacity(0.3) : cage,
                ),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: allGood ? sun.withOpacity(0.8) : dim,
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                value,
                style: TextStyle(
                  color: allGood ? sun : dim,
                  fontFamily: 'monospace',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // result panel
  Widget _resultFooter() {
    final pos = allGood ? wgs84Result : null;
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
              _row('lng', pos != null ? pos['lng']!.toStringAsFixed(6) : '—', glow: true),
              _row('lat', pos != null ? pos['lat']!.toStringAsFixed(6) : '—', glow: true),
            ]),
          ),
          Container(width: 1, height: 60, color: cage),
          const SizedBox(width: 16),
          Expanded(
            child: _col('Call', [
              _row('fn', 'geoToWgs84(pt)'),
              _row('input', allGood
                  ? 'Position($mercX, $mercY)'
                  : '—'),
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