// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'banner_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BannerModelImpl _$$BannerModelImplFromJson(Map json) => _$BannerModelImpl(
  id: json['id'] as String,
  title: json['title'] as String?,
  imageUrl: json['imageUrl'] as String,
  link: json['link'] as String?,
  status: json['status'] as String,
  order: (json['order'] as num).toInt(),
);

Map<String, dynamic> _$$BannerModelImplToJson(_$BannerModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'imageUrl': instance.imageUrl,
      'link': instance.link,
      'status': instance.status,
      'order': instance.order,
    };
