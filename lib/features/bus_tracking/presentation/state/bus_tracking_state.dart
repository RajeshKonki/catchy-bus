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
  const factory BusListState.loaded(List<BusSummary> buses) = _BusListLoaded;
  const factory BusListState.error(String message) = _BusListError;
}
@freezed
class CollegeStopsState with _$CollegeStopsState {
  const factory CollegeStopsState.initial() = _CollegeStopsInitial;
  const factory CollegeStopsState.loading() = _CollegeStopsLoading;
  const factory CollegeStopsState.loaded(List<RouteStop> stops) =
      _CollegeStopsLoaded;
  const factory CollegeStopsState.error(String message) = _CollegeStopsError;
}

@freezed
class HelpDeskState with _$HelpDeskState {
  const factory HelpDeskState.initial() = _HelpDeskInitial;
  const factory HelpDeskState.loading() = _HelpDeskLoading;
  const factory HelpDeskState.success() = _HelpDeskSuccess;
  const factory HelpDeskState.error(String message) = _HelpDeskError;
}
