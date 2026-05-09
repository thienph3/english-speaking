# Design Document — SpeakEng MVP

## Giới thiệu

Tài liệu thiết kế cho SpeakEng MVP — ứng dụng Flutter (Android) giúp người Việt luyện phát âm tiếng Anh. Kiến trúc: Flutter + Supabase (Auth, DB, Storage, Edge Functions) + Azure Speech + OpenAI APIs.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────┐
│                 Flutter App (Android)             │
├─────────────────────────────────────────────────┤
│  Presentation Layer (Screens + Widgets)          │
│  ├── features/auth/screens/                      │
│  ├── features/placement/screens/                 │
│  ├── features/daily_flow/screens/                │
│  ├── features/shadowing/screens/ + widgets/      │
│  ├── features/conversation/screens/ + widgets/   │
│  ├── features/progress/screens/                  │
│  └── shared/widgets/ (RecordButton, ScoreCard)   │
├─────────────────────────────────────────────────┤
│  State Management (Riverpod — StateNotifier)     │
│  ├── features/*/providers/*_provider.dart        │
│  └── features/*/providers/*_state.dart (freezed) │
├─────────────────────────────────────────────────┤
│  Logic Layer (Pure Dart — no dependencies)       │
│  ├── features/placement/logic/                   │
│  ├── features/shadowing/logic/                   │
│  └── features/conversation/logic/                │
├─────────────────────────────────────────────────┤
│  Data Layer (Repositories + Services)            │
│  ├── features/*/repositories/                    │
│  └── shared/services/ (Audio, Supabase, Content) │
└──────────────────┬──────────────────────────────┘
                   │ HTTPS
                   ▼
┌─────────────────────────────────────────────────┐
│              Supabase Backend                     │
├─────────────────────────────────────────────────┤
│  Auth        → Email/password authentication     │
│  PostgreSQL  → recordings, sentence_progress,    │
│                daily_metrics, user_profiles       │
│  Storage     → before/after audio recordings     │
│  Edge Functions:                                 │
│    /pronounce  → proxy Azure Speech              │
│    /transcribe → proxy OpenAI Whisper            │
│    /chat       → proxy OpenAI GPT-4o-mini        │
│    /tts        → proxy OpenAI TTS                │
└──────────────────┬──────────────────────────────┘
                   │
          ┌────────┴────────┐
          ▼                 ▼
┌──────────────────┐ ┌─────────────────────┐
│   Azure Speech   │ │    OpenAI APIs       │
│  Pronunciation   │ │  Whisper (STT)       │
│  Assessment      │ │  GPT-4o-mini (Chat)  │
│  (phoneme-level) │ │  TTS (voice output)  │
└──────────────────┘ └─────────────────────┘
```

---

## Cấu trúc thư mục Flutter (Feature-First)

```
lib/
├── main.dart                          # Entry point, ProviderScope
├── app.dart                           # MaterialApp.router
├── core/
│   ├── constants.dart
│   ├── theme.dart                     # AppColors, AppTypography, AppSpacing, AppRadius
│   ├── router.dart                    # GoRouter + redirect guards
│   └── exceptions.dart                # sealed class AppError
├── features/
│   ├── auth/
│   │   ├── repositories/auth_repository.dart
│   │   ├── providers/auth_provider.dart
│   │   └── screens/auth_screen.dart
│   ├── placement/
│   │   ├── logic/placement_calculator.dart
│   │   ├── providers/placement_provider.dart
│   │   └── screens/placement_screen.dart
│   ├── shadowing/
│   │   ├── models/sentence.dart
│   │   ├── models/pronunciation_result.dart
│   │   ├── logic/mastery_calculator.dart
│   │   ├── logic/phrase_splitter.dart
│   │   ├── logic/word_color_mapper.dart
│   │   ├── logic/phoneme_tip_lookup.dart
│   │   ├── logic/sentence_selector.dart
│   │   ├── repositories/shadowing_repository.dart
│   │   ├── providers/shadowing_provider.dart
│   │   ├── providers/shadowing_state.dart
│   │   ├── screens/shadowing_screen.dart
│   │   └── widgets/
│   │       ├── word_feedback_chip.dart
│   │       └── phoneme_tip_card.dart
│   ├── conversation/
│   │   ├── models/scenario.dart
│   │   ├── logic/target_phrase_detector.dart
│   │   ├── logic/response_time_calculator.dart
│   │   ├── repositories/conversation_repository.dart
│   │   ├── providers/conversation_provider.dart
│   │   ├── providers/conversation_state.dart
│   │   ├── screens/conversation_screen.dart
│   │   ├── screens/feedback_screen.dart
│   │   └── widgets/
│   │       ├── chat_bubble.dart
│   │       └── typing_indicator.dart
│   ├── progress/
│   │   ├── models/daily_metrics.dart
│   │   ├── models/sentence_progress.dart
│   │   ├── repositories/progress_repository.dart
│   │   ├── providers/progress_provider.dart
│   │   └── screens/progress_screen.dart
│   └── daily_flow/
│       ├── providers/daily_flow_provider.dart
│       ├── providers/daily_flow_state.dart
│       └── screens/daily_flow_screen.dart
├── shared/
│   ├── widgets/
│   │   ├── recording_button.dart
│   │   ├── score_card.dart
│   │   ├── speed_selector.dart
│   │   └── audio_player_widget.dart
│   └── services/
│       ├── audio_service.dart
│       ├── supabase_service.dart
│       └── content_service.dart
└── data/
    ├── sentences.json
    ├── scenarios.json
    ├── placement.json
    └── phoneme_tips.json
