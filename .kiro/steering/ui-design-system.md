---
inclusion: auto
---

# UI Design System — SpeakEng

## Design Philosophy

- **Minimal & focused** — không có visual clutter, user tập trung vào luyện nói
- **Large touch targets** — nút ghi âm lớn, dễ bấm khi đang tập trung nghe
- **Clear feedback** — màu sắc rõ ràng cho đúng/sai, animation cho loading
- **Vietnamese-first UI text** — tất cả UI text bằng tiếng Việt
- **Content in English** — sentences, scenarios, AI responses bằng tiếng Anh

## Color Palette

```dart
// core/theme.dart
class AppColors {
  // Primary
  static const primary = Color(0xFF2563EB);       // Blue 600
  static const primaryLight = Color(0xFFDBEAFE);  // Blue 100
  static const primaryDark = Color(0xFF1D4ED8);   // Blue 700

  // Pronunciation feedback
  static const correct = Color(0xFF16A34A);       // Green 600
  static const needsWork = Color(0xFFCA8A04);     // Yellow 600
  static const wrong = Color(0xFFDC2626);         // Red 600
  static const missed = Color(0xFF9CA3AF);        // Gray 400

  // Background
  static const background = Color(0xFFF9FAFB);    // Gray 50
  static const surface = Color(0xFFFFFFFF);       // White
  static const surfaceVariant = Color(0xFFF3F4F6); // Gray 100

  // Text
  static const textPrimary = Color(0xFF111827);   // Gray 900
  static const textSecondary = Color(0xFF6B7280); // Gray 500
  static const textOnPrimary = Color(0xFFFFFFFF); // White

  // Semantic
  static const error = Color(0xFFDC2626);         // Red 600
  static const success = Color(0xFF16A34A);       // Green 600
}
```

## Typography

```dart
class AppTypography {
  // Headings
  static const h1 = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3);
  static const h2 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.3);
  static const h3 = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.4);

  // Body
  static const bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5);
  static const bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);
  static const bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.4);

  // Sentence display (for shadowing)
  static const sentence = TextStyle(fontSize: 20, fontWeight: FontWeight.w500, height: 1.6);
  static const sentenceWord = TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.5);

  // Labels
  static const label = TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5);
  static const button = TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
}
```

## Spacing System

```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}
```

## Border Radius

```dart
class AppRadius {
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const full = BorderRadius.all(Radius.circular(999));
}
```

## Screen Layout Pattern

Tất cả screens tuân theo layout chuẩn:

```dart
class ExampleScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Tiêu đề'),
        // Không dùng elevation, dùng border bottom nếu cần
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            children: [
              // Content area (scrollable nếu cần)
              Expanded(child: _buildContent()),
              // Bottom action area (fixed)
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }
}
```

### Layout Rules

- **SafeArea** bọc toàn bộ body
- **Padding horizontal**: 16px (AppSpacing.md) cho tất cả screens
- **Bottom actions** (nút ghi âm, nút tiếp tục): fixed ở dưới, không scroll
- **Content area**: Expanded + SingleChildScrollView nếu content dài
- **Không dùng** `ListView` cho layout chính — chỉ dùng cho danh sách items

## Core Components

### 1. RecordButton (Nút ghi âm — component quan trọng nhất)

```
┌─────────────────────────────┐
│                             │
│      ┌───────────────┐      │
│      │               │      │
│      │   🎤 (icon)   │      │  72x72, circular
│      │               │      │  Primary color khi idle
│      └───────────────┘      │  Red khi recording (pulse animation)
│                             │
│     "Nhấn để ghi âm"       │  Label phía dưới
└─────────────────────────────┘
```

- Size: 72x72 (touch target lớn)
- States: idle (blue), recording (red + pulse), disabled (gray)
- Luôn ở bottom center của screen

### 2. WordFeedbackChip (Từ có màu)

```
┌──────────┐ ┌──────────┐ ┌──────────┐
│  think   │ │   is     │ │important │
│  (red)   │ │ (green)  │ │ (yellow) │
└──────────┘ └──────────┘ └──────────┘
```

- Wrap layout (flow theo dòng)
- Tap vào từ đỏ/vàng → mở bottom sheet phoneme detail
- Background color nhạt, text color đậm
- Padding: 8h × 4v, margin: 4

### 3. ScoreCard (Hiển thị điểm)

```
┌─────────────────────────────────────┐
│  Accuracy    Fluency    Completeness│
│    78%         85%         100%     │
│   ████░       █████       █████     │
└─────────────────────────────────────┘
```

- Row of 3 metrics
- Circular progress hoặc linear bar
- Số lớn + label nhỏ

### 4. ChatBubble (Hội thoại)

