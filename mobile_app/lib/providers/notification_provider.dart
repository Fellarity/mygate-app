import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;
  List<String> _notifications = [];
  bool _hasUnread = false;
  RealtimeChannel? _channel;

  List<String> get notifications => _notifications;
  bool get hasUnread => _hasUnread;

  Future<void> initNotifications(String employeeCode) async {
    final userKey = employeeCode.trim();
    print('DEBUG: Initializing Notifications for $userKey');

    // Clean up any existing channel before creating a new one
    if (_channel != null) {
      await supabase.removeChannel(_channel!);
      _channel = null;
    }

    try {
      final response = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userKey)
          .order('created_at', ascending: false);
      
      if (response != null) {
        _notifications = (response as List).map((n) => (n['message'] ?? 'New notification').toString()).toList();
        _hasUnread = (response).any((n) => n['is_read'] == false);
        print('DEBUG: Loaded ${_notifications.length} notifications');
      }
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error loading notifications: $e');
    }

    // Subscribe using a unique channel name per user
    final channelName = 'notifications_${userKey.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    
    _channel = supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userKey,
          ),
          callback: (payload) {
            final record = payload.newRecord;
            print('DEBUG: Received Realtime Payload for user: ${record['user_id']}');
            
            if (record['user_id'] == userKey) {
              final newMessage = record['message']?.toString() ?? 'New Message';
              
              _notifications.insert(0, newMessage);
              _hasUnread = true;
              print('DEBUG: Valid notification added to UI');
              notifyListeners();
            }
          },
        )
        .subscribe((status, [error]) {
          print('DEBUG: Realtime Status: $status');
          if (error != null) print('DEBUG: Realtime Error: $error');
        });
  }

  Future<void> markAsRead(String employeeCode) async {
    if (!_hasUnread) return;
    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', employeeCode)
          .eq('is_read', false);

      _hasUnread = false;
      notifyListeners();
    } catch (e) {
      print('DEBUG: Error marking as read: $e');
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      supabase.removeChannel(_channel!);
    }
    super.dispose();
  }
}
