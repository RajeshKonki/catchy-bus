import 'package:catchybus/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/banner_repository_impl.dart';
import '../../domain/repositories/banner_repository.dart';
import '../state/banner_state.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/di/injection.dart';

class BannerNotifier extends StateNotifier<BannerState> {
  final BannerRepository _repository;
  final String? _collegeId;

  BannerNotifier(this._repository, this._collegeId)
      : super(const BannerState.initial()) {
    getBanners();
  }

  Future<void> getBanners() async {
    state = const BannerState.loading();
    try {
      final banners = await _repository.getActiveBanners(collegeId: _collegeId);
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
  // Read the logged-in student's collegeId from auth state so banners are scoped
  final user = ref.watch(authProvider).user;
  final collegeId = user?.collegeId;
  return BannerNotifier(ref.watch(bannerRepositoryProvider), collegeId);
});
