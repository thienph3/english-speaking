# Kế hoạch triển khai: SpeakEng MVP

## Tổng quan

Triển khai ứng dụng SpeakEng MVP theo cấu trúc 4 tuần: Week 1 (nền tảng + shadowing cơ bản), Week 2 (phoneme UI + placement + phrase mode), Week 3 (conversation flow), Week 4 (feedback + progress + daily flow + polish). Tech stack: Flutter + Riverpod, Supabase, Azure Speech, OpenAI APIs.

## Tasks

- [x] 1. Week 1 — Flutter project setup, audio, Supabase, Edge Function /pronounce, basic shadowing
  - [x] 1.1 Khởi tạo Flutter project và cấu trúc thư mục (Feature-First)
    - Chạy `flutter create` với package name `com.speakeng.app`
    - Tạo cấu trúc feature-first: `lib/core/`, `lib/features/auth/`, `lib/features/placement/`, `lib/features/shadowing/`, `lib/features/conversation/`, `lib/features/progress/`, `lib/features/daily_flow/`, `lib/shared/widgets/`, `lib/shared/services/`, `lib/data/`
    - Mỗi feature có sub-folders: `models/`, `repositories/`, `providers/`, `screens/`, `widgets/`, `logic/`
    - Thêm dependencies vào pubspec.yaml (pinned versions): `flutter_riverpod`, `riverpod_annotation`, `go_router`, `supabase_flutter`, `record`, `just_audio`, `freezed`, `freezed_annotation`, `json_serializable`, `json_annotation`, `build_runner`
    - Tạo `lib/core/constants.dart`, `lib/core/theme.dart` (AppColors, AppTypography, AppSpacing, AppRadius theo UI Design System), `lib/core/exceptions.dart`
    - _Requirements: 1.1, 15.1_

  - [x] 1.2 Cấu hình Supabase Auth và tạo AuthRepository
    - Khởi tạo Supabase client trong `lib/shared/services/supabase_service.dart`
    - Implement `lib/features/auth/repositories/auth_repository.dart` với signUp, signIn, signOut, authStateChanges
    - Tạo `lib/features/auth/providers/auth_provider.dart` (StateNotifier cho auth state)
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 1.3 Tạo màn hình Auth (Login/Register)
    - Implement `lib/features/auth/screens/auth_screen.dart` với form email/password (tuân theo Screen Layout Pattern từ UI Design System)
    - Xử lý đăng ký và đăng nhập, hiển thị lỗi cụ thể khi sai thông tin
    - Tạo `lib/core/router.dart` với GoRouter, redirect logic (chưa login → /login)
    - _Requirements: 1.1, 1.2, 1.3, 1.6_

  - [x] 1.4 Implement AudioService (ghi âm và phát audio)
    - Tạo `lib/shared/services/audio_service.dart` sử dụng package `record` để ghi âm WAV 16kHz mono
    - Implement phát audio với `just_audio` (play, pause, stop, speed control)
    - Thêm AudioDurationValidator (pure logic) để kiểm tra duration (1–60 giây)
    - _Requirements: 3.1, 3.3, 13.3_

  - [x] 1.5 Tạo Data Models cơ bản (freezed)
    - Implement `lib/features/shadowing/models/sentence.dart` (@freezed Sentence class)
    - Implement `lib/features/shadowing/models/pronunciation_result.dart` (@freezed PronunciationResult, WordResult, PhonemeResult)
    - Implement `lib/features/progress/models/sentence_progress.dart` (@freezed SentenceProgress class)
    - Chạy `dart run build_runner build` để generate code
    - _Requirements: 15.4, 15.5, 3.5_

  - [x] 1.6 Tạo Supabase Edge Function /pronounce
    - Tạo edge function proxy gọi Azure Speech Pronunciation Assessment API
    - Nhận input: audio file (WAV) + reference_text
    - Trả về: AccuracyScore, FluencyScore, CompletenessScore, Words với Phonemes
    - Xử lý timeout 10 giây
    - _Requirements: 3.4, 13.2_

  - [x] 1.7 Implement ShadowingRepository và basic shadowing flow
    - Tạo `lib/features/shadowing/repositories/shadowing_repository.dart` gọi Edge Function /pronounce
    - Tạo `lib/features/shadowing/providers/shadowing_state.dart` (@freezed ShadowingState unions: initial, playing, recording, processing, result, error)
    - Tạo `lib/features/shadowing/providers/shadowing_provider.dart` (StateNotifier<ShadowingState>)
    - Implement `lib/features/shadowing/screens/shadowing_screen.dart` cơ bản: play audio → record → gửi → hiển thị kết quả (tuân theo Shadowing Screen Layout từ UI Design System)
    - _Requirements: 3.1, 3.3, 3.4, 3.7_

  - [x] 1.8 Tạo nội dung JSON ban đầu (sentences + placement)
    - Tạo `lib/data/sentences.json` với ít nhất 20 câu shadowing mẫu (2 situations × 10 câu) để test
    - Tạo `lib/data/placement.json` với 3 câu placement (easy, medium, hard)
    - Implement `lib/shared/services/content_service.dart` để load và parse JSON
    - _Requirements: 15.1, 15.3, 15.4, 15.5_