```

---

## Data Models (freezed + json_serializable)

Tất cả models dùng `@freezed` để đảm bảo immutability, `copyWith`, và JSON serialization.

### Sentence (Câu shadowing)

```dart
@freezed
class Sentence with _$Sentence {
  const Sentence._(); // cho custom getters

  const factory Sentence({
    required String id,
    required String text,
    required String situation,
    required List<String> phrases,
    required String targetGrammar,
    required String difficulty, // "easy", "medium", "hard"
    String? audioAssetPath,
  }) = _Sentence;

  bool get supportsPhrasePractice => text.split(' ').length > 5;

  factory Sentence.fromJson(Map<String, dynamic> json) =>
      _$SentenceFromJson(json);
}
```

### Scenario (Kịch bản hội thoại)

```dart
@freezed
class Scenario with _$Scenario {
  const factory Scenario({
    required String id,
    required String situation,
    required String aiRole,
    required String firstMessage,
    String? firstMessageAudioPath,
    required List<String> targetPhrases,
    required List<String> targetGrammar,
    @Default(5) int maxTurns,
    required List<String> hints,
    required String systemPrompt,
  }) = _Scenario;

  factory Scenario.fromJson(Map<String, dynamic> json) =>
      _$ScenarioFromJson(json);
}
```

### PronunciationResult (Kết quả phát âm)

```dart
@freezed
class PronunciationResult with _$PronunciationResult {
  const factory PronunciationResult({
    required double accuracyScore,
    required double fluencyScore,
    required double completenessScore,
    required List<WordResult> words,
  }) = _PronunciationResult;

  factory PronunciationResult.fromJson(Map<String, dynamic> json) =>
      _$PronunciationResultFromJson(json);
}

@freezed
class WordResult with _$WordResult {
  const factory WordResult({
    required String word,
    required double accuracyScore,
    String? errorType,
    required List<PhonemeResult> phonemes,
  }) = _WordResult;

  factory WordResult.fromJson(Map<String, dynamic> json) =>
      _$WordResultFromJson(json);
}

@freezed
class PhonemeResult with _$PhonemeResult {
  const factory PhonemeResult({
    required String phoneme,
    required double accuracyScore,
  }) = _PhonemeResult;

  factory PhonemeResult.fromJson(Map<String, dynamic> json) =>
      _$PhonemeResultFromJson(json);
}

enum WordColor { green, yellow, red }
```

### SentenceProgress (Tiến bộ mỗi câu)

```dart
@freezed
class SentenceProgress with _$SentenceProgress {
  const SentenceProgress._();

  const factory SentenceProgress({
    required String userId,
    required String sentenceId,
    @Default(0) int correctStreak,
    @Default(0) double bestAccuracy,
    DateTime? lastPracticed,
  }) = _SentenceProgress;

  bool get isMastered => correctStreak >= 3;

  factory SentenceProgress.fromJson(Map<String, dynamic> json) =>
      _$SentenceProgressFromJson(json);
}
```

### DailyMetrics (Metrics hàng ngày)

```dart
@freezed
class DailyMetrics with _$DailyMetrics {
  const factory DailyMetrics({
    required String userId,
    required DateTime date,
    @Default(0) int sentencesPracticed,
    @Default(0) int sentencesMastered,
    @Default(0) double avgAccuracy,
    @Default(0) int avgResponseTimeMs,
  }) = _DailyMetrics;

