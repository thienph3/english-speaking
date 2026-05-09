/// Application-wide constants for SpeakEng.
class AppConstants {
  AppConstants._();

  // Supabase
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Audio
  static const audioSampleRate = 16000;
  static const audioChannels = 1; // mono
  static const minAudioDuration = Duration(seconds: 1);
  static const maxAudioDuration = Duration(seconds: 60);

  // Pronunciation thresholds
  static const accuracyGoodThreshold = 80.0;
  static const accuracyFairThreshold = 50.0;

  // Mastery
  static const masteryStreakRequired = 3;

  // Placement
  static const placementSentenceCount = 3;

  // Conversation
  static const maxConversationTurns = 5;

  // API
  static const apiTimeoutDuration = Duration(seconds: 10);

  // Speed options
  static const speedOptions = [0.7, 1.0, 1.2];

  // Daily flow
  static const dailyShadowingCount = 3;
  static const dailyConversationCount = 1;
}
