import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/bus_route.dart';

part 'bus_tracking_state.freezed.dart';

@freezed
class BusTrackingState with _$BusTrackingState {
  const factory BusTrackingState.initial() = _Initial;
  const factory BusTrackingState.loading() = _Loading;
  const factory BusTrackingState.loaded(BusRoute busRoute) = _Loaded;
  const factory BusTrackingState.error(String message) = _Error;
}

@freezed
class BusListState with _$BusListState {
  const factory BusListState.initial() = _BusListInitial;
  const factory BusListState.loading() = _BusListLoading;
  const factory BusListState.loaded(List<String> buses) = _BusListLoaded;
  const factory BusListState.error(String message) = _BusListError;
}