- [x] 2. Checkpoint Week 1
  - Đảm bảo tất cả tests pass, hỏi user nếu có thắc mắc.

- [x] 3. Week 2 — Phoneme feedback UI, Vietnamese tips, phrase mode, speed control, placement, before/after
  - [x] 3.1 Implement Word Feedback UI (color-coded words)
    - Tạo `lib/features/shadowing/widgets/word_feedback_chip.dart` hiển thị từ với màu xanh/vàng/đỏ theo accuracy (dùng AppColors.correct/needsWork/wrong)
    - Implement `lib/features/shadowing/logic/word_color_mapper.dart` (pure static function)
    - Tích hợp vào ShadowingScreen: hiển thị Wrap layout WordFeedbackChip sau khi có kết quả
    - Accessibility: thêm underline cho từ sai (không chỉ dùng color)
    - _Requirements: 3.5_

  - [ ]* 3.2 Viết property test cho Word Color Mapping
    - **Property 3: Word color mapping**
    - **Validates: Requirements 3.5**

  - [x] 3.3 Implement Phoneme Detail và Vietnamese Tips
    - Tạo `lib/data/phoneme_tips.json` với mẹo phát âm tiếng Việt cho 11 phonemes
    - Implement `lib/features/shadowing/logic/phoneme_tip_lookup.dart` (PhonemeTipLookup — pure static, KHÔNG phải service)
    - Tạo `lib/features/shadowing/widgets/phoneme_tip_card.dart` hiển thị chi tiết phoneme sai + mẹo tiếng Việt
    - Khi user tap vào từ đỏ/vàng → hiển thị bottom sheet với phoneme details
    - _Requirements: 3.6, 5.1, 5.2, 5.3_

  - [ ]* 3.4 Viết property test cho Phoneme Tip Lookup
    - **Property 6: Phoneme tip lookup**
    - **Validates: Requirements 5.1**

  - [x] 3.5 Implement Phrase-by-Phrase Mode
    - Implement `lib/features/shadowing/logic/phrase_splitter.dart` (PhraseSplitter — pure static class)
    - Thêm UI toggle cho phrase mode trong ShadowingScreen (chỉ hiện khi câu > 5 từ)
    - Implement flow: luyện từng phrase → sau khi xong tất cả → luyện toàn câu
    - _Requirements: 4.1, 4.2, 4.3_

  - [ ]* 3.6 Viết property test cho Phrase Splitting Round-trip
    - **Property 5: Phrase splitting round-trip**
    - **Validates: Requirements 4.2**

  - [x] 3.7 Implement Speed Control cho audio playback
    - Thêm UI selector tốc độ (0.7x, 1.0x, 1.2x) vào ShadowingScreen
    - Tích hợp với AudioService.setSpeed()
    - _Requirements: 3.2_

  - [x] 3.8 Implement Mini Placement Test
    - Implement `lib/features/placement/logic/placement_calculator.dart` (PlacementCalculator — pure static)
    - Tạo `lib/features/placement/screens/placement_screen.dart`: hiển thị 3 câu tuần tự, ghi âm, gửi /pronounce, tính avg
    - Lưu kết quả vào bảng user_profiles (Supabase)
    - Cập nhật router: sau login lần đầu → placement → daily flow
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

  - [ ]* 3.9 Viết property test cho Placement Level Assignment
    - **Property 2: Placement level assignment**
    - **Validates: Requirements 2.3, 2.4, 2.5, 2.6**

  - [x] 3.10 Implement Before/After Recording Storage
    - Tạo logic trong ShadowingRepository: lần đầu luyện → lưu audio "before" lên Supabase Storage
    - Khi đạt mastery → lưu audio "after" lên Supabase Storage
    - Tạo bảng recordings trong Supabase với RLS policies
    - Thêm UI cho phép nghe lại before/after
    - _Requirements: 12.1, 12.2, 12.3_

  - [x] 3.11 Implement SentenceSelector (phục vụ câu theo level)
    - Implement `lib/features/shadowing/logic/sentence_selector.dart` (SentenceSelector — pure static class)
    - Tích hợp vào ShadowingProvider: chỉ phục vụ câu phù hợp với starting_level của user
    - _Requirements: 3.8, 3.9_

  - [ ]* 3.12 Viết property test cho Sentence Difficulty Serving
    - **Property 4: Sentence difficulty serving**
    - **Validates: Requirements 3.9**

