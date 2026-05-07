import 'package:flutter/material.dart';

import 'turf_demo.dart';

const _category = 'Geometry';

List<TurfDemo> geometryDemos() => const [
      TurfDemo(
        id: 'bbox',
        name: 'bbox',
        category: _category,
        icon: Icons.crop_free_rounded,
        description:
            'Calculates the bounding box for any GeoJSON object, including '
            'FeatureCollection. If recompute is not set and the input bbox is '
            'not null, the function uses the bbox of the given GeoJSONObject.',
        parameters: [
          TurfParameter(
            name: 'geoJson',
            type: 'GeoJSONObject',
            required: true,
            description: 'Geometry to enclose.',
          ),
          TurfParameter(
            name: 'recompute',
            type: 'bool',
            required: false,
            defaultValue: 'false',
            description:
                'Force recomputation, ignoring any pre-existing bbox already '
                'attached to the input.',
          ),
        ],
      ),
      TurfDemo(
        id: 'bbox_polygon',
        name: 'bboxPolygon',
        category: _category,
        icon: Icons.square_outlined,
        description:
            'Takes a BBox and returns an equivalent Feature<Polygon> closed '
            'on its first vertex.',
        parameters: [
          TurfParameter(
            name: 'bbox',
            type: 'BBox',
            required: true,
            description: '2D bounding box [west, south, east, north].',
          ),
          TurfParameter(
            name: 'properties',
            type: 'Map<String, dynamic>',
            required: false,
            defaultValue: 'const {}',
            description: 'Optional properties to attach to the new Feature.',
          ),
          TurfParameter(
            name: 'id',
            type: 'dynamic',
            required: false,
            description: 'Optional Feature id.',
          ),
        ],
      ),
      TurfDemo(
        id: 'center',
        name: 'center',
        category: _category,
        icon: Icons.adjust_rounded,
        description:
            'Takes a Feature or a FeatureCollection and returns the absolute '
            'center point of all feature(s) — the midpoint of their bounding '
            'box.',
        parameters: [
          TurfParameter(
            name: 'geoJSON',
            type: 'GeoJSONObject',
            required: true,
            description: 'Input geometry whose center will be computed.',
          ),
          TurfParameter(
            name: 'id',
            type: 'dynamic',
            required: false,
            description: 'Optional Feature id for the returned point.',
          ),
          TurfParameter(
            name: 'bbox',
            type: 'BBox?',
            required: false,
            description:
                'Optional bbox to attach to the returned center Feature.',
          ),
          TurfParameter(
            name: 'properties',
            type: 'Map<String, dynamic>?',
            required: false,
            description:
                'Optional properties to attach to the returned center Feature.',
          ),
        ],
      ),
      TurfDemo(
        id: 'centroid',
        name: 'centroid',
        category: _category,
        icon: Icons.gps_fixed_rounded,
        description:
            'Takes a Feature or a FeatureCollection and computes the centroid '
            'as the mean of all vertices within the object.',
        parameters: [
          TurfParameter(
            name: 'geoJSON',
            type: 'GeoJSONObject',
            required: true,
            description: 'Input geometry whose vertex average is computed.',
          ),
          TurfParameter(
            name: 'properties',
            type: 'Map<String, dynamic>?',
            required: false,
            description:
                'Optional properties to attach to the returned centroid '
                'Feature.',
          ),
        ],
      ),
      TurfDemo(
        id: 'circle',
        name: 'circle',
        category: _category,
        icon: Icons.radio_button_unchecked_rounded,
        description:
            'Takes a Point or a Feature<Point> and approximates a geodesic '
            'circle polygon around it given a radius and number of steps.',
        parameters: [
          TurfParameter(
            name: 'center',
            type: 'GeoJSONObject',
            required: true,
            description: 'Center point (Point or Feature<Point>).',
          ),
          TurfParameter(
            name: 'radius',
            type: 'num',
            required: true,
            description: 'Radius of the circle in the chosen unit.',
          ),
          TurfParameter(
            name: 'steps',
            type: 'num?',
            required: false,
            defaultValue: '64',
            description:
                'Number of vertices used to approximate the circle. Higher '
                'values produce smoother circles.',
          ),
          TurfParameter(
            name: 'unit',
            type: 'Unit?',
            required: false,
            defaultValue: 'Unit.kilometers',
            description: 'Unit of the radius.',
          ),
          TurfParameter(
            name: 'properties',
            type: 'Map<String, dynamic>?',
            required: false,
            description:
                'Optional properties to attach to the returned polygon. '
                'Defaults to the center properties when the input is a '
                'Feature.',
          ),
        ],
      ),
      TurfDemo(
        id: 'square',
        name: 'square',
        category: _category,
        icon: Icons.crop_square_outlined,
        description:
            'Takes a BBox and returns a square BBox of equal dimensions, '
            'expanding the smaller dimension symmetrically.',
        parameters: [
          TurfParameter(
            name: 'bbox',
            type: 'BBox',
            required: true,
            description: '2D bounding box [west, south, east, north].',
          ),
        ],
      ),
    ];
