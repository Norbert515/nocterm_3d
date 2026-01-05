/// A high-resolution buffer using Braille characters.
///
/// Each terminal cell is 2x4 sub-pixels, giving us 8x more resolution
/// than standard ASCII rendering.
///
/// Unicode Braille characters (U+2800 to U+28FF) represent a 2x4 dot matrix:
/// ```
/// ┌───┬───┐
/// │ 1 │ 4 │  Dot numbering (bit positions):
/// ├───┼───┤  1=0x01, 2=0x02, 3=0x04, 4=0x08
/// │ 2 │ 5 │  5=0x10, 6=0x20, 7=0x40, 8=0x80
/// ├───┼───┤
/// │ 3 │ 6 │  Character = 0x2800 + (dot bits)
/// ├───┼───┤
/// │ 7 │ 8 │
/// └───┴───┘
/// ```
class BrailleBuffer {
  /// Terminal width in characters.
  final int width;

  /// Terminal height in characters.
  final int height;

  /// Sub-pixel width (width * 2).
  int get pixelWidth => width * 2;

  /// Sub-pixel height (height * 4).
  int get pixelHeight => height * 4;

  /// Internal storage: one byte per character cell.
  /// Each bit represents a dot in the Braille pattern.
  late final List<List<int>> _cells;

  /// Depth buffer at sub-pixel resolution.
  late final List<List<double>> _depthBuffer;

  /// Creates a Braille buffer with the given terminal dimensions.
  BrailleBuffer(this.width, this.height) {
    _cells = List.generate(height, (_) => List.filled(width, 0));
    _depthBuffer = List.generate(
      pixelHeight,
      (_) => List.filled(pixelWidth, double.infinity),
    );
  }

  /// Clears the buffer to empty and resets depth.
  void clear() {
    for (final row in _cells) {
      row.fillRange(0, row.length, 0);
    }
    for (final row in _depthBuffer) {
      row.fillRange(0, row.length, double.infinity);
    }
  }

  /// Sets a sub-pixel at (px, py) in pixel coordinates.
  ///
  /// Only draws if the new depth is less than the existing depth (closer to camera).
  void setPixel(int px, int py, {double depth = 0}) {
    if (px < 0 || px >= pixelWidth || py < 0 || py >= pixelHeight) return;

    // Check depth - lower values are closer to camera
    if (depth > _depthBuffer[py][px]) return;
    _depthBuffer[py][px] = depth;

    // Calculate which character cell
    final cx = px ~/ 2;
    final cy = py ~/ 4;

    // Calculate which dot within the cell
    final dx = px % 2; // 0 = left, 1 = right
    final dy = py % 4; // 0-3 from top

    // Braille dot bit mapping:
    // Left column:  dy=0->bit0, dy=1->bit1, dy=2->bit2, dy=3->bit6
    // Right column: dy=0->bit3, dy=1->bit4, dy=2->bit5, dy=3->bit7
    int bit;
    if (dx == 0) {
      bit = dy < 3 ? (1 << dy) : 0x40;
    } else {
      bit = dy < 3 ? (1 << (dy + 3)) : 0x80;
    }

    _cells[cy][cx] |= bit;
  }

  /// Draws a line using Bresenham's algorithm at sub-pixel resolution.
  ///
  /// The depth is interpolated along the line for proper z-buffering.
  void drawLine(
    int x0,
    int y0,
    int x1,
    int y1, {
    double depth0 = 0,
    double depth1 = 0,
  }) {
    if (depth0 == depth1) {
      _drawLineWithDepth(x0, y0, x1, y1, depth0);
    } else {
      _drawLineWithInterpolatedDepth(x0, y0, x1, y1, depth0, depth1);
    }
  }

  /// Draws a line with constant depth.
  void _drawLineWithDepth(
    int x0,
    int y0,
    int x1,
    int y1,
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
      setPixel(x, y, depth: depth);

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
    double totalDistSq =
        ((x1 - x0) * (x1 - x0) + (y1 - y0) * (y1 - y0)).toDouble();
    if (totalDistSq == 0) totalDistSq = 1;

    while (true) {
      // Calculate interpolation factor based on distance traveled
      double currentDistSq =
          ((x - x0) * (x - x0) + (y - y0) * (y - y0)).toDouble();
      double t = (currentDistSq / totalDistSq).clamp(0.0, 1.0);

      double depth = depth0 + (depth1 - depth0) * t;
      setPixel(x, y, depth: depth);

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

  /// Renders the buffer to a string.
  String render() {
    final buffer = StringBuffer();
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        // Braille base is U+2800, add the dot pattern
        buffer.writeCharCode(0x2800 + _cells[y][x]);
      }
      if (y < height - 1) buffer.writeln();
    }
    return buffer.toString();
  }
}
