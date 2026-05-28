import 'dart:async';
import 'dart:io';

import 'package:speakeng/core/exceptions.dart';

/// Centralizes timeout/network error handling for all API calls.
class ApiCallHelper {
  static Future<T> execute<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on TimeoutException {
      throw const ApiTimeoutError();
    } on SocketException {
      throw const NetworkError();
    }
  }
}
