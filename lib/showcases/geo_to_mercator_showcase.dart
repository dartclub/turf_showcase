import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/to_mercator.dart';
import 'package:turf/helpers.dart' as turf;

class GeoToMercatorShowcase extends StatefulWidget {
  const GeoToMercatorShowcase({super.key});

  @override
  State<GeoToMercatorShowcase> createState() => _GeoToMercatorShowcaseState();
}

class _GeoToMercatorShowcaseState extends State<GeoToMercatorShowcase> {
  // colours
  static const ink    = Color(0xFF0F1117);
  static const card   = Color(0xFF1C2333);
  static const cage   = Color(0xFF30363D);
  static const dim    = Color(0xFF8B949E);
  static const bright = Color(0xFFE6EDF3);
  static const mint   = Color(0xFF1EBF77);
  static const sun    = Color(0xFFFFD33D);
  static const errorRed = Color(0xFFFF7B72);
  static const inputBlue = Color(0xFF58A6FF);

  late final TextEditingController lngCtrl;
  late final TextEditingController latCtrl;
  late final fm.MapController mapCtrl;

  // valid parsed values
  double lng = -71.0;
  double lat = 41.0;

  String? lngError;
  String? latError;

  bool get allGood => lngError == null && latError == null;

  @override
  void initState() {
    super.initState();
    mapCtrl = fm.MapController();
    lngCtrl = TextEditingController(text: '-71.0');
    latCtrl = TextEditingController(text: '41.0');
  }

  @override
  void dispose() {
    lngCtrl.dispose();
    latCtrl.dispose();
    super.dispose();
  }

  void checkLng(String val) {
    final n = double.tryParse(val);
    setState(() {
      if (n == null) {
        lngError = 'must be a number';
      } else if (n < -180 || n > 180) {
        lngError = 'lng must be −180 to 180';
      } else {
        lngError = null;
        lng = n;
        _moveMap();
      }
    });
  }

  void checkLat(String val) {
    final n = double.tryParse(val);
    setState(() {
      if (n == null) {
        latError = 'must be a number';
      } else if (n < -85.06 || n > 85.06) {
        // Mercator breaks near the poles so we cap at ~85°
        latError = 'lat must be −85.06 to 85.06';
      } else {
        latError = null;
        lat = n;
        _moveMap();
      }
    });
  }

  void _moveMap() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted || !allGood) return;
      mapCtrl.move(LatLng(lat, lng), mapCtrl.camera.zoom);
    });
  }

  // run the conversion
  turf.Feature<turf.Point> get inputPoint => turf.Feature<turf.Point>(
        geometry: turf.Point(coordinates: turf.Position(lng, lat)),
      );

  Map<String, double> get mercatorResult {
    final result = geoToMercator(inputPoint);
    final pt = result as turf.Feature<turf.Point>;
    final coords = pt.geometry!.coordinates;
    return {
      'x': coords.lng.toDouble(),
      'y': coords.lat.toDouble(),
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
            'Enter WGS84 coordinates to see the Mercator output',
            style: TextStyle(color: dim.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // map showing the WGS84 input point
  Widget _mapSection() {
    return SizedBox(
      height: 380,
      child: ClipRect(
        child: fm.FlutterMap(
          mapController: mapCtrl,
          options: fm.MapOptions(
            initialCenter: LatLng(lat, lng),
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
            if (allGood)
              fm.MarkerLayer(
                markers: [
                  fm.Marker(
                    point: LatLng(lat, lng),
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
                ],
              ),
            // callout bubble showing the mercator x/y on the map
            if (allGood)
              fm.MarkerLayer(
                markers: [
                  fm.Marker(
                    point: LatLng(lat, lng),
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
                        child: Builder(builder: (_) {
                          final m = mercatorResult;
                          return Text(
                            'x: ${m['x']!.toStringAsFixed(2)}\n'
                            'y: ${m['y']!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: sun,
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          );
                        }),
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
                  'lng: −180 to 180   ·   lat: −85.06 to 85.06  (Mercator limit)',
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
              // wgs84 inputs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WGS84 input',
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
                          label: 'lng',
                          ctrl: lngCtrl,
                          error: lngError,
                          onChanged: checkLng,
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: _field(
                          label: 'lat',
                          ctrl: latCtrl,
                          error: latError,
                          onChanged: checkLat,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // mercator output
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mercator output  (EPSG:3857)',
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
                      final m = allGood ? mercatorResult : null;
                      return Row(
                        children: [
                          Expanded(child: _outputField(
                            label: 'x',
                            value: m != null
                                ? m['x']!.toStringAsFixed(2)
                                : '—',
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: _outputField(
                            label: 'y',
                            value: m != null
                                ? m['y']!.toStringAsFixed(2)
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
                      color: error != null
                          ? errorRed.withOpacity(0.4)
                          : cage,
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
                    color: error != null ? errorRed : inputBlue,
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
    final m = allGood ? mercatorResult : null;
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
              _row('x', m != null ? m['x']!.toStringAsFixed(4) : '—', glow: true),
              _row('y', m != null ? m['y']!.toStringAsFixed(4) : '—', glow: true),
            ]),
          ),
          Container(width: 1, height: 60, color: cage),
          const SizedBox(width: 16),
          Expanded(
            child: _col('Call', [
              _row('fn', 'geoToMercator(pt)'),
              _row('input', allGood
                  ? 'Position($lng, $lat)'
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