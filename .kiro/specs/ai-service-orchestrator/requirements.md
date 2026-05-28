# Requirements Document

## Giới thiệu

AI Service Orchestrator là module trung tâm quản lý và điều phối tất cả dịch vụ AI trong SpeakEng App, bao gồm 4 loại service: TTS (Text-to-Speech), STT (Speech-to-Text), LLM (Large Language Model), và Pronunciation Assessment. Mỗi loại service có nhiều provider (online lẫn offline) với quota và chi phí khác nhau. Orchestrator cung cấp cơ chế Provider Registry, fallback chain có thể cấu hình, theo dõi quota server-side (Supabase), và adaptive model selection dựa trên thông số thiết bị. Module này thay thế Requirements 16–20 trong speakeng-mvp spec, được thiết kế độc lập (feature module) và inject qua Riverpod.

## Thuật ngữ

- **Orchestrator**: Module trung tâm điều phối việc chọn provider phù hợp cho mỗi AI service request, nằm tại `lib/features/ai_services/`
- **Service_Type**: Một trong 4 loại dịch vụ AI: TTS, STT, LLM, Pronunciation
- **Provider**: Một implementation cụ thể của một Service_Type (ví dụ: ElevenLabs TTS, Kokoro offline TTS)
- **Provider_Registry**: Bảng đăng ký tất cả provider khả dụng cho mỗi Service_Type, hỗ trợ pluggable implementations
- **Fallback_Chain**: Danh sách provider được sắp xếp theo thứ tự ưu tiên cho mỗi Service_Type; khi provider đầu fail hoặc hết quota, Orchestrator chuyển sang provider tiếp theo
- **Fallback_Strategy**: Chiến lược xác định thứ tự ưu tiên trong Fallback_Chain: "free_first", "quality_first", "offline_only", hoặc custom
- **Quota_Tracker**: Module theo dõi mức sử dụng (usage) của mỗi provider so với giới hạn free tier, lưu trữ trên Supabase DB và đồng bộ giữa các thiết bị
- **Device_Spec**: Thông số phần cứng thiết bị (RAM, CPU cores) dùng để chọn offline model phù hợp
- **Offline_Provider**: Provider chạy on-device không cần internet (Kokoro TTS, Piper TTS, Whisper on-device, wav2vec2, on-device LLM)
- **Online_Provider**: Provider gọi API cloud qua internet (ElevenLabs, OpenAI, Gemini, Azure Speech)
- **Usage_Record**: Bản ghi sử dụng một provider tại một thời điểm, bao gồm service type, provider ID, số lượng consumed, và timestamp
- **Quota_Limit**: Giới hạn sử dụng miễn phí của một provider trong một chu kỳ (ngày hoặc tháng)

## Requirements

### Requirement 1: Provider Registry — Đăng ký và quản lý provider

**User Story:** Là một developer, tôi muốn có một registry trung tâm quản lý tất cả AI provider, để dễ dàng thêm/bớt provider mà không ảnh hưởng logic nghiệp vụ.

#### Acceptance Criteria

1. THE Provider_Registry SHALL đăng ký tất cả provider khả dụng cho mỗi Service_Type khi App khởi động.
2. THE Provider_Registry SHALL lưu trữ metadata cho mỗi provider bao gồm: provider ID, Service_Type, loại kết nối (online hoặc offline), trạng thái sẵn sàng (ready, not_downloaded, unavailable), và Quota_Limit.
3. WHEN một provider mới được thêm vào hệ thống, THE Provider_Registry SHALL cho phép đăng ký provider đó mà không cần sửa đổi code của Orchestrator hoặc các module khác.
4. THE Provider_Registry SHALL cung cấp danh sách provider khả dụng (trạng thái ready) cho mỗi Service_Type khi được truy vấn.
5. WHEN một Offline_Provider chưa download model, THE Provider_Registry SHALL đánh dấu provider đó với trạng thái not_downloaded và loại khỏi danh sách khả dụng.

### Requirement 2: Fallback Chain — Chuỗi dự phòng có thể cấu hình

**User Story:** Là một User, tôi muốn App tự động chuyển sang provider khác khi provider hiện tại không khả dụng, để trải nghiệm luyện tập không bị gián đoạn.

#### Acceptance Criteria

