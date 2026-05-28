import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider cho trạng thái connectivity hiện tại.
///
/// Stream emit `true` khi online, `false` khi offline.
/// Kiểm tra bằng DNS lookup mỗi 10 giây.
final connectivityProvider = StreamProvider<bool>((ref) {
  return ConnectivityService().statusStream;
});

/// Provider đơn giản cho trạng thái online/offline hiện tại.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityProvider).value ?? true;
});

/// Service kiểm tra kết nối mạng bằng DNS lookup.
///
/// Không cần thêm package — dùng dart:io InternetAddress.lookup.
class ConnectivityService {
  static const _checkInterval = Duration(seconds: 10);
  static const _host = 'google.com';

  /// Stream trạng thái online/offline.
  Stream<bool> get statusStream async* {
    // Emit trạng thái ban đầu
    yield await checkConnectivity();

    // Kiểm tra định kỳ
    yield* Stream.periodic(_checkInterval, (_) => null)
        .asyncMap((_) => checkConnectivity());
  }

  /// Kiểm tra kết nối bằng DNS lookup.
  Future<bool> checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup(_host)
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    }
  }
}
