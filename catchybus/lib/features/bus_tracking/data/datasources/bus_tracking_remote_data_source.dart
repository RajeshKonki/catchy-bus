import '../models/bus_route_model.dart';

/// Mock data source for bus tracking
/// In production, this would be replaced with actual API calls
abstract class BusTrackingRemoteDataSource {
  Future<BusRouteModel> getBusRoute(String busNumber);
  Future<List<BusSummaryModel>> getAvailableBuses();
  Future<List<RouteStopModel>> getAllCollegeStops();
  Future<void> submitSupportQuery({
    required String query,
    required String subject,
    String? email,
  });
  Future<List<Map<String, dynamic>>> getStudentsByStop(String busNumber, String stopName);
  Stream<BusPositionModel> streamBusLocation(String busNumber);
  Stream<Map<String, dynamic>> streamTripStatus(String busNumber);
}

class BusTrackingRemoteDataSourceImpl implements BusTrackingRemoteDataSource {
  @override
  Future<BusRouteModel> getBusRoute(String busNumber) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data matching the design
    return BusRouteModel(
      id: 'mock-bus-id-10',
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
  Future<List<BusSummaryModel>> getAvailableBuses() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    final List<dynamic> data = [
      {
        'id': 'bus-10-id',
        'busNumber': 'Bus No. 10',
        'latitude': 40.7589,
        'longitude': -73.9851,
        'status': 'On Time',
        'isDelayed': false,
      },
      {
        'id': 'bus-15-id',
        'busNumber': 'Bus No. 15',
        'latitude': 40.7689,
        'longitude': -73.9951,
        'status': 'Delayed 5 min',
        'isDelayed': true,
      },
      {
        'id': 'bus-20-id',
        'busNumber': 'Bus No. 20',
        'latitude': 40.7489,
        'longitude': -73.9751,
        'status': 'On Time',
        'isDelayed': false,
      },
      {
        'id': 'bus-25-id',
        'busNumber': 'Bus No. 25',
        'latitude': 40.7789,
        'longitude': -73.9551,
        'status': 'On Time',
        'isDelayed': false,
      },
    ];

    return data.map((e) => BusSummaryModel.fromJson(e)).toList();
  }

  @override
  Future<List<RouteStopModel>> getAllCollegeStops() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    final List<dynamic> data = [
      {
        'name': 'Times Square',
        'latitude': 40.7580,
        'longitude': -73.9855,
        'type': 'stop'
      },
      {
        'name': 'MG Road',
        'latitude': 40.7489,
        'longitude': -73.9680,
        'type': 'stop'
      },
      {
        'name': 'Central Park',
        'latitude': 40.7812,
        'longitude': -73.9665,
        'type': 'stop'
      },
      {
        'name': 'Hostel Gate',
        'latitude': 40.7614,
        'longitude': -73.9776,
        'type': 'stop'
      },
      {
        'name': 'Grand Central',
        'latitude': 40.7527,
        'longitude': -73.9772,
        'type': 'stop'
      },
      {
        'name': 'Penn Station',
        'latitude': 40.7505,
        'longitude': -73.9934,
        'type': 'stop'
      },
      {
        'name': 'College Campus',
        'latitude': 40.7300,
        'longitude': -73.9950,
        'type': 'college'
      },
    ];

    return data.map((e) => RouteStopModel.fromJson(e)).toList();
  }

  @override
  Future<void> submitSupportQuery({
    required String query,
    required String subject,
    String? email,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<Map<String, dynamic>>> getStudentsByStop(String busNumber, String stopName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  @override
  Stream<BusPositionModel> streamBusLocation(String busNumber) async* {
    double lat = 40.7589;
    double lng = -73.9851;
    double bearing = 45.0;

    while (true) {
      await Future.delayed(const Duration(milliseconds: 500));
      lat += 0.0001;
      lng += 0.0001;
      yield BusPositionModel(latitude: lat, longitude: lng, bearing: bearing);
    }
  }

  @override
  Stream<Map<String, dynamic>> streamTripStatus(String busNumber) async* {
    // Mock: never emits - trip status comes from REST API in mock mode
  }
}
