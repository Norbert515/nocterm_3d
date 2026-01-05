/// Line rendering using Bresenham's algorithm.
class LineRenderer {
  /// Draws a line from (x0, y0) to (x1, y1) on the buffer using the given character.
  /// Uses Bresenham's line algorithm.
  static void drawLine(
    List<List<String>> buffer,
    int x0,
    int y0,
    int x1,
    int y1,
    String char,
  ) {
    // Ensure we're within bounds
    final height = buffer.length;
    if (height == 0) return;
    final width = buffer[0].length;

    int dx = (x1 - x0).abs();
    int dy = -(y1 - y0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx + dy;

    int x = x0;
    int y = y0;

    while (true) {
      // Plot pixel if within bounds
      if (x >= 0 && x < width && y >= 0 && y < height) {
        buffer[y][x] = char;
      }

      // Check if we've reached the end
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
}
