import 'package:flutter/material.dart';

import 'turf_demo.dart';

const _category = 'Lines';

List<TurfDemo> lineDemos() => const [
      TurfDemo(
        id: 'line_slice',
        name: 'lineSlice',
        category: _category,
        icon: Icons.content_cut_rounded,
        description:
            'Returns the sub-section of a LineString that lies between a '
            'start and a stop point. The reference points need not fall '
            'exactly on the line — they are projected onto the nearest '
            'segment first. Useful for extracting only the part of a route '
            'between waypoints.',
        parameters: [
          TurfParameter(
            name: 'startPt',
            type: 'Feature<Point>',
            required: true,
            description: 'Start point used to clip the line.',
          ),
          TurfParameter(
            name: 'stopPt',
            type: 'Feature<Point>',
            required: true,
            description: 'Stop point used to clip the line.',
          ),
          TurfParameter(
            name: 'line',
            type: 'Feature<LineString>',
            required: true,
            description: 'LineString feature to slice.',
          ),
        ],
      ),
      TurfDemo(
        id: 'nearest_point_on_line',
        name: 'nearestPointOnLine',
        category: _category,
        icon: Icons.near_me_rounded,
        description:
            'Takes a Point and a LineString and calculates the closest Point '
            'on the LineString. The properties of the returned Point contain '
            '`index` (segment index), `dist` (distance from the input point) '
            'and `location` (distance along the line to the snapped point).',
        parameters: [
          TurfParameter(
            name: 'line',
            type: 'LineString',
            required: true,
            description: 'LineString to project the point onto.',
          ),
          TurfParameter(
            name: 'point',
            type: 'Point',
            required: true,
            description: 'Reference point to snap.',
          ),
          TurfParameter(
            name: 'unit',
            type: 'Unit',
            required: false,
            defaultValue: 'Unit.kilometers',
            description:
                'Unit used for the `dist` and `location` properties of the '
                'returned Feature.',
          ),
        ],
      ),
      TurfDemo(
        id: 'point_to_line_distance',
        name: 'pointToLineDistance',
        category: _category,
        icon: Icons.height_rounded,
        description:
            'Returns the minimum distance between a point and a line, defined '
            'as the smallest distance between the point and any segment of '
            'the LineString.',
        parameters: [
          TurfParameter(
            name: 'point',
            type: 'Point',
            required: true,
            description: 'Input point.',
          ),
          TurfParameter(
            name: 'line',
            type: 'LineString',
            required: true,
            description: 'Reference line.',
          ),
          TurfParameter(
            name: 'unit',
            type: 'Unit',
            required: false,
            defaultValue: 'Unit.kilometers',
            description: 'Unit in which the result is returned.',
          ),
          TurfParameter(
            name: 'method',
            type: 'DistanceGeometry',
            required: false,
            defaultValue: 'DistanceGeometry.geodesic',
            description:
                'Distance calculation method (`geodesic` for great-circle, '
                '`planar` for flat-earth / rhumb).',
          ),
        ],
      ),
      TurfDemo(
        id: 'line_intersect',
        name: 'lineIntersect',
        category: _category,
        icon: Icons.close_rounded,
        description:
            'Takes any LineString or Polygon and returns the intersecting '
            'Point(s) as a FeatureCollection<Point>.',
        parameters: [
          TurfParameter(
            name: 'line1',
            type: 'GeoJSONObject',
            required: true,
            description:
                'First geometry (LineString, Polygon, MultiLineString, '
                'MultiPolygon, Feature or FeatureCollection).',
          ),
          TurfParameter(
            name: 'line2',
            type: 'GeoJSONObject',
            required: true,
            description: 'Second geometry, of the same supported types.',
          ),
          TurfParameter(
            name: 'removeDuplicates',
            type: 'bool',
            required: false,
            defaultValue: 'true',
            description:
                'When true, duplicate intersection points are filtered out.',
          ),
          TurfParameter(
            name: 'ignoreSelfIntersections',
            type: 'bool',
            required: false,
            defaultValue: 'false',
            description:
                'When true, self-intersections within either input feature '
                'are skipped.',
          ),
        ],
      ),
    ];
