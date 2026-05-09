/// Sealed class cho domain errors trong SpeakEng.
sealed class AppError {
  const AppError();

  String get userMessage;
}

/// Lỗi mất kết nối internet.
class NetworkError extends AppError {
  const NetworkError();

  @override
  String get userMessage => 'Mất kết nối internet. Vui lòng kiểm tra mạng.';
}

/// Lỗi API timeout (> 10 giây).
class ApiTimeoutError extends AppError {
  const ApiTimeoutError();

  @override
  String get userMessage => 'Không thể xử lý audio. Thử lại?';
}

/// Lỗi audio không hợp lệ.
class InvalidAudioError extends AppError {
  const InvalidAudioError({required this.reason});

  final String reason; // "too_short", "too_long", "silence"

  @override
  String get userMessage {
    switch (reason) {
      case 'too_short':
      case 'too_long':
        return 'Bản ghi quá ngắn/dài. Hãy ghi từ 2–10 giây.';
      case 'silence':
        return 'Không nghe thấy gì. Kiểm tra microphone.';
      default:
        return 'Lỗi ghi âm. Thử lại.';
    }
  }
}

/// Lỗi transcription (Whisper trả về tiếng Việt hoặc accuracy thấp).
class TranscriptionError extends AppError {
  const TranscriptionError();

  @override
  String get userMessage =>
      'Hãy thử nói bằng tiếng Anh hoặc nói chậm hơn.';
}

/// Lỗi TTS — fallback hiển thị text không có audio.
class TtsError extends AppError {
  const TtsError();

  @override
  String get userMessage => '';
}

/// Lỗi xác thực (đăng nhập/đăng ký thất bại).
class AuthError extends AppError {
  const AuthError({required this.message});

  final String message;

  @override
  String get userMessage => message;
}
