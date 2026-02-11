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

BusRouteModel _$BusRouteModelFromJson(Map<String, dynamic> json) {
  return _BusRouteModel.fromJson(json);
}

/// @nodoc
mixin _$BusRouteModel {
  String get busNumber => throw _privateConstructorUsedError;
  String get currentLocation => throw _privateConstructorUsedError;
  String get nextStop => throw _privateConstructorUsedError;
  int get arrivalTimeMinutes => throw _privateConstructorUsedError;
  double get distanceKm => throw _privateConstructorUsedError;
  bool get isOnTime => throw _privateConstructorUsedError;
  String get driverPhone => throw _privateConstructorUsedError;
  BusPositionModel get busPosition => throw _privateConstructorUsedError;
  List<RouteStopModel> get stops => throw _privateConstructorUsedError;
  List<RoutePointModel> get routePath => throw _privateConstructorUsedError;

  /// Serializes this BusRouteModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

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
    String busNumber,
    String currentLocation,
    String nextStop,
    int arrivalTimeMinutes,
    double distanceKm,
    bool isOnTime,
    String driverPhone,
    BusPositionModel busPosition,
    List<RouteStopModel> stops,
    List<RoutePointModel> routePath,
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
    Object? busNumber = null,
    Object? currentLocation = null,
    Object? nextStop = null,
    Object? arrivalTimeMinutes = null,
    Object? distanceKm = null,
    Object? isOnTime = null,
    Object? driverPhone = null,
    Object? busPosition = null,
    Object? stops = null,
    Object? routePath = null,
  }) {
    return _then(
      _value.copyWith(
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
    String busNumber,
    String currentLocation,
    String nextStop,
    int arrivalTimeMinutes,
    double distanceKm,
    bool isOnTime,
    String driverPhone,
    BusPositionModel busPosition,
    List<RouteStopModel> stops,
    List<RoutePointModel> routePath,
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
    Object? busNumber = null,
    Object? currentLocation = null,
    Object? nextStop = null,
    Object? arrivalTimeMinutes = null,
    Object? distanceKm = null,
    Object? isOnTime = null,
    Object? driverPhone = null,
    Object? busPosition = null,
    Object? stops = null,
    Object? routePath = null,
  }) {
    return _then(
      _$BusRouteModelImpl(
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BusRouteModelImpl extends _BusRouteModel {
  const _$BusRouteModelImpl({
    required this.busNumber,
    required this.currentLocation,
    required this.nextStop,
    required this.arrivalTimeMinutes,
    required this.distanceKm,
    required this.isOnTime,
    required this.driverPhone,
    required this.busPosition,
    required final List<RouteStopModel> stops,
    required final List<RoutePointModel> routePath,
  }) : _stops = stops,
       _routePath = routePath,
       super._();

  factory _$BusRouteModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BusRouteModelImplFromJson(json);

  @override
  final String busNumber;
  @override
  final String currentLocation;
  @override
  final String nextStop;
  @override
  final int arrivalTimeMinutes;
  @override
  final double distanceKm;
  @override
  final bool isOnTime;
  @override
  final String driverPhone;
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
  String toString() {
    return 'BusRouteModel(busNumber: $busNumber, currentLocation: $currentLocation, nextStop: $nextStop, arrivalTimeMinutes: $arrivalTimeMinutes, distanceKm: $distanceKm, isOnTime: $isOnTime, driverPhone: $driverPhone, busPosition: $busPosition, stops: $stops, routePath: $routePath)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BusRouteModelImpl &&
            (identical(other.busNumber, busNumber) ||
                other.busNumber == busNumber) &&
            (identical(other.currentLocation, currentLocation) ||
                other.currentLocation == currentLocation) &&
            (identical(other.nextStop, nextStop) ||
                other.nextStop == nextStop) &&
            (identical(other.arrivalTimeMinutes, arrivalTimeMinutes) ||
                other.arrivalTimeMinutes == arrivalTimeMinutes) &&
            (identical(other.distanceKm, distanceKm) ||
                other.distanceKm == distanceKm) &&
            (identical(other.isOnTime, isOnTime) ||
                other.isOnTime == isOnTime) &&
            (identical(other.driverPhone, driverPhone) ||
                other.driverPhone == driverPhone) &&
            (identical(other.busPosition, busPosition) ||
                other.busPosition == busPosition) &&
            const DeepCollectionEquality().equals(other._stops, _stops) &&
            const DeepCollectionEquality().equals(
              other._routePath,
              _routePath,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    busNumber,
    currentLocation,
    nextStop,
    arrivalTimeMinutes,
    distanceKm,
    isOnTime,
    driverPhone,
    busPosition,
    const DeepCollectionEquality().hash(_stops),
    const DeepCollectionEquality().hash(_routePath),
  );

  /// Create a copy of BusRouteModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BusRouteModelImplCopyWith<_$BusRouteModelImpl> get copyWith =>
      __$$BusRouteModelImplCopyWithImpl<_$BusRouteModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BusRouteModelImplToJson(this);
  }
}

abstract class _BusRouteModel extends BusRouteModel {
  const factory _BusRouteModel({
    required final String busNumber,
    required final String currentLocation,
    required final String nextStop,
    required final int arrivalTimeMinutes,
    required final double distanceKm,
    required final bool isOnTime,
    required final String driverPhone,
    required final BusPositionModel busPosition,
    required final List<RouteStopModel> stops,
    required final List<RoutePointModel> routePath,
  }) = _$BusRouteModelImpl;
  const _BusRouteModel._() : super._();

  factory _BusRouteModel.fromJson(Map<String, dynamic> json) =
      _$BusRouteModelImpl.fromJson;

  @override
  String get busNumber;
  @override
  String get currentLocation;
  @override
  String get nextStop;
  @override
  int get arrivalTimeMinutes;
  @override
  double get distanceKm;
  @override
  bool get isOnTime;
  @override
  String get driverPhone;
  @override
  BusPositionModel get busPosition;
  @override
  List<RouteStopModel> get stops;
  @override
  List<RoutePointModel> get routePath;

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
  $Res call({double latitude, double longitude, double bearing});
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
  $Res call({double latitude, double longitude, double bearing});
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
  }) : super._();

  factory _$BusPositionModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$BusPositionModelImplFromJson(json);

  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final double bearing;

  @override
  String toString() {
    return 'BusPositionModel(latitude: $latitude, longitude: $longitude, bearing: $bearing)';
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
            (identical(other.bearing, bearing) || other.bearing == bearing));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, latitude, longitude, bearing);

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
  String toString() {
    return 'RouteStopModel(name: $name, latitude: $latitude, longitude: $longitude, type: $type, estimatedArrivalMinutes: $estimatedArrivalMinutes)';
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
                other.estimatedArrivalMinutes == estimatedArrivalMinutes));
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

  /// Create a copy of RouteStopModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RouteStopModelImplCopyWith<_$RouteStopModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoutePointModel _$RoutePointModelFromJson(Map<String, dynamic> json) {
  return _RoutePointModel.fromJson(json);
}

/// @nodoc
mixin _$RoutePointModel {
  double get latitude => throw _privateConstructorUsedError;
  double get longitude => throw _privateConstructorUsedError;

  /// Serializes this RoutePointModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

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
@JsonSerializable()
class _$RoutePointModelImpl extends _RoutePointModel {
  const _$RoutePointModelImpl({required this.latitude, required this.longitude})
    : super._();

  factory _$RoutePointModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoutePointModelImplFromJson(json);

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

  @JsonKey(includeFromJson: false, includeToJson: false)
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

  @override
  Map<String, dynamic> toJson() {
    return _$$RoutePointModelImplToJson(this);
  }
}

abstract class _RoutePointModel extends RoutePointModel {
  const factory _RoutePointModel({
    required final double latitude,
    required final double longitude,
  }) = _$RoutePointModelImpl;
  const _RoutePointModel._() : super._();

  factory _RoutePointModel.fromJson(Map<String, dynamic> json) =
      _$RoutePointModelImpl.fromJson;

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
