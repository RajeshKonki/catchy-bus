// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bus_tracking_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BusTrackingState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(BusRoute busRoute) loaded,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(BusRoute busRoute)? loaded,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(BusRoute busRoute)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BusTrackingStateCopyWith<$Res> {
  factory $BusTrackingStateCopyWith(
    BusTrackingState value,
    $Res Function(BusTrackingState) then,
  ) = _$BusTrackingStateCopyWithImpl<$Res, BusTrackingState>;
}

/// @nodoc
class _$BusTrackingStateCopyWithImpl<$Res, $Val extends BusTrackingState>
    implements $BusTrackingStateCopyWith<$Res> {
  _$BusTrackingStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BusTrackingState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
    _$InitialImpl value,
    $Res Function(_$InitialImpl) then,
  ) = __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$BusTrackingStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
    _$InitialImpl _value,
    $Res Function(_$InitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusTrackingState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'BusTrackingState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(BusRoute busRoute) loaded,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(BusRoute busRoute)? loaded,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(BusRoute busRoute)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements BusTrackingState {
  const factory _Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
    _$LoadingImpl value,
    $Res Function(_$LoadingImpl) then,
  ) = __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$BusTrackingStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
    _$LoadingImpl _value,
    $Res Function(_$LoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusTrackingState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'BusTrackingState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(BusRoute busRoute) loaded,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(BusRoute busRoute)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(BusRoute busRoute)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements BusTrackingState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$LoadedImplCopyWith<$Res> {
  factory _$$LoadedImplCopyWith(
    _$LoadedImpl value,
    $Res Function(_$LoadedImpl) then,
  ) = __$$LoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({BusRoute busRoute});
}

/// @nodoc
class __$$LoadedImplCopyWithImpl<$Res>
    extends _$BusTrackingStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
    _$LoadedImpl _value,
    $Res Function(_$LoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusTrackingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? busRoute = null}) {
    return _then(
      _$LoadedImpl(
        null == busRoute
            ? _value.busRoute
            : busRoute // ignore: cast_nullable_to_non_nullable
                  as BusRoute,
      ),
    );
  }
}

/// @nodoc

class _$LoadedImpl implements _Loaded {
  const _$LoadedImpl(this.busRoute);

  @override
  final BusRoute busRoute;

