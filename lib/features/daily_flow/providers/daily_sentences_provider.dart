import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/features/shadowing/logic/sentence_selector.dart';
import 'package:speakeng/features/shadowing/models/sentence.dart';
import 'package:speakeng/shared/services/content_service.dart';
import 'package:speakeng/shared/services/supabase_service.dart';

/// Provider cho ContentService.
final contentServiceProvider = Provider<ContentService>((ref) {
  return ContentService();
});

/// Provider cho daily sentences — 3 câu được chọn theo user level.
///
/// Dùng ngày hiện tại làm seed để đảm bảo cùng 3 câu trong ngày,
/// nhưng thay đổi mỗi ngày mới.
final dailySentencesProvider = FutureProvider<List<Sentence>>((ref) async {
  final supabase = ref.read(supabaseProvider);
  final contentService = ref.read(contentServiceProvider);

  final userLevel = await _getUserLevel(supabase);
  final allSentences = await contentService.getAllSentences();
  final available = SentenceSelector.getAvailableSentences(
    allSentences,
    userLevel,
  );

  // Dùng ngày hiện tại làm seed cho shuffle ổn định trong ngày
  final today = DateTime.now();
  final seed = today.year * 10000 + today.month * 100 + today.day;
  final shuffled = List<Sentence>.from(available);
  _seededShuffle(shuffled, seed);

  return shuffled.take(3).toList();
});

/// Đọc starting_level từ user_profiles.
Future<String> _getUserLevel(SupabaseClient supabase) async {
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return 'easy_medium';

  final response = await supabase
      .from('user_profiles')
      .select('starting_level')
      .eq('user_id', userId)
      .maybeSingle();

  if (response == null) return 'easy_medium';
  return response['starting_level'] as String? ?? 'easy_medium';
}

/// Deterministic shuffle using a seeded LCG random.
void _seededShuffle<T>(List<T> list, int seed) {
  var s = seed;
  for (var i = list.length - 1; i > 0; i--) {
    s = (s * 1103515245 + 12345) & 0x7fffffff;
    final j = s % (i + 1);
    final temp = list[i];
    list[i] = list[j];
    list[j] = temp;
  }
}
