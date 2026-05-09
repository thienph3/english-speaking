import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:speakeng/features/shadowing/models/sentence.dart';

/// Service để load và parse nội dung JSON từ assets.
///
/// Cung cấp truy cập đến:
/// - Câu shadowing (sentences.json)
/// - Câu placement test (placement.json)
class ContentService {
  static const _sentencesPath = 'lib/data/sentences.json';
  static const _placementPath = 'lib/data/placement.json';

  List<Sentence>? _cachedSentences;
  List<PlacementSentence>? _cachedPlacement;

  /// Load tất cả câu shadowing từ assets.
  ///
  /// Kết quả được cache sau lần load đầu tiên.
  /// Trả về danh sách [Sentence] đã parse từ JSON.
  Future<List<Sentence>> getAllSentences() async {
    if (_cachedSentences != null) return _cachedSentences!;

    final jsonString = await rootBundle.loadString(_sentencesPath);
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    _cachedSentences = jsonList
        .map((e) => Sentence.fromJson(e as Map<String, dynamic>))
        .toList();

    return _cachedSentences!;
  }

  /// Load câu placement test từ assets.
  ///
  /// Kết quả được cache sau lần load đầu tiên.
  /// Trả về danh sách [PlacementSentence] sắp xếp theo độ khó
  /// (easy → medium → hard).
  Future<List<PlacementSentence>> getPlacementSentences() async {
    if (_cachedPlacement != null) return _cachedPlacement!;

    final jsonString = await rootBundle.loadString(_placementPath);
    final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;

    _cachedPlacement = jsonList
        .map((e) => PlacementSentence.fromJson(e as Map<String, dynamic>))
        .toList();

    return _cachedPlacement!;
  }

  /// Lọc câu shadowing theo situation.
  ///
  /// [situation] — tên tình huống (ví dụ: "ordering_food").
  Future<List<Sentence>> getSentencesBySituation(String situation) async {
    final all = await getAllSentences();
    return all.where((s) => s.situation == situation).toList();
  }

  /// Lọc câu shadowing theo difficulty.
  ///
  /// [difficulty] — mức độ khó: "easy", "medium", "hard".
  Future<List<Sentence>> getSentencesByDifficulty(String difficulty) async {
    final all = await getAllSentences();
    return all.where((s) => s.difficulty == difficulty).toList();
  }

  /// Xóa cache để force reload từ assets.
  void clearCache() {
    _cachedSentences = null;
    _cachedPlacement = null;
  }
}

/// Câu dùng trong placement test.
///
/// Chỉ gồm id, text, và difficulty — không cần phrases hay grammar.
class PlacementSentence {
  /// ID duy nhất của câu placement.
  final String id;

  /// Nội dung câu tiếng Anh.
  final String text;

  /// Độ khó: "easy", "medium", "hard".
  final String difficulty;

  const PlacementSentence({
    required this.id,
    required this.text,
    required this.difficulty,
  });

  /// Parse từ JSON map.
  factory PlacementSentence.fromJson(Map<String, dynamic> json) {
    return PlacementSentence(
      id: json['id'] as String,
      text: json['text'] as String,
      difficulty: json['difficulty'] as String,
    );
  }

  /// Convert sang JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'difficulty': difficulty,
    };
  }
}
