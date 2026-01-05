/// A triangular face defined by vertex indices.
class Face {
  /// First vertex index.
  final int v0;

  /// Second vertex index.
  final int v1;

  /// Third vertex index.
  final int v2;

  const Face(this.v0, this.v1, this.v2);
}
