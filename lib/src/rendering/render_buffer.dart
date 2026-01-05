/// A 2D buffer for rendering ASCII graphics with depth testing.
class RenderBuffer {
  /// The width of the buffer in characters.
  final int width;

  /// The height of the buffer in characters.
  final int height;

  /// The character buffer.
  final List<List<String>> _buffer;

  /// The depth buffer for z-buffering (lower values are closer).
  final List<List<double>> _depthBuffer;

  /// The character used for empty pixels.
  static const String emptyChar = ' ';

  /// The default character used for drawing.
  static const String defaultChar = '*';

  /// Creates a render buffer with the given dimensions.
  RenderBuffer(this.width, this.height)
      : _buffer = List.generate(height, (_) => List.filled(width, emptyChar)),
        _depthBuffer = List.generate(
            height, (_) => List.filled(width, double.infinity));

  /// Clears the buffer to empty characters and resets depth.
  void clear() {
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        _buffer[y][x] = emptyChar;
        _depthBuffer[y][x] = double.infinity;
      }
    }
  }

  /// Sets a pixel at (x, y) with the given character and depth.
  /// Only draws if the new depth is less than the existing depth (closer to camera).
  void setPixel(int x, int y, String char, {double depth = 0}) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;

    if (depth < _depthBuffer[y][x]) {
      _buffer[y][x] = char;
      _depthBuffer[y][x] = depth;
    }
  }

  /// Gets the character at (x, y).
  String getPixel(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return emptyChar;
    return _buffer[y][x];
  }

  /// Draws a line from (x0, y0) to (x1, y1) with depth testing.
  /// The depth is interpolated along the line.
  void drawLine(
    int x0,
    int y0,
    int x1,
    int y1,
    String char, {
    double depth0 = 0,
    double depth1 = 0,
  }) {
    // For simple cases or when depths are equal, use basic line drawing
    if (depth0 == depth1) {
      _drawLineWithDepth(x0, y0, x1, y1, char, depth0);
    } else {
      _drawLineWithInterpolatedDepth(x0, y0, x1, y1, char, depth0, depth1);
    }
  }

  /// Draws a line with constant depth.
  void _drawLineWithDepth(
    int x0,
    int y0,
    int x1,
    int y1,
    String char,
    double depth,
  ) {
    int dx = (x1 - x0).abs();
    int dy = -(y1 - y0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;

    int x = x0;
    int y = y0;

    while (true) {
      setPixel(x, y, char, depth: depth);

      if (x == x1 && y == y1) break;

      int e2 = 2 * err;

      if (e2 >= dy) {
        if (x == x1) break;
        err += dy;
        x += sx;
      }

      if (e2 <= dx) {
        if (y == y1) break;
        err += dx;
        y += sy;
      }
    }
  }

  /// Draws a line with interpolated depth along its length.
  void _drawLineWithInterpolatedDepth(
    int x0,
    int y0,
    int x1,
    int y1,
    String char,
    double depth0,
    double depth1,
  ) {
    int dx = (x1 - x0).abs();
    int dy = -(y1 - y0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;

    int x = x0;
    int y = y0;

    // Calculate total distance for interpolation
    double totalDist =
        ((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)).toDouble();
    if (totalDist == 0) totalDist = 1;

    while (true) {
      // Calculate interpolation factor based on distance traveled
      double currentDist =
          ((x - x0) * (x - x0) + (y - y0) * (y - y0)).toDouble();
      double t = currentDist / totalDist;
      // Use sqrt for linear interpolation along the line
      t = t > 0 ? t.clamp(0.0, 1.0) : 0.0;
      if (totalDist > 1) {
        t = (currentDist / totalDist).clamp(0.0, 1.0);
        // Take sqrt since we're comparing squared distances
        t = t > 0 ? t : 0.0;
      }

      double depth = depth0 + (depth1 - depth0) * t;
      setPixel(x, y, char, depth: depth);

      if (x == x1 && y == y1) break;

      int e2 = 2 * err;

      if (e2 >= dy) {
        if (x == x1) break;
        err += dy;
        x += sx;
      }

      if (e2 <= dx) {
        if (y == y1) break;
        err += dx;
        y += sy;
      }
    }
  }

  /// Renders the buffer to a single string for display.
  String render() {
    final buffer = StringBuffer();
    for (int y = 0; y < height; y++) {
      buffer.writeln(_buffer[y].join());
    }
    return buffer.toString();
  }

  /// Gets direct access to the character buffer for LineRenderer.
  List<List<String>> get buffer => _buffer;
}
