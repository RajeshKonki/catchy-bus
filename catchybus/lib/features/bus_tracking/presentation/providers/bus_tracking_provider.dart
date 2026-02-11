import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/get_available_buses.dart';
import '../../domain/usecases/get_bus_route.dart';
import '../state/bus_tracking_state.dart';

class BusTrackingNotifier extends StateNotifier<BusTrackingState> {
  final GetBusRoute getBusRoute;

  BusTrackingNotifier({required this.getBusRoute})
    : super(const BusTrackingState.initial());

  Future<void> loadBusRoute(String busNumber) async {
    state = const BusTrackingState.loading();

    final result = await getBusRoute(GetBusRouteParams(busNumber: busNumber));

    result.fold(
      (failure) => state = BusTrackingState.error(failure.message),
      (busRoute) => state = BusTrackingState.loaded(busRoute),
    );
  }

  void reset() {
    state = const BusTrackingState.initial();
  }
}

class BusListNotifier extends StateNotifier<BusListState> {
  final GetAvailableBuses getAvailableBuses;

  BusListNotifier({required this.getAvailableBuses})
    : super(const BusListState.initial());

  Future<void> loadAvailableBuses() async {
    state = const BusListState.loading();

    final result = await getAvailableBuses(NoParams());

    result.fold(
      (failure) => state = BusListState.error(failure.message),
      (buses) => state = BusListState.loaded(buses),
    );
  }
}
