import 'package:flutter/material.dart';

import 'turf_demo.dart';

const _category = 'Measurement';

List<TurfDemo> measurementDemos() => const [
      TurfDemo(
        id: 'distance',
        name: 'distance',
        category: _category,
        icon: Icons.straighten_rounded,
        description:
            'Calculates the distance between two Points in degrees, radians, '
            'miles, or kilometers. Uses the Haversine formula to account for '
            'global curvature.',
        parameters: [
          TurfParameter(
            name: 'from',
            type: 'Point',
            required: true,
            description: 'Origin point.',
          ),
          TurfParameter(
            name: 'to',
            type: 'Point',
            required: true,
            description: 'Destination point.',
          ),
          TurfParameter(
            name: 'unit',
            type: 'Unit',
            required: false,
            defaultValue: 'Unit.kilometers',
            description:
                'Unit in which the distance is returned (degrees, radians, '
                'miles, kilometers).',
          ),
        ],
      ),
      TurfDemo(
        id: 'bearing',
        name: 'bearing',
        category: _category,
        icon: Icons.explore_rounded,
        description:
            'Takes two Points and finds the geographic bearing between them, '
            'i.e. the angle measured in degrees from the north line '
            '(0 degrees).',
        parameters: [
          TurfParameter(
            name: 'start',
            type: 'Point',
            required: true,
            description: 'Starting point.',
          ),
          TurfParameter(
            name: 'end',
            type: 'Point',
            required: true,
            description: 'Ending point.',
          ),
          TurfParameter(
            name: 'calcFinal',
            type: 'bool',
            required: false,
            defaultValue: 'false',
            description:
                'When true, returns the final bearing (the heading observed at '
                'the end point) rather than the initial bearing.',
          ),
        ],
      ),
      TurfDemo(
        id: 'midpoint',
        name: 'midpoint',
        category: _category,
        icon: Icons.center_focus_strong_rounded,
        description:
            'Takes two Points and returns a point midway between them. The '
            'midpoint is calculated geodesically, meaning the curvature of '
            'the earth is taken into account.',
        parameters: [
          TurfParameter(
            name: 'point1',
            type: 'Point',
            required: true,
            description: 'First reference point.',
          ),
          TurfParameter(
            name: 'point2',
            type: 'Point',
            required: true,
            description: 'Second reference point.',
          ),
        ],
      ),
      TurfDemo(
        id: 'destination',
        name: 'destination',
        category: _category,
        icon: Icons.flag_rounded,
        description:
            'Takes a Point and calculates the location of a destination point '
            'given a distance in degrees, radians, miles, or kilometers; and '
            'a bearing in degrees. Uses the Haversine formula to account for '
            'global curvature.',
        parameters: [
          TurfParameter(
            name: 'origin',
            type: 'Point',
            required: true,
            description: 'Starting point.',
          ),
          TurfParameter(
            name: 'distance',
            type: 'num',
            required: true,
            description: 'Distance from the origin point.',
          ),
          TurfParameter(
            name: 'bearing',
            type: 'num',
            required: true,
            description:
                'Compass bearing in degrees clockwise from true north '
                '(-180 to 180).',
          ),
          TurfParameter(
            name: 'unit',
            type: 'Unit',
            required: false,
            defaultValue: 'Unit.kilometers',
            description: 'Unit in which the distance is expressed.',
          ),
        ],
      ),
      TurfDemo(
        id: 'length',
        name: 'length',
        category: _category,
        icon: Icons.timeline_rounded,
        description:
            'Takes a line and measures its total length in the specified '
            'unit by summing the geodesic distances of every consecutive '
            'segment.',
        parameters: [
          TurfParameter(
            name: 'line',
            type: 'Feature<LineString>',
            required: true,
            description: 'LineString feature whose length will be measured.',
          ),
          TurfParameter(
            name: 'unit',
            type: 'Unit',
            required: false,
            defaultValue: 'Unit.kilometers',
            description: 'Unit in which the length is returned.',
          ),
        ],
      ),
      TurfDemo(
        id: 'along',
        name: 'along',
        category: _category,
        icon: Icons.alt_route_rounded,
        description:
            'Takes a line and returns a Point at a specified distance along '
            'the line. Negative distances measure from the end of the line; '
            'distances larger than the line length return its end point.',
        parameters: [
          TurfParameter(
            name: 'line',
            type: 'Feature<LineString>',
            required: true,
            description: 'Input LineString feature.',
          ),
          TurfParameter(
            name: 'distance',
            type: 'num',
            required: true,
            description: 'Distance to travel along the line.',
          ),
          TurfParameter(
            name: 'unit',
            type: 'Unit',
            required: false,
            defaultValue: 'Unit.kilometers',
            description: 'Unit in which the distance is expressed.',
          ),
        ],
      ),
      TurfDemo(
        id: 'area',
        name: 'area',
        category: _category,
        icon: Icons.crop_square_rounded,
        description:
            'Takes a GeoJSONObject and returns its area in square meters. '
            'Works for Polygons, MultiPolygons, Features and '
            'FeatureCollections.',
        parameters: [
          TurfParameter(
            name: 'geojson',
            type: 'GeoJSONObject',
            required: true,
            description:
                'Input geometry whose total polygonal area will be summed.',
          ),
        ],
      ),
    ];
