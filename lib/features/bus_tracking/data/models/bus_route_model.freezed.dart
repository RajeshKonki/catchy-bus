// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bus_route_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BusRouteModel {
  String get id => throw _privateConstructorUsedError;
  String get busNumber => throw _privateConstructorUsedError;
  String get currentLocation => throw _privateConstructorUsedError;
  String get nextStop => throw _privateConstructorUsedError;
  String? get startPoint => throw _privateConstructorUsedError;
  String? get endPoint => throw _privateConstructorUsedError;
  int get arrivalTimeMinutes => throw _privateConstructorUsedError;
  double get distanceKm => throw _privateConstructorUsedError;
  bool get isOnTime => throw _privateConstructorUsedError;
  String get driverPhone => throw _privateConstructorUsedError;
  String? get driverName => throw _privateConstructorUsedError;
  String? get driverPhoto => throw _privateConstructorUsedError;
  int? get capacity => throw _privateConstructorUsedError;
  String? get collegeName => throw _privateConstructorUsedError;
  BusPositionModel get busPosition => throw _privateConstructorUsedError;
  List<RouteStopModel> get stops => throw _privateConstructorUsedError;
  List<RoutePointModel> get routePath => throw _privateConstructorUsedError;
  bool get isTripActive => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get students => throw _privateConstructorUsedError;

  /// Create a copy of BusRouteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BusRouteModelCopyWith<BusRouteModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BusRouteModelCopyWith<$Res> {
  factory $BusRouteModelCopyWith(
    BusRouteModel value,
    $Res Function(BusRouteModel) then,
  ) = _$BusRouteModelCopyWithImpl<$Res, BusRouteModel>;
  @useResult
  $Res call({
    String id,
    String busNumber,
    String currentLocation,
    String nextStop,
    String? startPoint,
    String? endPoint,
    int arrivalTimeMinutes,
    double distanceKm,
    bool isOnTime,
    String driverPhone,
    String? driverName,
    String? driverPhoto,
    int? capacity,
    String? collegeName,
    BusPositionModel busPosition,
    List<RouteStopModel> stops,
    List<RoutePointModel> routePath,
    bool isTripActive,
    List<Map<String, dynamic>> students,
  });

  $BusPositionModelCopyWith<$Res> get busPosition;
}

