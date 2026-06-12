import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/api_data.dart';
import '../showcases/along_showcase.dart';
import '../showcases/flip_showcase.dart'; 
import '../showcases/center_of_mass_showcase.dart';
import '../showcases/geo_to_mercator_showcase.dart';
import '../showcases/geo_to_wgs84_showcase.dart';
import '../showcases/point_on_feature_showcase.dart';
import '../showcases/envelope_showcase.dart';
import '../showcases/random_linestring_showcase.dart';
import '../showcases/flatten_showcase.dart';
import '../showcases/bearing_showcase.dart';
import '../showcases/boolean_point_in_polygon_showcase.dart';
import '../showcases/destination_showcase.dart';
import '../showcases/nearest_point_showcase.dart';
import '../showcases/line_intersect_showcase.dart';
import '../showcases/installation_section.dart';

class ApiPage extends StatefulWidget {
  const ApiPage({super.key});

  @override
  State<ApiPage> createState() => _ApiPageState();
}

class _ApiPageState extends State<ApiPage> {
  TurfFunction? _selectedFunction;
  String? _expandedCategory;
  String _searchQuery = '';
  bool _copied = false;

  static const _green = Color(0xFF1EBF77);
  static const _darkBg = Color(0xFF0F1117);
  static const _sidebarBg = Color(0xFF161B22);
  static const _cardBg = Color(0xFF1C2333);
  static const _border = Color(0xFF30363D);
  static const _textPrimary = Color(0xFFE6EDF3);
  static const _textSecondary = Color(0xFF8B949E);
  static const _codeBg = Color(0xFF0D1117);

  @override
  void initState() {
    super.initState();
    _selectedFunction = apiCategories.first.functions.first;
    _expandedCategory = apiCategories.first.name;
  }

