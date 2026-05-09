import 'package:flutter_riverpod/legacy.dart';

import 'package:speakeng/features/shadowing/logic/phrase_splitter.dart';
import 'package:speakeng/features/shadowing/models/sentence.dart';

/// Provider cho [PhraseModeNotifier].
final phraseModeProvider =
    StateNotifierProvider<PhraseModeNotifier, PhraseModeState>((ref) {
  return PhraseModeNotifier();
});

/// State cho phrase-by-phrase mode.
class PhraseModeState {
  const PhraseModeState({
    this.isEnabled = false,
    this.phrases = const [],
    this.currentPhraseIndex = 0,
    this.isFullSentenceMode = false,
  });

  /// Phrase mode đang bật hay không.
  final bool isEnabled;

  /// Danh sách phrases đã chia.
  final List<String> phrases;

  /// Index phrase đang luyện (0-based).
  final int currentPhraseIndex;

  /// Đã hoàn thành tất cả phrases, đang luyện toàn câu.
  final bool isFullSentenceMode;

  /// Phrase hiện tại đang luyện.
  String get currentPhrase =>
      phrases.isNotEmpty ? phrases[currentPhraseIndex] : '';

  /// Đã hoàn thành tất cả phrases chưa.
  bool get allPhrasesCompleted =>
      currentPhraseIndex >= phrases.length;

  PhraseModeState copyWith({
    bool? isEnabled,
    List<String>? phrases,
    int? currentPhraseIndex,
    bool? isFullSentenceMode,
  }) {
    return PhraseModeState(
      isEnabled: isEnabled ?? this.isEnabled,
      phrases: phrases ?? this.phrases,
      currentPhraseIndex: currentPhraseIndex ?? this.currentPhraseIndex,
      isFullSentenceMode: isFullSentenceMode ?? this.isFullSentenceMode,
    );
  }
}

/// Notifier quản lý phrase-by-phrase mode.
class PhraseModeNotifier extends StateNotifier<PhraseModeState> {
  PhraseModeNotifier() : super(const PhraseModeState());

  /// Bật/tắt phrase mode cho một câu.
  void toggle(Sentence sentence) {
    if (state.isEnabled) {
      state = const PhraseModeState();
      return;
    }
    final phrases = PhraseSplitter.split(sentence);
    state = PhraseModeState(
      isEnabled: true,
      phrases: phrases,
      currentPhraseIndex: 0,
      isFullSentenceMode: false,
    );
  }

  /// Chuyển sang phrase tiếp theo sau khi luyện xong phrase hiện tại.
  void advanceToNextPhrase() {
    if (!state.isEnabled) return;
    final nextIndex = state.currentPhraseIndex + 1;
    if (nextIndex >= state.phrases.length) {
      // Hoàn thành tất cả phrases → chuyển sang luyện toàn câu
      state = state.copyWith(isFullSentenceMode: true);
    } else {
      state = state.copyWith(currentPhraseIndex: nextIndex);
    }
  }

  /// Reset phrase mode (khi load câu mới).
  void reset() {
    state = const PhraseModeState();
  }
}