  factory DailyMetrics.fromJson(Map<String, dynamic> json) =>
      _$DailyMetricsFromJson(json);
}
```

---

## Database Schema (Supabase PostgreSQL)

```sql
-- Bảng lưu bản ghi âm
CREATE TABLE recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  sentence_id TEXT NOT NULL,
  audio_path TEXT NOT NULL,
  accuracy FLOAT,
  recording_type TEXT CHECK (recording_type IN ('before', 'after', 'practice')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Bảng tiến bộ mỗi câu
CREATE TABLE sentence_progress (
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  sentence_id TEXT NOT NULL,
  correct_streak INT DEFAULT 0,
  best_accuracy FLOAT DEFAULT 0,
  last_practiced TIMESTAMPTZ,
  PRIMARY KEY (user_id, sentence_id)
);

-- Bảng metrics hàng ngày
CREATE TABLE daily_metrics (
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  date DATE NOT NULL,
  sentences_practiced INT DEFAULT 0,
  sentences_mastered INT DEFAULT 0,
  avg_accuracy FLOAT DEFAULT 0,
  avg_response_time_ms INT DEFAULT 0,
  PRIMARY KEY (user_id, date)
);

-- Bảng kết quả placement
CREATE TABLE user_profiles (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id),
  placement_completed BOOLEAN DEFAULT FALSE,
  placement_avg_accuracy FLOAT,
  starting_level TEXT CHECK (starting_level IN ('easy', 'easy_medium', 'medium_hard')),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- RLS policies
ALTER TABLE recordings ENABLE ROW LEVEL SECURITY;
ALTER TABLE sentence_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only access own data" ON recordings
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can only access own data" ON sentence_progress
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can only access own data" ON daily_metrics
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users can only access own data" ON user_profiles
  FOR ALL USING (auth.uid() = user_id);
```

---

## Component Design (Logic Layer — Pure Dart, no dependencies)

### 1. AuthRepository (Data Layer)

```dart
/// lib/features/auth/repositories/auth_repository.dart
class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<AuthResponse> signUp(String email, String password);
  Future<AuthResponse> signIn(String email, String password);
  Future<void> signOut();
  Stream<AuthState> get authStateChanges;
  User? get currentUser;
}
```

### 2. PlacementCalculator (Logic Layer — Pure)

```dart
/// lib/features/placement/logic/placement_calculator.dart
/// KHÔNG import Flutter, Riverpod, Supabase
class PlacementCalculator {
  /// Tính mức khởi đầu từ 3 điểm accuracy
  /// avg ≥ 80 → medium_hard
  /// avg 50–79 → easy_medium
  /// avg < 50 → easy
  static String calculateLevel(List<double> scores) {
    assert(scores.length == 3);
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    if (avg >= 80) return 'medium_hard';
    if (avg >= 50) return 'easy_medium';
    return 'easy';
  }
}
```

### 3. MasteryCalculator (Logic Layer — Pure)

```dart
/// lib/features/shadowing/logic/mastery_calculator.dart
class MasteryCalculator {
  /// Cập nhật streak sau mỗi lần luyện
  /// accuracy ≥ 80 → streak + 1
  /// accuracy < 80 → streak = 0
  /// streak ≥ 3 → mastered
  static SentenceProgress updateProgress(
    SentenceProgress current,
    double newAccuracy,
  ) {
    final newStreak = newAccuracy >= 80 ? current.correctStreak + 1 : 0;
    final newBest = newAccuracy > current.bestAccuracy
        ? newAccuracy
        : current.bestAccuracy;
    return current.copyWith(
      correctStreak: newStreak,
      bestAccuracy: newBest,
      lastPracticed: DateTime.now(),
    );
  }

  static bool isMastered(SentenceProgress progress) =>
      progress.correctStreak >= 3;
}
```

### 4. PhraseSplitter (Logic Layer — Pure)

```dart
/// lib/features/shadowing/logic/phrase_splitter.dart
class PhraseSplitter {
  /// Chia câu thành cụm từ dựa trên danh sách phrases đã định nghĩa
  /// Nếu không có phrases, chia theo chunks 3-4 từ
  static List<String> split(Sentence sentence) {
    if (sentence.phrases.isNotEmpty) {
      return sentence.phrases;
    }
    final words = sentence.text.split(' ');
    final chunks = <String>[];
    for (var i = 0; i < words.length; i += 3) {
      final end = (i + 3).clamp(0, words.length);
      chunks.add(words.sublist(i, end).join(' '));
    }
    return chunks;
  }

  static bool supportsPhrasePractice(Sentence sentence) =>
      sentence.text.split(' ').length > 5;
}
```

### 5. ResponseTimeCalculator (Logic Layer — Pure, stateless)

```dart
/// lib/features/conversation/logic/response_time_calculator.dart
/// Pure function — KHÔNG giữ mutable state
class ResponseTimeCalculator {
  /// Tính trung bình response time từ danh sách (ms)
  static double average(List<int> responseTimes) {
    if (responseTimes.isEmpty) return 0;
    return responseTimes.reduce((a, b) => a + b) / responseTimes.length;
  }
}
```

### 6. WordColorMapper (Logic Layer — Pure)

```dart
/// lib/features/shadowing/logic/word_color_mapper.dart
class WordColorMapper {
  /// Map accuracy score → color
  /// ≥ 80 → green, 50–79 → yellow, < 50 → red
  static WordColor mapColor(double accuracyScore) {
    if (accuracyScore >= 80) return WordColor.green;
    if (accuracyScore >= 50) return WordColor.yellow;
    return WordColor.red;
  }
}
```

### 7. PhonemeTipLookup (Logic Layer — Pure)

```dart
/// lib/features/shadowing/logic/phoneme_tip_lookup.dart
/// Pure lookup — KHÔNG phải service, chỉ là static data + function
class PhonemeTipLookup {
  static const Map<String, String> vietnameseTips = {
    'θ': 'Đặt lưỡi giữa 2 răng, thổi hơi ra nhẹ. Không phải /t/ hay /s/.',
    'ð': 'Đặt lưỡi giữa 2 răng, rung dây thanh. Không phải /d/ hay /z/.',
    'r': 'Cong lưỡi ra sau, KHÔNG chạm vòm miệng. Khác hoàn toàn "r" tiếng Việt.',
    'l': 'Đầu lưỡi chạm vòm miệng phía trước. Khác với /r/.',
    'ʃ': 'Môi tròn, lưỡi lùi ra sau. Giống "s" nhưng dày hơn.',
    'ʒ': 'Giống /ʃ/ nhưng rung dây thanh.',
    'z': 'Giống /s/ nhưng rung dây thanh. Tiếng Việt không có âm này.',
    'ŋ': 'Âm "ng" cuối từ — giữ nguyên, không thêm /g/ phía sau.',
    'p_final': 'Phụ âm cuối — ngậm môi, bật hơi nhẹ. Không nuốt âm.',
    't_final': 'Phụ âm cuối — đầu lưỡi chạm vòm, bật nhẹ. Không nuốt.',
    'k_final': 'Phụ âm cuối — cuống lưỡi chạm vòm mềm, bật nhẹ.',
  };