  @override
  String toString() {
    return 'BusTrackingState.loaded(busRoute: $busRoute)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadedImpl &&
            (identical(other.busRoute, busRoute) ||
                other.busRoute == busRoute));
  }

  @override
  int get hashCode => Object.hash(runtimeType, busRoute);

  /// Create a copy of BusTrackingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      __$$LoadedImplCopyWithImpl<_$LoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(BusRoute busRoute) loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(busRoute);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(BusRoute busRoute)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(busRoute);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(BusRoute busRoute)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(busRoute);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _Loaded implements BusTrackingState {
  const factory _Loaded(final BusRoute busRoute) = _$LoadedImpl;

  BusRoute get busRoute;

  /// Create a copy of BusTrackingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
    _$ErrorImpl value,
    $Res Function(_$ErrorImpl) then,
  ) = __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$BusTrackingStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
    _$ErrorImpl _value,
    $Res Function(_$ErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusTrackingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$ErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'BusTrackingState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of BusTrackingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(BusRoute busRoute) loaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(BusRoute busRoute)? loaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(BusRoute busRoute)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements BusTrackingState {
  const factory _Error(final String message) = _$ErrorImpl;

  String get message;

  /// Create a copy of BusTrackingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$BusListState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<BusSummary> buses) loaded,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<BusSummary> buses)? loaded,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<BusSummary> buses)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_BusListInitial value) initial,
    required TResult Function(_BusListLoading value) loading,
    required TResult Function(_BusListLoaded value) loaded,
    required TResult Function(_BusListError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_BusListInitial value)? initial,
    TResult? Function(_BusListLoading value)? loading,
    TResult? Function(_BusListLoaded value)? loaded,
    TResult? Function(_BusListError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_BusListInitial value)? initial,
    TResult Function(_BusListLoading value)? loading,
    TResult Function(_BusListLoaded value)? loaded,
    TResult Function(_BusListError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BusListStateCopyWith<$Res> {
  factory $BusListStateCopyWith(
    BusListState value,
    $Res Function(BusListState) then,
  ) = _$BusListStateCopyWithImpl<$Res, BusListState>;
}

/// @nodoc
class _$BusListStateCopyWithImpl<$Res, $Val extends BusListState>
    implements $BusListStateCopyWith<$Res> {
  _$BusListStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BusListState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$BusListInitialImplCopyWith<$Res> {
  factory _$$BusListInitialImplCopyWith(
    _$BusListInitialImpl value,
    $Res Function(_$BusListInitialImpl) then,
  ) = __$$BusListInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$BusListInitialImplCopyWithImpl<$Res>
    extends _$BusListStateCopyWithImpl<$Res, _$BusListInitialImpl>
    implements _$$BusListInitialImplCopyWith<$Res> {
  __$$BusListInitialImplCopyWithImpl(
    _$BusListInitialImpl _value,
    $Res Function(_$BusListInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusListState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$BusListInitialImpl implements _BusListInitial {
  const _$BusListInitialImpl();

  @override
  String toString() {
    return 'BusListState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$BusListInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<BusSummary> buses) loaded,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<BusSummary> buses)? loaded,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<BusSummary> buses)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_BusListInitial value) initial,
    required TResult Function(_BusListLoading value) loading,
    required TResult Function(_BusListLoaded value) loaded,
    required TResult Function(_BusListError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_BusListInitial value)? initial,
    TResult? Function(_BusListLoading value)? loading,
    TResult? Function(_BusListLoaded value)? loaded,
    TResult? Function(_BusListError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_BusListInitial value)? initial,
    TResult Function(_BusListLoading value)? loading,
    TResult Function(_BusListLoaded value)? loaded,
    TResult Function(_BusListError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _BusListInitial implements BusListState {
  const factory _BusListInitial() = _$BusListInitialImpl;
}

/// @nodoc
abstract class _$$BusListLoadingImplCopyWith<$Res> {
  factory _$$BusListLoadingImplCopyWith(
    _$BusListLoadingImpl value,
    $Res Function(_$BusListLoadingImpl) then,
  ) = __$$BusListLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$BusListLoadingImplCopyWithImpl<$Res>
    extends _$BusListStateCopyWithImpl<$Res, _$BusListLoadingImpl>
    implements _$$BusListLoadingImplCopyWith<$Res> {
  __$$BusListLoadingImplCopyWithImpl(
    _$BusListLoadingImpl _value,
    $Res Function(_$BusListLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusListState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$BusListLoadingImpl implements _BusListLoading {
  const _$BusListLoadingImpl();

  @override
  String toString() {
    return 'BusListState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$BusListLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<BusSummary> buses) loaded,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<BusSummary> buses)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<BusSummary> buses)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_BusListInitial value) initial,
    required TResult Function(_BusListLoading value) loading,
    required TResult Function(_BusListLoaded value) loaded,
    required TResult Function(_BusListError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_BusListInitial value)? initial,
    TResult? Function(_BusListLoading value)? loading,
    TResult? Function(_BusListLoaded value)? loaded,
    TResult? Function(_BusListError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_BusListInitial value)? initial,
    TResult Function(_BusListLoading value)? loading,
    TResult Function(_BusListLoaded value)? loaded,
    TResult Function(_BusListError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _BusListLoading implements BusListState {
  const factory _BusListLoading() = _$BusListLoadingImpl;
}

/// @nodoc
abstract class _$$BusListLoadedImplCopyWith<$Res> {
  factory _$$BusListLoadedImplCopyWith(
    _$BusListLoadedImpl value,
    $Res Function(_$BusListLoadedImpl) then,
  ) = __$$BusListLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<BusSummary> buses});
}

/// @nodoc
class __$$BusListLoadedImplCopyWithImpl<$Res>
    extends _$BusListStateCopyWithImpl<$Res, _$BusListLoadedImpl>
    implements _$$BusListLoadedImplCopyWith<$Res> {
  __$$BusListLoadedImplCopyWithImpl(
    _$BusListLoadedImpl _value,
    $Res Function(_$BusListLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? buses = null}) {
    return _then(
      _$BusListLoadedImpl(
        null == buses
            ? _value._buses
            : buses // ignore: cast_nullable_to_non_nullable
                  as List<BusSummary>,
      ),
    );
  }
}

/// @nodoc

class _$BusListLoadedImpl implements _BusListLoaded {
  const _$BusListLoadedImpl(final List<BusSummary> buses) : _buses = buses;

  final List<BusSummary> _buses;
  @override
  List<BusSummary> get buses {
    if (_buses is EqualUnmodifiableListView) return _buses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_buses);
  }

  @override
  String toString() {
    return 'BusListState.loaded(buses: $buses)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BusListLoadedImpl &&
            const DeepCollectionEquality().equals(other._buses, _buses));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_buses));

  /// Create a copy of BusListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BusListLoadedImplCopyWith<_$BusListLoadedImpl> get copyWith =>
      __$$BusListLoadedImplCopyWithImpl<_$BusListLoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<BusSummary> buses) loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(buses);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<BusSummary> buses)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(buses);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<BusSummary> buses)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(buses);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_BusListInitial value) initial,
    required TResult Function(_BusListLoading value) loading,
    required TResult Function(_BusListLoaded value) loaded,
    required TResult Function(_BusListError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_BusListInitial value)? initial,
    TResult? Function(_BusListLoading value)? loading,
    TResult? Function(_BusListLoaded value)? loaded,
    TResult? Function(_BusListError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_BusListInitial value)? initial,
    TResult Function(_BusListLoading value)? loading,
    TResult Function(_BusListLoaded value)? loaded,
    TResult Function(_BusListError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _BusListLoaded implements BusListState {
  const factory _BusListLoaded(final List<BusSummary> buses) =
      _$BusListLoadedImpl;

  List<BusSummary> get buses;

  /// Create a copy of BusListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BusListLoadedImplCopyWith<_$BusListLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$BusListErrorImplCopyWith<$Res> {
  factory _$$BusListErrorImplCopyWith(
    _$BusListErrorImpl value,
    $Res Function(_$BusListErrorImpl) then,
  ) = __$$BusListErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$BusListErrorImplCopyWithImpl<$Res>
    extends _$BusListStateCopyWithImpl<$Res, _$BusListErrorImpl>
    implements _$$BusListErrorImplCopyWith<$Res> {
  __$$BusListErrorImplCopyWithImpl(
    _$BusListErrorImpl _value,
    $Res Function(_$BusListErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BusListState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$BusListErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$BusListErrorImpl implements _BusListError {
  const _$BusListErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'BusListState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BusListErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of BusListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BusListErrorImplCopyWith<_$BusListErrorImpl> get copyWith =>
      __$$BusListErrorImplCopyWithImpl<_$BusListErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<BusSummary> buses) loaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<BusSummary> buses)? loaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<BusSummary> buses)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_BusListInitial value) initial,
    required TResult Function(_BusListLoading value) loading,
    required TResult Function(_BusListLoaded value) loaded,
    required TResult Function(_BusListError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_BusListInitial value)? initial,
    TResult? Function(_BusListLoading value)? loading,
    TResult? Function(_BusListLoaded value)? loaded,
    TResult? Function(_BusListError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_BusListInitial value)? initial,
    TResult Function(_BusListLoading value)? loading,
    TResult Function(_BusListLoaded value)? loaded,
    TResult Function(_BusListError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _BusListError implements BusListState {
  const factory _BusListError(final String message) = _$BusListErrorImpl;

  String get message;

  /// Create a copy of BusListState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BusListErrorImplCopyWith<_$BusListErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CollegeStopsState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<RouteStop> stops) loaded,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<RouteStop> stops)? loaded,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<RouteStop> stops)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CollegeStopsInitial value) initial,
    required TResult Function(_CollegeStopsLoading value) loading,
    required TResult Function(_CollegeStopsLoaded value) loaded,
    required TResult Function(_CollegeStopsError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CollegeStopsInitial value)? initial,
    TResult? Function(_CollegeStopsLoading value)? loading,
    TResult? Function(_CollegeStopsLoaded value)? loaded,
    TResult? Function(_CollegeStopsError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CollegeStopsInitial value)? initial,
    TResult Function(_CollegeStopsLoading value)? loading,
    TResult Function(_CollegeStopsLoaded value)? loaded,
    TResult Function(_CollegeStopsError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CollegeStopsStateCopyWith<$Res> {
  factory $CollegeStopsStateCopyWith(
    CollegeStopsState value,
    $Res Function(CollegeStopsState) then,
  ) = _$CollegeStopsStateCopyWithImpl<$Res, CollegeStopsState>;
}

/// @nodoc
class _$CollegeStopsStateCopyWithImpl<$Res, $Val extends CollegeStopsState>
    implements $CollegeStopsStateCopyWith<$Res> {
  _$CollegeStopsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CollegeStopsState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$CollegeStopsInitialImplCopyWith<$Res> {
  factory _$$CollegeStopsInitialImplCopyWith(
    _$CollegeStopsInitialImpl value,
    $Res Function(_$CollegeStopsInitialImpl) then,
  ) = __$$CollegeStopsInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CollegeStopsInitialImplCopyWithImpl<$Res>
    extends _$CollegeStopsStateCopyWithImpl<$Res, _$CollegeStopsInitialImpl>
    implements _$$CollegeStopsInitialImplCopyWith<$Res> {
  __$$CollegeStopsInitialImplCopyWithImpl(
    _$CollegeStopsInitialImpl _value,
    $Res Function(_$CollegeStopsInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollegeStopsState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$CollegeStopsInitialImpl implements _CollegeStopsInitial {
  const _$CollegeStopsInitialImpl();

  @override
  String toString() {
    return 'CollegeStopsState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollegeStopsInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<RouteStop> stops) loaded,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<RouteStop> stops)? loaded,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<RouteStop> stops)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CollegeStopsInitial value) initial,
    required TResult Function(_CollegeStopsLoading value) loading,
    required TResult Function(_CollegeStopsLoaded value) loaded,
    required TResult Function(_CollegeStopsError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CollegeStopsInitial value)? initial,
    TResult? Function(_CollegeStopsLoading value)? loading,
    TResult? Function(_CollegeStopsLoaded value)? loaded,
    TResult? Function(_CollegeStopsError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CollegeStopsInitial value)? initial,
    TResult Function(_CollegeStopsLoading value)? loading,
    TResult Function(_CollegeStopsLoaded value)? loaded,
    TResult Function(_CollegeStopsError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _CollegeStopsInitial implements CollegeStopsState {
  const factory _CollegeStopsInitial() = _$CollegeStopsInitialImpl;
}

/// @nodoc
abstract class _$$CollegeStopsLoadingImplCopyWith<$Res> {
  factory _$$CollegeStopsLoadingImplCopyWith(
    _$CollegeStopsLoadingImpl value,
    $Res Function(_$CollegeStopsLoadingImpl) then,
  ) = __$$CollegeStopsLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$CollegeStopsLoadingImplCopyWithImpl<$Res>
    extends _$CollegeStopsStateCopyWithImpl<$Res, _$CollegeStopsLoadingImpl>
    implements _$$CollegeStopsLoadingImplCopyWith<$Res> {
  __$$CollegeStopsLoadingImplCopyWithImpl(
    _$CollegeStopsLoadingImpl _value,
    $Res Function(_$CollegeStopsLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollegeStopsState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$CollegeStopsLoadingImpl implements _CollegeStopsLoading {
  const _$CollegeStopsLoadingImpl();

  @override
  String toString() {
    return 'CollegeStopsState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollegeStopsLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<RouteStop> stops) loaded,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<RouteStop> stops)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<RouteStop> stops)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CollegeStopsInitial value) initial,
    required TResult Function(_CollegeStopsLoading value) loading,
    required TResult Function(_CollegeStopsLoaded value) loaded,
    required TResult Function(_CollegeStopsError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CollegeStopsInitial value)? initial,
    TResult? Function(_CollegeStopsLoading value)? loading,
    TResult? Function(_CollegeStopsLoaded value)? loaded,
    TResult? Function(_CollegeStopsError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CollegeStopsInitial value)? initial,
    TResult Function(_CollegeStopsLoading value)? loading,
    TResult Function(_CollegeStopsLoaded value)? loaded,
    TResult Function(_CollegeStopsError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _CollegeStopsLoading implements CollegeStopsState {
  const factory _CollegeStopsLoading() = _$CollegeStopsLoadingImpl;
}

/// @nodoc
abstract class _$$CollegeStopsLoadedImplCopyWith<$Res> {
  factory _$$CollegeStopsLoadedImplCopyWith(
    _$CollegeStopsLoadedImpl value,
    $Res Function(_$CollegeStopsLoadedImpl) then,
  ) = __$$CollegeStopsLoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({List<RouteStop> stops});
}

/// @nodoc
class __$$CollegeStopsLoadedImplCopyWithImpl<$Res>
    extends _$CollegeStopsStateCopyWithImpl<$Res, _$CollegeStopsLoadedImpl>
    implements _$$CollegeStopsLoadedImplCopyWith<$Res> {
  __$$CollegeStopsLoadedImplCopyWithImpl(
    _$CollegeStopsLoadedImpl _value,
    $Res Function(_$CollegeStopsLoadedImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollegeStopsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? stops = null}) {
    return _then(
      _$CollegeStopsLoadedImpl(
        null == stops
            ? _value._stops
            : stops // ignore: cast_nullable_to_non_nullable
                  as List<RouteStop>,
      ),
    );
  }
}

/// @nodoc

class _$CollegeStopsLoadedImpl implements _CollegeStopsLoaded {
  const _$CollegeStopsLoadedImpl(final List<RouteStop> stops) : _stops = stops;

  final List<RouteStop> _stops;
  @override
  List<RouteStop> get stops {
    if (_stops is EqualUnmodifiableListView) return _stops;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stops);
  }

  @override
  String toString() {
    return 'CollegeStopsState.loaded(stops: $stops)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollegeStopsLoadedImpl &&
            const DeepCollectionEquality().equals(other._stops, _stops));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_stops));

  /// Create a copy of CollegeStopsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollegeStopsLoadedImplCopyWith<_$CollegeStopsLoadedImpl> get copyWith =>
      __$$CollegeStopsLoadedImplCopyWithImpl<_$CollegeStopsLoadedImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<RouteStop> stops) loaded,
    required TResult Function(String message) error,
  }) {
    return loaded(stops);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<RouteStop> stops)? loaded,
    TResult? Function(String message)? error,
  }) {
    return loaded?.call(stops);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<RouteStop> stops)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(stops);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CollegeStopsInitial value) initial,
    required TResult Function(_CollegeStopsLoading value) loading,
    required TResult Function(_CollegeStopsLoaded value) loaded,
    required TResult Function(_CollegeStopsError value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CollegeStopsInitial value)? initial,
    TResult? Function(_CollegeStopsLoading value)? loading,
    TResult? Function(_CollegeStopsLoaded value)? loaded,
    TResult? Function(_CollegeStopsError value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CollegeStopsInitial value)? initial,
    TResult Function(_CollegeStopsLoading value)? loading,
    TResult Function(_CollegeStopsLoaded value)? loaded,
    TResult Function(_CollegeStopsError value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _CollegeStopsLoaded implements CollegeStopsState {
  const factory _CollegeStopsLoaded(final List<RouteStop> stops) =
      _$CollegeStopsLoadedImpl;

  List<RouteStop> get stops;

  /// Create a copy of CollegeStopsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollegeStopsLoadedImplCopyWith<_$CollegeStopsLoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$CollegeStopsErrorImplCopyWith<$Res> {
  factory _$$CollegeStopsErrorImplCopyWith(
    _$CollegeStopsErrorImpl value,
    $Res Function(_$CollegeStopsErrorImpl) then,
  ) = __$$CollegeStopsErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$CollegeStopsErrorImplCopyWithImpl<$Res>
    extends _$CollegeStopsStateCopyWithImpl<$Res, _$CollegeStopsErrorImpl>
    implements _$$CollegeStopsErrorImplCopyWith<$Res> {
  __$$CollegeStopsErrorImplCopyWithImpl(
    _$CollegeStopsErrorImpl _value,
    $Res Function(_$CollegeStopsErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CollegeStopsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$CollegeStopsErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$CollegeStopsErrorImpl implements _CollegeStopsError {
  const _$CollegeStopsErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'CollegeStopsState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CollegeStopsErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of CollegeStopsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CollegeStopsErrorImplCopyWith<_$CollegeStopsErrorImpl> get copyWith =>
      __$$CollegeStopsErrorImplCopyWithImpl<_$CollegeStopsErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(List<RouteStop> stops) loaded,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(List<RouteStop> stops)? loaded,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(List<RouteStop> stops)? loaded,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_CollegeStopsInitial value) initial,
    required TResult Function(_CollegeStopsLoading value) loading,
    required TResult Function(_CollegeStopsLoaded value) loaded,
    required TResult Function(_CollegeStopsError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_CollegeStopsInitial value)? initial,
    TResult? Function(_CollegeStopsLoading value)? loading,
    TResult? Function(_CollegeStopsLoaded value)? loaded,
    TResult? Function(_CollegeStopsError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_CollegeStopsInitial value)? initial,
    TResult Function(_CollegeStopsLoading value)? loading,
    TResult Function(_CollegeStopsLoaded value)? loaded,
    TResult Function(_CollegeStopsError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _CollegeStopsError implements CollegeStopsState {
  const factory _CollegeStopsError(final String message) =
      _$CollegeStopsErrorImpl;

  String get message;

  /// Create a copy of CollegeStopsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CollegeStopsErrorImplCopyWith<_$CollegeStopsErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$HelpDeskState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function() success,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function()? success,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function()? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_HelpDeskInitial value) initial,
    required TResult Function(_HelpDeskLoading value) loading,
    required TResult Function(_HelpDeskSuccess value) success,
    required TResult Function(_HelpDeskError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_HelpDeskInitial value)? initial,
    TResult? Function(_HelpDeskLoading value)? loading,
    TResult? Function(_HelpDeskSuccess value)? success,
    TResult? Function(_HelpDeskError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_HelpDeskInitial value)? initial,
    TResult Function(_HelpDeskLoading value)? loading,
    TResult Function(_HelpDeskSuccess value)? success,
    TResult Function(_HelpDeskError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HelpDeskStateCopyWith<$Res> {
  factory $HelpDeskStateCopyWith(
    HelpDeskState value,
    $Res Function(HelpDeskState) then,
  ) = _$HelpDeskStateCopyWithImpl<$Res, HelpDeskState>;
}

/// @nodoc
class _$HelpDeskStateCopyWithImpl<$Res, $Val extends HelpDeskState>
    implements $HelpDeskStateCopyWith<$Res> {
  _$HelpDeskStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HelpDeskState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$HelpDeskInitialImplCopyWith<$Res> {
  factory _$$HelpDeskInitialImplCopyWith(
    _$HelpDeskInitialImpl value,
    $Res Function(_$HelpDeskInitialImpl) then,
  ) = __$$HelpDeskInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$HelpDeskInitialImplCopyWithImpl<$Res>
    extends _$HelpDeskStateCopyWithImpl<$Res, _$HelpDeskInitialImpl>
    implements _$$HelpDeskInitialImplCopyWith<$Res> {
  __$$HelpDeskInitialImplCopyWithImpl(
    _$HelpDeskInitialImpl _value,
    $Res Function(_$HelpDeskInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HelpDeskState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$HelpDeskInitialImpl implements _HelpDeskInitial {
  const _$HelpDeskInitialImpl();

  @override
  String toString() {
    return 'HelpDeskState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$HelpDeskInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function() success,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function()? success,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function()? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_HelpDeskInitial value) initial,
    required TResult Function(_HelpDeskLoading value) loading,
    required TResult Function(_HelpDeskSuccess value) success,
    required TResult Function(_HelpDeskError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_HelpDeskInitial value)? initial,
    TResult? Function(_HelpDeskLoading value)? loading,
    TResult? Function(_HelpDeskSuccess value)? success,
    TResult? Function(_HelpDeskError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_HelpDeskInitial value)? initial,
    TResult Function(_HelpDeskLoading value)? loading,
    TResult Function(_HelpDeskSuccess value)? success,
    TResult Function(_HelpDeskError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _HelpDeskInitial implements HelpDeskState {
  const factory _HelpDeskInitial() = _$HelpDeskInitialImpl;
}

/// @nodoc
abstract class _$$HelpDeskLoadingImplCopyWith<$Res> {
  factory _$$HelpDeskLoadingImplCopyWith(
    _$HelpDeskLoadingImpl value,
    $Res Function(_$HelpDeskLoadingImpl) then,
  ) = __$$HelpDeskLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$HelpDeskLoadingImplCopyWithImpl<$Res>
    extends _$HelpDeskStateCopyWithImpl<$Res, _$HelpDeskLoadingImpl>
    implements _$$HelpDeskLoadingImplCopyWith<$Res> {
  __$$HelpDeskLoadingImplCopyWithImpl(
    _$HelpDeskLoadingImpl _value,
    $Res Function(_$HelpDeskLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HelpDeskState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$HelpDeskLoadingImpl implements _HelpDeskLoading {
  const _$HelpDeskLoadingImpl();

  @override
  String toString() {
    return 'HelpDeskState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$HelpDeskLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function() success,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function()? success,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function()? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_HelpDeskInitial value) initial,
    required TResult Function(_HelpDeskLoading value) loading,
    required TResult Function(_HelpDeskSuccess value) success,
    required TResult Function(_HelpDeskError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_HelpDeskInitial value)? initial,
    TResult? Function(_HelpDeskLoading value)? loading,
    TResult? Function(_HelpDeskSuccess value)? success,
    TResult? Function(_HelpDeskError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_HelpDeskInitial value)? initial,
    TResult Function(_HelpDeskLoading value)? loading,
    TResult Function(_HelpDeskSuccess value)? success,
    TResult Function(_HelpDeskError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _HelpDeskLoading implements HelpDeskState {
  const factory _HelpDeskLoading() = _$HelpDeskLoadingImpl;
}

/// @nodoc
abstract class _$$HelpDeskSuccessImplCopyWith<$Res> {
  factory _$$HelpDeskSuccessImplCopyWith(
    _$HelpDeskSuccessImpl value,
    $Res Function(_$HelpDeskSuccessImpl) then,
  ) = __$$HelpDeskSuccessImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$HelpDeskSuccessImplCopyWithImpl<$Res>
    extends _$HelpDeskStateCopyWithImpl<$Res, _$HelpDeskSuccessImpl>
    implements _$$HelpDeskSuccessImplCopyWith<$Res> {
  __$$HelpDeskSuccessImplCopyWithImpl(
    _$HelpDeskSuccessImpl _value,
    $Res Function(_$HelpDeskSuccessImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HelpDeskState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$HelpDeskSuccessImpl implements _HelpDeskSuccess {
  const _$HelpDeskSuccessImpl();

  @override
  String toString() {
    return 'HelpDeskState.success()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$HelpDeskSuccessImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function() success,
    required TResult Function(String message) error,
  }) {
    return success();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function()? success,
    TResult? Function(String message)? error,
  }) {
    return success?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function()? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_HelpDeskInitial value) initial,
    required TResult Function(_HelpDeskLoading value) loading,
    required TResult Function(_HelpDeskSuccess value) success,
    required TResult Function(_HelpDeskError value) error,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_HelpDeskInitial value)? initial,
    TResult? Function(_HelpDeskLoading value)? loading,
    TResult? Function(_HelpDeskSuccess value)? success,
    TResult? Function(_HelpDeskError value)? error,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_HelpDeskInitial value)? initial,
    TResult Function(_HelpDeskLoading value)? loading,
    TResult Function(_HelpDeskSuccess value)? success,
    TResult Function(_HelpDeskError value)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class _HelpDeskSuccess implements HelpDeskState {
  const factory _HelpDeskSuccess() = _$HelpDeskSuccessImpl;
}

/// @nodoc
abstract class _$$HelpDeskErrorImplCopyWith<$Res> {
  factory _$$HelpDeskErrorImplCopyWith(
    _$HelpDeskErrorImpl value,
    $Res Function(_$HelpDeskErrorImpl) then,
  ) = __$$HelpDeskErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$HelpDeskErrorImplCopyWithImpl<$Res>
    extends _$HelpDeskStateCopyWithImpl<$Res, _$HelpDeskErrorImpl>
    implements _$$HelpDeskErrorImplCopyWith<$Res> {
  __$$HelpDeskErrorImplCopyWithImpl(
    _$HelpDeskErrorImpl _value,
    $Res Function(_$HelpDeskErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HelpDeskState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$HelpDeskErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$HelpDeskErrorImpl implements _HelpDeskError {
  const _$HelpDeskErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'HelpDeskState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HelpDeskErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of HelpDeskState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HelpDeskErrorImplCopyWith<_$HelpDeskErrorImpl> get copyWith =>
      __$$HelpDeskErrorImplCopyWithImpl<_$HelpDeskErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function() success,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function()? success,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function()? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_HelpDeskInitial value) initial,
    required TResult Function(_HelpDeskLoading value) loading,
    required TResult Function(_HelpDeskSuccess value) success,
    required TResult Function(_HelpDeskError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_HelpDeskInitial value)? initial,
    TResult? Function(_HelpDeskLoading value)? loading,
    TResult? Function(_HelpDeskSuccess value)? success,
    TResult? Function(_HelpDeskError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_HelpDeskInitial value)? initial,
    TResult Function(_HelpDeskLoading value)? loading,
    TResult Function(_HelpDeskSuccess value)? success,
    TResult Function(_HelpDeskError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _HelpDeskError implements HelpDeskState {
  const factory _HelpDeskError(final String message) = _$HelpDeskErrorImpl;

  String get message;

  /// Create a copy of HelpDeskState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HelpDeskErrorImplCopyWith<_$HelpDeskErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
