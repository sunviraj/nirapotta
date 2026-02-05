class SensorReading {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final double? dbLevel; // Nullable if only accel data

  SensorReading({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.z,
    this.dbLevel,
  });

  @override
  String toString() {
    return 'T: $timestamp, X: $x, Y: $y, Z: $z, dB: $dbLevel';
  }

  String toCSV() {
    return '${timestamp.millisecondsSinceEpoch},${x.toStringAsFixed(4)},${y.toStringAsFixed(4)},${z.toStringAsFixed(4)},${dbLevel?.toStringAsFixed(2) ?? "0.0"}';
  }
}