1. THE Orchestrator SHALL duy trì một Fallback_Chain (danh sách provider theo thứ tự ưu tiên) cho mỗi Service_Type.
2. WHEN User cấu hình Fallback_Strategy, THE Orchestrator SHALL sắp xếp Fallback_Chain theo chiến lược đã chọn.
3. WHEN Fallback_Strategy là "free_first", THE Orchestrator SHALL sắp xếp provider miễn phí (hoặc còn quota free) lên đầu Fallback_Chain, sau đó đến provider trả phí theo giá tăng dần.
4. WHEN Fallback_Strategy là "quality_first", THE Orchestrator SHALL sắp xếp provider có chất lượng cao nhất lên đầu Fallback_Chain bất kể chi phí.
5. WHEN Fallback_Strategy là "offline_only", THE Orchestrator SHALL chỉ đưa Offline_Provider vào Fallback_Chain và loại bỏ tất cả Online_Provider.
6. THE Orchestrator SHALL cho phép User tạo Fallback_Chain tùy chỉnh (custom) bằng cách sắp xếp thủ công thứ tự provider.
7. THE Orchestrator SHALL lưu cấu hình Fallback_Chain của User vào Supabase DB để đồng bộ giữa các thiết bị.

### Requirement 3: Điều phối request — Chọn provider và xử lý fallback

**User Story:** Là một User, tôi muốn mỗi request AI được xử lý bởi provider tốt nhất hiện có, để luôn nhận được kết quả mà không cần quan tâm provider nào đang hoạt động.

#### Acceptance Criteria

1. WHEN một AI service request được gửi đến Orchestrator, THE Orchestrator SHALL chọn provider đầu tiên trong Fallback_Chain có trạng thái ready và còn quota.
2. IF provider được chọn trả về lỗi (timeout, network error, rate limit), THEN THE Orchestrator SHALL tự động chuyển sang provider tiếp theo trong Fallback_Chain.
3. IF tất cả provider trong Fallback_Chain đều fail, THEN THE Orchestrator SHALL trả về lỗi cuối cùng kèm thông tin provider nào đã thử.
4. WHEN Orchestrator chọn một provider cho request, THE Orchestrator SHALL ghi log provider ID, Service_Type, và kết quả (success hoặc failure) cho mỗi request.
5. THE Orchestrator SHALL thực hiện fallback trong vòng 5 giây timeout cho mỗi provider trước khi chuyển sang provider tiếp theo.
6. WHEN một Offline_Provider được chọn và device đang offline, THE Orchestrator SHALL xử lý request trực tiếp trên device mà không cần kết nối mạng.

### Requirement 4: Quota Tracking — Theo dõi mức sử dụng

**User Story:** Là một User, tôi muốn App tự động theo dõi quota sử dụng của mỗi provider, để tận dụng tối đa free tier và tránh phát sinh chi phí bất ngờ.

#### Acceptance Criteria

1. THE Quota_Tracker SHALL ghi lại mỗi Usage_Record (provider ID, Service_Type, số lượng consumed, timestamp) sau mỗi request thành công.
2. THE Quota_Tracker SHALL lưu trữ Usage_Record trên Supabase DB để đồng bộ giữa các thiết bị của cùng một User.
3. THE Quota_Tracker SHALL tính tổng usage của mỗi provider trong chu kỳ hiện tại (ngày hoặc tháng tùy provider).
4. WHEN tổng usage của một provider đạt 90% Quota_Limit, THE Quota_Tracker SHALL cảnh báo User rằng quota sắp hết.
5. WHEN tổng usage của một provider đạt 100% Quota_Limit, THE Orchestrator SHALL tự động loại provider đó khỏi danh sách khả dụng và chuyển sang provider tiếp theo trong Fallback_Chain.
6. THE Quota_Tracker SHALL reset usage counter khi bắt đầu chu kỳ mới (đầu ngày cho quota daily, đầu tháng cho quota monthly).
7. THE Quota_Tracker SHALL đồng bộ usage data từ server mỗi khi App khởi động hoặc khi User chuyển thiết bị.

### Requirement 5: Quota Limits cho từng provider

**User Story:** Là một developer, tôi muốn hệ thống biết chính xác giới hạn free tier của mỗi provider, để tự động quản lý fallback khi hết quota.

#### Acceptance Criteria