- [x] 4. Checkpoint Week 2
  - Đảm bảo tất cả tests pass, hỏi user nếu có thắc mắc.

- [x] 5. Week 3 — Edge Functions (transcribe, chat, tts), Conversation flow, loading states, hints
  - [x] 5.1 Tạo Supabase Edge Function /transcribe
    - Tạo edge function proxy gọi OpenAI Whisper API
    - Nhận input: audio file (WAV)
    - Trả về: text transcript, detected language
    - _Requirements: 6.3_

  - [x] 5.2 Tạo Supabase Edge Function /chat
    - Tạo edge function proxy gọi OpenAI GPT-4o-mini
    - Nhận input: messages array + scenario config (system_prompt)
    - Trả về: AI response text
    - Hỗ trợ feedback mode: trả về JSON có cấu trúc khi hội thoại kết thúc
    - _Requirements: 6.4, 7.2, 8.1_

  - [x] 5.3 Tạo Supabase Edge Function /tts
    - Tạo edge function proxy gọi OpenAI TTS API
    - Nhận input: text string
    - Trả về: audio binary (mp3)
    - _Requirements: 6.5_

  - [x] 5.4 Tạo Scenario model và nội dung scenarios
    - Implement `lib/features/conversation/models/scenario.dart` (@freezed Scenario class)
    - Tạo `lib/data/scenarios.json` với 3 kịch bản hội thoại (target_phrases, target_grammar, hints, system_prompt)
    - Pre-generate audio cho first_message của mỗi scenario
    - _Requirements: 6.1, 6.2, 7.1, 15.2_

  - [x] 5.5 Implement ConversationRepository
    - Tạo `lib/features/conversation/repositories/conversation_repository.dart` gọi /transcribe, /chat, /tts
    - Quản lý conversation history (messages array)
    - Implement logic giới hạn 5 turns
    - _Requirements: 6.3, 6.4, 6.5, 6.7_

  - [ ]* 5.6 Viết property test cho Conversation Turn Limit
    - **Property 7: Conversation turn limit**
    - **Validates: Requirements 6.7**

  - [x] 5.7 Implement ConversationProvider (state management)
    - Tạo `lib/features/conversation/providers/conversation_state.dart` (@freezed ConversationState unions: idle, recording, transcribing, thinking, speaking, feedback)
    - Tạo `lib/features/conversation/providers/conversation_provider.dart` (StateNotifier<ConversationState>)
    - Implement `lib/features/conversation/logic/response_time_calculator.dart` (pure static — KHÔNG giữ mutable state)
    - _Requirements: 6.9, 14.1_

  - [ ]* 5.8 Viết property test cho Average Calculation
    - **Property 8: Average calculation (response time & accuracy)**
    - **Validates: Requirements 6.9, 8.4, 11.1, 11.2**

  - [x] 5.9 Implement ConversationScreen UI
    - Tạo `lib/features/conversation/screens/conversation_screen.dart` (tuân theo Conversation Screen Layout từ UI Design System)
    - Tạo `lib/features/conversation/widgets/chat_bubble.dart` (AI: left/surfaceVariant, User: right/primaryLight, max 80% width)
    - Tạo `lib/features/conversation/widgets/typing_indicator.dart` (3 dots bounce animation + "Đang suy nghĩ...")
    - Hiển thị text AI ngay khi có, phát audio khi TTS sẵn sàng
    - Dùng `lib/shared/widgets/recording_button.dart` (72x72, pulse khi recording)
    - _Requirements: 6.2, 6.6, 14.1, 14.2_

  - [x] 5.10 Implement Hint System
    - Hiển thị nút "Gợi ý" trong ConversationScreen
    - Khi user nhấn → hiển thị hint từ scenario config
    - _Requirements: 6.8_

  - [x] 5.11 Implement TargetPhraseDetector
    - Tạo `lib/features/conversation/logic/target_phrase_detector.dart` (pure static class)
    - Tích hợp vào ConversationProvider: sau mỗi turn, detect target phrases đã sử dụng
    - _Requirements: 7.2, 7.3_

  - [ ]* 5.12 Viết property test cho Target Phrase Detection
    - **Property 9: Target phrase detection**
    - **Validates: Requirements 7.3**

  - [x] 5.13 Pre-cache first message audio cho Scenarios
    - Implement logic trong ConversationRepository: kiểm tra cache → nếu chưa có → gọi /tts → lưu local
    - Giảm thời gian chờ khi bắt đầu hội thoại
    - _Requirements: 14.3_

