import 'package:shared_preferences/shared_preferences.dart';

/// Singleton access to SharedPreferences, initialized once at app start.
class PrefsService {
  static SharedPreferences? _instance;

  static Future<void> initialize() async {
    _instance = await SharedPreferences.getInstance();
  }

  static SharedPreferences get instance {
    assert(_instance != null, 'Call PrefsService.initialize() first');
    return _instance!;
  }
}