  /// Trả về mẹo cho phoneme có accuracy < 80%
  /// Trả về null nếu không có mẹo hoặc accuracy đủ tốt
  static String? getTip(String phoneme, double accuracy) {
    if (accuracy >= 80) return null;
    return vietnameseTips[phoneme];
  }
}
```

### 8. TargetPhraseDetector (Logic Layer — Pure)

```dart
/// lib/features/conversation/logic/target_phrase_detector.dart
class TargetPhraseDetector {
  /// Kiểm tra transcript có chứa target phrases không
  static Map<String, bool> detectUsage(
    String transcript,
    List<String> targetPhrases,
  ) {
    final lowerTranscript = transcript.toLowerCase();
    return {
      for (final phrase in targetPhrases)
        phrase: lowerTranscript.contains(phrase.toLowerCase()),
    };
  }

  /// Tính tỷ lệ sử dụng target phrases (0.0 – 1.0)
  static double usageRate(Map<String, bool> usage) {
    if (usage.isEmpty) return 0;
    final used = usage.values.where((v) => v).length;
    return used / usage.length;
  }
}
```

### 9. AudioDurationValidator (Logic Layer — Pure)

```dart
/// lib/shared/services/audio_duration_validator.dart
class AudioDurationValidator {
  static const minDuration = Duration(seconds: 1);
  static const maxDuration = Duration(seconds: 60);

  /// Validate audio duration
  /// Trả về error message hoặc null nếu hợp lệ
  static String? validate(Duration duration) {
    if (duration < minDuration) {
      return 'Bản ghi quá ngắn. Hãy ghi từ 2–10 giây.';
    }
    if (duration > maxDuration) {
      return 'Bản ghi quá dài. Hãy ghi từ 2–10 giây.';
    }
    return null;
  }
}
```

### 10. SentenceSelector (Logic Layer — Pure)

```dart
/// lib/features/shadowing/logic/sentence_selector.dart
class SentenceSelector {
  /// Chọn câu shadowing phù hợp với level của user
  static List<Sentence> getAvailableSentences(
    List<Sentence> allSentences,
    String userLevel,
  ) {
    final allowedDifficulties = _getAllowedDifficulties(userLevel);
    return allSentences
        .where((s) => allowedDifficulties.contains(s.difficulty))
        .toList();
  }

  static Set<String> _getAllowedDifficulties(String level) {
    switch (level) {
      case 'easy':
        return {'easy'};
      case 'easy_medium':
        return {'easy', 'medium'};
      case 'medium_hard':
        return {'medium', 'hard'};
      default:
        return {'easy', 'medium', 'hard'};
    }
  }
}
```

---

## Daily Flow State Machine (freezed)

```dart
/// lib/features/daily_flow/providers/daily_flow_state.dart
enum DailyFlowStep { shadowing, conversation, summary }

@freezed
class DailyFlowState with _$DailyFlowState {
  const DailyFlowState._();

  const factory DailyFlowState({
    @Default(DailyFlowStep.shadowing) DailyFlowStep currentStep,
    @Default(0) int shadowingCompleted, // 0, 1, 2, 3
    @Default(false) bool conversationCompleted,
  }) = _DailyFlowState;

  DailyFlowStep get nextStep {
    if (shadowingCompleted < 3) return DailyFlowStep.shadowing;
    if (!conversationCompleted) return DailyFlowStep.conversation;
    return DailyFlowStep.summary;
  }

  bool get isComplete => currentStep == DailyFlowStep.summary;
}
```

---

## Edge Functions Interface

### /pronounce

```
POST /pronounce
Content-Type: multipart/form-data

Body:
  - audio: File (WAV, 16kHz, mono)
  - reference_text: String

Response: {
  "NBest": [{
    "PronunciationAssessment": {
      "AccuracyScore": number,
      "FluencyScore": number,
      "CompletenessScore": number
    },
    "Words": [{ "Word": string, "PronunciationAssessment": {...}, "Phonemes": [...] }]
  }]
}
```

### /transcribe

```
POST /transcribe
Content-Type: multipart/form-data

