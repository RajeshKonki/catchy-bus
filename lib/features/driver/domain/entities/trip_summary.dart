class TripSummary {
  final Duration duration;
  final double distanceKm;
  final String busId;
  final DateTime endTime;
  final double? driverLat;
  final double? driverLng;
  final String? routeId;
  final String? routeName;
  final bool isReverse;

  TripSummary({
    required this.duration,
    required this.distanceKm,
    required this.busId,
    required this.endTime,
    this.driverLat,
    this.driverLng,
    this.routeId,
    this.routeName,
    this.isReverse = false,
  });

  String get durationString {
    final minutes = duration.inMinutes;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
