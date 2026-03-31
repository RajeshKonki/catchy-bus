import 'package:catchybus/core/constants/api_constants.dart';
import 'package:catchybus/core/network/dio_client.dart';

import '../../domain/entities/banner.dart';
import '../../domain/repositories/banner_repository.dart';
import '../models/banner_model.dart';

class BannerRepositoryImpl implements BannerRepository {
  final DioClient _dioClient;

  BannerRepositoryImpl(this._dioClient);

  @override
  Future<List<BannerEntity>> getActiveBanners() async {
    try {
      final response = await _dioClient.get(ApiConstants.banners);
      List<dynamic>? data;

      if (response.data is List) {
        data = response.data;
      } else if (response.data is Map && response.data['data'] is List) {
        data = response.data['data'];
      } else if (response.data is Map && response.data['banners'] is List) {
        data = response.data['banners'];
      }

      if (data == null || data.isEmpty) {
        print('DEBUG: Banners response was null or empty, using fallback');
        return _getFallbackBanners();
      }

      print('DEBUG: Banners response: $data');
      return data.map((json) {
        final banner = BannerModel.fromJson(json).toEntity();
        // Handle relative URLs for images
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
      // Return fallback banners on error so the UI still looks good
      return _getFallbackBanners();
    }
  }

  List<BannerEntity> _getFallbackBanners() {
    return [
      const BannerEntity(
        id: 'fallback-1',
        title: 'Welcome to Catchy Bus',
        imageUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=1000&q=80',
        status: 'active',
        order: 1,
      ),
      const BannerEntity(
        id: 'fallback-2',
        title: 'Safety First',
        imageUrl: 'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=1000&q=80',
        status: 'active',
        order: 2,
      ),
      const BannerEntity(
        id: 'fallback-3',
        title: 'Track Your Ride',
        imageUrl: 'https://images.unsplash.com/photo-1594782078968-2b07659d4351?w=1000&q=80',
        status: 'active',
        order: 3,
      ),
    ];
  }
}
