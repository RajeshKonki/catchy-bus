import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/theme/app_theme.dart';

class NotificationModel {
  final String title;
  final String time;
  final bool isUnread;

  NotificationModel({
    required this.title,
    required this.time,
    this.isUnread = false,
  });
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<NotificationModel> notifications = [
      NotificationModel(
        title: 'Your bus is 1 km away!',
        time: '1 sec ago',
        isUnread: true,
      ),
      NotificationModel(
        title: 'Your Bus will be at the stop in 5 minutes!',
        time: '5 min ago',
      ),
      NotificationModel(
        title: 'Reminder: Please be at the bus stop by 7:00 AM.',
        time: '1 hr ago',
      ),
      NotificationModel(
        title: 'The Bus has started its journey!',
        time: '2 hrs ago',
      ),
      NotificationModel(
        title: 'Attention: Your bus is cancelled due to technical problems.',
        time: '1 day ago',
      ),
      NotificationModel(
        title: 'Your bus is currently delayed by 15 minutes!',
        time: '1 day ago',
      ),
      NotificationModel(
        title: 'Your bus is approaching the stop, please prepare to board.',
        time: '1 day ago',
      ),
      NotificationModel(
        title: 'Final Call: Last bus of the night',
        time: '1 day ago',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _NotificationItem(notification: notification);
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isUnread ? const Color(0xFF2E5AAC) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: notification.isUnread
                  ? Colors.white
                  : const Color(0xFFE9F0FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.directions_bus_outlined,
              color: notification.isUnread
                  ? const Color(0xFF2E5AAC)
                  : AppColors.deepBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    color: notification.isUnread ? Colors.white : Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.time,
                  style: TextStyle(
                    color: notification.isUnread
                        ? Colors.white.withOpacity(0.8)
                        : Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
