import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:turf/flip.dart';
import 'package:turf/helpers.dart';

class FlipShowcase extends StatefulWidget {
  const FlipShowcase({super.key});

  @override
  State<FlipShowcase> createState() => _FlipShowcaseState();
}

class _FlipShowcaseState extends State<FlipShowcase> {
  static const _green = Color(0xFF1EBF77);
  static const _cardBg = Color(0xFF1C2333);
  static const _border = Color(0xFF30363D);
  static const _codeBg = Color(0xFF0D1117);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _origColor = Color(0xFF3FB950);
  static const _flipColor = Color(0xFFF85149);
  static const _activeColor = Color(0xFFFFD33D);
  static const _errorColor = Color(0xFFFF7B72);

  late final TextEditingController _lngController;
  late final TextEditingController _latController;
  late final MapController _mapController;

  bool _isFlipped = false;
  String? _lngError;
  String? _latError;

  // Parsed valid values (only updated when input is valid)
  double _lng = 36.0;
  double _lat = 51.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _lngController = TextEditingController(text: '36.0');
    _latController = TextEditingController(text: '51.0');
  }

  @override
  void dispose() {
    _lngController.dispose();
    _latController.dispose();
    super.dispose();
  }

  bool get _isValid => _lngError == null && _latError == null;

  void _validateLng(String value) {
    final parsed = double.tryParse(value);
    setState(() {
      if (parsed == null) {
        _lngError = 'Must be a number';
      } else if (parsed < -180 || parsed > 180) {
        _lngError = 'Longitude must be between -180 and 180';
      } else {
        _lngError = null;
        _lng = parsed;
        if (_isFlipped) _isFlipped = false;
      }
    });
  }

  void _validateLat(String value) {
    final parsed = double.tryParse(value);
    setState(() {
      if (parsed == null) {
        _latError = 'Must be a number';
      } else if (parsed < -90 || parsed > 90) {
        _latError = 'Latitude must be between -90 and 90';
      } else {
        _latError = null;
        _lat = parsed;
        if (_isFlipped) _isFlipped = false;
      }
    });
  }

  Feature<Point> get _origPoint => Feature<Point>(
        geometry: Point(coordinates: Position(_lng, _lat)),
      );

  Feature<Point> get _resultPoint =>
      _isFlipped ? flip(_origPoint) as Feature<Point> : _origPoint;

  LatLng get _origLatLng => LatLng(_lat, _lng);
  LatLng get _flippedLatLng => LatLng(_lng, _lat);
  LatLng get _activeLatLng => _isFlipped ? _flippedLatLng : _origLatLng;

  double get _resultLng => _resultPoint.geometry!.coordinates.lng.toDouble();
  double get _resultLat => _resultPoint.geometry!.coordinates.lat.toDouble();

  void _toggleFlip() {
    if (!_isValid) return;
    setState(() => _isFlipped = !_isFlipped);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _mapController.move(_activeLatLng, _mapController.camera.zoom);
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
                  initialCenter: _origLatLng,
                  initialZoom: 3.5,
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
                        points: [_origLatLng, _flippedLatLng],
                        color: _activeColor.withOpacity(0.35),
                        strokeWidth: 1.5,
                        pattern: StrokePattern.dashed(
                          segments: [8.0, 6.0],
                        ),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      _buildGhostMarker(_origLatLng, _origColor, 'Original'),
                      _buildGhostMarker(_flippedLatLng, _flipColor, 'Flipped'),
                      _buildActiveMarker(_activeLatLng),
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
            'Toggle to flip lat ↔ lng on the map',
            style: TextStyle(
              color: _textSecondary.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildGhostMarker(LatLng pos, Color color, String label) {
    return Marker(
      point: pos,
      width: 36,
      height: 36,
      alignment: Alignment.topCenter,
      child: Tooltip(
        message: label,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.6), width: 1.5),
          ),
          child: Icon(Icons.location_on, color: color.withOpacity(0.7), size: 18),
        ),
      ),
    );
  }

  Marker _buildActiveMarker(LatLng pos) {
    return Marker(
      point: pos,
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _activeColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: _activeColor.withOpacity(0.6),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Range hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _green.withOpacity(0.07),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _green.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: _green.withOpacity(0.7), size: 13),
                const SizedBox(width: 7),
                Text(
                  'lng: −90 to 90   ·   lat: −90 to 90',
                  style: TextStyle(
                    color: _textSecondary,
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Lng + Lat fields
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'input',
                      style: TextStyle(
                        color: _textSecondary,
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
                        Expanded(child: _buildCoordField(
                          label: 'lng',
                          controller: _lngController,
                          error: _lngError,
                          onChanged: _validateLng,
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: _buildCoordField(
                          label: 'lat',
                          controller: _latController,
                          error: _latError,
                          onChanged: _validateLat,
                        )),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Flip button
              Column(
                children: [
                  const SizedBox(height: 18),
                  Opacity(
                    opacity: _isValid ? 1.0 : 0.4,
                    child: InkWell(
                      onTap: _isValid ? _toggleFlip : null,
                      borderRadius: BorderRadius.circular(6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _isFlipped
                              ? _flipColor.withOpacity(0.15)
                              : _green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _isFlipped
                                ? _flipColor.withOpacity(0.4)
                                : _green.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedRotation(
                              turns: _isFlipped ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.swap_vert,
                                color: _isFlipped ? _flipColor : _green,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isFlipped ? 'Unflip' : 'Flip',
                              style: TextStyle(
                                color: _isFlipped ? _flipColor : _green,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Output display
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'output',
                      style: TextStyle(
                        color: _textSecondary,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(child: _buildOutputField(
                          label: 'lng',
                          value: _isValid
                              ? _resultLng.toStringAsFixed(1)
                              : '—',
                        )),
                        const SizedBox(width: 8),
                        Expanded(child: _buildOutputField(
                          label: 'lat',
                          value: _isValid
                              ? _resultLat.toStringAsFixed(1)
                              : '—',
                        )),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoordField({
    required String label,
    required TextEditingController controller,
    required String? error,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _codeBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: error != null ? _errorColor.withOpacity(0.6) : _border,
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
                          ? _errorColor.withOpacity(0.4)
                          : _border,
                    ),
                  ),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: error != null ? _errorColor : _textSecondary,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  style: TextStyle(
                    color: error != null ? _errorColor : _origColor,
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
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^-?\d*\.?\d*')),
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
              color: _errorColor,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOutputField({
    required String label,
    required String value,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: BoxDecoration(
        color: _codeBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _isFlipped ? _flipColor.withOpacity(0.5) : _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(
                  color: _isFlipped ? _flipColor.withOpacity(0.3) : _border,
                ),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: _isFlipped ? _flipColor.withOpacity(0.8) : _textSecondary,
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
                  color: _isFlipped ? _flipColor : _textSecondary,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
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
              _kv('lng',
                  _isValid ? _resultLng.toStringAsFixed(6) : '—',
                  highlight: _isFlipped),
              _kv('lat',
                  _isValid ? _resultLat.toStringAsFixed(6) : '—',
                  highlight: _isFlipped),
            ]),
          ),
          Container(width: 1, height: 60, color: _border),
          const SizedBox(width: 16),
          Expanded(
            child: _resultColumn('Call', [
              _kv('fn', 'flip(geojson)'),
              _kv('input',
                  _isValid
                      ? 'Position(${_lng.toStringAsFixed(1)}, ${_lat.toStringAsFixed(1)})'
                      : '—'),
              _kv('mutate', 'false'),
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

  Widget _kv(String k, String v, {bool highlight = false}) {
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
              style: TextStyle(
                color: highlight ? _activeColor : _textPrimary,
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