/// @nodoc
class _$BusRouteModelCopyWithImpl<$Res, $Val extends BusRouteModel>
    implements $BusRouteModelCopyWith<$Res> {
  _$BusRouteModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BusRouteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? busNumber = null,
    Object? currentLocation = null,
    Object? nextStop = null,
    Object? startPoint = freezed,
    Object? endPoint = freezed,
    Object? arrivalTimeMinutes = null,
    Object? distanceKm = null,
    Object? isOnTime = null,
    Object? driverPhone = null,
    Object? driverName = freezed,
    Object? driverPhoto = freezed,
    Object? capacity = freezed,
    Object? collegeName = freezed,
    Object? busPosition = null,
    Object? stops = null,
    Object? routePath = null,
    Object? isTripActive = null,
    Object? students = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            busNumber: null == busNumber
                ? _value.busNumber
                : busNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            currentLocation: null == currentLocation
                ? _value.currentLocation
                : currentLocation // ignore: cast_nullable_to_non_nullable
                      as String,
            nextStop: null == nextStop
                ? _value.nextStop
                : nextStop // ignore: cast_nullable_to_non_nullable
                      as String,
            startPoint: freezed == startPoint
                ? _value.startPoint
                : startPoint // ignore: cast_nullable_to_non_nullable
                      as String?,
            endPoint: freezed == endPoint
                ? _value.endPoint
                : endPoint // ignore: cast_nullable_to_non_nullable
                      as String?,
            arrivalTimeMinutes: null == arrivalTimeMinutes
                ? _value.arrivalTimeMinutes
                : arrivalTimeMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            distanceKm: null == distanceKm
                ? _value.distanceKm
                : distanceKm // ignore: cast_nullable_to_non_nullable
                      as double,
            isOnTime: null == isOnTime
                ? _value.isOnTime
                : isOnTime // ignore: cast_nullable_to_non_nullable
                      as bool,
            driverPhone: null == driverPhone
                ? _value.driverPhone
                : driverPhone // ignore: cast_nullable_to_non_nullable
                      as String,
            driverName: freezed == driverName
                ? _value.driverName
                : driverName // ignore: cast_nullable_to_non_nullable
                      as String?,
            driverPhoto: freezed == driverPhoto
                ? _value.driverPhoto
                : driverPhoto // ignore: cast_nullable_to_non_nullable
                      as String?,
            capacity: freezed == capacity
                ? _value.capacity
                : capacity // ignore: cast_nullable_to_non_nullable
                      as int?,
            collegeName: freezed == collegeName
                ? _value.collegeName
                : collegeName // ignore: cast_nullable_to_non_nullable
                      as String?,
            busPosition: null == busPosition
                ? _value.busPosition
                : busPosition // ignore: cast_nullable_to_non_nullable
                      as BusPositionModel,
            stops: null == stops
                ? _value.stops
                : stops // ignore: cast_nullable_to_non_nullable
                      as List<RouteStopModel>,
            routePath: null == routePath
                ? _value.routePath
                : routePath // ignore: cast_nullable_to_non_nullable
                      as List<RoutePointModel>,
            isTripActive: null == isTripActive
                ? _value.isTripActive
                : isTripActive // ignore: cast_nullable_to_non_nullable
                      as bool,
            students: null == students
                ? _value.students
                : students // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>,
          )
          as $Val,
    );
  }

  /// Create a copy of BusRouteModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BusPositionModelCopyWith<$Res> get busPosition {
    return $BusPositionModelCopyWith<$Res>(_value.busPosition, (value) {
      return _then(_value.copyWith(busPosition: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$BusRouteModelImplCopyWith<$Res>
    implements $BusRouteModelCopyWith<$Res> {
  factory _$$BusRouteModelImplCopyWith(
    _$BusRouteModelImpl value,
    $Res Function(_$BusRouteModelImpl) then,
  ) = __$$BusRouteModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String busNumber,
    String currentLocation,
    String nextStop,
    String? startPoint,
    String? endPoint,
    int arrivalTimeMinutes,
    double distanceKm,
    bool isOnTime,
    String driverPhone,
    String? driverName,
    String? driverPhoto,
    int? capacity,
    String? collegeName,
    BusPositionModel busPosition,
    List<RouteStopModel> stops,
    List<RoutePointModel> routePath,
    bool isTripActive,
    List<Map<String, dynamic>> students,
  });

  @override
  $BusPositionModelCopyWith<$Res> get busPosition;
}

/// @nodoc
class __$$BusRouteModelImplCopyWithImpl<$Res>
    extends _$BusRouteModelCopyWithImpl<$Res, _$BusRouteModelImpl>
    implements _$$BusRouteModelImplCopyWith<$Res> {
  __$$BusRouteModelImplCopyWithImpl(
    _$BusRouteModelImpl _value,
    $Res Function(_$BusRouteModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusRouteModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? busNumber = null,
    Object? currentLocation = null,
    Object? nextStop = null,
    Object? startPoint = freezed,
    Object? endPoint = freezed,
    Object? arrivalTimeMinutes = null,
    Object? distanceKm = null,
    Object? isOnTime = null,
    Object? driverPhone = null,
    Object? driverName = freezed,
    Object? driverPhoto = freezed,
    Object? capacity = freezed,
    Object? collegeName = freezed,
    Object? busPosition = null,
    Object? stops = null,
    Object? routePath = null,
    Object? isTripActive = null,
    Object? students = null,
  }) {
    return _then(
      _$BusRouteModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        busNumber: null == busNumber
            ? _value.busNumber
            : busNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        currentLocation: null == currentLocation
            ? _value.currentLocation
            : currentLocation // ignore: cast_nullable_to_non_nullable
                  as String,
        nextStop: null == nextStop
            ? _value.nextStop
            : nextStop // ignore: cast_nullable_to_non_nullable
                  as String,
        startPoint: freezed == startPoint
            ? _value.startPoint
            : startPoint // ignore: cast_nullable_to_non_nullable
                  as String?,
        endPoint: freezed == endPoint
            ? _value.endPoint
            : endPoint // ignore: cast_nullable_to_non_nullable
                  as String?,
        arrivalTimeMinutes: null == arrivalTimeMinutes
            ? _value.arrivalTimeMinutes
            : arrivalTimeMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        distanceKm: null == distanceKm
            ? _value.distanceKm
            : distanceKm // ignore: cast_nullable_to_non_nullable
                  as double,
        isOnTime: null == isOnTime
            ? _value.isOnTime
            : isOnTime // ignore: cast_nullable_to_non_nullable
                  as bool,
        driverPhone: null == driverPhone
            ? _value.driverPhone
            : driverPhone // ignore: cast_nullable_to_non_nullable
                  as String,
        driverName: freezed == driverName
            ? _value.driverName
            : driverName // ignore: cast_nullable_to_non_nullable
                  as String?,
        driverPhoto: freezed == driverPhoto
            ? _value.driverPhoto
            : driverPhoto // ignore: cast_nullable_to_non_nullable
                  as String?,
        capacity: freezed == capacity
            ? _value.capacity
            : capacity // ignore: cast_nullable_to_non_nullable
                  as int?,
        collegeName: freezed == collegeName
            ? _value.collegeName
            : collegeName // ignore: cast_nullable_to_non_nullable
                  as String?,
        busPosition: null == busPosition
            ? _value.busPosition
            : busPosition // ignore: cast_nullable_to_non_nullable
                  as BusPositionModel,
        stops: null == stops
            ? _value._stops
            : stops // ignore: cast_nullable_to_non_nullable
                  as List<RouteStopModel>,
        routePath: null == routePath
            ? _value._routePath
            : routePath // ignore: cast_nullable_to_non_nullable
                  as List<RoutePointModel>,
        isTripActive: null == isTripActive
            ? _value.isTripActive
            : isTripActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        students: null == students
            ? _value._students
            : students // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
      ),
    );
  }
}

/// @nodoc

class _$BusRouteModelImpl extends _BusRouteModel {
  const _$BusRouteModelImpl({
    required this.id,
    required this.busNumber,
    required this.currentLocation,
    required this.nextStop,
    this.startPoint,
    this.endPoint,
    required this.arrivalTimeMinutes,
    required this.distanceKm,
    required this.isOnTime,
    required this.driverPhone,
    this.driverName,
    this.driverPhoto,
    this.capacity,
    this.collegeName,
    required this.busPosition,
    required final List<RouteStopModel> stops,
    required final List<RoutePointModel> routePath,
    this.isTripActive = false,
    final List<Map<String, dynamic>> students = const [],
  }) : _stops = stops,
       _routePath = routePath,
       _students = students,
       super._();

  @override
  final String id;
  @override
  final String busNumber;
  @override
  final String currentLocation;
  @override
  final String nextStop;
  @override
  final String? startPoint;
  @override
  final String? endPoint;
  @override
  final int arrivalTimeMinutes;
  @override
  final double distanceKm;
  @override
  final bool isOnTime;
  @override
  final String driverPhone;
  @override
  final String? driverName;
  @override
  final String? driverPhoto;
  @override
  final int? capacity;
  @override
  final String? collegeName;
  @override
  final BusPositionModel busPosition;
  final List<RouteStopModel> _stops;
  @override
  List<RouteStopModel> get stops {
    if (_stops is EqualUnmodifiableListView) return _stops;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stops);
  }

  final List<RoutePointModel> _routePath;
  @override
  List<RoutePointModel> get routePath {
    if (_routePath is EqualUnmodifiableListView) return _routePath;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_routePath);
  }

  @override
  @JsonKey()
  final bool isTripActive;
  final List<Map<String, dynamic>> _students;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get students {
    if (_students is EqualUnmodifiableListView) return _students;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_students);
  }

  @override
  String toString() {
    return 'BusRouteModel(id: $id, busNumber: $busNumber, currentLocation: $currentLocation, nextStop: $nextStop, startPoint: $startPoint, endPoint: $endPoint, arrivalTimeMinutes: $arrivalTimeMinutes, distanceKm: $distanceKm, isOnTime: $isOnTime, driverPhone: $driverPhone, driverName: $driverName, driverPhoto: $driverPhoto, capacity: $capacity, collegeName: $collegeName, busPosition: $busPosition, stops: $stops, routePath: $routePath, isTripActive: $isTripActive, students: $students)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BusRouteModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.busNumber, busNumber) ||
                other.busNumber == busNumber) &&
            (identical(other.currentLocation, currentLocation) ||
                other.currentLocation == currentLocation) &&
            (identical(other.nextStop, nextStop) ||
                other.nextStop == nextStop) &&
            (identical(other.startPoint, startPoint) ||
                other.startPoint == startPoint) &&
            (identical(other.endPoint, endPoint) ||
                other.endPoint == endPoint) &&
            (identical(other.arrivalTimeMinutes, arrivalTimeMinutes) ||
                other.arrivalTimeMinutes == arrivalTimeMinutes) &&
            (identical(other.distanceKm, distanceKm) ||
                other.distanceKm == distanceKm) &&
            (identical(other.isOnTime, isOnTime) ||
                other.isOnTime == isOnTime) &&
            (identical(other.driverPhone, driverPhone) ||
                other.driverPhone == driverPhone) &&
            (identical(other.driverName, driverName) ||
                other.driverName == driverName) &&
            (identical(other.driverPhoto, driverPhoto) ||
                other.driverPhoto == driverPhoto) &&
            (identical(other.capacity, capacity) ||
                other.capacity == capacity) &&
            (identical(other.collegeName, collegeName) ||
                other.collegeName == collegeName) &&
            (identical(other.busPosition, busPosition) ||
                other.busPosition == busPosition) &&
            const DeepCollectionEquality().equals(other._stops, _stops) &&
            const DeepCollectionEquality().equals(
              other._routePath,
              _routePath,
            ) &&
            (identical(other.isTripActive, isTripActive) ||
                other.isTripActive == isTripActive) &&
            const DeepCollectionEquality().equals(other._students, _students));
  }

  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    id,
    busNumber,
    currentLocation,
    nextStop,
    startPoint,
    endPoint,
    arrivalTimeMinutes,
    distanceKm,
    isOnTime,
    driverPhone,
    driverName,
    driverPhoto,
    capacity,
    collegeName,
    busPosition,
    const DeepCollectionEquality().hash(_stops),
    const DeepCollectionEquality().hash(_routePath),
    isTripActive,
    const DeepCollectionEquality().hash(_students),
  ]);

  /// Create a copy of BusRouteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BusRouteModelImplCopyWith<_$BusRouteModelImpl> get copyWith =>
      __$$BusRouteModelImplCopyWithImpl<_$BusRouteModelImpl>(this, _$identity);
}

