import '../math/vector3.dart';
import 'shape.dart';

/// A 3D text shape made of line segments.
///
/// Each character is rendered as a series of line segments that are
/// extruded into 3D space. The text is centered horizontally.
class Text3D extends Shape {
  /// The text string to render.
  final String text;

  /// Width of each character in world units.
  final double charWidth;

  /// Height of each character in world units.
  final double charHeight;

  /// Depth of the 3D extrusion.
  final double charDepth;

  /// Spacing between characters.
  final double spacing;

  Text3D(
    this.text, {
    this.charWidth = 0.6,
    this.charHeight = 1.0,
    this.charDepth = 0.2,
    this.spacing = 0.15,
  });

  /// Character definitions as line segments [(x1,y1), (x2,y2)].
  /// Coordinates: (0,0) is bottom-left, (1,1) is top-right.
  static const Map<String, List<((double, double), (double, double))>> _font = {
    'A': [
      ((0, 0), (0.5, 1)),
      ((0.5, 1), (1, 0)),
      ((0.2, 0.4), (0.8, 0.4)),
    ],
    'B': [
      ((0, 0), (0, 1)),
      ((0, 1), (0.7, 1)),
      ((0.7, 1), (0.8, 0.9)),
      ((0.8, 0.9), (0.8, 0.6)),
      ((0.8, 0.6), (0.7, 0.5)),
      ((0.7, 0.5), (0, 0.5)),
      ((0.7, 0.5), (0.8, 0.4)),
      ((0.8, 0.4), (0.8, 0.1)),
      ((0.8, 0.1), (0.7, 0)),
      ((0.7, 0), (0, 0)),
    ],
    'C': [
      ((1, 0.2), (0.8, 0)),
      ((0.8, 0), (0.2, 0)),
      ((0.2, 0), (0, 0.2)),
      ((0, 0.2), (0, 0.8)),
      ((0, 0.8), (0.2, 1)),
      ((0.2, 1), (0.8, 1)),
      ((0.8, 1), (1, 0.8)),
    ],
    'D': [
      ((0, 0), (0, 1)),
      ((0, 1), (0.6, 1)),
      ((0.6, 1), (0.9, 0.8)),
      ((0.9, 0.8), (0.9, 0.2)),
      ((0.9, 0.2), (0.6, 0)),
      ((0.6, 0), (0, 0)),
    ],
    'E': [
      ((1, 0), (0, 0)),
      ((0, 0), (0, 1)),
      ((0, 1), (1, 1)),
      ((0, 0.5), (0.7, 0.5)),
    ],
    'F': [
      ((0, 0), (0, 1)),
      ((0, 1), (1, 1)),
      ((0, 0.5), (0.7, 0.5)),
    ],
    'G': [
      ((1, 0.8), (0.8, 1)),
      ((0.8, 1), (0.2, 1)),
      ((0.2, 1), (0, 0.8)),
      ((0, 0.8), (0, 0.2)),
      ((0, 0.2), (0.2, 0)),
      ((0.2, 0), (0.8, 0)),
      ((0.8, 0), (1, 0.2)),
      ((1, 0.2), (1, 0.5)),
      ((1, 0.5), (0.5, 0.5)),
    ],
    'H': [
      ((0, 0), (0, 1)),
      ((1, 0), (1, 1)),
      ((0, 0.5), (1, 0.5)),
    ],
    'I': [
      ((0.3, 0), (0.7, 0)),
      ((0.5, 0), (0.5, 1)),
      ((0.3, 1), (0.7, 1)),
    ],
    'J': [
      ((0.3, 1), (0.8, 1)),
      ((0.8, 1), (0.8, 0.2)),
      ((0.8, 0.2), (0.6, 0)),
      ((0.6, 0), (0.3, 0)),
      ((0.3, 0), (0.1, 0.2)),
    ],
    'K': [
      ((0, 0), (0, 1)),
      ((0, 0.5), (1, 1)),
      ((0.4, 0.7), (1, 0)),
    ],
    'L': [
      ((0, 1), (0, 0)),
      ((0, 0), (1, 0)),
    ],
    'M': [
      ((0, 0), (0, 1)),
      ((0, 1), (0.5, 0.5)),
      ((0.5, 0.5), (1, 1)),
      ((1, 1), (1, 0)),
    ],
    'N': [
      ((0, 0), (0, 1)),
      ((0, 1), (1, 0)),
      ((1, 0), (1, 1)),
    ],
    'O': [
      ((0.2, 0), (0, 0.2)),
      ((0, 0.2), (0, 0.8)),
      ((0, 0.8), (0.2, 1)),
      ((0.2, 1), (0.8, 1)),
      ((0.8, 1), (1, 0.8)),
      ((1, 0.8), (1, 0.2)),
      ((1, 0.2), (0.8, 0)),
      ((0.8, 0), (0.2, 0)),
    ],
    'P': [
      ((0, 0), (0, 1)),
      ((0, 1), (0.8, 1)),
      ((0.8, 1), (1, 0.8)),
      ((1, 0.8), (1, 0.6)),
      ((1, 0.6), (0.8, 0.5)),
      ((0.8, 0.5), (0, 0.5)),
    ],
    'Q': [
      ((0.2, 0), (0, 0.2)),
      ((0, 0.2), (0, 0.8)),
      ((0, 0.8), (0.2, 1)),
      ((0.2, 1), (0.8, 1)),
      ((0.8, 1), (1, 0.8)),
      ((1, 0.8), (1, 0.2)),
      ((1, 0.2), (0.8, 0)),
      ((0.8, 0), (0.2, 0)),
      ((0.6, 0.3), (1, 0)),
    ],
    'R': [
      ((0, 0), (0, 1)),
      ((0, 1), (0.8, 1)),
      ((0.8, 1), (1, 0.8)),
      ((1, 0.8), (1, 0.6)),
      ((1, 0.6), (0.8, 0.5)),
      ((0.8, 0.5), (0, 0.5)),
      ((0.5, 0.5), (1, 0)),
    ],
    'S': [
      ((1, 0.8), (0.8, 1)),
      ((0.8, 1), (0.2, 1)),
      ((0.2, 1), (0, 0.8)),
      ((0, 0.8), (0, 0.6)),
      ((0, 0.6), (0.2, 0.5)),
      ((0.2, 0.5), (0.8, 0.5)),
      ((0.8, 0.5), (1, 0.4)),
      ((1, 0.4), (1, 0.2)),
      ((1, 0.2), (0.8, 0)),
      ((0.8, 0), (0.2, 0)),
      ((0.2, 0), (0, 0.2)),
    ],
    'T': [
      ((0, 1), (1, 1)),
      ((0.5, 1), (0.5, 0)),
    ],
    'U': [
      ((0, 1), (0, 0.2)),
      ((0, 0.2), (0.2, 0)),
      ((0.2, 0), (0.8, 0)),
      ((0.8, 0), (1, 0.2)),
      ((1, 0.2), (1, 1)),
    ],
    'V': [
      ((0, 1), (0.5, 0)),
      ((0.5, 0), (1, 1)),
    ],
    'W': [
      ((0, 1), (0.25, 0)),
      ((0.25, 0), (0.5, 0.5)),
      ((0.5, 0.5), (0.75, 0)),
      ((0.75, 0), (1, 1)),
    ],
    'X': [
      ((0, 0), (1, 1)),
      ((0, 1), (1, 0)),
    ],
    'Y': [
      ((0, 1), (0.5, 0.5)),
      ((0.5, 0.5), (1, 1)),
      ((0.5, 0.5), (0.5, 0)),
    ],
    'Z': [
      ((0, 1), (1, 1)),
      ((1, 1), (0, 0)),
      ((0, 0), (1, 0)),
    ],
    '0': [
      ((0.2, 0), (0, 0.2)),
      ((0, 0.2), (0, 0.8)),
      ((0, 0.8), (0.2, 1)),
      ((0.2, 1), (0.8, 1)),
      ((0.8, 1), (1, 0.8)),
      ((1, 0.8), (1, 0.2)),
      ((1, 0.2), (0.8, 0)),
      ((0.8, 0), (0.2, 0)),
      ((0.2, 0.2), (0.8, 0.8)),
    ],
    '1': [
      ((0.3, 0.8), (0.5, 1)),
      ((0.5, 1), (0.5, 0)),
      ((0.3, 0), (0.7, 0)),
    ],
    '2': [
      ((0, 0.8), (0.2, 1)),
      ((0.2, 1), (0.8, 1)),
      ((0.8, 1), (1, 0.8)),
      ((1, 0.8), (1, 0.6)),
      ((1, 0.6), (0, 0)),
      ((0, 0), (1, 0)),
    ],
    '3': [
      ((0, 0.8), (0.2, 1)),
      ((0.2, 1), (0.8, 1)),
      ((0.8, 1), (1, 0.8)),
      ((1, 0.8), (1, 0.6)),
      ((1, 0.6), (0.8, 0.5)),
      ((0.8, 0.5), (0.4, 0.5)),
      ((0.8, 0.5), (1, 0.4)),
      ((1, 0.4), (1, 0.2)),
      ((1, 0.2), (0.8, 0)),
      ((0.8, 0), (0.2, 0)),
      ((0.2, 0), (0, 0.2)),
    ],
    '4': [
      ((0.7, 0), (0.7, 1)),
      ((0.7, 1), (0, 0.4)),
      ((0, 0.4), (1, 0.4)),
    ],
    '5': [
      ((1, 1), (0, 1)),
      ((0, 1), (0, 0.5)),
      ((0, 0.5), (0.8, 0.5)),
      ((0.8, 0.5), (1, 0.4)),
      ((1, 0.4), (1, 0.2)),
      ((1, 0.2), (0.8, 0)),
      ((0.8, 0), (0.2, 0)),
      ((0.2, 0), (0, 0.2)),
    ],
    '6': [
      ((1, 0.8), (0.8, 1)),
      ((0.8, 1), (0.2, 1)),
      ((0.2, 1), (0, 0.8)),
      ((0, 0.8), (0, 0.2)),
      ((0, 0.2), (0.2, 0)),
      ((0.2, 0), (0.8, 0)),
      ((0.8, 0), (1, 0.2)),
      ((1, 0.2), (1, 0.4)),
      ((1, 0.4), (0.8, 0.5)),
      ((0.8, 0.5), (0, 0.5)),
    ],
    '7': [
      ((0, 1), (1, 1)),
      ((1, 1), (0.3, 0)),
    ],
    '8': [
      ((0.2, 0.5), (0, 0.4)),
      ((0, 0.4), (0, 0.2)),
      ((0, 0.2), (0.2, 0)),
      ((0.2, 0), (0.8, 0)),
      ((0.8, 0), (1, 0.2)),
      ((1, 0.2), (1, 0.4)),
      ((1, 0.4), (0.8, 0.5)),
      ((0.8, 0.5), (1, 0.6)),
      ((1, 0.6), (1, 0.8)),
      ((1, 0.8), (0.8, 1)),
      ((0.8, 1), (0.2, 1)),
      ((0.2, 1), (0, 0.8)),
      ((0, 0.8), (0, 0.6)),
      ((0, 0.6), (0.2, 0.5)),
      ((0.2, 0.5), (0.8, 0.5)),
    ],
    '9': [
      ((0, 0.2), (0.2, 0)),
      ((0.2, 0), (0.8, 0)),
      ((0.8, 0), (1, 0.2)),
      ((1, 0.2), (1, 0.8)),
      ((1, 0.8), (0.8, 1)),
      ((0.8, 1), (0.2, 1)),
      ((0.2, 1), (0, 0.8)),
      ((0, 0.8), (0, 0.6)),
      ((0, 0.6), (0.2, 0.5)),
      ((0.2, 0.5), (1, 0.5)),
    ],
    ' ': [], // Space - no segments
    '!': [
      ((0.5, 0.3), (0.5, 1)),
      ((0.5, 0), (0.5, 0.1)),
    ],
    '.': [
      ((0.4, 0), (0.6, 0)),
      ((0.6, 0), (0.6, 0.15)),
      ((0.6, 0.15), (0.4, 0.15)),
      ((0.4, 0.15), (0.4, 0)),
    ],
    ',': [
      ((0.4, 0.15), (0.6, 0.15)),
      ((0.6, 0.15), (0.5, -0.1)),
    ],
    '?': [
      ((0, 0.8), (0.2, 1)),
      ((0.2, 1), (0.8, 1)),
      ((0.8, 1), (1, 0.8)),
      ((1, 0.8), (1, 0.6)),
      ((1, 0.6), (0.5, 0.4)),
      ((0.5, 0.4), (0.5, 0.25)),
      ((0.5, 0), (0.5, 0.1)),
    ],
    '-': [
      ((0.2, 0.5), (0.8, 0.5)),
    ],
    '_': [
      ((0, 0), (1, 0)),
    ],
    ':': [
      ((0.4, 0.6), (0.6, 0.6)),
      ((0.6, 0.6), (0.6, 0.75)),
      ((0.6, 0.75), (0.4, 0.75)),
      ((0.4, 0.75), (0.4, 0.6)),
      ((0.4, 0.1), (0.6, 0.1)),
      ((0.6, 0.1), (0.6, 0.25)),
      ((0.6, 0.25), (0.4, 0.25)),
      ((0.4, 0.25), (0.4, 0.1)),
    ],
    '/': [
      ((0, 0), (1, 1)),
    ],
    '(': [
      ((0.6, 0), (0.4, 0.2)),
      ((0.4, 0.2), (0.4, 0.8)),
      ((0.4, 0.8), (0.6, 1)),
    ],
    ')': [
      ((0.4, 0), (0.6, 0.2)),
      ((0.6, 0.2), (0.6, 0.8)),
      ((0.6, 0.8), (0.4, 1)),
    ],
  };

