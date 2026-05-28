import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:speakeng/features/ai_services/models/service_types.dart';

const _quotaKey = 'quota_usage';
const _quotaResetKey = 'quota_reset_date';

/// Tracks API usage per provider and warns when near quota limit.
class QuotaTracker {
  final Map<String, int> _usage = {};
  bool _loaded = false;

  /// Load persisted usage from SharedPreferences.
  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    // Reset if cycle has passed
    final resetDate = prefs.getString(_quotaResetKey);
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month}';

    if (resetDate != currentMonth) {
      await prefs.remove(_quotaKey);
      await prefs.setString(_quotaResetKey, currentMonth);
      _loaded = true;
      return;
    }

    final json = prefs.getString(_quotaKey);
    if (json != null) {
      final map = jsonDecode(json) as Map<String, dynamic>;
      _usage.addAll(map.map((k, v) => MapEntry(k, v as int)));
    }
    _loaded = true;
  }

  /// Record one usage for a provider.
  Future<void> record(String providerId) async {
    await load();
    _usage[providerId] = (_usage[providerId] ?? 0) + 1;
    await _persist();
  }

  /// Get current usage count for a provider.
  int getUsage(String providerId) => _usage[providerId] ?? 0;

  /// Check if provider is near quota limit (≥80%).
  bool isNearLimit(ProviderInfo info) {
    if (info.quotaLimit == null) return false;
    final used = getUsage(info.id);
    return used >= info.quotaLimit! * 0.8;
  }

  /// Check if provider has exceeded quota.
  bool isExceeded(ProviderInfo info) {
    if (info.quotaLimit == null) return false;
    return getUsage(info.id) >= info.quotaLimit!;
  }

  /// Remaining quota for a provider (null = unlimited).
  int? remaining(ProviderInfo info) {
    if (info.quotaLimit == null) return null;
    final left = info.quotaLimit! - getUsage(info.id);
    return left.clamp(0, info.quotaLimit!);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_quotaKey, jsonEncode(_usage));
  }
}