  List<TurfCategory> get _filteredCategories {
    if (_searchQuery.isEmpty) return apiCategories;
    return apiCategories
        .map((cat) => TurfCategory(
              name: cat.name,
              icon: cat.icon,
              functions: cat.functions
                  .where((f) =>
                      f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      f.description.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList(),
            ))
        .where((cat) => cat.functions.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSidebar(),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: _sidebarBg,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('T', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'turf_dart',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _green.withOpacity(0.4)),
                ),
                child: const Text(
                  'API',
                  style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const Spacer(),
          _topNavLink('API', active: true),
          const SizedBox(width: 24)
        ],
      ),
    );
  }

  Widget _topNavLink(String label, {bool active = false}) {
    return Text(
      label,
      style: TextStyle(
        color: active ? _green : _textSecondary,
        fontSize: 14,
        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }

  Widget _buildSidebar() {
    final filtered = _filteredCategories;
    return Container(
      width: 280,
      decoration: const BoxDecoration(
        color: _sidebarBg,
        border: Border(right: BorderSide(color: _border)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: _codeBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  const Icon(Icons.search, color: _textSecondary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(color: _textPrimary, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'Search functions...',
                        hintStyle: TextStyle(color: _textSecondary, fontSize: 13),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: filtered.map((cat) => _buildCategorySection(cat)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection(TurfCategory cat) {
    final isExpanded = _expandedCategory == cat.name || _searchQuery.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() {
            _expandedCategory = isExpanded && _searchQuery.isEmpty ? null : cat.name;
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(cat.icon, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  cat.name.toUpperCase(),
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  color: _textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          ...cat.functions.map((fn) => _buildSidebarItem(fn)),
      ],
    );
  }

  Widget _buildSidebarItem(TurfFunction fn) {
    final isSelected = _selectedFunction?.name == fn.name;
    return InkWell(
      onTap: () => setState(() {
        _selectedFunction = fn;
        _expandedCategory = apiCategories
            .firstWhere((c) => c.functions.any((f) => f.name == fn.name))
            .name;
      }),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? _green.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? _green.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            if (isSelected)
              Container(
                width: 3,
                height: 14,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _green,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            Text(
              fn.name,
              style: TextStyle(
                color: isSelected ? _green : _textPrimary,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final fn = _selectedFunction;
    if (fn == null) {
      return const Center(
        child: Text('Select a function', style: TextStyle(color: _textSecondary)),
      );
    }

    final category = apiCategories.firstWhere(
      (c) => c.functions.any((f) => f.name == fn.name),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(category.icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                category.name,
                style: const TextStyle(color: _textSecondary, fontSize: 13),
              ),
              const Text(' / ', style: TextStyle(color: _border, fontSize: 13)),
              Text(
                fn.name,
                style: const TextStyle(
                  color: _green,
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            fn.name,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fn.description,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          _sectionHeader('Parameters'),
          const SizedBox(height: 12),
          _buildParamsTable(fn),
          const SizedBox(height: 40),
          _sectionHeader('Returns'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_forward, color: _green, size: 16),
                const SizedBox(width: 10),
                Text(
                  fn.returns,
                  style: const TextStyle(
                    color: _green,
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _sectionHeader('Example'),
          const SizedBox(height: 12),
          _buildCodeBlock(fn.example),
          ..._buildShowcaseSection(fn),
          const SizedBox(height: 60),
          _buildNavigation(fn, category),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildParamsTable(TurfFunction fn) {
    if (fn.params.isEmpty) {
      return const Text('None', style: TextStyle(color: _textSecondary, fontSize: 14));
    }
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text('Name', style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Type', style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Description', style: TextStyle(color: _textSecondary, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                ),
              ],
            ),
          ),
          ...fn.params.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return Container(
              decoration: BoxDecoration(
                color: i.isOdd ? Colors.white.withOpacity(0.02) : Colors.transparent,
                border: i < fn.params.length - 1
                    ? const Border(bottom: BorderSide(color: _border))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (p.optional) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: Colors.orange.withOpacity(0.3)),
                            ),
                            child: const Text(
                              'opt',
                              style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      p.type,
                      style: const TextStyle(
                        color: Color(0xFF79C0FF),
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      p.description,
                      style: const TextStyle(color: _textSecondary, fontSize: 13, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      decoration: BoxDecoration(
        color: _codeBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _border)),
            ),
            child: Row(
              children: [
                const Text(
                  'dart',
                  style: TextStyle(color: _textSecondary, fontSize: 12, fontFamily: 'monospace'),
                ),
                const Spacer(),
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    setState(() => _copied = true);
                    await Future.delayed(const Duration(seconds: 2));
                    if (mounted) setState(() => _copied = false);
                  },
                  child: Row(
                    children: [
                      Icon(
                        _copied ? Icons.check : Icons.copy,
                        color: _copied ? _green : _textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? 'Copied!' : 'Copy',
                        style: TextStyle(
                          color: _copied ? _green : _textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildHighlightedCode(code),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedCode(String code) {
    final lines = code.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.asMap().entries.map((entry) {
        final line = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: _highlightLine(line),
        );
      }).toList(),
    );
  }

  Widget _highlightLine(String line) {
    const keywords = ['final', 'var', 'const', 'void', 'return', 'true', 'false', 'null'];
    const types = ['Feature', 'Point', 'LineString', 'Polygon', 'MultiPoint',
        'MultiLineString', 'MultiPolygon', 'FeatureCollection', 'Position',
        'BBox', 'Unit', 'GeoJSONObject', 'int', 'double', 'bool', 'String', 'List'];

    if (line.trim().startsWith('//')) {
      return Text(
        line,
        style: const TextStyle(color: Color(0xFF6A737D), fontFamily: 'monospace', fontSize: 13, height: 1.5),
      );
    }

    final spans = <TextSpan>[];
    final words = line.split(RegExp(r'(?<=\s)|(?=\s)|(?=\()|(?<=\()|(?=\))|(?<=\))|(?=,)|(?<=,)|(?=;)|(?<=;)|(?=<)|(?=\[)|(?=\])|(?={)|(?=})'));

    for (final word in words) {
      final trimmed = word.trim();
      Color color = const Color(0xFFE6EDF3);

      if (keywords.contains(trimmed)) {
        color = const Color(0xFFFF7B72);
      } else if (types.any((t) => trimmed.startsWith(t))) {
        color = const Color(0xFF79C0FF);
      } else if (trimmed.startsWith("'") || trimmed.startsWith('"')) {
        color = const Color(0xFFA5D6FF);
      } else if (double.tryParse(trimmed) != null) {
        color = const Color(0xFF79C0FF);
      } else if (trimmed.startsWith('Unit.') || trimmed.startsWith('Position') || trimmed.contains('(')) {
        color = const Color(0xFFD2A8FF);
      }

      spans.add(TextSpan(
        text: word,
        style: TextStyle(color: color, fontFamily: 'monospace', fontSize: 13, height: 1.5),
      ));
    }

    return RichText(text: TextSpan(children: spans));
  }

  List<Widget> _buildShowcaseSection(TurfFunction fn) {
    Widget? showcase;
    if (fn.name == 'along') {
      showcase = const AlongShowcase();
    } else if (fn.name == 'flip') {
      showcase = const FlipShowcase(); 
    } else if (fn.name == 'centerOfMass') {
      showcase = const CenterOfMassShowcase();
    } else if (fn.name == 'geoToMercator') {
      showcase = const GeoToMercatorShowcase();
    } else if (fn.name == 'geoToWgs84') {
      showcase = const GeoToWgs84Showcase();
    } else if (fn.name == 'pointOnFeature') {
      showcase = const PointOnFeatureShowcase();
    } else if (fn.name == 'envelope') {
      showcase = const EnvelopeShowcase();
    } else if (fn.name == 'randomLineString') {
      showcase = const RandomLinestringShowcase();
    } else if (fn.name == 'flatten') {
      showcase = const FlattenShowcase();
    } else if (fn.name == 'bearing') {
      showcase = const BearingShowcase();
    } else if (fn.name == 'booleanPointInPolygon') {
      showcase = const BooleanPointInPolygonShowcase();
    } else if (fn.name == 'destination') {
      showcase = const DestinationShowcase();
    } else if (fn.name == 'nearestPoint') {
      showcase = const NearestPointShowcase();
    } else if (fn.name == 'lineIntersect') {
      showcase = const LineIntersectShowcase();
    }

    final installation = InstallationSection(
      functionName: fn.name,
      usageExample: "import 'package:turf/turf.dart';\n\n${fn.example}",
    );

    return [
      if (showcase != null) ...[
        const SizedBox(height: 40),
        _sectionHeader('Try it'),
        const SizedBox(height: 12),
        showcase,
      ],
      const SizedBox(height: 40),
      _sectionHeader('Installation'),
      const SizedBox(height: 12),
      installation,
    ];
  }

  Widget _buildNavigation(TurfFunction fn, TurfCategory category) {
    final allFunctions = apiCategories.expand((c) => c.functions).toList();
    final idx = allFunctions.indexWhere((f) => f.name == fn.name);
    final prev = idx > 0 ? allFunctions[idx - 1] : null;
    final next = idx < allFunctions.length - 1 ? allFunctions[idx + 1] : null;

    return Row(
      children: [
        if (prev != null)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedFunction = prev),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('← Previous', style: TextStyle(color: _textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(prev.name, style: const TextStyle(color: _green, fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
        if (prev != null && next != null) const SizedBox(width: 16),
        if (next != null)
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedFunction = next),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Next →', style: TextStyle(color: _textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(next.name, style: const TextStyle(color: _green, fontFamily: 'monospace', fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}