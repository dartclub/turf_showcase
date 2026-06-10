import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/flatten.dart';
import 'package:turf/helpers.dart' as turf;

class FlattenShowcase extends StatefulWidget {
  const FlattenShowcase({super.key});

  @override
  State<FlattenShowcase> createState() => _FlattenShowcaseState();
}

class _FlattenShowcaseState extends State<FlattenShowcase> {
  // colours
  static const ink    = Color(0xFF0F1117);
  static const card   = Color(0xFF1C2333);
  static const cage   = Color(0xFF30363D);
  static const dim    = Color(0xFF8B949E);
  static const bright = Color(0xFFE6EDF3);
  static const mint   = Color(0xFF1EBF77);
  static const sun    = Color(0xFFFFD33D);

  // colours for each flattened polygon
  static const pieceColors = [
    Color(0xFF58A6FF),
    Color(0xFFF85149),
    Color(0xFFD2A8FF),
  ];

  static const unflattenedColor = Color(0xFF8B949E);

  bool flattened = false;
  late final fm.MapController mapCtrl;

  // three polygon shapes over Europe as a MultiPolygon
  // piece 1: rough France shape
  static const piece1 = [
    [48.8, -4.5], [51.0, 2.5], [49.5, 8.0],
    [47.5, 7.5], [43.5, 7.0], [42.5, 3.0],
    [43.5, -1.8], [48.8, -4.5],
  ];

  // piece 2: rough Germany shape
  static const piece2 = [
    [54.5, 8.5], [54.8, 13.5], [51.0, 15.0],
    [48.5, 13.5], [47.5, 10.5], [49.5, 6.0],
    [51.5, 6.0], [54.5, 8.5],
  ];

  // piece 3: rough Italy shape
  static const piece3 = [
    [44.0, 7.0], [45.5, 13.5], [44.5, 12.5],
    [41.5, 15.5], [38.0, 15.5], [37.5, 13.0],
    [40.0, 9.0], [44.0, 7.0],
  ];

  @override
  void initState() {
    super.initState();
    mapCtrl = fm.MapController();
  }

  List<List<List<double>>> get allPieces => [piece1, piece2, piece3];

  // convert raw coords to LatLng list
  List<LatLng> toLatLngs(List<List<double>> ring) =>
      ring.map((c) => LatLng(c[0], c[1])).toList();

  // build turf MultiPolygon from pieces
  turf.Feature<turf.MultiPolygon> get multiPolygon {
    final rings = allPieces.map((piece) => [
      piece.map((c) => turf.Position(c[1], c[0])).toList()
        ..add(turf.Position(piece.first[1], piece.first[0])),
    ]).toList();

    return turf.Feature<turf.MultiPolygon>(
      geometry: turf.MultiPolygon(coordinates: rings),
    );
  }

  // run flatten and extract polygon ring coords
  List<List<LatLng>> get flattenedPieces {
    final result = flatten(multiPolygon);
    return result.features.map((f) {
      final poly = f.geometry as turf.Polygon;
      return poly.coordinates.first
          .map((pos) => LatLng(pos.lat.toDouble(), pos.lng.toDouble()))
          .toList();
    }).toList();
  }

  void _toggle() => setState(() => flattened = !flattened);
  void _reset() => setState(() => flattened = false);

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
            flattened
                ? '3 individual polygons'
                : '1 MultiPolygon feature',
            style: TextStyle(color: dim.withOpacity(0.9), fontSize: 12),
          ),
        ],
      ),
    );
  }

  // the map
  Widget _mapSection() {
    final pieces = flattenedPieces;
    return SizedBox(
      height: 420,
      child: ClipRect(
        child: fm.FlutterMap(
          mapController: mapCtrl,
          options: fm.MapOptions(
            initialCenter: const LatLng(47.0, 8.0),
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
            fm.PolygonLayer(
              polygons: flattened
                  ? pieces.asMap().entries.map((entry) {
                      final color = pieceColors[entry.key % pieceColors.length];
                      return fm.Polygon(
                        points: entry.value,
                        color: color.withOpacity(0.3),
                        borderColor: color,
                        borderStrokeWidth: 2.5,
                      );
                    }).toList()
                  : allPieces.map((piece) => fm.Polygon(
                      points: toLatLngs(piece),
                      color: unflattenedColor.withOpacity(0.15),
                      borderColor: unflattenedColor.withOpacity(0.5),
                      borderStrokeWidth: 1.5,
                    )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // flatten/reset button + legend
  Widget _controls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: cage)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // before/after legend
          Expanded(
            child: Row(
              children: [
                // before
                Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: unflattenedColor.withOpacity(0.4),
                    border: Border.all(color: unflattenedColor),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'MultiPolygon',
                  style: TextStyle(color: dim, fontFamily: 'monospace', fontSize: 11),
                ),
                const SizedBox(width: 16),
                // after
                ...pieceColors.asMap().entries.map((e) => Row(
                  children: [
                    Container(
                      width: 12, height: 12,
                      decoration: BoxDecoration(
                        color: e.value.withOpacity(0.4),
                        border: Border.all(color: e.value),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Polygon ${e.key + 1}',
                      style: const TextStyle(
                          color: dim, fontFamily: 'monospace', fontSize: 11),
                    ),
                    const SizedBox(width: 10),
                  ],
                )),
              ],
            ),
          ),
          // buttons
          Row(
            children: [
              // flatten / unflatten toggle
              InkWell(
                onTap: _toggle,
                borderRadius: BorderRadius.circular(6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: flattened
                        ? sun.withOpacity(0.12)
                        : mint.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: flattened
                          ? sun.withOpacity(0.4)
                          : mint.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        flattened ? Icons.layers_clear : Icons.layers,
                        color: flattened ? sun : mint,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        flattened ? 'Unflattened' : 'Flatten',
                        style: TextStyle(
                          color: flattened ? sun : mint,
                          fontSize: 13,
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
                onTap: _reset,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
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
    );
  }

  // result panel
  Widget _resultFooter() {
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
              _row('type', 'FeatureCollection<GeometryObject>'),
              _row('input', '1 MultiPolygon feature'),
              _row('output', flattened ? '3 Polygon features' : '—', glow: flattened),
            ]),
          ),
          Container(width: 1, height: 60, color: cage),
          const SizedBox(width: 16),
          Expanded(
            child: _col('Call', [
              _row('fn', 'flatten(geojson)'),
              _row('input', 'Feature<MultiPolygon>'),
              _row('returns', 'FeatureCollection'),
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