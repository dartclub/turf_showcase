import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/random_linestring.dart';
import 'package:turf/helpers.dart' as turf;

class RandomLinestringShowcase extends StatefulWidget {
  const RandomLinestringShowcase({super.key});

  @override
  State<RandomLinestringShowcase> createState() =>
      _RandomLinestringShowcaseState();
}

class _RandomLinestringShowcaseState extends State<RandomLinestringShowcase> {
  // colours
  static const ink    = Color(0xFF0F1117);
  static const card   = Color(0xFF1C2333);
  static const cage   = Color(0xFF30363D);
  static const dim    = Color(0xFF8B949E);
  static const bright = Color(0xFFE6EDF3);
  static const mint   = Color(0xFF1EBF77);
  static const sun    = Color(0xFFFFD33D);

  // line colours cycling per line
  static const lineColors = [
    Color(0xFF58A6FF),
    Color(0xFFD2A8FF),
    Color(0xFFF85149),
    Color(0xFF1EBF77),
    Color(0xFFFFD33D),
  ];

  // controls
  int count        = 3;
  int numVertices  = 8;
  double maxLength = 1.5;

  // generated lines
  late turf.FeatureCollection<turf.LineString> lines;

  // bbox over Europe
  static final bbox = turf.BBox(-10.0, 35.0, 30.0, 60.0);

  late final fm.MapController mapCtrl;

  @override
  void initState() {
    super.initState();
    mapCtrl = fm.MapController();
    _generate();
  }

  void _generate() {
    lines = randomLineString(
      count,
      bbox: bbox,
      numVertices: numVertices,
      maxLength: maxLength,
    );
  }

  void _regenerate() => setState(() => _generate());

  // convert turf LineString coords to flutter_map LatLng list
  List<LatLng> _toLatLngs(turf.LineString line) {
    return line.coordinates
        .map((pos) => LatLng(pos.lat.toDouble(), pos.lng.toDouble()))
        .toList();
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
            style: TextStyle(
                color: bright, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            'Adjust parameters and regenerate',
            style: TextStyle(color: dim.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // the map
  Widget _mapSection() {
    return SizedBox(
      height: 420,
      child: ClipRect(
        child: fm.FlutterMap(
          mapController: mapCtrl,
          options: fm.MapOptions(
            initialCenter: const LatLng(47.0, 10.0),
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
            fm.PolylineLayer(
              polylines: lines.features.asMap().entries.map((entry) {
                final i = entry.key;
                final feature = entry.value;
                final color = lineColors[i % lineColors.length];
                return fm.Polyline(
                  points: _toLatLngs(feature.geometry!),
                  color: color,
                  strokeWidth: 2.5,
                );
              }).toList(),
            ),
            // start dots for each line
            fm.MarkerLayer(
              markers: lines.features.asMap().entries.map((entry) {
                final i = entry.key;
                final feature = entry.value;
                final color = lineColors[i % lineColors.length];
                final first = feature.geometry!.coordinates.first;
                return fm.Marker(
                  point: LatLng(first.lat.toDouble(), first.lng.toDouble()),
                  width: 12,
                  height: 12,
                  alignment: Alignment.center,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
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

  // sliders + generate button
  Widget _controls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: cage)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // sliders
              Expanded(
                child: Column(
                  children: [
                    _slider(
                      label: 'count',
                      value: count.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      display: '$count lines',
                      onChanged: (v) => setState(() {
                        count = v.round();
                        _generate();
                      }),
                    ),
                    const SizedBox(height: 10),
                    _slider(
                      label: 'vertices',
                      value: numVertices.toDouble(),
                      min: 3,
                      max: 20,
                      divisions: 17,
                      display: '$numVertices pts',
                      onChanged: (v) => setState(() {
                        numVertices = v.round();
                        _generate();
                      }),
                    ),
                    const SizedBox(height: 10),
                    _slider(
                      label: 'maxLength',
                      value: maxLength,
                      min: 0.5,
                      max: 5.0,
                      divisions: 9,
                      display: '${maxLength.toStringAsFixed(1)}°',
                      onChanged: (v) => setState(() {
                        maxLength = v;
                        _generate();
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // generate button
              Column(
                children: [
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _regenerate,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: mint.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: mint.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.shuffle, color: mint, size: 15),
                          SizedBox(width: 6),
                          Text(
                            'Regenerate',
                            style: TextStyle(
                              color: mint,
                              fontSize: 13,
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
          width: 48,
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
    final totalPoints = lines.features
        .fold(0, (sum, f) => sum + f.geometry!.coordinates.length);

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
              _row('type', 'FeatureCollection<LineString>'),
              _row('count', '${lines.features.length} lines', glow: true),
              _row('totalPts', '$totalPoints vertices', glow: true),
            ]),
          ),
          Container(width: 1, height: 60, color: cage),
          const SizedBox(width: 16),
          Expanded(
            child: _col('Call', [
              _row('fn', 'randomLineString(count)'),
              _row('vertices', '$numVertices per line'),
              _row('maxLength', '${maxLength.toStringAsFixed(1)}°'),
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