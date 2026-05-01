import '../../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

abstract class NotificationRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({String? phoneNumber});
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  Future<void> deleteAllNotifications();
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final DioClient dioClient;

  NotificationRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<NotificationModel>> getNotifications({String? phoneNumber}) async {
    final response = await dioClient.get(
      '/notifications',
      queryParameters: phoneNumber != null ? {'phoneNumber': phoneNumber} : null,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = response.data['data'];
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch notifications');
    }
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await dioClient.patch('/notifications/$notificationId/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await dioClient.patch('/notifications/read-all');
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await dioClient.delete('/notifications/$notificationId');
  }

  @override
  Future<void> deleteAllNotifications() async {
    await dioClient.delete('/notifications/all');
  }
}