- [x] 6. Checkpoint Week 3
  - Đảm bảo tất cả tests pass, hỏi user nếu có thắc mắc.

- [x] 7. Week 4 — Post-conversation feedback, progress dashboard, daily flow, error handling, polish
  - [x] 7.1 Implement Post-Conversation Feedback
    - Sau turn cuối (hoặc user kết thúc sớm), gửi request feedback JSON đến /chat
    - Parse response: grammar_errors, vocabulary_suggestions, positive, improve
    - Tạo `lib/features/conversation/screens/feedback_screen.dart` hiển thị feedback chi tiết
    - Hiển thị mức độ sử dụng target_phrases và avg response time
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

  - [x] 7.2 Implement MasteryCalculator và ProgressRepository
    - Implement `lib/features/shadowing/logic/mastery_calculator.dart` (MasteryCalculator — pure static class)
    - Tạo `lib/features/progress/repositories/progress_repository.dart`: CRUD cho sentence_progress, daily_metrics
    - Tích hợp vào ShadowingProvider: sau mỗi lần luyện → cập nhật streak, check mastery
    - _Requirements: 10.1, 10.3, 10.4_

  - [ ]* 7.3 Viết property test cho Mastery Streak Logic
    - **Property 11: Mastery streak logic**
    - **Validates: Requirements 10.1, 10.3, 10.4**

  - [x] 7.4 Implement Progress Dashboard
    - Tạo `lib/features/progress/providers/progress_provider.dart` (load metrics từ Supabase)
    - Tạo `lib/features/progress/screens/progress_screen.dart`: hiển thị ProgressCard (sentences mastered, avg accuracy, avg response time)
    - Hiển thị so sánh tuần này vs tuần trước (dùng AppColors.success/error cho +/-)
    - Lưu daily_metrics vào Supabase mỗi ngày
    - _Requirements: 10.2, 11.1, 11.2, 11.3, 11.4_

  - [x] 7.5 Implement Daily Flow (state machine + UI)
    - Implement `lib/features/daily_flow/providers/daily_flow_state.dart` (@freezed DailyFlowState, DailyFlowStep enum)
    - Implement `lib/features/daily_flow/providers/daily_flow_provider.dart` (StateNotifier<DailyFlowState>)
    - Tạo `lib/features/daily_flow/screens/daily_flow_screen.dart`: orchestrate 3 shadowing → 1 conversation → summary (tuân theo Daily Flow Screen Layout từ UI Design System)
    - Tạo summary screen hiển thị: câu mới mastered, thay đổi response time, avg accuracy
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

  - [ ]* 7.6 Viết property test cho Daily Flow State Machine
    - **Property 10: Daily flow state machine**
    - **Validates: Requirements 9.1, 9.2, 9.3**

  - [x] 7.7 Implement Router Logic hoàn chỉnh
    - Cập nhật `lib/core/router.dart` với đầy đủ redirect logic
    - Chưa login → /login, login lần đầu → /placement, đã placement → / (daily flow)
    - _Requirements: 1.4, 1.5_

  - [ ]* 7.8 Viết property test cho Post-login Routing Logic
    - **Property 1: Post-login routing logic**
    - **Validates: Requirements 1.4, 1.5**

  - [x] 7.9 Implement Error Handling toàn diện
    - Implement `lib/core/exceptions.dart` với sealed class AppError (NetworkError, ApiTimeoutError, InvalidAudioError, TranscriptionError, TtsError)
    - Thêm connectivity check: hiển thị thông báo mất mạng, vô hiệu hóa tính năng cần mạng
    - Xử lý timeout 10 giây cho /pronounce
    - Xử lý audio silence detection, audio quá ngắn/dài
    - Xử lý Whisper trả về tiếng Việt hoặc accuracy < 20%
    - Fallback khi /tts fail: hiển thị text không có audio
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6_

  - [ ]* 7.10 Viết property test cho Audio Duration Validation
    - **Property 12: Audio duration validation**
    - **Validates: Requirements 13.3**

  - [x] 7.11 Hoàn thiện nội dung 100 câu shadowing
    - Cập nhật `lib/data/sentences.json` với đầy đủ 100 câu (10 situations × 10 câu)
    - Đảm bảo mỗi câu có difficulty, situation, phrases, targetGrammar
    - _Requirements: 15.1, 15.4, 15.5_

  - [ ]* 7.12 Viết property test cho Sentence Data Completeness
    - **Property 13: Sentence data completeness**
    - **Validates: Requirements 15.4, 15.5**

  - [x] 7.13 Tạo Database Schema trên Supabase
    - Tạo SQL migration: bảng recordings, sentence_progress, daily_metrics, user_profiles
    - Thiết lập RLS policies cho tất cả bảng
    - _Requirements: 2.7, 10.3, 11.3, 12.1_

