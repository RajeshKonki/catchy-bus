import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/banner_repository_impl.dart';
import '../../domain/repositories/banner_repository.dart';
import '../state/banner_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/di/injection.dart';

class BannerNotifier extends StateNotifier<BannerState> {
  final BannerRepository _repository;

  BannerNotifier(this._repository) : super(const BannerState.initial()) {
    getBanners();
  }

  Future<void> getBanners() async {
    state = const BannerState.loading();
    try {
      final banners = await _repository.getActiveBanners();
      state = BannerState.loaded(banners);
    } catch (e) {
      state = BannerState.error(e.toString());
    }
  }
}

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepositoryImpl(getIt<DioClient>());
});

final bannerProvider = StateNotifierProvider<BannerNotifier, BannerState>((ref) {
  return BannerNotifier(ref.watch(bannerRepositoryProvider));
});
