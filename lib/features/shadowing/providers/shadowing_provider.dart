import 'package:flutter_riverpod/legacy.dart';

import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/features/shadowing/models/sentence.dart';
import 'package:speakeng/features/shadowing/providers/shadowing_state.dart';
import 'package:speakeng/features/shadowing/repositories/shadowing_repository.dart';

/// Provider cho tốc độ phát audio hiện tại (0.7, 1.0, 1.2).
final playbackSpeedProvider = StateProvider<double>((ref) => 1.0);

/// Provider cho [ShadowingNotifier].
final shadowingProvider =
    StateNotifierProvider<ShadowingNotifier, ShadowingState>((ref) {
  return ShadowingNotifier(ref.read(shadowingRepositoryProvider));
});

/// StateNotifier quản lý flow shadowing:
/// load câu → play audio → record → gửi → hiển thị kết quả.
///
/// TODO(thienph3): khi build daily flow, gọi
/// SentenceSelector.getAvailableSentences(allSentences, userLevel)
/// để chỉ phục vụ câu phù hợp với starting_level của user.
class ShadowingNotifier extends StateNotifier<ShadowingState> {
  ShadowingNotifier(this._repository)
      : super(const ShadowingState.initial());

  final ShadowingRepository _repository;

  /// Load một câu mới để luyện tập.
  void loadSentence(Sentence sentence) {
    state = ShadowingState.loaded(sentence);
  }

  /// Bắt đầu phát audio mẫu.
  void startPlaying() {
    final sentence = _currentSentence;
    if (sentence == null) return;
    state = ShadowingState.playing(sentence);
  }

  /// Kết thúc phát audio, quay lại loaded.
  void stopPlaying() {
    final sentence = _currentSentence;
    if (sentence == null) return;
    state = ShadowingState.loaded(sentence);
  }

  /// Bắt đầu ghi âm.
  void startRecording() {
    final sentence = _currentSentence;
    if (sentence == null) return;
    state = ShadowingState.recording(sentence);
  }

  /// Dừng ghi âm và gửi audio lên server.
  Future<void> stopAndSubmit(String audioPath) async {
    final sentence = _currentSentence;
    if (sentence == null) return;

    state = ShadowingState.processing(sentence);

    try {
      final result = await _repository.pronounce(
        audioPath: audioPath,
        referenceText: sentence.text,
      );
      state = ShadowingState.result(sentence, result);
    } on AppError catch (error) {
      state = ShadowingState.error(error);
    }
  }

  /// Quay lại trạng thái loaded để thử lại.
  void retry() {
    final sentence = _currentSentence;
    if (sentence == null) {
      state = const ShadowingState.initial();
      return;
    }
    state = ShadowingState.loaded(sentence);
  }

  /// Lấy sentence hiện tại từ state (nếu có).
  Sentence? get _currentSentence {
    return switch (state) {
      ShadowingLoaded(:final sentence) => sentence,
      ShadowingPlaying(:final sentence) => sentence,
      ShadowingRecording(:final sentence) => sentence,
      ShadowingProcessing(:final sentence) => sentence,
      ShadowingResult(:final sentence) => sentence,
      _ => null,
    };
  }
}