- [x] 8. Checkpoint cuối — Final verification
  - Đảm bảo tất cả tests pass, hỏi user nếu có thắc mắc.

## Notes

- Tasks đánh dấu `*` là optional và có thể bỏ qua để ship MVP nhanh hơn
- Mỗi task tham chiếu requirements cụ thể để đảm bảo traceability
- Checkpoints đảm bảo validation tăng dần sau mỗi tuần
- Property tests kiểm tra correctness properties từ design document
- Unit tests kiểm tra edge cases và ví dụ cụ thể
- Nội dung JSON (sentences, scenarios) có thể phát triển song song với code

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "1.4", "1.5", "1.8"] },
    { "id": 2, "tasks": ["1.3", "1.6"] },
    { "id": 3, "tasks": ["1.7"] },
    { "id": 4, "tasks": ["3.1", "3.3", "3.5", "3.7", "3.8", "3.11"] },
    { "id": 5, "tasks": ["3.2", "3.4", "3.6", "3.9", "3.10", "3.12"] },
    { "id": 6, "tasks": ["5.1", "5.2", "5.3", "5.4"] },
    { "id": 7, "tasks": ["5.5", "5.11"] },
    { "id": 8, "tasks": ["5.6", "5.7", "5.8", "5.12", "5.13"] },
    { "id": 9, "tasks": ["5.9", "5.10"] },
    { "id": 10, "tasks": ["7.1", "7.2", "7.13"] },
    { "id": 11, "tasks": ["7.3", "7.4", "7.5", "7.10", "7.11"] },
    { "id": 12, "tasks": ["7.6", "7.7", "7.9", "7.12"] },
    { "id": 13, "tasks": ["7.8"] }
  ]
}
```


---

## Phase 2: Offline TTS/STT Engine

- [ ] 9. Offline Voice Engine — adaptive model download + on-device TTS/STT
  - [ ] 9.1 Implement DeviceTierDetector (pure logic)
    - Tạo `lib/features/settings/logic/device_tier_detector.dart`
    - Detect RAM via `device_info_plus` → classify lowEnd/midRange/highEnd
    - _Requirements: 17.1, 17.2_

  - [ ] 9.2 Tạo OfflineModelConfig và model registry
    - Tạo `lib/features/settings/models/offline_model_config.dart` (@freezed)
    - Define model URLs, sizes cho mỗi tier (whisper-tiny/small, piper/kokoro)
    - _Requirements: 17.3, 17.4_

  - [ ] 9.3 Implement ModelDownloadRepository
    - Tạo `lib/features/settings/repositories/model_download_repository.dart`
    - Download models via `dio` với progress callback + resume support
    - Lưu vào app internal storage (getApplicationSupportDirectory)
    - Checksum verification sau download
    - _Requirements: 17.5, 17.6, 17.7, 17.8, 17.9_

  - [ ] 9.4 Implement ModelManagerProvider (state management)
    - Tạo `lib/features/settings/providers/model_manager_state.dart` (@freezed)
    - Tạo `lib/features/settings/providers/model_manager_provider.dart`
    - States: notDownloaded, downloading(progress), downloaded, error
    - Auto-start download sau splash screen (background)
    - _Requirements: 17.5, 17.6_

  - [ ] 9.5 Implement OfflineVoiceService (sherpa-onnx wrapper)
    - Tạo `lib/shared/services/offline_voice_service.dart`
    - Initialize sherpa-onnx với model paths
    - Methods: synthesize(text) → Uint8List, transcribe(audio) → String
    - Thêm `sherpa_onnx` dependency vào pubspec.yaml
    - _Requirements: 16.3, 16.4_

  - [ ] 9.6 Implement VoiceServiceRouter (strategy pattern)
    - Tạo `lib/shared/services/voice_service_router.dart`
    - Route TTS/STT calls: offline (sherpa-onnx) hoặc online (Edge Functions)
    - Dựa trên user setting + model availability
    - _Requirements: 16.1, 16.3, 16.4, 16.5_

  - [ ] 9.7 Tạo Settings Screen
    - Tạo `lib/features/settings/screens/settings_screen.dart`
    - Toggle bật/tắt offline TTS/STT (disabled nếu chưa download)
    - Hiển thị model download status + progress
    - Hiển thị device tier detected
    - Thêm route /settings vào router
    - _Requirements: 16.1, 16.2, 16.6_

  - [ ] 9.8 Integrate VoiceServiceRouter vào ConversationProvider
    - Cập nhật ConversationProvider để dùng VoiceServiceRouter thay vì gọi trực tiếp repository
    - Khi offline enabled → dùng on-device, khi disabled → dùng online (ElevenLabs→OpenAI fallback)
    - _Requirements: 16.3, 16.4, 16.5_

  - [ ] 9.9 Background model download sau splash screen
    - Trigger download tự động khi app khởi động (nếu chưa có models)
    - Không block UI — download ở background
    - Hiển thị subtle indicator trên home screen khi đang download
    - _Requirements: 17.5_


  - [ ] 9.10 Implement OfflinePronunciationService (wav2vec2 forced alignment)
    - Tạo `lib/shared/services/offline_pronunciation_service.dart`
    - Load wav2vec2 ONNX model via ONNX Runtime
    - Implement forced alignment: audio + reference text → confidence per word
    - Return PronunciationResult (word-level only, phonemes = empty)
    - _Requirements: 18.1, 18.2, 18.7_

  - [ ] 9.11 Implement PronunciationServiceRouter
    - Tạo `lib/shared/services/pronunciation_service_router.dart`
    - Route: offline enabled → wav2vec2 word-level, offline disabled → Azure phoneme-level
    - Cập nhật ShadowingProvider để dùng router thay vì gọi trực tiếp ShadowingRepository
    - _Requirements: 18.1, 18.3_

  - [ ] 9.12 Update Shadowing UI cho offline mode indicator
    - Hiển thị badge "Offline (word-level)" hoặc "Online (phoneme-level)" trên ShadowingScreen
    - Khi offline: ẩn phoneme detail bottom sheet (tap word chỉ hiển thị score, không có tips)
    - _Requirements: 18.4, 18.5_

  - [ ] 9.13 Cập nhật Model Registry thêm wav2vec2
    - Thêm wav2vec2-base (~360MB) cho low-end devices
    - Thêm wav2vec2-large (~1.2GB) cho mid/high-end devices
    - Cập nhật ModelDownloadRepository để download thêm pronunciation model
    - Cập nhật Settings screen hiển thị 3 models: TTS + STT + Pronunciation
    - _Requirements: 18.6, 17.3, 17.4_


- [ ] 10. Multi-Provider LLM Fallback + Offline LLM
  - [ ] 10.1 Implement LlmQuotaTracker
    - Tạo `lib/shared/services/llm_quota_tracker.dart`
    - Track usage per provider (Gemini Flash-Lite, Gemini Flash, GPT-4.1 nano)
    - Lưu vào Supabase `api_usage` table (thêm columns cho LLM tracking)
    - Methods: canUseGeminiFlashLite(), canUseGeminiFlash(), incrementUsage()
    - _Requirements: 19.2_

  - [ ] 10.2 Implement LlmServiceRouter (online fallback chain)
    - Tạo `lib/shared/services/llm_service_router.dart`
    - Fallback chain: Gemini 3.1 Flash-Lite → Gemini 2.0 Flash → GPT-4.1 nano
    - Check quota trước mỗi request, auto-switch khi exceeded
    - Log provider used per request
    - _Requirements: 19.1, 19.3, 19.4, 19.5_

  - [ ] 10.3 Update Edge Function /chat cho multi-provider
    - Cập nhật `supabase/functions/chat/index.ts`
    - Nhận field `provider` trong request body ("gemini-flash-lite", "gemini-flash", "gpt-nano")
    - Route đến Gemini API hoặc OpenAI API tùy provider
    - Thêm env vars: GEMINI_API_KEY
    - _Requirements: 19.1_

  - [ ] 10.4 Cập nhật SQL migration cho LLM quota tracking
    - Thêm columns vào `api_usage`: gemini_flash_lite_tokens, gemini_flash_requests, gpt_nano_tokens
    - Thêm RPC functions cho increment
    - _Requirements: 19.2_

  - [ ] 10.5 Implement OnDeviceLlmService
    - Tạo `lib/shared/services/on_device_llm_service.dart`
    - Load GGUF model via llama.cpp hoặc MediaPipe LLM Inference API
    - Method: generate(messages, systemPrompt) → String
    - Handle timeout (>30s → suggest switch to online)
    - _Requirements: 20.1, 20.4, 20.6_

  - [ ] 10.6 Cập nhật Model Registry thêm LLM models
    - Thêm LLM model configs per device tier (gemma-2b, phi-3-mini, qwen3-4b)
    - Cập nhật ModelDownloadRepository để download LLM model
    - Cập nhật Settings screen hiển thị LLM model status
    - _Requirements: 20.2_

  - [ ] 10.7 Integrate LlmServiceRouter vào ConversationProvider
    - Cập nhật ConversationProvider để dùng LlmServiceRouter thay vì gọi trực tiếp /chat
    - Khi offline enabled → dùng on-device LLM
    - Khi online → dùng fallback chain (Gemini → GPT)
    - Hiển thị indicator "Offline AI" khi dùng local model
    - _Requirements: 19.1, 20.1, 20.5_

  - [ ] 10.8 Hiển thị cảnh báo chất lượng offline
    - Khi user bật offline LLM lần đầu → hiển thị dialog cảnh báo chất lượng có thể kém hơn
    - Hiển thị "Offline AI" badge trên ConversationScreen
    - Nếu response >30s → hiển thị option chuyển sang online
    - _Requirements: 20.3, 20.5, 20.6_