Body:
  - audio: File (WAV)

Response: {
  "text": string,
  "language": string,
  "words": [{ "word": string, "start": number, "end": number }]
}
```

### /chat

```
POST /chat
Content-Type: application/json

Body: {
  "messages": [{ "role": string, "content": string }],
  "scenario": { "system_prompt": string }
}

Response: {
  "choices": [{ "message": { "role": "assistant", "content": string } }]
}
```

### /tts

```
POST /tts
Content-Type: application/json

Body: { "text": string }

Response: audio/mpeg (binary)
```

---

## Conversation Flow (Sequence)

```
1. User chọn Scenario
2. App phát pre-cached audio tin nhắn đầu tiên của AI
3. App hiển thị text tin nhắn AI
4. User nhấn nút ghi âm → ghi âm giọng nói
5. App gửi audio → /transcribe → nhận transcript
6. App gửi transcript + history → /chat → nhận AI response
7. App hiển thị AI response text ngay lập tức
8. App gửi AI response → /tts → nhận audio → phát
9. Lặp lại bước 4–8 (tối đa 5 turns)
10. Sau turn cuối: gửi request feedback JSON → /chat
11. App hiển thị feedback (grammar_errors, vocabulary, positive, improve)
```

---

## Error Handling Strategy

```dart
sealed class AppError {
  String get userMessage;
}

class NetworkError extends AppError {
  @override
  String get userMessage => 'Mất kết nối internet. Vui lòng kiểm tra mạng.';
}

class ApiTimeoutError extends AppError {
  @override
  String get userMessage => 'Không thể xử lý audio. Thử lại?';
}

class InvalidAudioError extends AppError {
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

class TranscriptionError extends AppError {
  @override
  String get userMessage => 'Hãy thử nói bằng tiếng Anh hoặc nói chậm hơn.';
}

class TtsError extends AppError {
  @override
  String get userMessage => ''; // Fallback: hiển thị text, không cần thông báo
}
```

---

## Router Logic (GoRouter)

```dart
GoRouter appRouter(Ref ref) {
  return GoRouter(
    redirect: (context, state) {
      final user = ref.read(authProvider);
      final profile = ref.read(userProfileProvider);

      // Chưa đăng nhập → login
      if (user == null) return '/login';

      // Đã đăng nhập, chưa placement → placement
      if (profile?.placementCompleted != true) return '/placement';

      // Đã placement → daily flow
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const AuthScreen()),
      GoRoute(path: '/placement', builder: (_, __) => const PlacementScreen()),
      GoRoute(path: '/', builder: (_, __) => const DailyFlowScreen()),
      GoRoute(path: '/shadowing/:id', builder: (_, state) => ShadowingScreen(sentenceId: state.pathParameters['id']!)),
      GoRoute(path: '/conversation/:id', builder: (_, state) => ConversationScreen(scenarioId: state.pathParameters['id']!)),
      GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
    ],
  );
}
```

---

## Correctness Properties

*Một property là một đặc tính hoặc hành vi phải đúng trong mọi trường hợp thực thi hợp lệ của hệ thống — về cơ bản là một phát biểu hình thức về những gì hệ thống phải làm.*

### Property 1: Post-login routing logic

*For any* authenticated user, nếu user chưa hoàn thành placement (placementCompleted == false) thì router SHALL điều hướng đến PlacementScreen, ngược lại SHALL điều hướng đến DailyFlowScreen.

**Validates: Requirements 1.4, 1.5**

### Property 2: Placement level assignment

*For any* 3 điểm accuracy (mỗi điểm trong khoảng [0, 100]), mức khởi đầu được gán SHALL tuân theo: avg ≥ 80 → "medium_hard", 50 ≤ avg < 80 → "easy_medium", avg < 50 → "easy".

**Validates: Requirements 2.3, 2.4, 2.5, 2.6**

### Property 3: Word color mapping

*For any* word accuracy score trong khoảng [0, 100], màu hiển thị SHALL là: green nếu score ≥ 80, yellow nếu 50 ≤ score < 80, red nếu score < 50.

**Validates: Requirements 3.5**

### Property 4: Sentence difficulty serving

*For any* user với starting_level đã xác định, tất cả câu shadowing được phục vụ SHALL có difficulty nằm trong tập hợp cho phép của level đó (easy → {easy}, easy_medium → {easy, medium}, medium_hard → {medium, hard}).

**Validates: Requirements 3.9**

### Property 5: Phrase splitting round-trip

*For any* câu shadowing, khi chia thành các cụm từ (phrases), việc nối tất cả phrases lại SHALL tạo ra chuỗi tương đương với câu gốc.

**Validates: Requirements 4.2**

### Property 6: Phoneme tip lookup

*For any* phoneme có accuracy < 80 và tồn tại trong bảng tips, hệ thống SHALL trả về mẹo phát âm tiếng Việt tương ứng. Nếu accuracy ≥ 80, SHALL trả về null.

**Validates: Requirements 5.1**

### Property 7: Conversation turn limit

*For any* cuộc hội thoại AI, số lượng turns SHALL không vượt quá maxTurns (= 5) của Scenario.

**Validates: Requirements 6.7**

### Property 8: Average calculation (response time & accuracy)

*For any* danh sách N giá trị số (response times hoặc accuracy scores) với N > 0, giá trị trung bình SHALL bằng tổng các giá trị chia cho N.

**Validates: Requirements 6.9, 8.4, 11.1, 11.2**

### Property 9: Target phrase detection

*For any* transcript và danh sách target_phrases, hàm detectUsage SHALL trả về true cho một phrase khi và chỉ khi transcript chứa phrase đó (case-insensitive).

**Validates: Requirements 7.3**

### Property 10: Daily flow state machine

*For any* daily flow execution, các bước SHALL diễn ra theo thứ tự: shadowing (3 câu) → conversation (1 cuộc) → summary. Sau khi hoàn thành 3 câu shadowing, bước tiếp theo SHALL là conversation. Sau conversation, bước tiếp theo SHALL là summary.

**Validates: Requirements 9.1, 9.2, 9.3**

### Property 11: Mastery streak logic

*For any* chuỗi lần luyện tập một Sentence, correct_streak SHALL tăng 1 khi accuracy ≥ 80 và reset về 0 khi accuracy < 80. Sentence SHALL được đánh dấu mastered khi correct_streak ≥ 3.

**Validates: Requirements 10.1, 10.3, 10.4**

### Property 12: Audio duration validation

*For any* bản ghi âm có duration < 1 giây hoặc > 60 giây, hệ thống SHALL trả về thông báo lỗi. Với duration trong khoảng [1, 60] giây, SHALL trả về null (hợp lệ).

**Validates: Requirements 13.3**

### Property 13: Sentence data completeness

*For any* Sentence trong bộ nội dung, nó SHALL có các trường difficulty (thuộc {"easy", "medium", "hard"}), situation (non-empty), phrases (non-empty list), và targetGrammar (non-empty).

**Validates: Requirements 15.4, 15.5**


---

## Offline Voice Engine (sherpa-onnx)

### Architecture

```
┌─────────────────────────────────────────────────┐
│  Conversation_Module                             │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  VoiceServiceRouter                       │   │
│  │  (checks offlineEnabled setting)          │   │
│  └──────┬───────────────────────┬────────────┘   │
│         │ offline=true          │ offline=false   │
│         ▼                       ▼                │
│  ┌──────────────┐    ┌─────────────────────┐    │
│  │ Offline_Engine│    │ Online (Edge Fns)    │    │
│  │ sherpa-onnx   │    │ ElevenLabs→OpenAI   │    │
│  │ TTS: Kokoro   │    │ TTS: /tts           │    │
│  │ STT: Whisper  │    │ STT: /transcribe    │    │
│  └──────────────┘    └─────────────────────┘    │
└─────────────────────────────────────────────────┘
```

### Device Tier Detection

```dart
/// lib/features/settings/logic/device_tier_detector.dart
/// Pure logic — no Flutter imports except device_info_plus data.
enum DeviceTier { lowEnd, midRange, highEnd }

