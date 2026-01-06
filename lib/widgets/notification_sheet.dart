import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/notification_provider.dart';

class NotificationSheet extends StatelessWidget {
  const NotificationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();
    
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
              if (notifProv.notifications.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // Could implement "Mark all as read" here
                  },
                  child: Text(
                    'Clear All',
                    style: TextStyle(color: Colors.indigo.shade300),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 10),
          
          Expanded(
            child: notifProv.notifications.isEmpty 
              ? _buildEmptyState()
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: notifProv.notifications.length,
                  itemBuilder: (ctx, i) {
                     final n = notifProv.notifications[i];
                     return _NotificationTile(notification: n)
                        .animate()
                        .fadeIn(delay: (i * 100).ms)
                        .slideY(begin: 0.1, end: 0);
                  },
                ),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final dynamic notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification.isRead;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isRead 
            ? Colors.white.withOpacity(0.03) 
            : Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRead 
              ? Colors.white.withOpacity(0.05) 
              : Colors.indigo.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRead 
                  ? Colors.white.withOpacity(0.05) 
                  : Colors.indigo.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(notification.relatedEntityType),
              color: isRead ? Colors.white60 : Colors.indigo.shade300,
              size: 20,
            ),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              color: isRead ? Colors.white70 : Colors.white,
              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
              fontSize: 15,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
          onTap: () {
            context.read<NotificationProvider>().markAsRead(notification.id);
            if (notification.relatedEntityType == 'server' && notification.relatedEntityId != null) {
              Navigator.pop(context);
              context.push('/server/${notification.relatedEntityId}');
            }
          },
        ),
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'server': return Icons.groups_rounded;
      case 'announcement': return Icons.campaign_rounded;
      case 'chat': return Icons.chat_bubble_rounded;
      default: return Icons.notifications_rounded;
    }
  }
}
