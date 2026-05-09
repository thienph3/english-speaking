# Requirements Document

## Giới thiệu

SpeakEng MVP là ứng dụng Flutter (Android) giúp người Việt luyện phát âm tiếng Anh và xây dựng sự tự tin khi nói. Ứng dụng dựa trên 3 trụ cột: Shadowing với phản hồi phát âm cấp phoneme (Azure Speech), Hội thoại AI (GPT-4o-mini + Whisper), và Tiến bộ thực tế (metrics cụ thể). Backend sử dụng Supabase (Auth, DB, Storage, Edge Functions). Mục tiêu MVP: daily flow 5 phút (3 shadowing + 1 conversation + summary) với 100 câu shadowing, 3 scenario hội thoại, và mini placement test 3 câu.

## Thuật ngữ

- **App**: Ứng dụng SpeakEng trên nền tảng Android, được xây dựng bằng Flutter
- **User**: Người dùng ứng dụng — người Việt học tiếng Anh trình độ A2–B1
- **Shadowing_Module**: Module luyện phát âm theo phương pháp shadowing — nghe câu mẫu rồi nhắc lại
- **Pronunciation_Engine**: Dịch vụ Azure Speech Pronunciation Assessment đánh giá phát âm cấp phoneme
- **Conversation_Module**: Module hội thoại AI sử dụng GPT-4o-mini để phản hồi và Whisper để chuyển giọng nói thành văn bản
- **Progress_Tracker**: Module theo dõi tiến bộ của User qua các metrics cụ thể
- **Placement_Module**: Module kiểm tra trình độ ban đầu gồm 3 câu (easy/medium/hard)
- **Auth_System**: Hệ thống xác thực người dùng qua Supabase Auth
- **Edge_Function**: Supabase Edge Function đóng vai trò proxy gọi API bên ngoài (Azure, OpenAI)
- **Offline_Engine**: Module TTS/STT chạy on-device sử dụng sherpa-onnx (Kokoro TTS + Whisper STT), không cần internet
- **Model_Manager**: Module quản lý download, lưu trữ, và chọn model offline phù hợp với device
- **Auth_System**: Hệ thống xác thực người dùng qua Supabase Auth
- **Edge_Function**: Supabase Edge Function đóng vai trò proxy gọi API bên ngoài (Azure, OpenAI)
- **Sentence**: Một câu shadowing trong bộ nội dung 100 câu thuộc 10 tình huống
- **Scenario**: Một kịch bản hội thoại AI với vai trò, target phrases, và target grammar
- **Mastery**: Trạng thái đạt được khi User phát âm một Sentence với accuracy ≥ 80% ba lần liên tiếp
- **Daily_Flow**: Luồng luyện tập hàng ngày gồm 3 câu shadowing + 1 hội thoại + tóm tắt

## Requirements

### Requirement 1: Xác thực người dùng

**User Story:** Là một User, tôi muốn đăng nhập vào App trước khi sử dụng, để dữ liệu luyện tập được lưu trữ và đồng bộ an toàn.

#### Acceptance Criteria

1. THE Auth_System SHALL yêu cầu User đăng nhập trước khi truy cập bất kỳ tính năng nào của App.
2. THE Auth_System SHALL hỗ trợ đăng ký tài khoản bằng email và mật khẩu thông qua Supabase Auth.
3. THE Auth_System SHALL hỗ trợ đăng nhập bằng email và mật khẩu đã đăng ký.
4. WHEN User đăng nhập thành công lần đầu tiên, THE App SHALL điều hướng User đến Placement_Module.
5. WHEN User đăng nhập thành công các lần sau, THE App SHALL điều hướng User đến màn hình Daily_Flow.
6. IF User nhập sai thông tin đăng nhập, THEN THE Auth_System SHALL hiển thị thông báo lỗi cụ thể và cho phép thử lại.

### Requirement 2: Mini Placement Test

**User Story:** Là một User mới, tôi muốn được đánh giá trình độ phát âm ban đầu, để App cung cấp nội dung phù hợp với khả năng của tôi.

#### Acceptance Criteria