1. THE Quota_Tracker SHALL theo dõi ElevenLabs TTS với Quota_Limit 10.000 ký tự mỗi tháng.
2. THE Quota_Tracker SHALL theo dõi ElevenLabs Scribe (STT) với Quota_Limit 300 phút mỗi tháng.
3. THE Quota_Tracker SHALL theo dõi Gemini 2.0 Flash với Quota_Limit 1.500 requests mỗi ngày.
4. THE Quota_Tracker SHALL theo dõi Azure Speech (Pronunciation) với Quota_Limit 500.000 ký tự mỗi tháng.
5. THE Quota_Tracker SHALL đánh dấu Gemini 3.1 Flash-Lite là không giới hạn trong free tier (unlimited requests).
6. THE Quota_Tracker SHALL đánh dấu Offline_Provider là không giới hạn quota (chỉ phụ thuộc vào tài nguyên device).

### Requirement 6: Adaptive Offline Model Selection

**User Story:** Là một User, tôi muốn App tự chọn model offline phù hợp với thiết bị của tôi, để đảm bảo hiệu năng tốt mà không tốn quá nhiều bộ nhớ.

#### Acceptance Criteria

1. THE Orchestrator SHALL detect Device_Spec (tổng RAM, số CPU cores) khi App khởi động.
2. THE Orchestrator SHALL phân loại device thành 3 tier: low_end (RAM ≤ 4GB), mid_range (RAM 4–8GB), high_end (RAM > 8GB).
3. WHEN device là low_end, THE Orchestrator SHALL chọn Whisper Tiny (40MB) cho STT offline và Piper (30MB) cho TTS offline.
4. WHEN device là mid_range hoặc high_end, THE Orchestrator SHALL chọn Whisper Small (150MB) cho STT offline và Kokoro (150MB) cho TTS offline.
5. WHEN device là low_end, THE Orchestrator SHALL chọn wav2vec2-base (360MB) cho Pronunciation offline.
6. WHEN device là mid_range hoặc high_end VÀ storage khả dụng đủ, THE Orchestrator SHALL chọn wav2vec2-large (1.2GB) cho Pronunciation offline.
7. WHEN device là mid_range hoặc high_end VÀ storage khả dụng không đủ cho wav2vec2-large, THE Orchestrator SHALL fallback về wav2vec2-base (360MB).
8. WHEN device là low_end, THE Orchestrator SHALL chọn Gemma 2B (1.5GB) cho LLM offline. WHEN device là mid_range, THE Orchestrator SHALL chọn Phi-3 mini 3.8B (2.2GB). WHEN device là high_end, THE Orchestrator SHALL chọn Qwen3 4B (2.5GB).

### Requirement 7: Model Download và Lifecycle Management

**User Story:** Là một User, tôi muốn download model offline một cách mượt mà và quản lý storage hiệu quả, để sử dụng offline mode khi cần.

#### Acceptance Criteria

1. THE Orchestrator SHALL download offline models ở background mà không block UI chính của App.
2. WHILE download đang diễn ra, THE Orchestrator SHALL hiển thị progress bao gồm phần trăm hoàn thành và số MB đã tải trên tổng số MB.
3. THE Orchestrator SHALL cho phép User hủy (cancel) download bất kỳ lúc nào.
4. IF download bị gián đoạn (mất mạng hoặc User cancel), THEN THE Orchestrator SHALL hỗ trợ resume download từ vị trí đã dừng khi có kết nối lại.
5. THE Orchestrator SHALL xác minh integrity của model file sau khi download hoàn tất bằng checksum verification.
6. THE Orchestrator SHALL lưu model files vào internal storage của App (không bị xóa khi clear cache).
7. THE Orchestrator SHALL cho phép User xóa model files đã download để giải phóng storage.
8. WHEN User xóa model files của một Offline_Provider, THE Provider_Registry SHALL cập nhật trạng thái provider đó thành not_downloaded.

### Requirement 8: TTS Provider Configuration

**User Story:** Là một User, tôi muốn App sử dụng TTS provider tốt nhất hiện có để phát giọng AI, để trải nghiệm nghe tự nhiên và mượt mà.

#### Acceptance Criteria