  List<Vector3>? _cachedVertices;
  List<(int, int)>? _cachedEdges;

  @override
  List<Vector3> get vertices {
    _cachedVertices ??= _generateVertices();
    return _cachedVertices!;
  }

  @override
  List<(int, int)> get edges {
    _cachedEdges ??= _generateEdges();
    return _cachedEdges!;
  }

  /// Generates vertices for each character in the text.
  List<Vector3> _generateVertices() {
    final vertices = <Vector3>[];
    final upperText = text.toUpperCase();

    // Calculate total width to center the text
    final charFullWidth = charWidth + spacing;
    final totalWidth = upperText.length * charFullWidth - spacing;
    final startX = -totalWidth / 2;

    // Half depth for front/back positioning
    final halfDepth = charDepth / 2;

    for (int i = 0; i < upperText.length; i++) {
      final char = upperText[i];
      final segments = _font[char] ?? [];

      final charOffset = startX + i * charFullWidth;

      // For each segment, we need 4 vertices (2 endpoints x 2 faces)
      for (final segment in segments) {
        final (start, end) = segment;

        // Scale and position vertices
        // Front face vertices
        final frontStart = Vector3(
          charOffset + start.$1 * charWidth,
          (start.$2 - 0.5) * charHeight, // Center vertically
          halfDepth,
        );
        final frontEnd = Vector3(
          charOffset + end.$1 * charWidth,
          (end.$2 - 0.5) * charHeight,
          halfDepth,
        );

        // Back face vertices
        final backStart = Vector3(
          charOffset + start.$1 * charWidth,
          (start.$2 - 0.5) * charHeight,
          -halfDepth,
        );
        final backEnd = Vector3(
          charOffset + end.$1 * charWidth,
          (end.$2 - 0.5) * charHeight,
          -halfDepth,
        );

        vertices.addAll([frontStart, frontEnd, backStart, backEnd]);
      }
    }

    return vertices;
  }

  /// Generates edges connecting the vertices.
  List<(int, int)> _generateEdges() {
    final edges = <(int, int)>[];
    final upperText = text.toUpperCase();

    int vertexOffset = 0;

    for (int i = 0; i < upperText.length; i++) {
      final char = upperText[i];
      final segments = _font[char] ?? [];

      for (int j = 0; j < segments.length; j++) {
        // Each segment has 4 vertices: frontStart, frontEnd, backStart, backEnd
        final baseIdx = vertexOffset + j * 4;

        // Front face edge
        edges.add((baseIdx, baseIdx + 1));

        // Back face edge
        edges.add((baseIdx + 2, baseIdx + 3));

        // Connecting edges (front to back)
        edges.add((baseIdx, baseIdx + 2)); // frontStart to backStart
        edges.add((baseIdx + 1, baseIdx + 3)); // frontEnd to backEnd
      }

      vertexOffset += segments.length * 4;
    }

    return edges;
  }
}
