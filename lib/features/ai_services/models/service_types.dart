/// Loại dịch vụ AI trong hệ thống.
enum ServiceType { tts, stt, llm, pronunciation }

/// Loại kết nối của provider.
enum ConnectionType { online, offline }

/// Trạng thái sẵn sàng của provider.
enum ProviderStatus { ready, notDownloaded, unavailable }

/// Chiến lược fallback khi chọn provider.
enum FallbackStrategy { freeFist, qualityFirst, offlineOnly }

/// Thông tin metadata của một AI provider.
class ProviderInfo {
  const ProviderInfo({
    required this.id,
    required this.serviceType,
    required this.connectionType,
    this.status = ProviderStatus.ready,
    this.quotaLimit,
    this.quotaCycle = QuotaCycle.monthly,
    this.qualityRank = 0,
  });

  final String id;
  final ServiceType serviceType;
  final ConnectionType connectionType;
  final ProviderStatus status;

  /// Giới hạn quota (null = unlimited).
  final int? quotaLimit;
  final QuotaCycle quotaCycle;

  /// Thứ tự chất lượng (0 = cao nhất).
  final int qualityRank;

  bool get isOnline => connectionType == ConnectionType.online;
  bool get isOffline => connectionType == ConnectionType.offline;
  bool get isReady => status == ProviderStatus.ready;
  bool get hasUnlimitedQuota => quotaLimit == null;

  ProviderInfo copyWith({ProviderStatus? status}) {
    return ProviderInfo(
      id: id,
      serviceType: serviceType,
      connectionType: connectionType,
      status: status ?? this.status,
      quotaLimit: quotaLimit,
      quotaCycle: quotaCycle,
      qualityRank: qualityRank,
    );
  }
}

/// Chu kỳ reset quota.
enum QuotaCycle { daily, monthly }
