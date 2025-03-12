import '../constants/api_codes.dart';

class ApiResponse<T> {
  final String code;
  final String message;
  final T? data;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic)? parser) {
    return ApiResponse(
      code: json['code'] as String,
      message: json['message'] as String,
      data:
          json['data'] != null && parser != null ? parser(json['data']) : null,
    );
  }

  bool get isSuccess => code == ApiCodes.codeSuccess;

  String get errorMessage =>
      message.isNotEmpty ? message : ApiCodes.getMessageForCode(code);
}
