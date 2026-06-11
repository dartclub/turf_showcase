import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart';
import 'package:turf/nearest_point.dart';
import 'package:turf/helpers.dart' as turf;

import '_common.dart';

class NearestPointShowcase extends StatefulWidget {
  const NearestPointShowcase({super.key});

  @override
  State<NearestPointShowcase> createState() => _NearestPointShowcaseState();
}

class _NearestPointShowcaseState extends State<NearestPointShowcase> {
  late LatLng _target;
  late List<LatLng> _candidates;
  bool _draggingTarget = false;
  int? _draggingCandidate;
  late final fm.MapController _mapCtrl;

  static const _defaultTarget = LatLng(41.01, 28.965);

  static List<LatLng> _generate(int n) {
    final r = Random(13);
    return List.generate(n, (i) {
      return LatLng(
        _defaultTarget.latitude + (r.nextDouble() - 0.5) * 0.6,
        _defaultTarget.longitude + (r.nextDouble() - 0.5) * 0.8,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    _mapCtrl = fm.MapController();
    _target = _defaultTarget;
    _candidates = _generate(8);
  }

  int get _nearestIndex {
    final fc = turf.FeatureCollection<turf.Point>(
      features: _candidates
          .map((p) => turf.Feature<turf.Point>(
                geometry: turf.Point(coordinates: turf.Position(p.longitude, p.latitude)),
              ))
          .toList(),
    );
    final tFeat = turf.Feature<turf.Point>(
      geometry: turf.Point(coordinates: turf.Position(_target.longitude, _target.latitude)),
    );
    final result = nearestPoint(tFeat, fc);
    final coords = result.geometry!.coordinates;
    final found = LatLng(coords.lat.toDouble(), coords.lng.toDouble());
    int best = 0;
    double bestDist = double.infinity;
    for (var i = 0; i < _candidates.length; i++) {
      final c = _candidates[i];
      final d = (c.latitude - found.latitude) * (c.latitude - found.latitude) +
          (c.longitude - found.longitude) * (c.longitude - found.longitude);
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  void _onTargetDrag(DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_target) + d.delta);
    setState(() => _target = next);
  }

  void _onCandidateDrag(int idx, DragUpdateDetails d) {
    final cam = _mapCtrl.camera;
    final next = cam.screenOffsetToLatLng(cam.latLngToScreenOffset(_candidates[idx]) + d.delta);
    setState(() => _candidates[idx] = next);
  }

  void _reset() => setState(() {
        _target = _defaultTarget;
        _candidates = _generate(8);
      });

  @override
  Widget build(BuildContext context) {
    final nearestIdx = _nearestIndex;
    final nearest = _candidates[nearestIdx];
    return ShowcaseFrame(
      hint: 'Drag the green target — the nearest blue point glows yellow',
      map: fm.FlutterMap(
        mapController: _mapCtrl,
        options: fm.MapOptions(
          initialCameraFit: fm.CameraFit.coordinates(
            coordinates: [_target, ..._candidates],
            padding: const EdgeInsets.all(70),
          ),
          interactionOptions: const fm.InteractionOptions(
            flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
          ),
        ),
        children: [
          darkTileLayer(),
          fm.PolylineLayer(polylines: [
            fm.Polyline(
              points: [_target, nearest],
              color: ShowcaseColors.sun.withOpacity(0.85),
              strokeWidth: 2.5,
              pattern: fm.StrokePattern.dashed(segments: const [8.0, 6.0]),
            ),
          ]),
          fm.MarkerLayer(markers: [
            ..._candidates.asMap().entries.map((e) {
              final isNearest = e.key == nearestIdx;
              final isActive = _draggingCandidate == e.key;
              return fm.Marker(
                point: e.value,
                width: isNearest ? 38 : 30,
                height: isNearest ? 38 : 30,
                alignment: Alignment.center,
                child: GestureDetector(
                  onPanStart: (_) => setState(() => _draggingCandidate = e.key),
                  onPanUpdate: (d) => _onCandidateDrag(e.key, d),
                  onPanEnd: (_) => setState(() => _draggingCandidate = null),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isNearest
                          ? ShowcaseColors.sun
                          : ShowcaseColors.sky.withOpacity(0.85),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: isActive ? 3 : 2,
                      ),
                      boxShadow: isNearest
                          ? [
                              BoxShadow(
                                color: ShowcaseColors.sun.withOpacity(0.6),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      isNearest ? Icons.star : Icons.circle,
                      color: isNearest ? Colors.black87 : Colors.white,
                      size: isNearest ? 18 : 12,
                    ),
                  ),
                ),
              );
            }),
            fm.Marker(
              point: _target,
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _draggingTarget = true),
                onPanUpdate: _onTargetDrag,
                onPanEnd: (_) => setState(() => _draggingTarget = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: ShowcaseColors.lime,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: _draggingTarget ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ShowcaseColors.lime.withOpacity(0.5),
                        blurRadius: _draggingTarget ? 14 : 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.gps_fixed,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ]),
        ],
      ),
      controls: ControlsBar(children: [
        Row(
          children: [
            ResultBox(
              label: 'nearest',
              value: '#${nearestIdx + 1}  '
                  '${nearest.latitude.toStringAsFixed(3)}, ${nearest.longitude.toStringAsFixed(3)}',
              icon: Icons.star,
            ),
            const Spacer(),
            ResetButton(onTap: _reset),
          ],
        ),
      ]),
      resultPanel: ResultPanel(
        resultRows: [
          kv('type', 'Feature<Point>'),
          kv('index', '${nearestIdx + 1} of ${_candidates.length}'),
          kv('lat', nearest.latitude.toStringAsFixed(6), glow: true),
          kv('lng', nearest.longitude.toStringAsFixed(6), glow: true),
        ],
        callRows: [
          kv('fn', 'nearestPoint(target, points)'),
          kv('candidates', '${_candidates.length}'),
        ],
      ),
    );
  }
}
