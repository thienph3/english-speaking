import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:speakeng/core/exceptions.dart';
import 'package:speakeng/features/shadowing/models/pronunciation_result.dart';
import 'package:speakeng/features/shadowing/models/sentence.dart';

part 'shadowing_state.freezed.dart';

/// State unions cho Shadowing flow.
///
/// - [initial]: chưa có câu nào được load
/// - [loaded]: câu đã sẵn sàng để luyện
/// - [playing]: đang phát audio mẫu
/// - [recording]: đang ghi âm user
/// - [processing]: đang chờ Azure trả kết quả
/// - [result]: hiển thị kết quả phát âm
/// - [error]: có lỗi xảy ra
@freezed
sealed class ShadowingState with _$ShadowingState {
  /// Trạng thái ban đầu — chưa load câu nào.
  const factory ShadowingState.initial() = ShadowingInitial;

  /// Câu đã được load, sẵn sàng luyện tập.
  const factory ShadowingState.loaded(Sentence sentence) = ShadowingLoaded;

  /// Đang phát audio mẫu cho user nghe.
  const factory ShadowingState.playing(Sentence sentence) = ShadowingPlaying;

  /// Đang ghi âm giọng nói user.
  const factory ShadowingState.recording(Sentence sentence) =
      ShadowingRecording;

  /// Đang gửi audio lên server và chờ kết quả.
  const factory ShadowingState.processing(Sentence sentence) =
      ShadowingProcessing;

  /// Hiển thị kết quả phát âm.
  const factory ShadowingState.result(
    Sentence sentence,
    PronunciationResult result,
  ) = ShadowingResult;

  /// Có lỗi xảy ra.
  const factory ShadowingState.error(AppError error) = ShadowingError;
}
