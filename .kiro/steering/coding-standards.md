---
inclusion: auto
---

# Coding Standards — SpeakEng

## Ngôn ngữ & Framework

- **Dart** (Flutter) cho mobile app
- **TypeScript** (Deno) cho Supabase Edge Functions
- Dart SDK: >=3.0.0
- Flutter: stable channel

## Giới hạn file

- Mỗi file Dart: **tối đa 200 LOC** (không tính comments và blank lines)
- Nếu vượt 200 LOC → tách thành file riêng
- Mỗi class: **tối đa 1 public class per file** (private helper classes OK)
- Mỗi function/method: **tối đa 30 LOC**
- Nếu function > 30 LOC → extract helper methods

## Naming Conventions

### Dart

- Files: `snake_case.dart` (ví dụ: `auth_repository.dart`)
- Classes: `PascalCase` (ví dụ: `AuthRepository`)
- Variables/functions: `camelCase` (ví dụ: `currentUser`)
- Constants: `camelCase` (ví dụ: `maxTurns = 5`)
- Private members: prefix `_` (ví dụ: `_supabase`)
- Providers: suffix `Provider` (ví dụ: `authProvider`)
- Notifiers: suffix `Notifier` (ví dụ: `AuthNotifier`)

### TypeScript (Edge Functions)

- Files: `kebab-case.ts` (ví dụ: `pronounce.ts`)
- Functions: `camelCase`
- Constants: `UPPER_SNAKE_CASE`

## Import Order

```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:convert';

// 2. Flutter
import 'package:flutter/material.dart';

// 3. Third-party packages (alphabetical)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 4. Project imports (alphabetical)
import 'package:speakeng/core/constants.dart';
import 'package:speakeng/models/sentence.dart';
```

## Error Handling

- **KHÔNG** dùng `try-catch` chung chung — luôn catch exception cụ thể
- Dùng `sealed class AppError` cho domain errors
- Repository methods trả về `Future<Result<T>>` hoặc throw typed exceptions
- UI layer catch errors và hiển thị user-friendly message

```dart
// ✅ Đúng
try {
  final result = await repository.pronounce(audio, text);
  return result;
} on TimeoutException {
  throw ApiTimeoutError();
} on SocketException {
  throw NetworkError();
}

// ❌ Sai
try {
  final result = await repository.pronounce(audio, text);
  return result;
} catch (e) {
  print(e); // KHÔNG
}
```

## Comments & Documentation

- **Public APIs**: luôn có doc comment `///`
- **Private methods**: comment khi logic phức tạp
- **KHÔNG** comment obvious code
- **TODO**: format `// TODO(tên): mô tả` — phải có tên người

```dart
/// Tính mức khởi đầu từ 3 điểm accuracy placement.
///
/// - avg ≥ 80 → medium_hard
/// - 50 ≤ avg < 80 → easy_medium
/// - avg < 50 → easy
static String calculateLevel(List<double> scores) { ... }
```

## Null Safety

- **KHÔNG** dùng `!` (bang operator) trừ khi 100% chắc chắn không null
- Prefer `?.` và `??` over null checks
- Dùng `required` cho named parameters bắt buộc

## Testing

- Unit tests cho business logic (models, calculators, validators)
- Widget tests cho UI components quan trọng
- Test file đặt tại `test/` mirror cấu trúc `lib/`
- Naming: `{file_name}_test.dart`
- Mỗi test case: 1 assertion chính (AAA pattern: Arrange, Act, Assert)

## Git Commits

- Format: `type(scope): message` (conventional commits)
- Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
- Scope: `auth`, `shadowing`, `conversation`, `progress`, `edge-fn`, `ui`
- Message: tiếng Anh, lowercase, không dấu chấm cuối
- Ví dụ: `feat(shadowing): add phoneme feedback UI with color-coded words`

## Dependencies

- Chỉ thêm dependency khi thực sự cần
- Prefer Flutter/Dart built-in trước khi dùng package
- Pin exact versions trong pubspec.yaml
- Core packages đã chọn (KHÔNG thay đổi):
  - State: `flutter_riverpod` + `riverpod_annotation`
  - Router: `go_router`
  - Backend: `supabase_flutter`
  - Audio record: `record`
  - Audio play: `just_audio`
  - Serialization: `freezed` + `json_serializable`
  - HTTP: `dio` (cho custom API calls nếu cần)