1. THE Placement_Module SHALL trình bày 3 câu kiểm tra với độ khó tăng dần: easy, medium, hard.
2. WHEN User hoàn thành ghi âm một câu placement, THE Placement_Module SHALL gửi audio đến Pronunciation_Engine để đánh giá accuracy.
3. WHEN User hoàn thành cả 3 câu placement, THE Placement_Module SHALL tính điểm trung bình accuracy từ 3 kết quả.
4. WHEN điểm trung bình accuracy ≥ 80%, THE Placement_Module SHALL gán mức khởi đầu medium/hard cho User.
5. WHEN điểm trung bình accuracy từ 50% đến 79%, THE Placement_Module SHALL gán mức khởi đầu easy/medium cho User.
6. WHEN điểm trung bình accuracy < 50%, THE Placement_Module SHALL gán mức khởi đầu easy cho User.
7. THE Placement_Module SHALL lưu kết quả placement và mức khởi đầu vào cơ sở dữ liệu Supabase.

### Requirement 3: Shadowing — Nghe và nhắc lại

**User Story:** Là một User, tôi muốn nghe câu mẫu rồi nhắc lại để luyện phát âm, để cải thiện khả năng phát âm từng âm tiết chính xác.

#### Acceptance Criteria

1. THE Shadowing_Module SHALL phát audio câu mẫu cho User nghe trước khi ghi âm.
2. THE Shadowing_Module SHALL cho phép User điều chỉnh tốc độ phát audio ở các mức 0.7x, 1.0x, và 1.2x.
3. WHEN User nhấn nút ghi âm, THE Shadowing_Module SHALL bắt đầu ghi âm giọng nói của User.
4. WHEN User hoàn thành ghi âm, THE Shadowing_Module SHALL gửi file audio cùng reference text đến Pronunciation_Engine qua Edge_Function /pronounce.
5. THE Shadowing_Module SHALL hiển thị kết quả phát âm với các từ được tô màu: xanh (accuracy ≥ 80%), đỏ (accuracy < 50%), và vàng (accuracy 50%–79%).
6. WHEN User nhấn vào một từ được tô màu đỏ hoặc vàng, THE Shadowing_Module SHALL hiển thị chi tiết phoneme bị sai và mẹo phát âm bằng tiếng Việt.
7. THE Shadowing_Module SHALL hiển thị điểm tổng thể gồm accuracy, fluency, và completeness.
8. THE Shadowing_Module SHALL cung cấp nội dung 100 câu shadowing phân bổ đều trong 10 tình huống thực tế.
9. THE Shadowing_Module SHALL phục vụ câu shadowing theo mức độ khó phù hợp với kết quả placement của User.

### Requirement 4: Shadowing — Luyện theo cụm từ

**User Story:** Là một User, tôi muốn luyện phát âm từng cụm từ trong câu dài, để dễ dàng tập trung vào phần khó.

#### Acceptance Criteria

1. THE Shadowing_Module SHALL cung cấp chế độ luyện theo cụm từ (phrase-by-phrase) cho các câu có nhiều hơn 5 từ.
2. WHEN User chọn chế độ phrase-by-phrase, THE Shadowing_Module SHALL chia câu thành các cụm từ và cho phép User luyện từng cụm riêng biệt.
3. WHEN User hoàn thành luyện tất cả các cụm từ, THE Shadowing_Module SHALL cho phép User luyện toàn bộ câu.

### Requirement 5: Mẹo phát âm cho người Việt

**User Story:** Là một User người Việt, tôi muốn nhận mẹo phát âm cụ thể cho các âm mà người Việt thường phát sai, để biết cách sửa lỗi hiệu quả.

#### Acceptance Criteria

1. WHEN Pronunciation_Engine trả về phoneme có accuracy < 80%, THE Shadowing_Module SHALL hiển thị mẹo phát âm bằng tiếng Việt cho phoneme đó.
2. THE Shadowing_Module SHALL cung cấp mẹo phát âm tiếng Việt cho các phoneme: /θ/, /ð/, /r/, /l/, /ʃ/, /ʒ/, /z/, /ŋ/, /p/ cuối từ, /t/ cuối từ, /k/ cuối từ.
3. THE Shadowing_Module SHALL mô tả vị trí lưỡi, môi, và cách phát âm trong mỗi mẹo.

### Requirement 6: Hội thoại AI

**User Story:** Là một User, tôi muốn luyện nói tiếng Anh trong các tình huống thực tế với AI, để xây dựng phản xạ nói và sự tự tin.

#### Acceptance Criteria

