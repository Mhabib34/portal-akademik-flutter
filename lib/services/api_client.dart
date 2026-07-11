// ============================================================
// api_client.dart — Wrapper HTTP terpusat
//   Semua page tinggal panggil ApiClient.get()/postForm()/postJson(),
//   header "Authorization: Bearer <token>" otomatis ditempelkan,
//   tidak perlu diurus manual di tiap file lagi.
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;

import 'token_service.dart';

class ApiException implements Exception {
  final String message;
  final bool isUnauthorized;

  ApiException(this.message, {this.isUnauthorized = false});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static const Duration _timeout = Duration(seconds: 15);

  /// GET dengan query params opsional.
  static Future<Map<String, dynamic>> get(
    String url, {
    Map<String, String>? queryParams,
    bool useAuth = true,
  }) async {
    var uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    final headers = await _buildHeaders(useAuth);

    try {
      final response = await http.get(uri, headers: headers).timeout(_timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    }
  }

  /// POST application/x-www-form-urlencoded (form biasa, sesuai $_POST di PHP).
  static Future<Map<String, dynamic>> postForm(
    String url, {
    Map<String, String>? body,
    bool useAuth = true,
  }) async {
    final headers = await _buildHeaders(useAuth);

    try {
      final response = await http
          .post(Uri.parse(url), headers: headers, body: body)
          .timeout(_timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    }
  }

  /// POST application/json (dipakai endpoint seperti ajukan_krs.php, simpan_nilai.php).
  static Future<Map<String, dynamic>> postJson(
    String url, {
    Map<String, dynamic>? body,
    bool useAuth = true,
  }) async {
    final headers = await _buildHeaders(useAuth);
    headers['Content-Type'] = 'application/json';

    try {
      final response = await http
          .post(Uri.parse(url), headers: headers, body: jsonEncode(body ?? {}))
          .timeout(_timeout);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Tidak dapat terhubung ke server. Periksa koneksi Anda.');
    }
  }

  static Future<Map<String, String>> _buildHeaders(bool useAuth) async {
    final headers = <String, String>{};
    if (useAuth) {
      final token = await TokenService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Respons server tidak valid');
    }

    if (response.statusCode == 401) {
      throw ApiException(
        data['message']?.toString() ?? 'Sesi Anda berakhir, silakan login ulang',
        isUnauthorized: true,
      );
    }

    return data;
  }
}
