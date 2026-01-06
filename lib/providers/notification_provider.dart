import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<AppNotification> _notifications = [];
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  List<AppNotification> get notifications => _notifications;

  RealtimeChannel? _subscription;

  void init() {
    _fetchNotifications();
    _subscribe();
  }

  Future<void> _fetchNotifications() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(50);
      
      _notifications = (res as List).map((e) => AppNotification.fromJson(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  void _subscribe() {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _subscription = _supabase
      .channel('public:notifications:user_id=eq.${user.id}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq, 
          column: 'user_id', 
          value: user.id
        ),
        callback: (payload) {
           final newNotif = AppNotification.fromJson(payload.newRecord);
           _notifications.insert(0, newNotif);
           notifyListeners();
        }
      )
      .subscribe();
  }

  Future<void> markAsRead(String id) async {
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
      // Optimistic update
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        // Create generic copy or just force refresh? Generic copy is cleaner but verbose in Dart without libraries
        // Let's just refetch or ignore generic update for MVP
        _fetchNotifications(); 
      }
    } catch (e) {
      debugPrint('Error marking read: $e');
    }
  }
  
  void disposeSub() {
    if (_subscription != null) _supabase.removeChannel(_subscription!);
  }
}