abstract class _BusRouteModel extends BusRouteModel {
  const factory _BusRouteModel({
    required final String id,
    required final String busNumber,
    required final String currentLocation,
    required final String nextStop,
    final String? startPoint,
    final String? endPoint,
    required final int arrivalTimeMinutes,
    required final double distanceKm,
    required final bool isOnTime,
    required final String driverPhone,
    final String? driverName,
    final String? driverPhoto,
    final int? capacity,
    final String? collegeName,
    required final BusPositionModel busPosition,
    required final List<RouteStopModel> stops,
    required final List<RoutePointModel> routePath,
    final bool isTripActive,
    final List<Map<String, dynamic>> students,
  }) = _$BusRouteModelImpl;
  const _BusRouteModel._() : super._();

  @override
  String get id;
  @override
  String get busNumber;
  @override
  String get currentLocation;
  @override
  String get nextStop;
  @override
  String? get startPoint;
  @override
  String? get endPoint;
  @override
  int get arrivalTimeMinutes;
  @override
  double get distanceKm;
  @override
  bool get isOnTime;
  @override
  String get driverPhone;
  @override
  String? get driverName;
  @override
  String? get driverPhoto;
  @override
  int? get capacity;
  @override
  String? get collegeName;
  @override
  BusPositionModel get busPosition;
  @override
  List<RouteStopModel> get stops;
  @override
  List<RoutePointModel> get routePath;
  @override
  bool get isTripActive;
  @override
  List<Map<String, dynamic>> get students;

