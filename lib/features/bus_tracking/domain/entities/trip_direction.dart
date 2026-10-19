enum TripDirection {
  forward,
  reverse
}

extension TripDirectionExtension on TripDirection {
  bool get isReverse => this == TripDirection.reverse;
  bool get isForward => this == TripDirection.forward;

  static TripDirection fromString(String? value) {
    if (value == null) return TripDirection.forward;
    final lower = value.toLowerCase();
    if (lower == 'reverse' || lower == 'return' || lower == 'backward') {
      return TripDirection.reverse;
    }
    return TripDirection.forward;
  }
}