1. THE Provider_Registry SHALL đăng ký 4 TTS provider: ElevenLabs (online, free 10.000 chars/tháng), OpenAI TTS (online, $15/1M chars), Kokoro (offline, 150MB), Piper (offline, 30MB).
2. WHEN Fallback_Strategy là "free_first", THE Orchestrator SHALL sắp xếp TTS Fallback_Chain: ElevenLabs → Kokoro/Piper (nếu đã download) → OpenAI TTS.
3. WHEN Fallback_Strategy là "quality_first", THE Orchestrator SHALL sắp xếp TTS Fallback_Chain: ElevenLabs → OpenAI TTS → Kokoro → Piper.
4. THE Orchestrator SHALL trả về audio data (bytes) cho caller bất kể provider nào xử lý request.

### Requirement 9: STT Provider Configuration

**User Story:** Là một User, tôi muốn App chuyển giọng nói thành text chính xác nhất có thể, để transcript phản ánh đúng những gì tôi nói.

#### Acceptance Criteria

1. THE Provider_Registry SHALL đăng ký 3 STT provider: ElevenLabs Scribe (online, free 300 phút/tháng), OpenAI Whisper (online, $0.006/phút), Whisper on-device (offline, 40–150MB tùy model).
2. WHEN Fallback_Strategy là "free_first", THE Orchestrator SHALL sắp xếp STT Fallback_Chain: ElevenLabs Scribe → Whisper on-device (nếu đã download) → OpenAI Whisper.
3. WHEN Fallback_Strategy là "quality_first", THE Orchestrator SHALL sắp xếp STT Fallback_Chain: OpenAI Whisper → ElevenLabs Scribe → Whisper on-device.
4. THE Orchestrator SHALL trả về transcript text cho caller bất kể provider nào xử lý request.

### Requirement 10: LLM Provider Configuration

**User Story:** Là một User, tôi muốn App tận dụng tối đa free tier của nhiều LLM provider, để giảm chi phí mà vẫn đảm bảo conversation luôn hoạt động.

#### Acceptance Criteria

1. THE Provider_Registry SHALL đăng ký 4 LLM provider: Gemini 3.1 Flash-Lite (online, free unlimited), Gemini 2.0 Flash (online, free 1.500 req/ngày), GPT-4.1 nano (online, $0.10/1M tokens), on-device LLM (offline, 1.5–2.5GB tùy model).
2. WHEN Fallback_Strategy là "free_first", THE Orchestrator SHALL sắp xếp LLM Fallback_Chain: Gemini 3.1 Flash-Lite → Gemini 2.0 Flash → on-device LLM (nếu đã download) → GPT-4.1 nano.
3. WHEN Fallback_Strategy là "quality_first", THE Orchestrator SHALL sắp xếp LLM Fallback_Chain: GPT-4.1 nano → Gemini 2.0 Flash → Gemini 3.1 Flash-Lite → on-device LLM.
4. THE Orchestrator SHALL trả về response text cho caller bất kể provider nào xử lý request.
5. WHEN on-device LLM được sử dụng, THE Orchestrator SHALL áp dụng cùng scenario config (system_prompt, target_phrases) như online providers.

### Requirement 11: Pronunciation Provider Configuration

**User Story:** Là một User, tôi muốn nhận feedback phát âm chính xác nhất có thể, với fallback về word-level khi offline.

#### Acceptance Criteria

1. THE Provider_Registry SHALL đăng ký 2 Pronunciation provider: Azure Speech (online, phoneme-level, free 500.000 chars/tháng), wav2vec2 on-device (offline, word-level, 360MB–1.2GB).
2. WHEN Fallback_Strategy là "free_first" hoặc "quality_first", THE Orchestrator SHALL ưu tiên Azure Speech cho Pronunciation vì cung cấp phoneme-level detail.
3. WHEN Azure Speech không khả dụng (hết quota hoặc offline) VÀ wav2vec2 đã download, THE Orchestrator SHALL fallback về wav2vec2 on-device với word-level scoring.
4. WHEN wav2vec2 on-device được sử dụng, THE Orchestrator SHALL thông báo caller rằng kết quả chỉ ở word-level (không có phoneme detail).
5. THE Orchestrator SHALL trả về kết quả pronunciation assessment cho caller với metadata chỉ rõ mức độ chi tiết (phoneme-level hoặc word-level).

### Requirement 12: Migration — Tích hợp với module hiện tại

**User Story:** Là một developer, tôi muốn các module hiện tại (Conversation, Shadowing) gọi AI services thông qua Orchestrator, để tập trung logic provider selection vào một nơi duy nhất.

