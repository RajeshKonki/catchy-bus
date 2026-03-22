import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/notifications_provider.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationsProvider);

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
        actions: [
          if (notificationState is NotificationsLoaded &&
              notificationState.notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllAsRead(),
              child: const Text('Mark all as read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(notificationsProvider.notifier).fetchNotifications(),
        child: _buildBody(notificationState, ref),
      ),
    );
  }

  Widget _buildBody(NotificationsState state, WidgetRef ref) {
    if (state is NotificationsLoading) {
      return _LoadingSkelton();
    } else if (state is NotificationsError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.message}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).fetchNotifications(),
              child: const Text('Sync Notifications'),
            ),
          ],
        ),
      );
    } else if (state is NotificationsLoaded) {
      if (state.notifications.isEmpty) {
        return const Center(child: Text('No notifications yet.'));
      }
      return ListView.separated(
        itemCount: state.notifications.length,
        separatorBuilder: (context, index) =>
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return _NotificationItem(
            notification: notification,
            onTap: () {
              if (!notification.isRead) {
                ref
                    .read(notificationsProvider.notifier)
                    .markAsRead(notification.id);
              }
            },
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;

  const _NotificationItem({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: !notification.isRead ? const Color(0xFF2E5AAC).withOpacity(0.05) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: !notification.isRead
                    ? const Color(0xFFE9F0FD)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.directions_bus_outlined,
                color: !notification.isRead
                    ? const Color(0xFF2E5AAC)
                    : Colors.grey[400],
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
                      color: !notification.isRead ? Colors.black : Colors.grey[700],
                      fontSize: 16,
                      fontWeight: !notification.isRead ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTimeAgo(notification.createdAt),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead)
               Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF2E5AAC),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) return '${difference.inSeconds} sec ago';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hrs ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _LoadingSkelton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.separated(
        itemCount: 8,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(width: 48, height: 48, color: Colors.white),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 200, height: 16, color: Colors.white),
                  const SizedBox(height: 8),
                  Container(width: 100, height: 12, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
