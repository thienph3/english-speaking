import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:speakeng/shared/services/supabase_service.dart';

/// Provider cho RecordingRepository.
final recordingRepositoryProvider = Provider<RecordingRepository>((ref) {
  return RecordingRepository(ref.read(supabaseProvider));
});

/// Loại bản ghi âm.
enum RecordingType { before, after, practice }

/// Metadata của một bản ghi âm.
class RecordingMetadata {
  final String id;
  final String userId;
  final String sentenceId;
  final String audioPath;
  final double? accuracy;
  final RecordingType recordingType;
  final DateTime createdAt;

  const RecordingMetadata({
    required this.id,
    required this.userId,
    required this.sentenceId,
    required this.audioPath,
    this.accuracy,
    required this.recordingType,
    required this.createdAt,
  });

  factory RecordingMetadata.fromJson(Map<String, dynamic> json) {
    return RecordingMetadata(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      sentenceId: json['sentence_id'] as String,
      audioPath: json['audio_path'] as String,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      recordingType: _parseType(json['recording_type'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static RecordingType _parseType(String type) {
    switch (type) {
      case 'before':
        return RecordingType.before;
      case 'after':
        return RecordingType.after;
      default:
        return RecordingType.practice;
    }
  }
}

/// Repository quản lý upload/download audio recordings lên Supabase Storage
/// và lưu metadata vào bảng recordings.
class RecordingRepository {
  final SupabaseClient _supabase;

  /// Tên bucket trên Supabase Storage.
  static const _bucket = 'recordings';

  /// Tên bảng metadata.
  static const _table = 'recordings';

  RecordingRepository(this._supabase);

  /// Upload audio file lên Supabase Storage và lưu metadata.
  ///
  /// [audioBytes] — nội dung file audio (WAV).
  /// [sentenceId] — ID câu shadowing.
  /// [recordingType] — loại bản ghi (before/after/practice).
  /// [accuracy] — điểm accuracy (optional).
  Future<RecordingMetadata> uploadRecording({
    required Uint8List audioBytes,
    required String sentenceId,
    required RecordingType recordingType,
    double? accuracy,
  }) async {
    final userId = _currentUserId;
    final path = _buildStoragePath(
      userId: userId,
      sentenceId: sentenceId,
      type: recordingType,
    );

    await _uploadToStorage(path, audioBytes);
    return _saveMetadata(
      userId: userId,
      sentenceId: sentenceId,
      audioPath: path,
      recordingType: recordingType,
      accuracy: accuracy,
    );
  }

  /// Lấy URL tạm thời để phát audio recording.
  Future<String> getSignedUrl(String audioPath) async {
    final response = await _supabase.storage
        .from(_bucket)
        .createSignedUrl(audioPath, 3600);
    return response;
  }

  /// Lấy bản ghi before/after cho một sentence.
  Future<List<RecordingMetadata>> getBeforeAfter(
    String sentenceId,
  ) async {
    final userId = _currentUserId;
    final response = await _supabase
        .from(_table)
        .select()
        .eq('user_id', userId)
        .eq('sentence_id', sentenceId)
        .inFilter('recording_type', ['before', 'after'])
        .order('created_at');

    return (response as List)
        .map((e) => RecordingMetadata.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Kiểm tra đã có bản ghi "before" cho sentence chưa.
  Future<bool> hasBeforeRecording(String sentenceId) async {
    final userId = _currentUserId;
    final response = await _supabase
        .from(_table)
        .select('id')
        .eq('user_id', userId)
        .eq('sentence_id', sentenceId)
        .eq('recording_type', 'before')
        .limit(1);

    return (response as List).isNotEmpty;
  }

  String get _currentUserId {
    final user = _supabase.auth.currentUser;
    if (user == null) throw StateError('User not authenticated');
    return user.id;
  }

  String _buildStoragePath({
    required String userId,
    required String sentenceId,
    required RecordingType type,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$userId/$sentenceId/${type.name}_$timestamp.wav';
  }

  Future<void> _uploadToStorage(String path, Uint8List bytes) async {
    await _supabase.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'audio/wav',
            upsert: true,
          ),
        );
  }

  Future<RecordingMetadata> _saveMetadata({
    required String userId,
    required String sentenceId,
    required String audioPath,
    required RecordingType recordingType,
    double? accuracy,
  }) async {
    final response = await _supabase.from(_table).insert({
      'user_id': userId,
      'sentence_id': sentenceId,
      'audio_path': audioPath,
      'accuracy': accuracy,
      'recording_type': recordingType.name,
    }).select().single();

    return RecordingMetadata.fromJson(response);
  }
}
