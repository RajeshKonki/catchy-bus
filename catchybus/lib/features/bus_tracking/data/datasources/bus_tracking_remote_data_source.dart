import '../models/bus_route_model.dart';

/// Mock data source for bus tracking
/// In production, this would be replaced with actual API calls
abstract class BusTrackingRemoteDataSource {
  Future<BusRouteModel> getBusRoute(String busNumber);
  Future<List<String>> getAvailableBuses();
}

class BusTrackingRemoteDataSourceImpl implements BusTrackingRemoteDataSource {
  @override
  Future<BusRouteModel> getBusRoute(String busNumber) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data matching the design
    return BusRouteModel(
      busNumber: busNumber,
      currentLocation: 'MG Road',
      nextStop: 'Hostel Gate',
      arrivalTimeMinutes: 8,
      distanceKm: 4.2,
      isOnTime: true,
      driverPhone: '+1234567890',
      busPosition: const BusPositionModel(
        latitude: 40.7589,
        longitude: -73.9851,
        bearing: 45.0,
      ),
      stops: const [
        RouteStopModel(
          name: 'MG Road',
          latitude: 40.7489,
          longitude: -73.9680,
          type: 'current',
        ),
        RouteStopModel(
          name: 'Hostel Gate',
          latitude: 40.7614,
          longitude: -73.9776,
          type: 'next',
          estimatedArrivalMinutes: 8,
        ),
      ],
      routePath: const [
        RoutePointModel(latitude: 40.7489, longitude: -73.9680),
        RoutePointModel(latitude: 40.7520, longitude: -73.9700),
        RoutePointModel(latitude: 40.7550, longitude: -73.9730),
        RoutePointModel(latitude: 40.7589, longitude: -73.9851),
        RoutePointModel(latitude: 40.7614, longitude: -73.9776),
      ],
    );
  }

  @override
  Future<List<String>> getAvailableBuses() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      'Bus No. 10',
      'Bus No. 15',
      'Bus No. 20',
      'Bus No. 25',
      'Bus No. 30',
    ];
  }
}
