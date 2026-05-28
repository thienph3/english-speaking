import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:speakeng/features/conversation/models/scenario.dart';

/// Provider that loads all available scenarios (filtered by date).
final availableScenariosProvider = FutureProvider<List<Scenario>>((ref) async {
  final jsonString = await rootBundle.loadString('lib/data/scenarios.json');
  final list = json.decode(jsonString) as List<dynamic>;
  final all = list
      .map((e) => Scenario.fromJson(e as Map<String, dynamic>))
      .toList();

  return all.where((s) => s.isAvailableNow).toList();
});

/// Provider that picks today's conversation scenario.
///
/// Prioritizes event scenarios if available, otherwise picks
/// a random common scenario (seeded by date for consistency).
final dailyScenarioProvider = FutureProvider<Scenario?>((ref) async {
  final scenarios = await ref.watch(availableScenariosProvider.future);
  if (scenarios.isEmpty) return null;

  // Prefer event scenarios if any are active
  final events = scenarios.where((s) => s.category == ScenarioCategory.event);
  if (events.isNotEmpty) {
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    return events.elementAt(seed % events.length);
  }

  // Otherwise pick a common scenario (deterministic per day)
  final today = DateTime.now();
  final seed = today.year * 10000 + today.month * 100 + today.day;
  final rng = Random(seed);
  return scenarios[rng.nextInt(scenarios.length)];
});
