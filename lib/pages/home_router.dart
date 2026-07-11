import 'package:flutter/material.dart';

import 'admin_home_page.dart';
import 'dosen_home_page.dart';
import 'mahasiswa_home_page.dart';

// ============================================================
// home_router.dart — Pilih halaman home yang tepat sesuai role
//   Dipanggil dari login_page.dart & change_password.dart supaya
//   logic role->page cuma ada di 1 tempat.
// ============================================================

Widget buildHomePageForRole({
  required String role,
  required String userId,
  required String nama,
  required String username,
  required String nim,
}) {
  switch (role) {
    case 'admin':
      return AdminHomePage(userId: userId, nama: nama, username: username);
    case 'dosen':
      return DosenHomePage(userId: userId, nama: nama, username: username);
    default:
      return MahasiswaHomePage(
        userId: userId,
        nama: nama,
        username: username,
        nim: nim,
      );
  }
}
