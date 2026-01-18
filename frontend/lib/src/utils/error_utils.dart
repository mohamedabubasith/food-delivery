import 'package:dio/dio.dart';

class ErrorUtils {
  static String parseError(Object error) {
    if (error is DioException) {
      if (error.response?.data != null) {
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          // Standard Backend Format: { "message": "...", "error": "..." }
          if (data.containsKey('error') && data['error'] != null) {
            return data['error'].toString();
          }
          if (data.containsKey('detail')) {
            return data['detail'].toString();
          }
           if (data.containsKey('message')) {
            return data['message'].toString();
          }
        }
      }
      return 'Network Error: ${error.message}';
    }
    return error.toString();
  }
}