class DeviceTierDetector {
  /// Detect tier based on RAM.
  /// ≤4GB → lowEnd, 4-8GB → midRange, >8GB → highEnd
  static DeviceTier detect({required int totalRamMB}) {
    if (totalRamMB <= 4096) return DeviceTier.lowEnd;
    if (totalRamMB <= 8192) return DeviceTier.midRange;
    return DeviceTier.highEnd;
  }
}
```

### Model Registry

```dart
/// lib/features/settings/models/offline_model_config.dart
@freezed
class OfflineModelConfig with _$OfflineModelConfig {
  const factory OfflineModelConfig({
    required String sttModelName,    // "whisper-tiny" or "whisper-small"
    required String sttModelUrl,     // Download URL
    required int sttModelSizeMB,     // 40 or 150
    required String ttsModelName,    // "piper-en" or "kokoro-en"
    required String ttsModelUrl,     // Download URL
    required int ttsModelSizeMB,     // 30 or 150
  }) = _OfflineModelConfig;
}

/// Model configs per device tier
const modelConfigs = {
  DeviceTier.lowEnd: OfflineModelConfig(
    sttModelName: 'whisper-tiny.en',
    sttModelUrl: 'https://huggingface.co/.../whisper-tiny-en.onnx',
    sttModelSizeMB: 40,
    ttsModelName: 'piper-en-us-amy-low',
    ttsModelUrl: 'https://huggingface.co/.../piper-en-us-amy-low.onnx',
    ttsModelSizeMB: 30,
  ),
  DeviceTier.midRange: OfflineModelConfig(
    sttModelName: 'whisper-small.en',
    sttModelUrl: 'https://huggingface.co/.../whisper-small-en.onnx',
    sttModelSizeMB: 150,
    ttsModelName: 'kokoro-en-us',
    ttsModelUrl: 'https://huggingface.co/.../kokoro-82m-en.onnx',
    ttsModelSizeMB: 150,
  ),
  DeviceTier.highEnd: OfflineModelConfig(
    sttModelName: 'whisper-small.en',
    sttModelUrl: 'https://huggingface.co/.../whisper-small-en.onnx',
    sttModelSizeMB: 150,
    ttsModelName: 'kokoro-en-us',
    ttsModelUrl: 'https://huggingface.co/.../kokoro-82m-en.onnx',
    ttsModelSizeMB: 150,
  ),
};
```

### Model Manager State

```dart
/// lib/features/settings/providers/model_manager_state.dart
@freezed
sealed class ModelDownloadState with _$ModelDownloadState {
  const factory ModelDownloadState.notDownloaded() = _NotDownloaded;
  const factory ModelDownloadState.downloading({
    required double progress, // 0.0 – 1.0
    required int downloadedMB,
    required int totalMB,
  }) = _Downloading;
  const factory ModelDownloadState.downloaded() = _Downloaded;
  const factory ModelDownloadState.error(String message) = _Error;
}
```

### VoiceServiceRouter (Strategy Pattern)

```dart
/// lib/shared/services/voice_service_router.dart
/// Routes TTS/STT calls to offline or online based on user setting.
class VoiceServiceRouter {
  final bool offlineEnabled;
  final OfflineVoiceService? _offlineService;
  final ConversationRepository _onlineService;

