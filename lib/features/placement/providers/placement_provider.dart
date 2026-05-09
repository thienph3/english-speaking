import 'package:flutter_riverpod/legacy.dart';

import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/features/placement/logic/placement_calculator.dart';
import 'package:speakeng/features/placement/repositories/placement_repository.dart';
import 'package:speakeng/features/shadowing/repositories/shadowing_repository.dart';
import 'package:speakeng/shared/services/content_service.dart';

/// Trạng thái của placement test.
enum PlacementStatus {
  loading,
  ready,
  recording,
  processing,
  showingScore,
  completed,
  error,
}

/// State class cho placement test.
class PlacementState {
  const PlacementState({
    this.status = PlacementStatus.loading,
    this.currentIndex = 0,
    this.sentences = const [],
    this.scores = const [],
    this.currentScore,
    this.level,
    this.avgAccuracy,
    this.errorMessage,
  });

  final PlacementStatus status;
  final int currentIndex;
  final List<PlacementSentence> sentences;
  final List<double> scores;
  final double? currentScore;
  final String? level;
  final double? avgAccuracy;
  final String? errorMessage;

  PlacementState copyWith({
    PlacementStatus? status,
    int? currentIndex,
    List<PlacementSentence>? sentences,
    List<double>? scores,
    double? currentScore,
    String? level,
    double? avgAccuracy,
    String? errorMessage,
  }) {
    return PlacementState(
      status: status ?? this.status,
      currentIndex: currentIndex ?? this.currentIndex,
      sentences: sentences ?? this.sentences,
      scores: scores ?? this.scores,
      currentScore: currentScore,
      level: level ?? this.level,
      avgAccuracy: avgAccuracy ?? this.avgAccuracy,
      errorMessage: errorMessage,
    );
  }
}

/// Provider cho PlacementNotifier.
final placementProvider =
    StateNotifierProvider<PlacementNotifier, PlacementState>((ref) {
  return PlacementNotifier(
    shadowingRepo: ref.read(shadowingRepositoryProvider),
    placementRepo: ref.read(placementRepositoryProvider),
    contentService: ContentService(),
  );
});

/// StateNotifier quản lý luồng placement test.
///
/// Flow: load sentences → hiển thị câu → ghi âm → gửi /pronounce →
/// hiển thị score → next → sau 3 câu → tính level → lưu Supabase.
class PlacementNotifier extends StateNotifier<PlacementState> {
  PlacementNotifier({
    required ShadowingRepository shadowingRepo,
    required PlacementRepository placementRepo,
    required ContentService contentService,
  })  : _shadowingRepo = shadowingRepo,
        _placementRepo = placementRepo,
        _contentService = contentService,
        super(const PlacementState()) {
    _loadSentences();
  }

  final ShadowingRepository _shadowingRepo;
  final PlacementRepository _placementRepo;
  final ContentService _contentService;

  /// Load 3 câu placement từ content service.
  Future<void> _loadSentences() async {
    try {
      final sentences = await _contentService.getPlacementSentences();
      state = state.copyWith(
        status: PlacementStatus.ready,
        sentences: sentences,
      );
    } on Exception {
      state = state.copyWith(
        status: PlacementStatus.error,
        errorMessage: 'Không thể tải nội dung. Thử lại.',
      );
    }
  }

  /// Bắt đầu ghi âm cho câu hiện tại.
  void startRecording() {
    state = state.copyWith(status: PlacementStatus.recording);
  }

  /// Gửi audio đến /pronounce và xử lý kết quả.
  Future<void> submitRecording(String audioPath) async {
    state = state.copyWith(status: PlacementStatus.processing);
    try {
      final sentence = state.sentences[state.currentIndex];
      final result = await _shadowingRepo.pronounce(
        audioPath: audioPath,
        referenceText: sentence.text,
      );
      final score = result.accuracyScore;
      state = state.copyWith(
        status: PlacementStatus.showingScore,
        currentScore: score,
        scores: [...state.scores, score],
      );
    } on AppError catch (e) {
      state = state.copyWith(
        status: PlacementStatus.error,
        errorMessage: e.userMessage,
      );
    }
  }

  /// Chuyển sang câu tiếp theo hoặc hoàn thành placement.
  Future<void> nextSentence() async {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex >= state.sentences.length) {
      await _completePlacement();
    } else {
      state = state.copyWith(
        status: PlacementStatus.ready,
        currentIndex: nextIndex,
      );
    }
  }

  /// Tính level và lưu kết quả vào Supabase.
  Future<void> _completePlacement() async {
    state = state.copyWith(status: PlacementStatus.processing);
    try {
      final level = PlacementCalculator.calculateLevel(state.scores);
      final avg = PlacementCalculator.calculateAverage(state.scores);
      await _placementRepo.savePlacementResult(
        avgAccuracy: avg,
        level: level,
      );
      state = state.copyWith(
        status: PlacementStatus.completed,
        level: level,
        avgAccuracy: avg,
      );
    } on AppError catch (e) {
      state = state.copyWith(
        status: PlacementStatus.error,
        errorMessage: e.userMessage,
      );
    }
  }

  /// Retry khi gặp lỗi — quay lại trạng thái ready.
  void retry() {
    state = state.copyWith(
      status: PlacementStatus.ready,
      errorMessage: null,
    );
  }
}
