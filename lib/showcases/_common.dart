import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';

class ShowcaseColors {
  static const ink = Color(0xFF0F1117);
  static const card = Color(0xFF1C2333);
  static const cage = Color(0xFF30363D);
  static const dim = Color(0xFF8B949E);
  static const bright = Color(0xFFE6EDF3);
  static const mint = Color(0xFF1EBF77);
  static const sun = Color(0xFFFFD33D);
  static const sky = Color(0xFF58A6FF);
  static const coral = Color(0xFFF85149);
  static const lime = Color(0xFF3FB950);
  static const violet = Color(0xFFD2A8FF);
  static const errorRed = Color(0xFFFF7B72);
}

fm.TileLayer darkTileLayer() {
  return fm.TileLayer(
    urlTemplate:
        'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
    subdomains: const ['a', 'b', 'c', 'd'],
    userAgentPackageName: 'com.example.turf_showcase',
  );
}

class ShowcaseFrame extends StatelessWidget {
  final String hint;
  final double mapHeight;
  final Widget map;
  final Widget? controls;
  final Widget resultPanel;
  final Widget? infoStrip;

  const ShowcaseFrame({
    super.key,
    required this.hint,
    required this.map,
    required this.resultPanel,
    this.controls,
    this.infoStrip,
    this.mapHeight = 420,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ShowcaseColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ShowcaseColors.cage),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShowcaseHeader(hint: hint),
          SizedBox(height: mapHeight, child: ClipRect(child: map)),
          if (controls != null) controls!,
          if (infoStrip != null) infoStrip!,
          resultPanel,
        ],
      ),
    );
  }
}

class ShowcaseHeader extends StatelessWidget {
  final String hint;
  const ShowcaseHeader({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ShowcaseColors.cage)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: ShowcaseColors.mint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Example interactive map',
            style: TextStyle(
              color: ShowcaseColors.bright,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              hint,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: ShowcaseColors.dim.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ResultPanel extends StatelessWidget {
  final List<Widget> resultRows;
  final List<Widget> callRows;

  const ResultPanel({
    super.key,
    required this.resultRows,
    required this.callRows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ShowcaseColors.cage)),
        color: ShowcaseColors.ink,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ResultColumn(title: 'Result', rows: resultRows)),
          Container(width: 1, height: 60, color: ShowcaseColors.cage),
          const SizedBox(width: 16),
          Expanded(child: ResultColumn(title: 'Call', rows: callRows)),
        ],
      ),
    );
  }
}

class ResultColumn extends StatelessWidget {
  final String title;
  final List<Widget> rows;
  const ResultColumn({super.key, required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: ShowcaseColors.dim,
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
}

Widget kv(String k, String v, {bool glow = false, double labelWidth = 76}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            k,
            style: const TextStyle(
              color: ShowcaseColors.dim,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: TextStyle(
              color: glow ? ShowcaseColors.sun : ShowcaseColors.bright,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
      ],
    ),
  );
}

class ChipBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const ChipBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ControlsBar extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;

  const ControlsBar({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(20, 14, 20, 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ShowcaseColors.cage)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

fm.Marker dotMarker({
  required LatLng point,
  required Color color,
  IconData icon = Icons.location_on,
  double size = 36,
  String? tooltip,
  bool emphasize = false,
}) {
  Widget child = Container(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: emphasize ? 3 : 2),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.5),
          blurRadius: emphasize ? 14 : 8,
          spreadRadius: emphasize ? 2 : 1,
        ),
      ],
    ),
    child: Icon(icon, color: Colors.white, size: size * 0.5),
  );
  if (tooltip != null) {
    child = Tooltip(message: tooltip, child: child);
  }
  return fm.Marker(
    point: point,
    width: size,
    height: size,
    alignment: Alignment.center,
    child: child,
  );
}

class DraggableHandleMarker extends StatelessWidget {
  final bool active;
  final IconData icon;
  final double size;

  const DraggableHandleMarker({
    super.key,
    this.active = false,
    this.icon = Icons.open_with,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: active
            ? ShowcaseColors.coral.withOpacity(0.9)
            : ShowcaseColors.sky.withOpacity(0.85),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: active ? 2.5 : 1.5,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: ShowcaseColors.coral.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: active ? size * 0.55 : size * 0.45,
      ),
    );
  }
}

class ResetButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const ResetButton({
    super.key,
    required this.onTap,
    this.label = 'Reset',
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ShowcaseColors.mint.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: ShowcaseColors.mint.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, color: ShowcaseColors.mint, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: ShowcaseColors.mint,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ResultBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const ResultBox({
    super.key,
    required this.label,
    required this.value,
    this.color = ShowcaseColors.sun,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: ShowcaseColors.ink,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: ShowcaseColors.dim,
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