  /// Create a copy of BusRouteModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BusRouteModelImplCopyWith<_$BusRouteModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BusPositionModel _$BusPositionModelFromJson(Map<String, dynamic> json) {
  return _BusPositionModel.fromJson(json);
}

/// @nodoc
mixin _$BusPositionModel {
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  double get bearing => throw _privateConstructorUsedError;
  String? get currentLocation => throw _privateConstructorUsedError;
  String? get nextStop => throw _privateConstructorUsedError;
  bool? get isOnTime => throw _privateConstructorUsedError;
  int? get delayMinutes => throw _privateConstructorUsedError;
  List<Map<String, dynamic>>? get students =>
      throw _privateConstructorUsedError;

  /// Serializes this BusPositionModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BusPositionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BusPositionModelCopyWith<BusPositionModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BusPositionModelCopyWith<$Res> {
  factory $BusPositionModelCopyWith(
    BusPositionModel value,
    $Res Function(BusPositionModel) then,
  ) = _$BusPositionModelCopyWithImpl<$Res, BusPositionModel>;
  @useResult
  $Res call({
    double latitude,
    double longitude,
    double bearing,
    String? currentLocation,
    String? nextStop,
    bool? isOnTime,
    int? delayMinutes,
    List<Map<String, dynamic>>? students,
  });
}