  /// TTS: text → audio bytes
  Future<Uint8List> textToSpeech(String text) async {
    if (offlineEnabled && _offlineService != null) {
      return _offlineService!.synthesize(text);
    }
    return _onlineService.textToSpeech(text);
  }

  /// STT: audio bytes → transcript text
  Future<String> speechToText(Uint8List audio) async {
    if (offlineEnabled && _offlineService != null) {
      return _offlineService!.transcribe(audio);
    }
    return _onlineService.transcribe(audio);
  }
}
```

### Feature Structure

```
lib/features/settings/
├── logic/
│   └── device_tier_detector.dart
├── models/
│   └── offline_model_config.dart
├── providers/
│   ├── model_manager_provider.dart
│   └── model_manager_state.dart
├── repositories/
│   └── model_download_repository.dart
├── screens/
│   └── settings_screen.dart
└── widgets/
    └── model_download_card.dart

lib/shared/services/
├── offline_voice_service.dart      # sherpa-onnx wrapper
└── voice_service_router.dart       # strategy pattern router
```

### Dependencies

```yaml
# pubspec.yaml additions
dependencies:
  sherpa_onnx: ^1.10.0          # On-device TTS + STT
  device_info_plus: ^10.1.0     # Detect RAM, CPU
  dio: ^5.4.0                   # Download with progress + resume
```

### Correctness Properties (additions)

#### Property 14: Device tier classification

*For any* device RAM value, tier SHALL be: ≤4096MB → lowEnd, 4097–8192MB → midRange, >8192MB → highEnd.

**Validates: Requirements 17.1, 17.2**

#### Property 15: Voice routing

*For any* TTS/STT request, nếu offlineEnabled == true VÀ models đã downloaded, hệ thống SHALL route đến on-device engine. Ngược lại SHALL route đến online (ElevenLabs→OpenAI fallback).

**Validates: Requirements 16.3, 16.4, 16.5**


---

## Offline Pronunciation Scoring (wav2vec2 Forced Alignment)

### How It Works

```
User records audio → wav2vec2 forced alignment với reference text
  → Confidence score per word (0–100)
  → Color-coded display (same UI as Azure, nhưng word-level only)
```

Khác với Azure (phoneme-level), offline mode chỉ cho word-level scoring.
User được thông báo rõ: "Offline mode — word-level feedback".

### wav2vec2 Model Selection (adaptive)

```dart
/// Thêm vào model registry
const pronunciationModels = {
  DeviceTier.lowEnd: OfflineModelConfig(
    name: 'wav2vec2-base',
    url: 'https://huggingface.co/darjusul/wav2vec2-ONNX-collection/...',
    sizeMB: 360,
  ),
  DeviceTier.midRange: OfflineModelConfig(
    name: 'wav2vec2-large',
    url: 'https://huggingface.co/darjusul/wav2vec2-ONNX-collection/...',
    sizeMB: 1200,
  ),
  DeviceTier.highEnd: OfflineModelConfig(
    name: 'wav2vec2-large',
    url: 'https://huggingface.co/darjusul/wav2vec2-ONNX-collection/...',
    sizeMB: 1200,
  ),
};
```

### OfflinePronunciationService

```dart
/// lib/shared/services/offline_pronunciation_service.dart
class OfflinePronunciationService {
  /// Forced alignment: audio + reference text → word-level scores.
  ///
  /// Returns PronunciationResult with word scores (no phoneme detail).
  Future<PronunciationResult> assess({
    required Uint8List audio,
    required String referenceText,
  }) async {
    // 1. Run wav2vec2 forced alignment via ONNX Runtime
    // 2. Get confidence per word
    // 3. Map to PronunciationResult (phonemes list empty)
    final wordScores = await _runForcedAlignment(audio, referenceText);

    final words = wordScores.map((ws) => WordResult(
      word: ws.word,
      accuracyScore: ws.confidence * 100,
      errorType: ws.confidence < 0.5 ? 'Mispronunciation' : null,
      phonemes: [], // No phoneme detail in offline mode
    )).toList();

    final avgAccuracy = words.isEmpty ? 0.0
        : words.map((w) => w.accuracyScore).reduce((a, b) => a + b) / words.length;

    return PronunciationResult(
      accuracyScore: avgAccuracy,
      fluencyScore: avgAccuracy, // Approximate
      completenessScore: _calculateCompleteness(referenceText, words),
      words: words,
    );
  }
}
```

### Pronunciation Service Router (updated)

```dart
/// Extends VoiceServiceRouter to include pronunciation routing
class PronunciationServiceRouter {
  final bool offlineEnabled;
  final OfflinePronunciationService? _offlineService;
  final ShadowingRepository _onlineService; // Azure via Edge Function