```
┌─────────────────────────────┐
│ AI:                         │
│ ┌─────────────────────┐    │
│ │ Hi! What can I get  │    │  Left-aligned, gray bg
│ │ for you today?      │    │
│ └─────────────────────┘    │
│                             │
│    ┌─────────────────────┐ │
│    │ I'd like a latte,  │ │  Right-aligned, primary bg
│    │ please.             │ │
│    └─────────────────────┘ │
└─────────────────────────────┘
```

- AI messages: left, surfaceVariant background
- User messages: right, primaryLight background
- Max width: 80% of screen width
- Border radius: 16px (lg)

### 5. TypingIndicator (Loading)

```
┌─────────────────┐
│  ● ● ●          │  3 dots, bounce animation
│  Đang suy nghĩ  │
└─────────────────┘
```

- 3 animated dots
- Text "Đang suy nghĩ..." phía dưới
- Hiển thị trong chat bubble position (left)

### 6. SpeedSelector (Tốc độ phát)

```
┌─────────────────────────────┐
│  [0.7x]  [1.0x]  [1.2x]    │  SegmentedButton
└─────────────────────────────┘
```

- SegmentedButton hoặc ToggleButtons
- 3 options cố định
- Compact, đặt gần audio player

### 7. ProgressCard (Thẻ tiến bộ)

```
┌─────────────────────────────┐
│  📊 Tuần này                │
│                             │
│  Câu đã master: 5          │
│  Accuracy TB: 76% (+8%)    │
│  Response time: 3.1s (-0.5)│
└─────────────────────────────┘
```

- Card với elevation nhẹ hoặc border
- Metrics với so sánh tuần trước (+ green, - red)

## Screen Flows

### Shadowing Screen Layout

```
┌─────────────────────────────┐
│  ← Ordering food & drinks   │  AppBar với situation name
├─────────────────────────────┤
│                             │
│  "I'd like a latte, please" │  Sentence text (large)
│                             │
│  [0.7x] [1.0x] [1.2x]     │  Speed selector
│                             │
│  ▶️ Play                    │  Play button
│                             │
│  ─── Results area ───       │  Sau khi record:
│  [I'd] [like] [a] [latte]  │  Word chips (colored)
│  [please]                   │
│                             │
│  Accuracy: 78%  Fluency: 85%│  Score summary
│                             │
├─────────────────────────────┤
│        🎤 Ghi âm            │  Record button (fixed bottom)
└─────────────────────────────┘
```

### Conversation Screen Layout

```
┌─────────────────────────────┐
│  ← Order coffee (2/5)       │  AppBar + turn counter
├─────────────────────────────┤
│                             │
│  [AI bubble]                │  Chat history
│       [User bubble]         │
│  [AI bubble]                │
│  [● ● ● Đang suy nghĩ]    │  Typing indicator
│                             │
│                             │
├─────────────────────────────┤
│  💡 Gợi ý    🎤 Ghi âm     │  Hint + Record (fixed bottom)
└─────────────────────────────┘
```

### Daily Flow Screen Layout

```
┌─────────────────────────────┐
│  SpeakEng                   │  AppBar
├─────────────────────────────┤
│                             │
│  Chào buổi sáng! 👋        │  Greeting
│                             │
│  Hôm nay:                  │
│  ● Shadowing (0/3)  ○      │  Progress steps
│  ○ Hội thoại (0/1)         │
│  ○ Tóm tắt                 │
│                             │
│  Câu đã master: 23         │  Quick stats
│                             │
├─────────────────────────────┤
│     [  Bắt đầu luyện  ]    │  CTA button (fixed bottom)
└─────────────────────────────┘
```

## Animation Guidelines

- **Recording pulse**: scale 1.0 → 1.1, duration 600ms, repeat
- **Typing indicator**: 3 dots opacity 0.3 → 1.0, staggered 200ms
- **Page transitions**: slide from right (default GoRouter)
- **Score reveal**: fade in + slide up, duration 300ms
- **Word chips appear**: staggered fade in, 50ms delay each
- **KHÔNG** dùng heavy animations — app phải nhẹ và nhanh

## Responsive Rules

- **Target**: Android phones, 360–412dp width
- **Min width support**: 320dp
- **KHÔNG** cần tablet layout cho MVP
- Text scale: respect system text size (MediaQuery.textScaleFactor)
- Nút ghi âm: luôn 72x72 bất kể screen size

## Accessibility

- Tất cả interactive elements: min 48x48 touch target
- Semantic labels cho screen readers (Semantics widget)
- Color contrast ratio ≥ 4.5:1 cho text
- Không dùng color alone để truyền thông tin — kết hợp icon/text
- Word feedback: ngoài màu, thêm underline cho từ sai