/// @nodoc
class _$BusPositionModelCopyWithImpl<$Res, $Val extends BusPositionModel>
    implements $BusPositionModelCopyWith<$Res> {
  _$BusPositionModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BusPositionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
    Object? bearing = null,
    Object? currentLocation = freezed,
    Object? nextStop = freezed,
    Object? isOnTime = freezed,
    Object? delayMinutes = freezed,
    Object? students = freezed,
  }) {
    return _then(
      _value.copyWith(
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
            bearing: null == bearing
                ? _value.bearing
                : bearing // ignore: cast_nullable_to_non_nullable
                      as double,
            currentLocation: freezed == currentLocation
                ? _value.currentLocation
                : currentLocation // ignore: cast_nullable_to_non_nullable
                      as String?,
            nextStop: freezed == nextStop
                ? _value.nextStop
                : nextStop // ignore: cast_nullable_to_non_nullable
                      as String?,
            isOnTime: freezed == isOnTime
                ? _value.isOnTime
                : isOnTime // ignore: cast_nullable_to_non_nullable
                      as bool?,
            delayMinutes: freezed == delayMinutes
                ? _value.delayMinutes
                : delayMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            students: freezed == students
                ? _value.students
                : students // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BusPositionModelImplCopyWith<$Res>
    implements $BusPositionModelCopyWith<$Res> {
  factory _$$BusPositionModelImplCopyWith(
    _$BusPositionModelImpl value,
    $Res Function(_$BusPositionModelImpl) then,
  ) = __$$BusPositionModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double latitude,
    double longitude,
    double bearing,
    String? currentLocation,
    String? nextStop,
    bool? isOnTime,
    int? delayMinutes,
    List<Map<String, dynamic>>? students,
  });
}

/// @nodoc
class __$$BusPositionModelImplCopyWithImpl<$Res>
    extends _$BusPositionModelCopyWithImpl<$Res, _$BusPositionModelImpl>
    implements _$$BusPositionModelImplCopyWith<$Res> {
  __$$BusPositionModelImplCopyWithImpl(
    _$BusPositionModelImpl _value,
    $Res Function(_$BusPositionModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusPositionModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? latitude = null,
    Object? longitude = null,
    Object? bearing = null,
    Object? currentLocation = freezed,
    Object? nextStop = freezed,
    Object? isOnTime = freezed,
    Object? delayMinutes = freezed,
    Object? students = freezed,
  }) {
    return _then(
      _$BusPositionModelImpl(
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        bearing: null == bearing
            ? _value.bearing
            : bearing // ignore: cast_nullable_to_non_nullable
                  as double,
        currentLocation: freezed == currentLocation
            ? _value.currentLocation
            : currentLocation // ignore: cast_nullable_to_non_nullable
                  as String?,
        nextStop: freezed == nextStop
            ? _value.nextStop
            : nextStop // ignore: cast_nullable_to_non_nullable
                  as String?,
        isOnTime: freezed == isOnTime
            ? _value.isOnTime
            : isOnTime // ignore: cast_nullable_to_non_nullable
                  as bool?,
        delayMinutes: freezed == delayMinutes
            ? _value.delayMinutes
            : delayMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        students: freezed == students
            ? _value._students
            : students // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BusPositionModelImpl extends _BusPositionModel {
  const _$BusPositionModelImpl({
    required this.latitude,
    required this.longitude,
    required this.bearing,
    this.currentLocation,
    this.nextStop,
    this.isOnTime,
    this.delayMinutes,
    final List<Map<String, dynamic>>? students,
  }) : _students = students,
       super._();

  factory _$BusPositionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BusPositionModelImplFromJson(json);

  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final double bearing;
  @override
  final String? currentLocation;
  @override
  final String? nextStop;
  @override
  final bool? isOnTime;
  @override
  final int? delayMinutes;
  final List<Map<String, dynamic>>? _students;
  @override
  List<Map<String, dynamic>>? get students {
    final value = _students;
    if (value == null) return null;
    if (_students is EqualUnmodifiableListView) return _students;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'BusPositionModel(latitude: $latitude, longitude: $longitude, bearing: $bearing, currentLocation: $currentLocation, nextStop: $nextStop, isOnTime: $isOnTime, delayMinutes: $delayMinutes, students: $students)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BusPositionModelImpl &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.bearing, bearing) || other.bearing == bearing) &&
            (identical(other.currentLocation, currentLocation) ||
                other.currentLocation == currentLocation) &&
            (identical(other.nextStop, nextStop) ||
                other.nextStop == nextStop) &&
            (identical(other.isOnTime, isOnTime) ||
                other.isOnTime == isOnTime) &&
            (identical(other.delayMinutes, delayMinutes) ||
                other.delayMinutes == delayMinutes) &&
            const DeepCollectionEquality().equals(other._students, _students));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    latitude,
    longitude,
    bearing,
    currentLocation,
    nextStop,
    isOnTime,
    delayMinutes,
    const DeepCollectionEquality().hash(_students),
  );

  /// Create a copy of BusPositionModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BusPositionModelImplCopyWith<_$BusPositionModelImpl> get copyWith =>
      __$$BusPositionModelImplCopyWithImpl<_$BusPositionModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BusPositionModelImplToJson(this);
  }
}

abstract class _BusPositionModel extends BusPositionModel {
  const factory _BusPositionModel({
    required final double latitude,
    required final double longitude,
    required final double bearing,
    final String? currentLocation,
    final String? nextStop,
    final bool? isOnTime,
    final int? delayMinutes,
    final List<Map<String, dynamic>>? students,
  }) = _$BusPositionModelImpl;
  const _BusPositionModel._() : super._();

  factory _BusPositionModel.fromJson(Map<String, dynamic> json) =
      _$BusPositionModelImpl.fromJson;

  @override
  double get latitude;
  @override
  double get longitude;
  @override
  double get bearing;
  @override
  String? get currentLocation;
  @override
  String? get nextStop;
  @override
  bool? get isOnTime;
  @override
  int? get delayMinutes;
  @override
  List<Map<String, dynamic>>? get students;

  /// Create a copy of BusPositionModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BusPositionModelImplCopyWith<_$BusPositionModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RouteStopModel _$RouteStopModelFromJson(Map<String, dynamic> json) {
  return _RouteStopModel.fromJson(json);
}

/// @nodoc
mixin _$RouteStopModel {
  String get name => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  int? get estimatedArrivalMinutes => throw _privateConstructorUsedError;
  int? get studentCount => throw _privateConstructorUsedError;
  int? get boardedStudentCount => throw _privateConstructorUsedError;
  String? get scheduledTime => throw _privateConstructorUsedError;

  /// Serializes this RouteStopModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RouteStopModelCopyWith<RouteStopModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RouteStopModelCopyWith<$Res> {
  factory $RouteStopModelCopyWith(
    RouteStopModel value,
    $Res Function(RouteStopModel) then,
  ) = _$RouteStopModelCopyWithImpl<$Res, RouteStopModel>;
  @useResult
  $Res call({
    String name,
    double latitude,
    double longitude,
    String type,
    int? estimatedArrivalMinutes,
    int? studentCount,
    int? boardedStudentCount,
    String? scheduledTime,
  });
}

/// @nodoc
class _$RouteStopModelCopyWithImpl<$Res, $Val extends RouteStopModel>
    implements $RouteStopModelCopyWith<$Res> {
  _$RouteStopModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? type = null,
    Object? estimatedArrivalMinutes = freezed,
    Object? studentCount = freezed,
    Object? boardedStudentCount = freezed,
    Object? scheduledTime = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String,
            estimatedArrivalMinutes: freezed == estimatedArrivalMinutes
                ? _value.estimatedArrivalMinutes
                : estimatedArrivalMinutes // ignore: cast_nullable_to_non_nullable
                      as int?,
            studentCount: freezed == studentCount
                ? _value.studentCount
                : studentCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            boardedStudentCount: freezed == boardedStudentCount
                ? _value.boardedStudentCount
                : boardedStudentCount // ignore: cast_nullable_to_non_nullable
                      as int?,
            scheduledTime: freezed == scheduledTime
                ? _value.scheduledTime
                : scheduledTime // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RouteStopModelImplCopyWith<$Res>
    implements $RouteStopModelCopyWith<$Res> {
  factory _$$RouteStopModelImplCopyWith(
    _$RouteStopModelImpl value,
    $Res Function(_$RouteStopModelImpl) then,
  ) = __$$RouteStopModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    double latitude,
    double longitude,
    String type,
    int? estimatedArrivalMinutes,
    int? studentCount,
    int? boardedStudentCount,
    String? scheduledTime,
  });
}

/// @nodoc
class __$$RouteStopModelImplCopyWithImpl<$Res>
    extends _$RouteStopModelCopyWithImpl<$Res, _$RouteStopModelImpl>
    implements _$$RouteStopModelImplCopyWith<$Res> {
  __$$RouteStopModelImplCopyWithImpl(
    _$RouteStopModelImpl _value,
    $Res Function(_$RouteStopModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? type = null,
    Object? estimatedArrivalMinutes = freezed,
    Object? studentCount = freezed,
    Object? boardedStudentCount = freezed,
    Object? scheduledTime = freezed,
  }) {
    return _then(
      _$RouteStopModelImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String,
        estimatedArrivalMinutes: freezed == estimatedArrivalMinutes
            ? _value.estimatedArrivalMinutes
            : estimatedArrivalMinutes // ignore: cast_nullable_to_non_nullable
                  as int?,
        studentCount: freezed == studentCount
            ? _value.studentCount
            : studentCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        boardedStudentCount: freezed == boardedStudentCount
            ? _value.boardedStudentCount
            : boardedStudentCount // ignore: cast_nullable_to_non_nullable
                  as int?,
        scheduledTime: freezed == scheduledTime
            ? _value.scheduledTime
            : scheduledTime // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RouteStopModelImpl extends _RouteStopModel {
  const _$RouteStopModelImpl({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.estimatedArrivalMinutes,
    this.studentCount,
    this.boardedStudentCount,
    this.scheduledTime,
  }) : super._();

  factory _$RouteStopModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RouteStopModelImplFromJson(json);

  @override
  final String name;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String type;
  @override
  final int? estimatedArrivalMinutes;
  @override
  final int? studentCount;
  @override
  final int? boardedStudentCount;
  @override
  final String? scheduledTime;

  @override
  String toString() {
    return 'RouteStopModel(name: $name, latitude: $latitude, longitude: $longitude, type: $type, estimatedArrivalMinutes: $estimatedArrivalMinutes, studentCount: $studentCount, boardedStudentCount: $boardedStudentCount, scheduledTime: $scheduledTime)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RouteStopModelImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(
                  other.estimatedArrivalMinutes,
                  estimatedArrivalMinutes,
                ) ||
                other.estimatedArrivalMinutes == estimatedArrivalMinutes) &&
            (identical(other.studentCount, studentCount) ||
                other.studentCount == studentCount) &&
            (identical(other.boardedStudentCount, boardedStudentCount) ||
                other.boardedStudentCount == boardedStudentCount) &&
            (identical(other.scheduledTime, scheduledTime) ||
                other.scheduledTime == scheduledTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    latitude,
    longitude,
    type,
    estimatedArrivalMinutes,
    studentCount,
    boardedStudentCount,
    scheduledTime,
  );

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RouteStopModelImplCopyWith<_$RouteStopModelImpl> get copyWith =>
      __$$RouteStopModelImplCopyWithImpl<_$RouteStopModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RouteStopModelImplToJson(this);
  }
}

abstract class _RouteStopModel extends RouteStopModel {
  const factory _RouteStopModel({
    required final String name,
    required final double latitude,
    required final double longitude,
    required final String type,
    final int? estimatedArrivalMinutes,
    final int? studentCount,
    final int? boardedStudentCount,
    final String? scheduledTime,
  }) = _$RouteStopModelImpl;
  const _RouteStopModel._() : super._();

  factory _RouteStopModel.fromJson(Map<String, dynamic> json) =
      _$RouteStopModelImpl.fromJson;

  @override
  String get name;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String get type;
  @override
  int? get estimatedArrivalMinutes;
  @override
  int? get studentCount;
  @override
  int? get boardedStudentCount;
  @override
  String? get scheduledTime;

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteStopModelImplCopyWith<_$RouteStopModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RoutePointModel {
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;

  /// Create a copy of RoutePointModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoutePointModelCopyWith<RoutePointModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoutePointModelCopyWith<$Res> {
  factory $RoutePointModelCopyWith(
    RoutePointModel value,
    $Res Function(RoutePointModel) then,
  ) = _$RoutePointModelCopyWithImpl<$Res, RoutePointModel>;
  @useResult
  $Res call({double latitude, double longitude});
}

/// @nodoc
class _$RoutePointModelCopyWithImpl<$Res, $Val extends RoutePointModel>
    implements $RoutePointModelCopyWith<$Res> {
  _$RoutePointModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoutePointModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? latitude = null, Object? longitude = null}) {
    return _then(
      _value.copyWith(
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RoutePointModelImplCopyWith<$Res>
    implements $RoutePointModelCopyWith<$Res> {
  factory _$$RoutePointModelImplCopyWith(
    _$RoutePointModelImpl value,
    $Res Function(_$RoutePointModelImpl) then,
  ) = __$$RoutePointModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double latitude, double longitude});
}

/// @nodoc
class __$$RoutePointModelImplCopyWithImpl<$Res>
    extends _$RoutePointModelCopyWithImpl<$Res, _$RoutePointModelImpl>
    implements _$$RoutePointModelImplCopyWith<$Res> {
  __$$RoutePointModelImplCopyWithImpl(
    _$RoutePointModelImpl _value,
    $Res Function(_$RoutePointModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RoutePointModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? latitude = null, Object? longitude = null}) {
    return _then(
      _$RoutePointModelImpl(
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc

class _$RoutePointModelImpl extends _RoutePointModel {
  const _$RoutePointModelImpl({required this.latitude, required this.longitude})
    : super._();

  @override
  final double latitude;
  @override
  final double longitude;

  @override
  String toString() {
    return 'RoutePointModel(latitude: $latitude, longitude: $longitude)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoutePointModelImpl &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude));
  }

  @override
  int get hashCode => Object.hash(runtimeType, latitude, longitude);

  /// Create a copy of RoutePointModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoutePointModelImplCopyWith<_$RoutePointModelImpl> get copyWith =>
      __$$RoutePointModelImplCopyWithImpl<_$RoutePointModelImpl>(
        this,
        _$identity,
      );
}

abstract class _RoutePointModel extends RoutePointModel {
  const factory _RoutePointModel({
    required final double latitude,
    required final double longitude,
  }) = _$RoutePointModelImpl;
  const _RoutePointModel._() : super._();

  @override
  double get latitude;
  @override
  double get longitude;

  /// Create a copy of RoutePointModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoutePointModelImplCopyWith<_$RoutePointModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BusSummaryModel {
  String get id => throw _privateConstructorUsedError;
  String get busNumber => throw _privateConstructorUsedError;
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  bool get isDelayed => throw _privateConstructorUsedError;
  List<RouteStopModel>? get routeStops => throw _privateConstructorUsedError;

  /// Create a copy of BusSummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BusSummaryModelCopyWith<BusSummaryModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BusSummaryModelCopyWith<$Res> {
  factory $BusSummaryModelCopyWith(
    BusSummaryModel value,
    $Res Function(BusSummaryModel) then,
  ) = _$BusSummaryModelCopyWithImpl<$Res, BusSummaryModel>;
  @useResult
  $Res call({
    String id,
    String busNumber,
    double latitude,
    double longitude,
    String status,
    bool isDelayed,
    List<RouteStopModel>? routeStops,
  });
}

/// @nodoc
class _$BusSummaryModelCopyWithImpl<$Res, $Val extends BusSummaryModel>
    implements $BusSummaryModelCopyWith<$Res> {
  _$BusSummaryModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BusSummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? busNumber = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? status = null,
    Object? isDelayed = null,
    Object? routeStops = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            busNumber: null == busNumber
                ? _value.busNumber
                : busNumber // ignore: cast_nullable_to_non_nullable
                      as String,
            latitude: null == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double,
            longitude: null == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            isDelayed: null == isDelayed
                ? _value.isDelayed
                : isDelayed // ignore: cast_nullable_to_non_nullable
                      as bool,
            routeStops: freezed == routeStops
                ? _value.routeStops
                : routeStops // ignore: cast_nullable_to_non_nullable
                      as List<RouteStopModel>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BusSummaryModelImplCopyWith<$Res>
    implements $BusSummaryModelCopyWith<$Res> {
  factory _$$BusSummaryModelImplCopyWith(
    _$BusSummaryModelImpl value,
    $Res Function(_$BusSummaryModelImpl) then,
  ) = __$$BusSummaryModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String busNumber,
    double latitude,
    double longitude,
    String status,
    bool isDelayed,
    List<RouteStopModel>? routeStops,
  });
}

/// @nodoc
class __$$BusSummaryModelImplCopyWithImpl<$Res>
    extends _$BusSummaryModelCopyWithImpl<$Res, _$BusSummaryModelImpl>
    implements _$$BusSummaryModelImplCopyWith<$Res> {
  __$$BusSummaryModelImplCopyWithImpl(
    _$BusSummaryModelImpl _value,
    $Res Function(_$BusSummaryModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusSummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? busNumber = null,
    Object? latitude = null,
    Object? longitude = null,
    Object? status = null,
    Object? isDelayed = null,
    Object? routeStops = freezed,
  }) {
    return _then(
      _$BusSummaryModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        busNumber: null == busNumber
            ? _value.busNumber
            : busNumber // ignore: cast_nullable_to_non_nullable
                  as String,
        latitude: null == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double,
        longitude: null == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        isDelayed: null == isDelayed
            ? _value.isDelayed
            : isDelayed // ignore: cast_nullable_to_non_nullable
                  as bool,
        routeStops: freezed == routeStops
            ? _value._routeStops
            : routeStops // ignore: cast_nullable_to_non_nullable
                  as List<RouteStopModel>?,
      ),
    );
  }
}

/// @nodoc

class _$BusSummaryModelImpl extends _BusSummaryModel {
  const _$BusSummaryModelImpl({
    required this.id,
    required this.busNumber,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.isDelayed,
    final List<RouteStopModel>? routeStops,
  }) : _routeStops = routeStops,
       super._();

  @override
  final String id;
  @override
  final String busNumber;
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final String status;
  @override
  final bool isDelayed;
  final List<RouteStopModel>? _routeStops;
  @override
  List<RouteStopModel>? get routeStops {
    final value = _routeStops;
    if (value == null) return null;
    if (_routeStops is EqualUnmodifiableListView) return _routeStops;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'BusSummaryModel(id: $id, busNumber: $busNumber, latitude: $latitude, longitude: $longitude, status: $status, isDelayed: $isDelayed, routeStops: $routeStops)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BusSummaryModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.busNumber, busNumber) ||
                other.busNumber == busNumber) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.isDelayed, isDelayed) ||
                other.isDelayed == isDelayed) &&
            const DeepCollectionEquality().equals(
              other._routeStops,
              _routeStops,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    busNumber,
    latitude,
    longitude,
    status,
    isDelayed,
    const DeepCollectionEquality().hash(_routeStops),
  );

  /// Create a copy of BusSummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BusSummaryModelImplCopyWith<_$BusSummaryModelImpl> get copyWith =>
      __$$BusSummaryModelImplCopyWithImpl<_$BusSummaryModelImpl>(
        this,
        _$identity,
      );
}

abstract class _BusSummaryModel extends BusSummaryModel {
  const factory _BusSummaryModel({
    required final String id,
    required final String busNumber,
    required final double latitude,
    required final double longitude,
    required final String status,
    required final bool isDelayed,
    final List<RouteStopModel>? routeStops,
  }) = _$BusSummaryModelImpl;
  const _BusSummaryModel._() : super._();

  @override
  String get id;
  @override
  String get busNumber;
  @override
  double get latitude;
  @override
  double get longitude;
  @override
  String get status;
  @override
  bool get isDelayed;
  @override
  List<RouteStopModel>? get routeStops;

  /// Create a copy of BusSummaryModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BusSummaryModelImplCopyWith<_$BusSummaryModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
