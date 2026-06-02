import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:turf/along.dart';
import 'package:turf/helpers.dart';
import 'package:turf/length.dart';

class AlongShowcase extends StatefulWidget {
  const AlongShowcase({super.key});

  @override
  State<AlongShowcase> createState() => _AlongShowcaseState();
}

class _AlongShowcaseState extends State<AlongShowcase>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF1EBF77);
  static const _cardBg = Color(0xFF1C2333);
  static const _border = Color(0xFF30363D);
  static const _codeBg = Color(0xFF0D1117);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _startColor = Color(0xFF3FB950);
  static const _endColor = Color(0xFFF85149);
  static const _alongColor = Color(0xFFFFD33D);

  late final Feature<LineString> _line;
  late final double _totalLengthKm;
  late final MapController _mapController;

  double _distanceKm = 0;
  Unit _unit = Unit.kilometers;

  Timer? _animationTimer;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _line = Feature<LineString>(
      geometry: LineString(coordinates: [
        Position(-74.0060, 40.7128),
        Position(-74.0030, 40.7264),
        Position(-73.9857, 40.7484),
        Position(-73.9712, 40.7831),
        Position(-73.9580, 40.8005),
      ]),
    );
    _totalLengthKm = length(_line, Unit.kilometers).toDouble();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  double get _totalLengthInUnit {
    switch (_unit) {
      case Unit.kilometers:
        return _totalLengthKm;
      case Unit.miles:
        return _totalLengthKm * 0.621371;
      case Unit.meters:
        return _totalLengthKm * 1000;
      case Unit.nauticalmiles:
        return _totalLengthKm * 0.539957;
      default:
        return _totalLengthKm;
    }
  }

  String get _unitLabel {
    switch (_unit) {
      case Unit.kilometers:
        return 'km';
      case Unit.miles:
        return 'mi';
      case Unit.meters:
        return 'm';
      case Unit.nauticalmiles:
        return 'nmi';
      default:
        return 'km';
    }
  }

  Feature<Point> get _alongPoint => along(_line, _distanceKm, _unit);

  List<LatLng> get _routePoints => _line.geometry!.coordinates
      .map((p) => LatLng(p.lat.toDouble(), p.lng.toDouble()))
      .toList();

  LatLng get _startLatLng => _routePoints.first;
  LatLng get _endLatLng => _routePoints.last;

  LatLng get _alongLatLng {
    final pos = _alongPoint.geometry!.coordinates;
    return LatLng(pos.lat.toDouble(), pos.lng.toDouble());
  }

  void _togglePlay() {
    if (_isPlaying) {
      _animationTimer?.cancel();
      setState(() => _isPlaying = false);
      return;
    }
    setState(() {
      _isPlaying = true;
      if (_distanceKm >= _totalLengthInUnit) _distanceKm = 0;
    });
    _animationTimer = Timer.periodic(const Duration(milliseconds: 50), (t) {
      final step = _totalLengthInUnit / 200;
      final next = _distanceKm + step;
      if (next >= _totalLengthInUnit) {
        setState(() {
          _distanceKm = _totalLengthInUnit;
          _isPlaying = false;
        });
        t.cancel();
      } else {
        setState(() => _distanceKm = next);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          SizedBox(
            height: 420,
            child: ClipRRect(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCameraFit: CameraFit.coordinates(
                    coordinates: _routePoints,
                    padding: const EdgeInsets.all(48),
                  ),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                    subdomains: const ['a', 'b', 'c', 'd'],
                    userAgentPackageName: 'com.example.turf_showcase',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePoints,
                        color: _green.withOpacity(0.85),
                        strokeWidth: 4,
                        borderColor: Colors.black54,
                        borderStrokeWidth: 1,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      _buildMarker(_startLatLng, _startColor, Icons.flag, 'Start'),
                      _buildMarker(_endLatLng, _endColor, Icons.location_on, 'End'),
                      _buildAlongMarker(_alongLatLng),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _buildControls(),
          _buildResultPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Example interactive map',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'Drag the slider to move the point along the line',
            style: TextStyle(
              color: _textSecondary.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildMarker(LatLng pos, Color color, IconData icon, String label) {
    return Marker(
      point: pos,
      width: 36,
      height: 36,
      alignment: Alignment.topCenter,
      child: Tooltip(
        message: label,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  Marker _buildAlongMarker(LatLng pos) {
    return Marker(
      point: pos,
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _alongColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: _alongColor.withOpacity(0.6),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.my_location, color: Colors.black87, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'distance',
                style: TextStyle(
                  color: _textSecondary,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _codeBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _border),
                ),
                child: Text(
                  '${_distanceKm.toStringAsFixed(2)} $_unitLabel',
                  style: const TextStyle(
                    color: _alongColor,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              _buildUnitDropdown(),
              const SizedBox(width: 12),
              InkWell(
                onTap: _togglePlay,
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _green.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: _green,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _isPlaying ? 'Pause' : 'Animate',
                        style: const TextStyle(
                          color: _green,
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
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _green,
              inactiveTrackColor: _border,
              thumbColor: _alongColor,
              overlayColor: _alongColor.withOpacity(0.15),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: _distanceKm.clamp(0, _totalLengthInUnit).toDouble(),
              min: 0,
              max: _totalLengthInUnit,
              onChanged: (v) => setState(() {
                _distanceKm = v;
                if (_isPlaying) {
                  _animationTimer?.cancel();
                  _isPlaying = false;
                }
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0 $_unitLabel',
                    style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        fontFamily: 'monospace')),
                Text(
                  '${_totalLengthInUnit.toStringAsFixed(2)} $_unitLabel (total)',
                  style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _codeBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Unit>(
          value: _unit,
          isDense: true,
          dropdownColor: _codeBg,
          icon: const Icon(Icons.arrow_drop_down,
              color: _textSecondary, size: 16),
          style: const TextStyle(
            color: _textPrimary,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
          items: const [
            DropdownMenuItem(
                value: Unit.kilometers, child: Text('Unit.kilometers')),
            DropdownMenuItem(value: Unit.miles, child: Text('Unit.miles')),
            DropdownMenuItem(value: Unit.meters, child: Text('Unit.meters')),
            DropdownMenuItem(
                value: Unit.nauticalmiles,
                child: Text('Unit.nauticalmiles')),
          ],
          onChanged: (u) {
            if (u == null) return;
            final fractionTraveled = _distanceKm / _totalLengthInUnit;
            setState(() {
              _unit = u;
              _distanceKm = _totalLengthInUnit * fractionTraveled;
            });
          },
        ),
      ),
    );
  }

  Widget _buildResultPanel() {
    final pos = _alongPoint.geometry!.coordinates;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
        color: _codeBg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _resultColumn('Result', [
              _kv('type', 'Feature<Point>'),
              _kv('lat', pos.lat.toStringAsFixed(6)),
              _kv('lng', pos.lng.toStringAsFixed(6)),
            ]),
          ),
          Container(width: 1, height: 60, color: _border),
          const SizedBox(width: 16),
          Expanded(
            child: _resultColumn('Call', [
              _kv('fn', 'along(line, distance, unit)'),
              _kv('distance', '${_distanceKm.toStringAsFixed(2)} $_unitLabel'),
              _kv('unit', _unit.toString()),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _resultColumn(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: _textSecondary,
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

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              k,
              style: const TextStyle(
                color: _textSecondary,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              v,
              style: const TextStyle(
                color: _textPrimary,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