#### Acceptance Criteria

1. THE Orchestrator SHALL cung cấp interface thống nhất cho ConversationRepository để gọi TTS, STT, và LLM services.
2. THE Orchestrator SHALL cung cấp interface thống nhất cho ShadowingRepository để gọi Pronunciation service.
3. WHEN ConversationRepository cần TTS, THE ConversationRepository SHALL gọi Orchestrator thay vì gọi trực tiếp Edge_Function /tts.
4. WHEN ConversationRepository cần STT, THE ConversationRepository SHALL gọi Orchestrator thay vì gọi trực tiếp Edge_Function /transcribe.
5. WHEN ConversationRepository cần LLM response, THE ConversationRepository SHALL gọi Orchestrator thay vì gọi trực tiếp Edge_Function /chat.
6. WHEN ShadowingRepository cần pronunciation assessment, THE ShadowingRepository SHALL gọi Orchestrator thay vì gọi trực tiếp Edge_Function /pronounce.
7. THE Orchestrator SHALL được inject vào các repository thông qua Riverpod provider.

### Requirement 13: UI — MVP Auto-Fallback và Toggle

**User Story:** Là một User, tôi muốn có giao diện đơn giản để bật/tắt offline mode và thấy provider nào đang hoạt động, để kiểm soát trải nghiệm sử dụng.

#### Acceptance Criteria

1. THE App SHALL hiển thị toggle bật/tắt offline mode trong màn hình Settings.
2. THE App SHALL chỉ cho phép bật offline mode khi ít nhất một Offline_Provider đã download model thành công.
3. WHEN User bật offline mode, THE Orchestrator SHALL chuyển Fallback_Strategy sang "offline_only" cho TTS và STT.
4. THE App SHALL hiển thị indicator trên màn hình chính cho biết provider hiện tại đang xử lý request (ví dụ: "ElevenLabs", "Offline", "Gemini").
5. WHEN Orchestrator thực hiện auto-fallback, THE App SHALL hiển thị thông báo ngắn cho User biết đã chuyển provider (ví dụ: "Đã chuyển sang offline mode").
6. THE App SHALL hiển thị trạng thái download model cho mỗi Offline_Provider: "Chưa tải", "Đang tải (X%)", "Sẵn sàng", "Lỗi".

### Requirement 14: UI — Thống kê sử dụng (v0.2)

**User Story:** Là một User, tôi muốn xem thống kê sử dụng quota của mỗi provider, để biết mình đã dùng bao nhiêu và còn bao nhiêu.

#### Acceptance Criteria

1. THE App SHALL hiển thị trang thống kê sử dụng cho mỗi Service_Type trong Settings.
2. THE App SHALL hiển thị usage hiện tại so với Quota_Limit cho mỗi Online_Provider (ví dụ: "ElevenLabs TTS: 7.200/10.000 chars").
3. THE App SHALL hiển thị biểu đồ thanh (progress bar) thể hiện phần trăm quota đã sử dụng.
4. THE App SHALL hiển thị ngày reset quota tiếp theo cho mỗi provider.
5. WHEN quota của một provider đạt 90%, THE App SHALL hiển thị cảnh báo màu vàng trên progress bar.
6. WHEN quota của một provider đạt 100%, THE App SHALL hiển thị trạng thái "Hết quota" màu đỏ và thông tin provider fallback đang được sử dụng.

### Requirement 15: Feature Module Independence

**User Story:** Là một developer, tôi muốn AI Service Orchestrator là một feature module độc lập, để dễ bảo trì, test, và mở rộng mà không ảnh hưởng các module khác.

#### Acceptance Criteria

1. THE Orchestrator SHALL nằm trong thư mục `lib/features/ai_services/` với cấu trúc feature module chuẩn (models, repositories, providers, logic).
2. THE Orchestrator SHALL không import trực tiếp code từ các feature module khác (shadowing, conversation, progress).
3. THE Orchestrator SHALL expose public API thông qua Riverpod providers để các module khác sử dụng.
4. THE Orchestrator SHALL định nghĩa abstract interface cho mỗi Service_Type để provider implementations tuân theo.
5. THE Orchestrator SHALL cho phép thêm provider mới bằng cách tạo class implement interface tương ứng và đăng ký vào Provider_Registry mà không cần sửa code Orchestrator core.
