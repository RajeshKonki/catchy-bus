class TripSummary {
  final Duration duration;
  final double distanceKm;
  final String busId;
  final DateTime endTime;

  TripSummary({
    required this.duration,
    required this.distanceKm,
    required this.busId,
    required this.endTime,
  });

  String get durationString {
    final minutes = duration.inMinutes;
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
