import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalException;

  ApiException({
    required this.message,
    this.statusCode,
    this.originalException,
  });

  factory ApiException.fromDioException(DioException dioException) {
    int? statusCode = dioException.response?.statusCode;
    String message = 'An unexpected error occurred. Please try again.';

    final response = dioException.response;
    if (response != null && response.data != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          message = data['message'].toString();
        } else if (data['error'] != null) {
          message = data['error'].toString();
        } else if (data['errors'] != null) {
          final errors = data['errors'];
          if (errors is List) {
            message = errors.join(', ');
          } else if (errors is Map) {
            message = errors.values.join(', ');
          } else {
            message = errors.toString();
          }
        }
      } else if (data is String && data.isNotEmpty) {
        message = data;
      }
    } else {
      switch (dioException.type) {
        case DioExceptionType.connectionTimeout:
          message = 'Connection timeout. Please check your internet connection.';
          break;
        case DioExceptionType.sendTimeout:
          message = 'Send timeout. Please try again.';
          break;
        case DioExceptionType.receiveTimeout:
          message = 'Receive timeout. Please try again.';
          break;
        case DioExceptionType.badCertificate:
          message = 'Secure connection failed. Bad certificate.';
          break;
        case DioExceptionType.cancel:
          message = 'Request cancelled.';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection. Please check your network settings.';
          break;
        case DioExceptionType.badResponse:
          message = _getMessageForStatus(statusCode);
          break;
        case DioExceptionType.unknown:
        default:
          if (dioException.error != null) {
            final errorStr = dioException.error.toString();
            if (errorStr.contains('SocketException')) {
              message = 'No internet connection. Please check your network settings.';
            } else {
              message = errorStr;
            }
          }
          break;
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      originalException: dioException,
    );
  }

  static String _getMessageForStatus(int? statusCode) {
    if (statusCode == null) return 'An unexpected network error occurred.';
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check the submitted details.';
      case 401:
        return 'Unauthorized access. Please login again.';
      case 403:
        return 'Access forbidden.';
      case 404:
        return 'Requested resource not found.';
      case 409:
        return 'Conflict occurred. Please try again.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Bad gateway. Please try again later.';
      case 503:
        return 'Service unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. Please try again later.';
      default:
        return 'Server returned error status: $statusCode';
    }
  }

  @override
  String toString() => message;
}