1. THE Conversation_Module SHALL cung cấp 3 kịch bản hội thoại (Scenario) cho MVP.
2. THE Conversation_Module SHALL phát tin nhắn đầu tiên của AI bằng giọng nói (OpenAI TTS) khi User bắt đầu Scenario.
3. WHEN User nói, THE Conversation_Module SHALL ghi âm và gửi audio đến Edge_Function /transcribe (Whisper) để chuyển thành văn bản.
4. WHEN nhận được transcript từ Whisper, THE Conversation_Module SHALL gửi transcript cùng lịch sử hội thoại đến Edge_Function /chat (GPT-4o-mini) để tạo phản hồi.
5. WHEN nhận được phản hồi từ GPT-4o-mini, THE Conversation_Module SHALL gửi text phản hồi đến Edge_Function /tts để tạo audio và phát cho User nghe.
6. THE Conversation_Module SHALL hiển thị text phản hồi của AI trong khi chờ audio TTS được tạo.
7. THE Conversation_Module SHALL giới hạn mỗi Scenario tối đa 5 lượt hội thoại (turns).
8. THE Conversation_Module SHALL hiển thị gợi ý (hints) cho User khi User gặp khó khăn trong việc trả lời.
9. THE Conversation_Module SHALL đo thời gian phản hồi (response time) của User — từ lúc AI nói xong đến lúc User bắt đầu nói.

### Requirement 7: Hội thoại AI — Dẫn dắt sử dụng target phrases

**User Story:** Là một User, tôi muốn AI dẫn dắt tôi sử dụng các cụm từ mục tiêu trong hội thoại, để tôi học cách dùng chúng trong ngữ cảnh thực tế.

#### Acceptance Criteria

1. THE Conversation_Module SHALL cấu hình mỗi Scenario với danh sách target_phrases và target_grammar.
2. WHILE hội thoại đang diễn ra, THE Conversation_Module SHALL sử dụng system prompt để GPT-4o-mini dẫn dắt User sử dụng target_phrases một cách tự nhiên.
3. WHEN hội thoại kết thúc, THE Conversation_Module SHALL đánh giá mức độ User đã sử dụng target_phrases và target_grammar.

### Requirement 8: Phản hồi sau hội thoại

**User Story:** Là một User, tôi muốn nhận phản hồi chi tiết sau mỗi cuộc hội thoại, để biết điểm mạnh và điểm cần cải thiện.

#### Acceptance Criteria

1. WHEN hội thoại kết thúc (đạt max turns hoặc User kết thúc sớm), THE Conversation_Module SHALL yêu cầu GPT-4o-mini tạo phản hồi dạng JSON có cấu trúc.
2. THE Conversation_Module SHALL hiển thị phản hồi bao gồm: lỗi ngữ pháp (grammar_errors), gợi ý từ vựng (vocabulary_suggestions), điểm tích cực (positive), và điểm cần cải thiện (improve).
3. THE Conversation_Module SHALL hiển thị mức độ sử dụng target_phrases trong phản hồi.
4. THE Conversation_Module SHALL hiển thị thời gian phản hồi trung bình của User trong cuộc hội thoại.

### Requirement 9: Daily Flow 5 phút

**User Story:** Là một User, tôi muốn có một luồng luyện tập cố định 5 phút mỗi ngày, để duy trì thói quen luyện nói đều đặn.

#### Acceptance Criteria

1. THE App SHALL cung cấp Daily_Flow gồm 3 bước tuần tự: 3 câu shadowing, 1 cuộc hội thoại AI, và tóm tắt kết quả.
2. WHEN User hoàn thành 3 câu shadowing, THE App SHALL tự động chuyển sang bước hội thoại AI.
3. WHEN User hoàn thành hội thoại AI, THE App SHALL hiển thị màn hình tóm tắt kết quả ngày hôm đó.
4. THE App SHALL hiển thị tóm tắt bao gồm: số câu mới mastered, thay đổi response time, và accuracy trung bình.

### Requirement 10: Theo dõi tiến bộ — Mastery

**User Story:** Là một User, tôi muốn thấy số câu tôi đã master, để có bằng chứng cụ thể về sự tiến bộ.

#### Acceptance Criteria

1. WHEN User đạt accuracy ≥ 80% cho một Sentence ba lần liên tiếp, THE Progress_Tracker SHALL đánh dấu Sentence đó là mastered.
2. THE Progress_Tracker SHALL hiển thị tổng số Sentence đã mastered trên màn hình chính.
3. THE Progress_Tracker SHALL lưu correct_streak và best_accuracy cho mỗi Sentence vào cơ sở dữ liệu.
4. WHEN User đạt accuracy < 80% cho một Sentence, THE Progress_Tracker SHALL reset correct_streak về 0 cho Sentence đó.