  Future<PronunciationResult> assess({
    required String audioPath,
    required String referenceText,
  }) async {
    if (offlineEnabled && _offlineService != null) {
      final audio = await File(audioPath).readAsBytes();
      return _offlineService!.assess(audio: audio, referenceText: referenceText);
    }
    return _onlineService.pronounce(audioPath: audioPath, referenceText: referenceText);
  }
}
```

### Correctness Property 16: Offline pronunciation word scoring

*For any* audio + reference text khi offline mode bật, hệ thống SHALL trả về confidence score (0–100) cho mỗi word trong reference text. Words không detected trong audio SHALL có score = 0.

**Validates: Requirements 18.2, 18.3, 18.7**


---

## Multi-Provider LLM Fallback Chain

### Architecture

```
User message → LLMServiceRouter
  → Check Gemini 3.1 Flash-Lite quota
    → OK? → Call Gemini 3.1 Flash-Lite (free)
    → Exceeded? → Check Gemini 2.0 Flash quota
      → OK? → Call Gemini 2.0 Flash (free, 1500 req/day)
      → Exceeded? → Call GPT-4.1 nano (paid, $0.10/1M tokens)
```

### LLM Quota Tracker

```dart
/// lib/shared/services/llm_quota_tracker.dart
class LlmQuotaTracker {
  /// Track daily/monthly usage per provider.
  /// Stored in Supabase `api_usage` table.

  Future<bool> canUseGeminiFlashLite() async;  // monthly token limit
  Future<bool> canUseGeminiFlash() async;       // 1500 req/day
  Future<void> incrementUsage(String provider, int tokens) async;
}
```

### LLMServiceRouter

```dart
/// lib/shared/services/llm_service_router.dart
enum LlmProvider { geminiFlashLite, geminiFlash, gptNano, offlineLlm }

class LlmServiceRouter {
  final bool offlineEnabled;
  final LlmQuotaTracker _quotaTracker;
  final OnDeviceLlmService? _offlineService;

  /// Route chat request to best available provider.
  Future<String> chat({
    required List<Map<String, String>> messages,
    required String systemPrompt,
  }) async {
    if (offlineEnabled && _offlineService != null) {
      return _offlineService!.generate(messages, systemPrompt);
    }

    // Online fallback chain
    if (await _quotaTracker.canUseGeminiFlashLite()) {
      return _callGeminiFlashLite(messages, systemPrompt);
    }
    if (await _quotaTracker.canUseGeminiFlash()) {
      return _callGeminiFlash(messages, systemPrompt);
    }
    return _callGptNano(messages, systemPrompt);
  }
}
```

### On-Device LLM (adaptive per device)

```dart
/// Model selection per device tier
const llmModels = {
  DeviceTier.lowEnd: OfflineModelConfig(
    name: 'gemma-2b-it',
    url: 'https://huggingface.co/.../gemma-2b-it-q4.gguf',
    sizeMB: 1500,
  ),
  DeviceTier.midRange: OfflineModelConfig(
    name: 'phi-3-mini-4k-instruct',
    url: 'https://huggingface.co/.../phi-3-mini-q4.gguf',
    sizeMB: 2200,
  ),
  DeviceTier.highEnd: OfflineModelConfig(
    name: 'qwen3-4b-instruct',
    url: 'https://huggingface.co/.../qwen3-4b-q4.gguf',
    sizeMB: 2500,
  ),
};
```

### Edge Function /chat (updated)

Edge Function `/chat` cần hỗ trợ multiple providers:
- Nhận thêm field `provider` trong request body
- Route đến Gemini API hoặc OpenAI API tùy provider
- Env vars: `GEMINI_API_KEY`, `OPENAI_API_KEY`

### Correctness Property 17: LLM fallback chain order

*For any* chat request khi online, hệ thống SHALL thử providers theo thứ tự: Gemini 3.1 Flash-Lite → Gemini 2.0 Flash → GPT-4.1 nano. Chỉ chuyển sang provider tiếp theo khi provider hiện tại đạt quota limit.

**Validates: Requirements 19.1, 19.2, 19.3, 19.4**
