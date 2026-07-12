// ============================================================
// auth_service.dart — Logic autentikasi (login, logout, ganti password)
// ============================================================

import '../config/api_config.dart';
import 'api_client.dart';
import 'token_service.dart';

class AuthService {
  AuthService._();

  static Future<UserSession> login(String username, String password) async {
    final data = await ApiClient.postForm(
      ApiConfig.login,
      body: {'username': username, 'password': password},
      useAuth: false,
    );

    if (data['status'] != 'ok') {
      throw ApiException(data['message']?.toString() ?? 'Login gagal');
    }

    final session = UserSession.fromJson(data['data'] as Map<String, dynamic>);
    await TokenService.saveSession(session);
    return session;
  }

  static Future<void> logout() async {
    try {
      await ApiClient.postForm(ApiConfig.logout);
    } catch (_) {
      // Kalau gagal (mis. tidak ada koneksi), tetap lanjut hapus sesi lokal
      // supaya user tidak "terjebak" login di device ini.
    } finally {
      await TokenService.clearSession();
    }
  }

  static Future<void> changePassword(String passwordBaru) async {
    final data = await ApiClient.postForm(
      ApiConfig.changePassword,
      body: {'password_baru': passwordBaru},
    );

    if (data['status'] != 'ok') {
      throw ApiException(data['message']?.toString() ?? 'Gagal mengubah password');
    }

    // Update sesi lokal: set must_change_password = 0
    // agar app tidak minta ganti password lagi saat dibuka ulang
    final currentSession = await TokenService.getSession();
    if (currentSession != null) {
      final updatedSession = UserSession(
        token: currentSession.token,
        expiresAt: currentSession.expiresAt,
        id: currentSession.id,
        nama: currentSession.nama,
        username: currentSession.username,
        role: currentSession.role,
        nim: currentSession.nim,
        nidn: currentSession.nidn,
        mustChangePassword: 0,
      );
      await TokenService.saveSession(updatedSession);
    }
  }
}