### Requirement 11: Theo dõi tiến bộ — Response Time và Accuracy

**User Story:** Là một User, tôi muốn theo dõi thời gian phản hồi và độ chính xác phát âm theo thời gian, để thấy sự cải thiện cụ thể.

#### Acceptance Criteria

1. THE Progress_Tracker SHALL ghi lại response time trung bình của User trong mỗi cuộc hội thoại AI.
2. THE Progress_Tracker SHALL ghi lại accuracy trung bình của User trong mỗi phiên shadowing.
3. THE Progress_Tracker SHALL lưu metrics hàng ngày (sentences_practiced, sentences_mastered, avg_accuracy, avg_response_time_ms) vào bảng daily_metrics.
4. THE Progress_Tracker SHALL hiển thị so sánh metrics tuần này với tuần trước.

### Requirement 12: Ghi âm Before/After

**User Story:** Là một User, tôi muốn nghe lại bản ghi âm đầu tiên so với bản ghi âm mới nhất của mỗi câu, để cảm nhận sự tiến bộ rõ ràng.

#### Acceptance Criteria

1. WHEN User luyện một Sentence lần đầu tiên, THE App SHALL lưu bản ghi âm đó làm bản "before" vào Supabase Storage.
2. WHEN User đạt Mastery cho một Sentence, THE App SHALL lưu bản ghi âm đó làm bản "after" vào Supabase Storage.
3. THE App SHALL cho phép User nghe lại cả bản "before" và "after" để so sánh.

### Requirement 13: Xử lý lỗi mạng và API

**User Story:** Là một User, tôi muốn nhận thông báo rõ ràng khi có lỗi xảy ra, để biết cách xử lý và tiếp tục luyện tập.

#### Acceptance Criteria

1. IF App mất kết nối internet, THEN THE App SHALL hiển thị thông báo yêu cầu kết nối lại và vô hiệu hóa các tính năng cần mạng.
2. IF Pronunciation_Engine không phản hồi trong 10 giây, THEN THE App SHALL hiển thị thông báo "Không thể xử lý audio. Thử lại?" kèm nút retry.
3. IF User ghi âm audio ngắn hơn 1 giây hoặc dài hơn 60 giây, THEN THE App SHALL hiển thị thông báo "Bản ghi quá ngắn/dài. Hãy ghi từ 2–10 giây."
4. IF audio ghi âm không phát hiện giọng nói (silence), THEN THE App SHALL hiển thị thông báo "Không nghe thấy gì. Kiểm tra microphone."
5. IF Whisper transcribe trả về text tiếng Việt hoặc accuracy < 20%, THEN THE App SHALL hiển thị thông báo "Hãy thử nói bằng tiếng Anh" hoặc "Thử nói chậm hơn."
6. IF Edge_Function /tts không phản hồi, THEN THE App SHALL hiển thị text phản hồi AI mà không có audio.

### Requirement 14: Trạng thái loading và UX trong hội thoại

**User Story:** Là một User, tôi muốn biết App đang xử lý khi chờ phản hồi AI, để không cảm thấy App bị treo.

#### Acceptance Criteria

1. WHILE Conversation_Module đang chờ phản hồi từ API (Whisper, GPT-4o-mini, TTS), THE App SHALL hiển thị chỉ báo "đang suy nghĩ..." với animation typing indicator.
2. WHEN GPT-4o-mini trả về text phản hồi, THE App SHALL hiển thị text ngay lập tức trong khi chờ TTS tạo audio.
3. THE Conversation_Module SHALL pre-cache tin nhắn đầu tiên của AI cho mỗi Scenario để giảm thời gian chờ khi bắt đầu hội thoại.

### Requirement 15: Quản lý nội dung MVP

**User Story:** Là một User, tôi muốn có đủ nội dung luyện tập đa dạng, để không bị lặp lại quá nhanh.

#### Acceptance Criteria

1. THE App SHALL cung cấp 100 câu shadowing phân bổ đều trong 10 tình huống (10 câu mỗi tình huống).
2. THE App SHALL cung cấp 3 kịch bản hội thoại AI (Scenario) với các tình huống khác nhau.
3. THE App SHALL cung cấp 3 câu placement test với độ khó easy, medium, hard.
4. THE App SHALL phân loại mỗi Sentence theo difficulty (easy, medium, hard) và situation.
5. THE App SHALL gắn mỗi Sentence với danh sách phrases và target_grammar.

