import 'package:flutter/material.dart';

import 'turf_demo.dart';

const _category = 'Transform';

List<TurfDemo> transformDemos() => const [
      TurfDemo(
        id: 'transform_rotate',
        name: 'transformRotate',
        category: _category,
        icon: Icons.rotate_right_rounded,
        description:
            'Rotates any GeoJSONObject by the specified angle (degrees), '
            'around its centroid or a given pivot Point.',
        parameters: [
          TurfParameter(
            name: 'geoJSON',
            type: 'GeoJSONObject',
            required: true,
            description: 'Input geometry to rotate.',
          ),
          TurfParameter(
            name: 'angle',
            type: 'num',
            required: true,
            description: 'Rotation angle in degrees, clockwise.',
          ),
          TurfParameter(
            name: 'pivot',
            type: 'Point?',
            required: false,
            description:
                'Optional rotation pivot. Defaults to the centroid of the '
                'input geometry.',
          ),
          TurfParameter(
            name: 'mutate',
            type: 'bool',
            required: false,
            defaultValue: 'false',
            description:
                'When true, mutates the input in place instead of returning a '
                'new object.',
          ),
        ],
      ),
      TurfDemo(
        id: 'clean_coords',
        name: 'cleanCoords',
        category: _category,
        icon: Icons.cleaning_services_rounded,
        description:
            'Removes redundant collinear and duplicate coordinates from any '
            'GeometryType while preserving its overall shape.',
        parameters: [
          TurfParameter(
            name: 'geojson',
            type: 'GeoJSONObject',
            required: true,
            description: 'Feature or geometry to clean.',
          ),
          TurfParameter(
            name: 'mutate',
            type: 'bool',
            required: false,
            defaultValue: 'false',
            description: 'Allows the input GeoJSON to be mutated in place.',
          ),
        ],
      ),
      TurfDemo(
        id: 'explode',
        name: 'explode',
        category: _category,
        icon: Icons.scatter_plot_rounded,
        description:
            'Takes a Feature or FeatureCollection and returns every vertex '
            'as an individual Point inside a FeatureCollection<Point>.',
        parameters: [
          TurfParameter(
            name: 'geojson',
            type: 'GeoJSONObject',
            required: true,
            description: 'Input geometry whose vertices will be exploded.',
          ),
        ],
      ),
      TurfDemo(
        id: 'polygon_to_line',
        name: 'polygonToLine',
        category: _category,
        icon: Icons.polyline_rounded,
        description:
            'Converts a Polygon to a LineString (or MultiLineString), and a '
            'MultiPolygon to a FeatureCollection of LineString / '
            'MultiLineString features.',
        parameters: [
          TurfParameter(
            name: 'poly',
            type: 'GeoJSONObject',
            required: true,
            description: 'Polygon or MultiPolygon to convert.',
          ),
          TurfParameter(
            name: 'properties',
            type: 'Map<String, dynamic>?',
            required: false,
            description:
                'Optional properties to attach to the resulting Feature(s). '
                'Defaults to the polygon properties when the input is a '
                'Feature.',
          ),
        ],
      ),
    ];
