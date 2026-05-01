import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/notification_entity.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import 'package:catchybus/features/auth/presentation/providers/auth_provider.dart';

abstract class NotificationsState {
  const NotificationsState();
}

class NotificationsInitial extends NotificationsState {}
class NotificationsLoading extends NotificationsState {}
class NotificationsLoaded extends NotificationsState {
  final List<NotificationEntity> notifications;
  const NotificationsLoaded(this.notifications);
}
class NotificationsError extends NotificationsState {
  final String message;
  const NotificationsError(this.message);
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationRepository repository;
  final Ref ref;

  NotificationsNotifier({required this.repository, required this.ref}) : super(NotificationsInitial());

  Future<void> fetchNotifications() async {
    state = NotificationsLoading();
    
    final user = ref.read(authProvider).user;
    final result = await repository.getNotifications(phoneNumber: user?.phone);

    result.fold(
      (failure) => state = NotificationsError(failure.message),
      (notifications) => state = NotificationsLoaded(notifications),
    );
  }

  Future<void> markAsRead(String notificationId) async {
    // According to user request, marking as read should delete the notification
    await repository.deleteNotification(notificationId);
    if (state is NotificationsLoaded) {
      final currentNotifications = (state as NotificationsLoaded).notifications;
      final updatedNotifications = currentNotifications.where((n) => n.id != notificationId).toList();
      state = NotificationsLoaded(updatedNotifications);
    }
  }

  Future<void> markAllAsRead() async {
    // According to user request, marking all as read should delete all notifications
    await repository.deleteAllNotifications();
    state = const NotificationsLoaded([]);
  }

  Future<void> deleteNotification(String notificationId) async {
    await repository.deleteNotification(notificationId);
    if (state is NotificationsLoaded) {
      final currentNotifications = (state as NotificationsLoaded).notifications;
      final updatedNotifications = currentNotifications.where((n) => n.id != notificationId).toList();
      state = NotificationsLoaded(updatedNotifications);
    }
  }

  Future<void> deleteAllNotifications() async {
    await repository.deleteAllNotifications();
    state = const NotificationsLoaded([]);
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final remoteDataSource = NotificationRemoteDataSourceImpl(dioClient: getIt<DioClient>());
  return NotificationRepositoryImpl(remoteDataSource: remoteDataSource);
});

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(
    repository: ref.watch(notificationRepositoryProvider),
    ref: ref,
  )..fetchNotifications();
});
