class TripSummary {
  final Duration duration;
  final double distanceKm;
  final String busId;
  final DateTime endTime;
  final double? driverLat;
  final double? driverLng;

  TripSummary({
    required this.duration,
    required this.distanceKm,
    required this.busId,
    required this.endTime,
    this.driverLat,
    this.driverLng,
  });

  String get durationString {
    final minutes = duration.inMinutes;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
