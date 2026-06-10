class TurfFunction {
  final String name;
  final String description;
  final List<TurfParam> params;
  final String returns;
  final String example;

  const TurfFunction({
    required this.name,
    required this.description,
    required this.params,
    required this.returns,
    required this.example,
  });
}

class TurfParam {
  final String name;
  final String type;
  final String description;
  final bool optional;

  const TurfParam({
    required this.name,
    required this.type,
    required this.description,
    this.optional = false,
  });
}

class TurfCategory {
  final String name;
  final String icon;
  final List<TurfFunction> functions;

  const TurfCategory({
    required this.name,
    required this.icon,
    required this.functions,
  });
}

const List<TurfCategory> apiCategories = [
  TurfCategory(
    name: 'Measurement',
    icon: '📐',
    functions: [
      TurfFunction(
        name: 'along',
        description:
            'Takes a LineString and returns a Point at a specified distance along the line.',
        params: [
          TurfParam(name: 'line', type: 'Feature<LineString>', description: 'Input line'),
          TurfParam(name: 'distance', type: 'num', description: 'Distance along the line'),
          TurfParam(name: 'unit', type: 'Unit', description: 'Units of distance', optional: true),
        ],
        returns: 'Feature<Point>',
        example: '''final line = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(0, 0),
    Position(10, 10),
  ]),
);
final pt = along(line, 5, Unit.kilometers);''',
      ),
      TurfFunction(
        name: 'area',
        description: 'Takes a GeoJSON object and returns its area in square meters.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Input GeoJSON'),
        ],
        returns: 'double',
        example: '''final polygon = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(0, 0), Position(10, 0),
    Position(10, 10), Position(0, 10),
    Position(0, 0),
  ]]),
);
final sqMeters = area(polygon);''',
      ),
      TurfFunction(
        name: 'bbox',
        description:
            'Takes a GeoJSON object and returns the bounding box as [minX, minY, maxX, maxY].',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Any GeoJSON object'),
        ],
        returns: 'BBox',
        example: '''final line = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(0, 0), Position(10, 10),
  ]),
);
final box = bbox(line);
// box = [0, 0, 10, 10]''',
      ),
      TurfFunction(
        name: 'bboxPolygon',
        description: 'Takes a bounding box and returns an equivalent Polygon.',
        params: [
          TurfParam(name: 'bbox', type: 'BBox', description: 'Bounding box extent as [minX, minY, maxX, maxY]'),
        ],
        returns: 'Feature<Polygon>',
        example: '''final box = BBox.named(
  lat1: 0, lng1: 0, lat2: 10, lng2: 10,
);
final poly = bboxPolygon(box);''',
      ),
      TurfFunction(
        name: 'bearing',
        description:
            'Takes two Points and finds the geographic bearing between them.',
        params: [
          TurfParam(name: 'start', type: 'Point', description: 'Starting point'),
          TurfParam(name: 'end', type: 'Point', description: 'Ending point'),
          TurfParam(name: 'final_', type: 'bool', description: 'Calculate final bearing', optional: true),
        ],
        returns: 'double',
        example: '''final start = Point(coordinates: Position(-75.343, 39.984));
final end = Point(coordinates: Position(-75.534, 39.123));
final angle = bearing(start, end);
// angle ≈ -170.2''',
      ),
      TurfFunction(
        name: 'center',
        description:
            'Takes a Feature or FeatureCollection and returns the absolute center point.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'GeoJSON to be centered'),
        ],
        returns: 'Feature<Point>',
        example: '''final fc = FeatureCollection(features: [
  Feature(geometry: Point(coordinates: Position(0, 0))),
  Feature(geometry: Point(coordinates: Position(10, 10))),
]);
final c = center(fc);''',
      ),
      TurfFunction(
        name: 'centroid',
        description:
            'Takes a Feature or FeatureCollection and computes the centroid as the mean of all vertices.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'GeoJSON to be centered'),
        ],
        returns: 'Feature<Point>',
        example: '''final polygon = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(0, 0), Position(10, 0),
    Position(10, 10), Position(0, 10),
    Position(0, 0),
  ]]),
);
final c = centroid(polygon);''',
      ),
      TurfFunction(
        name: 'centerOfMass',
        description:
            'Takes a Feature or FeatureCollection and returns the center of mass as a Point, using the weighted centroid of all vertices.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'GeoJSON to measure'),
          TurfParam(name: 'properties', type: 'Map?', description: 'Properties to attach to the result', optional: true),
        ],
        returns: 'Feature<Point>',
        example: '''final polygon = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(0, 0), Position(10, 0),
    Position(10, 10), Position(0, 10),
    Position(0, 0),
  ]]),
);
final com = centerOfMass(polygon);
// roughly Position(5.0, 5.0)''',
      ),
      TurfFunction(
        name: 'destination',
        description:
            'Calculates the destination point given a distance and bearing from an origin point.',
        params: [
          TurfParam(name: 'origin', type: 'Point', description: 'Starting point'),
          TurfParam(name: 'distance', type: 'num', description: 'Distance from origin'),
          TurfParam(name: 'bearing', type: 'num', description: 'Bearing in degrees'),
          TurfParam(name: 'unit', type: 'Unit', description: 'Unit of distance', optional: true),
        ],
        returns: 'Point',
        example: '''final origin = Point(coordinates: Position(-75.343, 39.984));
final dest = destination(origin, 50, 90, Unit.miles);''',
      ),
      TurfFunction(
        name: 'distance',
        description:
            'Calculates the distance between two Points using the Haversine formula.',
        params: [
          TurfParam(name: 'from', type: 'Point', description: 'Origin point'),
          TurfParam(name: 'to', type: 'Point', description: 'Destination point'),
          TurfParam(name: 'unit', type: 'Unit', description: 'Unit of distance', optional: true),
        ],
        returns: 'double',
        example: '''final from = Point(coordinates: Position(-75.343, 39.984));
final to = Point(coordinates: Position(-75.534, 39.123));
final d = distance(from, to, Unit.miles);
// d ≈ 60.37''',
      ),
      TurfFunction(
        name: 'envelope',
        description:
            'Takes any GeoJSON object and returns a rectangular Polygon that represents the smallest bounding box that contains the entire feature.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Any GeoJSON object'),
        ],
        returns: 'Feature<Polygon>',
        example: '''final points = FeatureCollection<Point>(
        features: [
          Feature(geometry: Point(coordinates: Position(2.35, 48.85))),
          Feature(geometry: Point(coordinates: Position(13.40, 52.52))),
          Feature(geometry: Point(coordinates: Position(-3.70, 40.41))),
        ],
      );
      final box = envelope(points);
      // returns a rectangle that fits all three points''',
      ),
      TurfFunction(
        name: 'flatten',
        description:
            'Takes any GeoJSON object and returns a FeatureCollection of simple single-geometry features. Multi geometries like MultiPolygon or MultiLineString are split into their individual parts.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Any GeoJSON object including Multi geometries'),
        ],
        returns: 'FeatureCollection<GeometryObject>',
        example: '''final multiPolygon = Feature<MultiPolygon>(
        geometry: MultiPolygon(coordinates: [...]),
      );
      final result = flatten(multiPolygon);
      // returns FeatureCollection with 3 individual Polygon features''',
      ),
      TurfFunction(
        name: 'length',
        description: 'Takes a GeoJSON LineString and measures its total length.',
        params: [
          TurfParam(name: 'geojson', type: 'Feature<LineString>', description: 'Line to measure'),
          TurfParam(name: 'unit', type: 'Unit', description: 'Unit of length', optional: true),
        ],
        returns: 'double',
        example: '''final line = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(115, -32), Position(131, -22), Position(143, -25),
  ]),
);
final l = length(line, Unit.miles);''',
      ),
      TurfFunction(
        name: 'midpoint',
        description: 'Takes two Points and returns the midpoint between them.',
        params: [
          TurfParam(name: 'point1', type: 'Point', description: 'First point'),
          TurfParam(name: 'point2', type: 'Point', description: 'Second point'),
        ],
        returns: 'Feature<Point>',
        example: '''final p1 = Point(coordinates: Position(144.834823, -37.771257));
final p2 = Point(coordinates: Position(145.14244, -37.830937));
final mid = midpoint(p1, p2);''',
      ),
      TurfFunction(
        name: 'nearestPoint',
        description:
            'Takes a reference Point and a FeatureCollection of Points and returns the nearest point.',
        params: [
          TurfParam(name: 'targetPoint', type: 'Feature<Point>', description: 'Reference point'),
          TurfParam(name: 'points', type: 'FeatureCollection<Point>', description: 'FeatureCollection of points'),
        ],
        returns: 'Feature<Point>',
        example: '''final target = Feature(geometry: Point(coordinates: Position(28.965, 41.01)));
final pts = FeatureCollection(features: [
  Feature(geometry: Point(coordinates: Position(28.973, 41.01))),
  Feature(geometry: Point(coordinates: Position(28.955, 41.01))),
]);
final nearest = nearestPoint(target, pts);''',
      ),
      TurfFunction(
        name: 'nearestPointOnLine',
        description: 'Takes a Point and a LineString and returns the closest point on the line.',
        params: [
          TurfParam(name: 'lines', type: 'Feature<LineString>', description: 'Line to snap to'),
          TurfParam(name: 'inPt', type: 'Feature<Point>', description: 'Point to snap from'),
          TurfParam(name: 'unit', type: 'Unit', description: 'Unit of distance', optional: true),
        ],
        returns: 'Feature<Point>',
        example: '''final line = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(-77.031669, 38.878605),
    Position(-77.029609, 38.881946),
  ]),
);
final pt = Feature(geometry: Point(coordinates: Position(-77.037076, 38.884017)));
final snapped = nearestPointOnLine(line, pt);''',
      ),
      TurfFunction(
        name: 'pointOnFeature',
        description:
            'Takes a Feature or FeatureCollection and returns a Point guaranteed to be on the surface of the feature — unlike center or centroid, which can fall outside concave shapes.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Any GeoJSON feature'),
        ],
        returns: 'Feature<Point>',
        example: '''final polygon = Feature<Polygon>(
        geometry: Polygon(coordinates: [[
          Position(0, 0), Position(10, 0),
          Position(10, 10), Position(0, 10),
          Position(0, 0),
        ]]),
      );
      final pt = pointOnFeature(polygon);
      // guaranteed to lie on the polygon surface''',
      ),
      TurfFunction(
        name: 'pointToLineDistance',
        description: 'Returns the minimum distance between a Point and a LineString.',
        params: [
          TurfParam(name: 'pt', type: 'Feature<Point>', description: 'Input point'),
          TurfParam(name: 'line', type: 'Feature<LineString>', description: 'Input line'),
          TurfParam(name: 'unit', type: 'Unit', description: 'Unit of distance', optional: true),
        ],
        returns: 'double',
        example: '''final pt = Feature(geometry: Point(coordinates: Position(0, 0)));
final line = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(1, 1), Position(1, 2), Position(1, 3),
  ]),
);
final d = pointToLineDistance(pt, line, Unit.kilometers);''',
      ),
            TurfFunction(
        name: 'randomLineString',
        description:
            'Generates a FeatureCollection of random LineStrings within a given bounding box. Useful for testing and prototyping spatial algorithms.',
        params: [
          TurfParam(name: 'count', type: 'int', description: 'Number of LineStrings to generate'),
          TurfParam(name: 'bbox', type: 'BBox?', description: 'Bounding box to generate within', optional: true),
          TurfParam(name: 'numVertices', type: 'int', description: 'Number of vertices per line (default 10)', optional: true),
          TurfParam(name: 'maxLength', type: 'double', description: 'Max decimal degrees a vertex can move from its predecessor', optional: true),
          TurfParam(name: 'maxRotation', type: 'double', description: 'Max radians a segment can turn from the previous segment', optional: true),
        ],
        returns: 'FeatureCollection<LineString>',
        example: '''final lines = randomLineString(
        3,
        bbox: BBox.named(lat1: 35.0, lng1: -10.0, lat2: 60.0, lng2: 30.0),
        numVertices: 8,
        maxLength: 1.5,
      );''',
      ),
      TurfFunction(
        name: 'rhumbBearing',
        description: 'Finds the bearing angle between two Points along a rhumb line.',
        params: [
          TurfParam(name: 'start', type: 'Feature<Point>', description: 'Starting point'),
          TurfParam(name: 'end', type: 'Feature<Point>', description: 'Ending point'),
          TurfParam(name: 'final_', type: 'bool', description: 'Calculate final bearing', optional: true),
        ],
        returns: 'double',
        example: '''final start = Feature(geometry: Point(coordinates: Position(-75.343, 39.984)));
final end = Feature(geometry: Point(coordinates: Position(-75.534, 39.123)));
final b = rhumbBearing(start, end);''',
      ),
      TurfFunction(
        name: 'rhumbDestination',
        description: 'Returns the destination Point traveling along a rhumb line.',
        params: [
          TurfParam(name: 'origin', type: 'Feature<Point>', description: 'Starting point'),
          TurfParam(name: 'distance', type: 'num', description: 'Distance from origin'),
          TurfParam(name: 'bearing', type: 'num', description: 'Bearing in degrees'),
          TurfParam(name: 'unit', type: 'Unit', description: 'Unit of distance', optional: true),
        ],
        returns: 'Feature<Point>',
        example: '''final pt = Feature(geometry: Point(coordinates: Position(-75.343, 39.984)));
final dest = rhumbDestination(pt, 50, 90, unit: Unit.miles);''',
      ),
      TurfFunction(
        name: 'rhumbDistance',
        description: 'Calculates the distance along a rhumb line between two Points.',
        params: [
          TurfParam(name: 'from', type: 'Feature<Point>', description: 'Origin point'),
          TurfParam(name: 'to', type: 'Feature<Point>', description: 'Destination point'),
          TurfParam(name: 'unit', type: 'Unit', description: 'Unit of distance', optional: true),
        ],
        returns: 'double',
        example: '''final from = Feature(geometry: Point(coordinates: Position(-75.343, 39.984)));
final to = Feature(geometry: Point(coordinates: Position(-75.534, 39.123)));
final d = rhumbDistance(from, to, Unit.miles);''',
      ),
      TurfFunction(
        name: 'square',
        description: 'Takes a bounding box and calculates the minimum square bounding box.',
        params: [
          TurfParam(name: 'bbox', type: 'BBox', description: 'Bounding box extent'),
        ],
        returns: 'BBox',
        example: '''final bbox = BBox.named(lat1: 0, lng1: 0, lat2: 5, lng2: 10);
final sq = square(bbox);
// sq = [-2.5, 0, 7.5, 10]''',
      ),
    ],
  ),
  TurfCategory(
    name: 'Coordinate Mutation',
    icon: '🔄',
    functions: [
      TurfFunction(
        name: 'cleanCoords',
        description:
            'Removes redundant coordinates from any GeoJSON Geometry.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Input GeoJSON'),
          TurfParam(name: 'mutate', type: 'bool', description: 'Mutate input rather than clone', optional: true),
        ],
        returns: 'GeoJSONObject',
        example: '''final line = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(0, 0), Position(0, 2),
    Position(0, 5), Position(0, 8),  // redundant
    Position(0, 8), Position(10, 8),
  ]),
);
final cleaned = cleanCoords(line);''',
      ),
      TurfFunction(
        name: 'flip',
        description: 'Takes input features and flips all their coordinates (lat ↔ lng).',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Input GeoJSON'),
          TurfParam(name: 'mutate', type: 'bool', description: 'Mutate input rather than clone', optional: true),
        ],
        returns: 'GeoJSONObject',
        example: '''final pt = Feature(
  geometry: Point(coordinates: Position(36.0, -94.0)),
);
final flipped = flip(pt);
// coordinates = Position(-94.0, 36.0)''',
      ),
      TurfFunction(
        name: 'truncate',
        description:
            'Takes a GeoJSON Feature and truncates the precision of its coordinates.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Input GeoJSON'),
          TurfParam(name: 'precision', type: 'int', description: 'Decimal degrees of precision', optional: true),
          TurfParam(name: 'coordinates', type: 'int', description: 'Maximum coordinate dimensions', optional: true),
          TurfParam(name: 'mutate', type: 'bool', description: 'Mutate input rather than clone', optional: true),
        ],
        returns: 'GeoJSONObject',
        example: '''final pt = Feature(
  geometry: Point(coordinates: Position(70.123456789, 40.123456789)),
);
final truncated = truncate(pt, precision: 3);
// coordinates = Position(70.123, 40.123)''',
      ),
    ],
  ),
  TurfCategory(
    name: 'Transformation',
    icon: '🔀',
    functions: [
      TurfFunction(
        name: 'geoToMercator',
        description:
            'Converts a WGS84 GeoJSON object into Web Mercator (EPSG:3857) projection.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Input GeoJSON with WGS84 coordinates'),
          TurfParam(name: 'mutate', type: 'bool', description: 'Mutate input rather than clone', optional: true),
        ],
        returns: 'GeoJSONObject',
        example: '''final pt = Feature(
  geometry: Point(coordinates: Position(-71.0, 41.0)),
);
final mercator = geoToMercator(pt);
// x ≈ -7903683.85, y ≈ 5012341.66''',
      ),
      TurfFunction(
        name: 'geoToWgs84',
        description:
            'Converts a Web Mercator (EPSG:3857) GeoJSON object back into WGS84 coordinates.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Input GeoJSON with Mercator coordinates'),
          TurfParam(name: 'mutate', type: 'bool', description: 'Mutate input rather than clone', optional: true),
        ],
        returns: 'GeoJSONObject',
        example: '''final pt = Feature(
  geometry: Point(coordinates: Position(-7903683.85, 5012341.66)),
);
final wgs84 = geoToWgs84(pt);
// lng ≈ -71.0, lat ≈ 41.0''',
      ),
      TurfFunction(
        name: 'polygonSmooth',
        description: 'Smooths a Polygon or MultiPolygon using the Chaikin algorithm.',
        params: [
          TurfParam(name: 'inputPolygon', type: 'GeoJSONObject', description: 'Input polygon'),
          TurfParam(name: 'iterations', type: 'int', description: 'Number of smoothing iterations', optional: true),
        ],
        returns: 'FeatureCollection',
        example: '''final polygon = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(11, 0), Position(22, 4),
    Position(31, 0), Position(31, 11),
    Position(21, 15), Position(11, 11),
    Position(11, 0),
  ]]),
);
final smoothed = polygonSmooth(polygon, iterations: 3);''',
      ),
      TurfFunction(
        name: 'transformRotate',
        description:
            'Rotates any GeoJSON Feature or FeatureCollection by a given angle around a pivot point.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Input GeoJSON'),
          TurfParam(name: 'angle', type: 'num', description: 'Rotation angle in degrees (CW)'),
          TurfParam(name: 'pivot', type: 'Feature<Point>', description: 'Pivot point (default: centroid)', optional: true),
          TurfParam(name: 'mutate', type: 'bool', description: 'Mutate input rather than clone', optional: true),
        ],
        returns: 'GeoJSONObject',
        example: '''final poly = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(0, 29), Position(3.5, 29),
    Position(2.5, 32), Position(0, 29),
  ]]),
);
final rotated = transformRotate(poly, 100);''',
      ),
      TurfFunction(
        name: 'lineToPolygon',
        description:
            'Converts LineStrings and MultiLineStrings to Polygon or MultiPolygon.',
        params: [
          TurfParam(name: 'lines', type: 'GeoJSONObject', description: 'Input LineString or MultiLineString'),
          TurfParam(name: 'autoComplete', type: 'bool', description: 'Auto-complete open line strings', optional: true),
          TurfParam(name: 'orderCoords', type: 'bool', description: 'Sort line strings to place outer ring first', optional: true),
        ],
        returns: 'Feature<Polygon>',
        example: '''final line = LineString(coordinates: [
  Position(125, -30), Position(145, -30),
  Position(145, -20), Position(125, -20),
  Position(125, -30),
]);
final polygon = lineToPolygon(line);''',
      ),
      TurfFunction(
        name: 'polygonToLine',
        description: 'Converts a Polygon or MultiPolygon to a LineString or MultiLineString.',
        params: [
          TurfParam(name: 'polygon', type: 'GeoJSONObject', description: 'Input Polygon or MultiPolygon'),
        ],
        returns: 'GeoJSONObject',
        example: '''final poly = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(125, -30), Position(145, -30),
    Position(145, -20), Position(125, -20),
    Position(125, -30),
  ]]),
);
final line = polygonToLine(poly);''',
      ),
    ],
  ),
  TurfCategory(
    name: 'Feature Conversion',
    icon: '🔁',
    functions: [
      TurfFunction(
        name: 'explode',
        description:
            'Takes a feature or set of features and returns all positions as Points.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Input GeoJSON'),
        ],
        returns: 'FeatureCollection<Point>',
        example: '''final polygon = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(0, 0), Position(10, 0),
    Position(10, 10), Position(0, 10),
    Position(0, 0),
  ]]),
);
final points = explode(polygon);
// 5 point features''',
      ),
    ],
  ),
  TurfCategory(
    name: 'Misc',
    icon: '🛠',
    functions: [
      TurfFunction(
        name: 'lineIntersect',
        description: 'Takes any LineString or Polygon and returns the intersecting points.',
        params: [
          TurfParam(name: 'line1', type: 'GeoJSONObject', description: 'First line'),
          TurfParam(name: 'line2', type: 'GeoJSONObject', description: 'Second line'),
        ],
        returns: 'FeatureCollection<Point>',
        example: '''final l1 = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(-122.431, 37.773), Position(-122.431, 37.777),
  ]),
);
final l2 = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(-122.434, 37.775), Position(-122.428, 37.775),
  ]),
);
final intersects = lineIntersect(l1, l2);''',
      ),
      TurfFunction(
        name: 'lineOverlap',
        description: 'Takes any LineString or Polygon and returns the overlapping lines.',
        params: [
          TurfParam(name: 'line1', type: 'GeoJSONObject', description: 'First line or polygon'),
          TurfParam(name: 'line2', type: 'GeoJSONObject', description: 'Second line or polygon'),
          TurfParam(name: 'tolerance', type: 'double', description: 'Tolerance distance in degrees', optional: true),
        ],
        returns: 'FeatureCollection<LineString>',
        example: '''final l1 = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(115, 0), Position(125, 0), Position(125, 5),
  ]),
);
final l2 = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(120, 0), Position(130, 0),
  ]),
);
final overlapping = lineOverlap(l1, l2);''',
      ),
      TurfFunction(
        name: 'lineSlice',
        description:
            'Takes a LineString, a start Point, and a stop Point and returns the line between those points.',
        params: [
          TurfParam(name: 'startPt', type: 'Feature<Point>', description: 'Start point'),
          TurfParam(name: 'stopPt', type: 'Feature<Point>', description: 'Stop point'),
          TurfParam(name: 'line', type: 'Feature<LineString>', description: 'Line to slice'),
        ],
        returns: 'Feature<LineString>',
        example: '''final start = Feature(geometry: Point(coordinates: Position(-77.029609, 38.881946)));
final stop = Feature(geometry: Point(coordinates: Position(-77.021129, 38.865938)));
final line = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(-77.031669, 38.878605),
    Position(-77.029609, 38.881946),
    Position(-77.021129, 38.865938),
  ]),
);
final sliced = lineSlice(start, stop, line);''',
      ),
      TurfFunction(
        name: 'lineSliceAlong',
        description:
            'Takes a LineString and returns a subsection between the specified distances.',
        params: [
          TurfParam(name: 'line', type: 'Feature<LineString>', description: 'Input line'),
          TurfParam(name: 'startDist', type: 'num', description: 'Start distance along line'),
          TurfParam(name: 'stopDist', type: 'num', description: 'Stop distance along line'),
          TurfParam(name: 'unit', type: 'Unit', description: 'Unit of distance', optional: true),
        ],
        returns: 'Feature<LineString>',
        example: '''final line = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(115, -32), Position(131, -22), Position(143, -25),
  ]),
);
final sliced = lineSliceAlong(line, 100, 750, Unit.miles);''',
      ),
      TurfFunction(
        name: 'lineSegment',
        description: 'Creates a FeatureCollection of 2-vertex LineString segments from a LineString or Polygon.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Input GeoJSON'),
        ],
        returns: 'FeatureCollection<LineString>',
        example: '''final polygon = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(0, 0), Position(10, 0),
    Position(10, 10), Position(0, 10), Position(0, 0),
  ]]),
);
final segments = lineSegment(polygon);
// 4 two-vertex line segments''',
      ),
    ],
  ),
  TurfCategory(
    name: 'Boolean',
    icon: '✅',
    functions: [
      TurfFunction(
        name: 'booleanClockwise',
        description: 'Returns true if the ring is clockwise, false if counter-clockwise.',
        params: [
          TurfParam(name: 'line', type: 'Feature<LineString>', description: 'LineString to evaluate'),
        ],
        returns: 'bool',
        example: '''final cw = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(0, 0), Position(1, 1), Position(1, 0), Position(0, 0),
  ]),
);
final isClockwise = booleanClockwise(cw); // true''',
      ),
      TurfFunction(
        name: 'booleanConcave',
        description: 'Returns true if a Polygon is concave, false if convex.',
        params: [
          TurfParam(name: 'polygon', type: 'Feature<Polygon>', description: 'Polygon to evaluate'),
        ],
        returns: 'bool',
        example: '''final polygon = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(0, 0), Position(0, 1),
    Position(0.5, 0.5), Position(1, 1),
    Position(1, 0), Position(0, 0),
  ]]),
);
final concave = booleanConcave(polygon); // true''',
      ),
      TurfFunction(
        name: 'booleanContains',
        description:
            'Returns true if the first geometry completely contains the second.',
        params: [
          TurfParam(name: 'feature1', type: 'GeoJSONObject', description: 'GeoJSON Feature to be compared'),
          TurfParam(name: 'feature2', type: 'GeoJSONObject', description: 'GeoJSON Feature to be compared'),
        ],
        returns: 'bool',
        example: '''final polygon = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(0, 0), Position(0, 10),
    Position(10, 10), Position(10, 0), Position(0, 0),
  ]]),
);
final point = Feature(geometry: Point(coordinates: Position(5, 5)));
final contains = booleanContains(polygon, point); // true''',
      ),
      TurfFunction(
        name: 'booleanCrosses',
        description: 'Returns true if the intersection of two geometries results in a lower-dimension geometry.',
        params: [
          TurfParam(name: 'feature1', type: 'GeoJSONObject', description: 'GeoJSON Feature'),
          TurfParam(name: 'feature2', type: 'GeoJSONObject', description: 'GeoJSON Feature'),
        ],
        returns: 'bool',
        example: '''final line = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(2, 2), Position(4, 4),
  ]),
);
final polygon = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(1, 3), Position(3, 3),
    Position(3, 5), Position(1, 5), Position(1, 3),
  ]]),
);
final crosses = booleanCrosses(line, polygon); // true''',
      ),
      TurfFunction(
        name: 'booleanDisjoint',
        description: 'Returns true if the geometries do not share any space.',
        params: [
          TurfParam(name: 'feature1', type: 'GeoJSONObject', description: 'GeoJSON Feature'),
          TurfParam(name: 'feature2', type: 'GeoJSONObject', description: 'GeoJSON Feature'),
        ],
        returns: 'bool',
        example: '''final point = Feature(geometry: Point(coordinates: Position(2, 2)));
final line = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(1, 1), Position(1, 2), Position(1, 3), Position(1, 4),
  ]),
);
final disjoint = booleanDisjoint(point, line); // true''',
      ),
      TurfFunction(
        name: 'booleanEqual',
        description: 'Determines whether two geometries are exactly equal.',
        params: [
          TurfParam(name: 'feature1', type: 'GeoJSONObject', description: 'GeoJSON Feature'),
          TurfParam(name: 'feature2', type: 'GeoJSONObject', description: 'GeoJSON Feature'),
        ],
        returns: 'bool',
        example: '''final pt1 = Feature(geometry: Point(coordinates: Position(0, 0)));
final pt2 = Feature(geometry: Point(coordinates: Position(0, 0)));
final equal = booleanEqual(pt1, pt2); // true''',
      ),
      TurfFunction(
        name: 'booleanOverlap',
        description: 'Returns true if the features share some but not all points.',
        params: [
          TurfParam(name: 'feature1', type: 'GeoJSONObject', description: 'GeoJSON Feature'),
          TurfParam(name: 'feature2', type: 'GeoJSONObject', description: 'GeoJSON Feature'),
        ],
        returns: 'bool',
        example: '''final poly1 = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(0, 0), Position(0, 5), Position(5, 5),
    Position(5, 0), Position(0, 0),
  ]]),
);
final poly2 = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(1, 1), Position(1, 6), Position(6, 6),
    Position(6, 1), Position(1, 1),
  ]]),
);
final overlaps = booleanOverlap(poly1, poly2); // true''',
      ),
      TurfFunction(
        name: 'booleanParallel',
        description: 'Returns true if two LineStrings are parallel.',
        params: [
          TurfParam(name: 'line1', type: 'Feature<LineString>', description: 'First line'),
          TurfParam(name: 'line2', type: 'Feature<LineString>', description: 'Second line'),
        ],
        returns: 'bool',
        example: '''final l1 = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(0, 0), Position(0, 1),
  ]),
);
final l2 = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(1, 0), Position(1, 1),
  ]),
);
final parallel = booleanParallel(l1, l2); // true''',
      ),
      TurfFunction(
        name: 'booleanPointInPolygon',
        description: 'Returns true if a Point is inside a Polygon or MultiPolygon.',
        params: [
          TurfParam(name: 'point', type: 'Feature<Point>', description: 'Point to check'),
          TurfParam(name: 'polygon', type: 'GeoJSONObject', description: 'Polygon or MultiPolygon'),
          TurfParam(name: 'ignoreBoundary', type: 'bool', description: 'Ignore boundary edges', optional: true),
        ],
        returns: 'bool',
        example: '''final pt = Feature(geometry: Point(coordinates: Position(-77.0, 44.0)));
final poly = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(-81, 41), Position(-81, 47),
    Position(-72, 47), Position(-72, 41),
    Position(-81, 41),
  ]]),
);
final inPoly = booleanPointInPolygon(pt, poly); // true''',
      ),
      TurfFunction(
        name: 'booleanPointOnLine',
        description: 'Returns true if a Point is on a LineString.',
        params: [
          TurfParam(name: 'pt', type: 'Feature<Point>', description: 'Point to check'),
          TurfParam(name: 'line', type: 'Feature<LineString>', description: 'LineString to check against'),
          TurfParam(name: 'ignoreEndVertices', type: 'bool', description: 'Ignore start and end vertices', optional: true),
        ],
        returns: 'bool',
        example: '''final pt = Feature(geometry: Point(coordinates: Position(-77.0183, 38.8955)));
final line = Feature<LineString>(
  geometry: LineString(coordinates: [
    Position(-77.031669, 38.878605),
    Position(-77.029609, 38.881946),
  ]),
);
final onLine = booleanPointOnLine(pt, line);''',
      ),
      TurfFunction(
        name: 'booleanWithin',
        description: 'Returns true if the first geometry is completely within the second.',
        params: [
          TurfParam(name: 'feature1', type: 'GeoJSONObject', description: 'GeoJSON Feature'),
          TurfParam(name: 'feature2', type: 'GeoJSONObject', description: 'GeoJSON Feature'),
        ],
        returns: 'bool',
        example: '''final point = Feature(geometry: Point(coordinates: Position(5, 5)));
final polygon = Feature<Polygon>(
  geometry: Polygon(coordinates: [[
    Position(0, 0), Position(0, 10),
    Position(10, 10), Position(10, 0), Position(0, 0),
  ]]),
);
final within = booleanWithin(point, polygon); // true''',
      ),
    ],
  ),
  TurfCategory(
    name: 'Meta',
    icon: '🔬',
    functions: [
      TurfFunction(
        name: 'coordAll',
        description: 'Returns all coordinates from any GeoJSON object as a list of Positions.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Any GeoJSON object'),
        ],
        returns: 'List<Position>',
        example: '''final fc = FeatureCollection(features: [
  Feature(geometry: Point(coordinates: Position(26, 37))),
  Feature(geometry: Point(coordinates: Position(36, 53))),
]);
final coords = coordAll(fc);
// [Position(26, 37), Position(36, 53)]''',
      ),
      TurfFunction(
        name: 'coordEach',
        description: 'Iterates over coordinates in any GeoJSON object, calling callback on each.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Any GeoJSON object'),
          TurfParam(name: 'callback', type: 'CoordEachCallback', description: 'Called for each coordinate'),
          TurfParam(name: 'excludeWrapCoord', type: 'bool', description: 'Exclude closing coordinate of Polygons', optional: true),
        ],
        returns: 'void',
        example: '''coordEach(featureCollection, (
  coord, coordIndex, featureIndex,
  multiFeatureIndex, geometryIndex,
) {
  print(coord);
});''',
      ),
      TurfFunction(
        name: 'featureEach',
        description: 'Iterates over features in any GeoJSON object, calling callback on each.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Any GeoJSON object'),
          TurfParam(name: 'callback', type: 'FeatureEachCallback', description: 'Called for each feature'),
        ],
        returns: 'void',
        example: '''featureEach(featureCollection, (feature, index) {
  print(feature.geometry);
});''',
      ),
      TurfFunction(
        name: 'geomEach',
        description: 'Iterates over geometry objects in any GeoJSON, calling callback on each.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Any GeoJSON object'),
          TurfParam(name: 'callback', type: 'GeomEachCallback', description: 'Called for each geometry'),
        ],
        returns: 'void',
        example: '''geomEach(featureCollection, (
  geometry, featureIndex,
  properties, bbox, id,
) {
  print(geometry?.type);
});''',
      ),
      TurfFunction(
        name: 'flattenEach',
        description:
            'Iterates over flattened features in any GeoJSON, calling callback on each.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Any GeoJSON object'),
          TurfParam(name: 'callback', type: 'FlattenEachCallback', description: 'Called for each flattened feature'),
        ],
        returns: 'void',
        example: '''flattenEach(featureCollection, (feature, featureIndex, multiFeatureIndex) {
  print(feature.geometry);
});''',
      ),
      TurfFunction(
        name: 'segmentEach',
        description:
            'Iterates over 2-vertex line segments in any GeoJSON, calling callback on each.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Any GeoJSON object'),
          TurfParam(name: 'callback', type: 'SegmentEachCallback', description: 'Called for each segment'),
          TurfParam(name: 'combineNestedGeometries', type: 'bool', description: 'Combine nested geometries', optional: true),
        ],
        returns: 'void',
        example: '''var total = 0;
segmentEach(polygon, (
  segment, featureIndex,
  multiFeatureIndex, geometryIndex, segmentIndex,
) {
  total++;
});
// total == number of segments''',
      ),
      TurfFunction(
        name: 'segmentReduce',
        description: 'Reduces 2-vertex line segments in any GeoJSON, similar to Iterable.reduce.',
        params: [
          TurfParam(name: 'geojson', type: 'GeoJSONObject', description: 'Any GeoJSON object'),
          TurfParam(name: 'callback', type: 'SegmentReduceCallback', description: 'Reduce callback'),
          TurfParam(name: 'initialValue', type: 'T?', description: 'Initial value for reduction', optional: true),
        ],
        returns: 'T?',
        example: '''final total = segmentReduce<int>(polygon,
  (prev, segment, initial, fi, mfi, gi, si) {
    return (prev ?? 0) + 1;
  },
  0,
);''',
      ),
      TurfFunction(
        name: 'clusterEach',
        description: 'Iterates over clusters in a FeatureCollection by a property value.',
        params: [
          TurfParam(name: 'geojson', type: 'FeatureCollection', description: 'FeatureCollection'),
          TurfParam(name: 'property', type: 'dynamic', description: 'Property name/value to cluster by'),
          TurfParam(name: 'callback', type: 'ClusterEachCallback', description: 'Called for each cluster'),
        ],
        returns: 'void',
        example: '''clusterEach(fc, 'cluster', (cluster, value, index) {
  print('Cluster \$value: \${cluster?.features.length} features');
});''',
      ),
    ],
  ),
];