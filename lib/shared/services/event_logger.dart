import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/shared/services/supabase_service.dart';

/// Provider cho EventLogger instance.
final eventLoggerProvider = Provider<EventLogger>((ref) {
  return EventLogger(ref.read(supabaseProvider));
});

/// Ghi event analytics vào Supabase table `events`.
///
/// Fail silently — logging không bao giờ làm crash app.
class EventLogger {
  EventLogger(this._supabase);

  final SupabaseClient _supabase;

  /// Ghi một event với metadata tùy chọn.
  ///
  /// Events: 'daily_flow_started', 'shadowing_completed',
  /// 'conversation_completed', 'daily_flow_completed'.
  Future<void> log(String event, {Map<String, dynamic>? metadata}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase.from('events').insert({
        'user_id': userId,
        'event_name': event,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Fail silently — logging should never break the app
    }
  }
}
