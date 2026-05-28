import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'app.dart';
import 'shared/services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sherpa.initBindings();
  await SupabaseService.initialize();
  runApp(const ProviderScope(child: SpeakEngApp()));
}
