// ============================================================
// token_service.dart — Simpan/ambil/hapus sesi login
//   Pakai shared_preferences supaya user tidak perlu login ulang
//   tiap kali app dibuka.
// ============================================================

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  final String token;
  final String expiresAt;
  final String id;
  final String nama;
  final String username;
  final String role;
  final String nim;
  final String nidn;
  final int mustChangePassword;

  const UserSession({
    required this.token,
    required this.expiresAt,
    required this.id,
    required this.nama,
    required this.username,
    required this.role,
    required this.nim,
    required this.nidn,
    required this.mustChangePassword,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      token: json['token']?.toString() ?? '',
      expiresAt: json['expires_at']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      nim: json['nim']?.toString() ?? '',
      nidn: json['nidn']?.toString() ?? '',
      mustChangePassword:
          int.tryParse(json['must_change_password']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'expires_at': expiresAt,
        'id': id,
        'nama': nama,
        'username': username,
        'role': role,
        'nim': nim,
        'nidn': nidn,
        'must_change_password': mustChangePassword,
      };
}

class TokenService {
  TokenService._();

  static const String _keySession = 'user_session';

  static Future<void> saveSession(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySession, jsonEncode(session.toJson()));
  }

  static Future<UserSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keySession);
    if (raw == null) return null;

    try {
      return UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getToken() async {
    final session = await getSession();
    return session?.token;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySession);
  }

  static Future<bool> isLoggedIn() async {
    final session = await getSession();
    return session != null && session.token.isNotEmpty;
  }

  /// Cek token sudah kedaluwarsa berdasarkan expires_at yang dikirim
  /// backend saat login. Dipakai buat auto-redirect ke login page
  /// kalau sesi sudah basi (misal app di-resume setelah beberapa hari).
  static Future<bool> isTokenExpired() async {
    final session = await getSession();
    if (session == null || session.expiresAt.isEmpty) return true;

    final expiresAt = DateTime.tryParse(session.expiresAt);
    if (expiresAt == null) return true;

    return DateTime.now().isAfter(expiresAt);
  }
}
