import 'package:equatable/equatable.dart';

class BannerEntity extends Equatable {
  final String id;
  final String? title;
  final String imageUrl;
  final String? link;
  final String status;
  final int order;

  const BannerEntity({
    required this.id,
    this.title,
    required this.imageUrl,
    this.link,
    required this.status,
    required this.order,
  });

  @override
  List<Object?> get props => [id, title, imageUrl, link, status, order];
}
