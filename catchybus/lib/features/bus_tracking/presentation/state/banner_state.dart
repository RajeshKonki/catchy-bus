import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/banner.dart';

part 'banner_state.freezed.dart';

@freezed
class BannerState with _$BannerState {
  const factory BannerState.initial() = _Initial;
  const factory BannerState.loading() = _Loading;
  const factory BannerState.loaded(List<BannerEntity> banners) = _Loaded;
  const factory BannerState.error(String message) = _Error;
}
