import 'package:catchybus/core/constants/api_constants.dart';
import 'package:catchybus/core/network/dio_client.dart';

import '../../domain/entities/banner.dart';
import '../../domain/repositories/banner_repository.dart';
import '../models/banner_model.dart';

class BannerRepositoryImpl implements BannerRepository {
  final DioClient _dioClient;

  BannerRepositoryImpl(this._dioClient);

  @override
  Future<List<BannerEntity>> getActiveBanners({String? collegeId}) async {
    try {
      // Pass collegeId so server returns global + this college's banners only
      final queryParams = collegeId != null ? {'collegeId': collegeId} : null;
      final response = await _dioClient.get(
        ApiConstants.banners,
        queryParameters: queryParams,
      );
      List<dynamic>? data;

      if (response.data is List) {
        data = response.data;
      } else if (response.data is Map && response.data['data'] is List) {
        data = response.data['data'];
      } else if (response.data is Map && response.data['banners'] is List) {
        data = response.data['banners'];
      }

      if (data == null || data.isEmpty) {
        return [];
      }

      return data.map((json) {
        final banner = BannerModel.fromJson(json).toEntity();
        String imageUrl = banner.imageUrl;
        if (!imageUrl.startsWith('http')) {
          final baseUrl = ApiConstants.baseUrl.replaceAll('/api/', '');
          imageUrl = '$baseUrl${imageUrl.startsWith('/') ? imageUrl : '/$imageUrl'}';
        }
        return BannerEntity(
          id: banner.id,
          title: banner.title,
          imageUrl: imageUrl,
          link: banner.link,
          status: banner.status,
          order: banner.order,
        );
      }).toList();
    } catch (e) {
      print('DEBUG: Error fetching banners: $e');
      return [];
    }
  }
}
