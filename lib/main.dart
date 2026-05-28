import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'app.dart';
import 'features/ai_services/logic/quota_tracker.dart';
import 'shared/services/prefs_service.dart';
import 'shared/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sherpa.initBindings();
  await SupabaseService.initialize();
  await PrefsService.initialize();

  // Initialize quota tracker early so UI shows correct values
  await QuotaTracker().load();

  // Global error handlers — prevent white screen of death
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled: $error\n$stack');
    return true;
  };

  runApp(const ProviderScope(child: SpeakEngApp()));
}
