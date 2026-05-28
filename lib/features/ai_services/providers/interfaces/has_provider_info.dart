import 'package:speakeng/features/ai_services/models/service_types.dart';

/// Interface chung cho tất cả AI providers có ProviderInfo.
abstract class HasProviderInfo {
  ProviderInfo get info;
}
