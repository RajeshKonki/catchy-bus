import 'package:catchybus/features/bus_tracking/domain/entities/banner.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'banner_model.freezed.dart';
part 'banner_model.g.dart';

@freezed
class BannerModel with _$BannerModel {
  const BannerModel._();

  const factory BannerModel({
    required String id,
    String? title,
    @JsonKey(name: 'imageUrl') required String imageUrl,
    String? link,
    required String status,
    required int order,
  }) = _BannerModel;

  factory BannerModel.fromJson(Map<String, dynamic> json) =>
      _$BannerModelFromJson(json);

  BannerEntity toEntity() {
    return BannerEntity(
      id: id,
      title: title,
      imageUrl: imageUrl,
      link: link,
      status: status,
      order: order,
    );
  }
}
