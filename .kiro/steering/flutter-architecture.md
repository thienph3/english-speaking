---
inclusion: auto
---

# Flutter Architecture — SpeakEng

## Kiến trúc tổng thể: Feature-First + Clean Architecture (simplified)

```
lib/
├── main.dart                    # Entry point, ProviderScope
├── app.dart                     # MaterialApp.router
├── core/                        # Shared utilities
│   ├── constants.dart
│   ├── theme.dart
│   ├── router.dart
│   └── exceptions.dart
├── features/                    # Feature modules
│   ├── auth/
│   ├── placement/
│   ├── shadowing/
│   ├── conversation/
│   ├── progress/
│   └── daily_flow/
├── shared/                      # Shared widgets & services
│   ├── widgets/
│   └── services/
└── data/                        # Static JSON content
    ├── sentences.json
    ├── scenarios.json
    ├── placement.json
    └── phoneme_tips.json
```

## Feature Module Structure

Mỗi feature có cấu trúc giống nhau:

```
features/shadowing/
├── models/                      # Data classes cho feature này
│   ├── sentence.dart
│   └── pronunciation_result.dart
├── repositories/                # Data access layer
│   └── shadowing_repository.dart
├── providers/                   # Riverpod providers + state
│   ├── shadowing_provider.dart
│   └── shadowing_state.dart
├── screens/                     # Full-page screens
│   └── shadowing_screen.dart
├── widgets/                     # Feature-specific widgets
│   ├── word_feedback_chip.dart
│   └── phoneme_tip_card.dart
└── logic/                       # Pure business logic (no dependencies)
    ├── mastery_calculator.dart
    └── phrase_splitter.dart
```

## Layer Rules

### 1. Logic Layer (Pure Dart — no imports from Flutter/packages)

- Chứa business logic thuần túy
- **KHÔNG** import Flutter, Riverpod, Supabase
- **KHÔNG** có side effects (no I/O, no network)
- Input → Output, dễ test
- Ví dụ: `PlacementCalculator`, `MasteryCalculator`, `PhraseSplitter`, `WordColorMapper`

```dart
// ✅ Pure logic — dễ test
class PlacementCalculator {
  static String calculateLevel(List<double> scores) {
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    if (avg >= 80) return 'medium_hard';
    if (avg >= 50) return 'easy_medium';
    return 'easy';
  }
}
```

### 2. Repository Layer (Data access)

- Gọi Supabase, Edge Functions, local storage
- Trả về domain models (không trả raw JSON)
- Handle network errors, parse responses
- **KHÔNG** chứa business logic
- **KHÔNG** import Flutter widgets

```dart
class ShadowingRepository {
  final SupabaseClient _supabase;

  Future<PronunciationResult> pronounce(Uint8List audio, String referenceText) async {
    // Gọi edge function, parse response, return domain model
  }
}
```

### 3. Provider Layer (State management — Riverpod)

- Kết nối Repository + Logic → State
- Quản lý UI state (loading, error, data)
- **1 provider file = 1 feature state**
- Dùng `StateNotifier` hoặc `AsyncNotifier`

```dart
// State class dùng freezed
@freezed
class ShadowingState with _$ShadowingState {
  const factory ShadowingState.initial() = _Initial;
  const factory ShadowingState.playing(Sentence sentence) = _Playing;
  const factory ShadowingState.recording() = _Recording;
  const factory ShadowingState.processing() = _Processing;
  const factory ShadowingState.result(PronunciationResult result) = _Result;
  const factory ShadowingState.error(AppError error) = _Error;
}
```

### 4. Screen Layer (UI)

- Chỉ chứa layout và navigation logic
- Đọc state từ providers, dispatch actions
- **KHÔNG** chứa business logic
- **KHÔNG** gọi repository trực tiếp
- Mỗi screen: 1 file, tối đa 200 LOC

### 5. Widget Layer (Reusable UI components)

- Stateless khi có thể
- Nhận data qua constructor (không đọc provider trực tiếp)
- Tái sử dụng được giữa các screens

## State Management Pattern (Riverpod)

### Provider Types

```dart
// 1. Simple value provider
final supabaseProvider = Provider<SupabaseClient>((ref) => ...);

// 2. Repository provider
final shadowingRepoProvider = Provider<ShadowingRepository>((ref) {
  return ShadowingRepository(ref.read(supabaseProvider));
});

// 3. State provider (cho complex state)
final shadowingProvider = StateNotifierProvider<ShadowingNotifier, ShadowingState>((ref) {
  return ShadowingNotifier(ref.read(shadowingRepoProvider));
});

// 4. Future provider (cho one-shot async data)
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  return ref.read(authRepoProvider).getProfile();
});
```

### State Pattern

- Dùng `freezed` unions cho complex states (loading/error/data)
- Dùng simple classes cho straightforward states
- **KHÔNG** dùng `ChangeNotifier` — chỉ dùng `StateNotifier` hoặc `Notifier`

## Navigation (GoRouter)

- Declarative routing với redirect guards
- Route paths: lowercase, kebab-case
- Nested routes cho related screens

```dart
// Routes
/login
/placement
/                          → DailyFlowScreen (home)
/shadowing/:sentenceId
/conversation/:scenarioId
/progress
```

## Dependency Injection

- Tất cả dependencies inject qua Riverpod providers
- **KHÔNG** dùng service locator pattern
- **KHÔNG** dùng global singletons
- Repositories nhận dependencies qua constructor

## Async Patterns

- Dùng `AsyncValue` cho async state trong UI
- Dùng `ref.watch` cho reactive updates
- Dùng `ref.read` cho one-shot actions (button press)
- **KHÔNG** dùng `FutureBuilder` hoặc `StreamBuilder` — dùng Riverpod thay thế

## Model Serialization

- Dùng `freezed` + `json_serializable` cho tất cả models
- Immutable by default
- `copyWith` cho state updates

```dart
@freezed
class Sentence with _$Sentence {
  const factory Sentence({
    required String id,
    required String text,
    required String situation,
    required List<String> phrases,
    required String targetGrammar,
    required String difficulty,
    String? audioAssetPath,
  }) = _Sentence;

  factory Sentence.fromJson(Map<String, dynamic> json) =>
      _$SentenceFromJson(json);
}
```