### Requirement 16: On-Device TTS/STT (Offline Voice Engine)

**User Story:** Là một User, tôi muốn có option sử dụng TTS và STT offline trên device, để tiết kiệm chi phí API và giảm latency khi phát/nhận giọng nói.

#### Acceptance Criteria

1. THE App SHALL cung cấp option bật/tắt Offline_Engine trong màn hình Settings (mặc định: tắt — dùng online ElevenLabs/OpenAI).
2. THE App SHALL chỉ hiển thị option bật Offline_Engine khi Model_Manager xác nhận models đã được download thành công.
3. WHEN User bật Offline_Engine, THE Conversation_Module SHALL sử dụng on-device TTS (Kokoro/Piper) thay vì ElevenLabs/OpenAI TTS cho phát giọng AI.
4. WHEN User bật Offline_Engine, THE Conversation_Module SHALL sử dụng on-device STT (Whisper via sherpa-onnx) thay vì ElevenLabs/OpenAI Whisper cho transcribe giọng User.
5. WHEN User bật Offline_Engine, THE Pronunciation_Engine (Azure) và GPT-4o-mini SHALL vẫn hoạt động online bình thường — Offline_Engine chỉ thay thế TTS và STT.
6. THE App SHALL hiển thị trạng thái Offline_Engine trên Settings: "Chưa tải model" / "Đang tải..." / "Sẵn sàng".

### Requirement 17: Adaptive Model Download theo Device

**User Story:** Là một User, tôi muốn App tự chọn model offline phù hợp với thiết bị của tôi, để không bị lag hoặc tốn quá nhiều bộ nhớ.

#### Acceptance Criteria

1. THE Model_Manager SHALL detect thông số device (RAM, CPU cores) khi App khởi động.
2. THE Model_Manager SHALL phân loại device thành 3 tier: low-end (≤4GB RAM), mid-range (4–8GB), high-end (>8GB).
3. WHEN device là low-end, THE Model_Manager SHALL chọn Whisper Tiny (~40MB) cho STT và Piper (~30MB) cho TTS.
4. WHEN device là mid-range hoặc high-end, THE Model_Manager SHALL chọn Whisper Small (~150MB) cho STT và Kokoro (~150MB) cho TTS.
5. THE Model_Manager SHALL download models ở background sau splash screen, không block UI chính.
6. THE Model_Manager SHALL hiển thị progress download (% và MB) và cho phép User cancel.
7. THE Model_Manager SHALL lưu models vào internal storage của App (không xóa khi clear cache).
8. IF download bị gián đoạn (mất mạng, user cancel), THEN THE Model_Manager SHALL hỗ trợ resume download từ vị trí đã dừng.
9. THE Model_Manager SHALL kiểm tra integrity của model files sau khi download (checksum verification).


### Requirement 18: Offline Pronunciation Scoring (Word-Level)

**User Story:** Là một User đã bật Offline_Engine, tôi muốn vẫn nhận được feedback phát âm ở word-level khi luyện shadowing, để không phụ thuộc hoàn toàn vào Azure online.

#### Acceptance Criteria

1. WHEN User bật Offline_Engine VÀ Model_Manager đã download wav2vec2 model, THE Shadowing_Module SHALL sử dụng wav2vec2 forced alignment để chấm điểm phát âm ở word-level thay vì Azure.
2. THE Offline_Engine SHALL thực hiện forced alignment giữa audio user và reference text, trả về confidence score (0–100) cho mỗi word.
3. THE Shadowing_Module SHALL hiển thị kết quả word-level offline với cùng UI color-coded (xanh ≥80%, vàng 50–79%, đỏ <50%) như khi dùng Azure online.
4. WHEN Offline_Engine bật, THE Shadowing_Module SHALL KHÔNG hiển thị phoneme-level detail và Vietnamese tips (chỉ có khi dùng Azure online).
5. THE App SHALL hiển thị indicator rõ ràng cho User biết đang dùng "Offline mode (word-level)" hay "Online mode (phoneme-level)" trên màn hình shadowing.
6. WHEN device là low-end (≤4GB RAM), THE Model_Manager SHALL chọn wav2vec2-base (~360MB). WHEN device là mid-range/high-end, THE Model_Manager SHALL chọn wav2vec2-large (~1.2GB) nếu storage đủ, ngược lại fallback về wav2vec2-base.
7. THE Offline_Engine SHALL tính overall accuracy score = trung bình confidence scores của tất cả words.
