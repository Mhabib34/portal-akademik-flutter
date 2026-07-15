import 'package:flutter/material.dart';

import './soft_bottom_nav.dart';
import '../pages/admin/penjadwalan_page.dart';
import '../pages/admin/fakultas_prodi_hub_page.dart';
import '../services/auth_service.dart';
import './logout_dialog.dart';
import '../pages/auth/login_page.dart';

// ============================================================
// admin_nav_helper.dart — Logika navigasi bottom-nav Admin
//   SATU tempat definisi nav items + routing.
//   Semua halaman admin cukup import helper ini.
// ============================================================

class AdminNavHelper {
  AdminNavHelper._();

  /// Item-item bottom nav — urutan tetap di semua halaman.
  static const List<SoftNavItem> navItems = [
    SoftNavItem(icon: Icons.home_rounded, label: 'Beranda'),
    SoftNavItem(icon: Icons.calendar_month_rounded, label: 'Jadwal'),
    SoftNavItem(icon: Icons.storage_rounded, label: 'Data'),
    SoftNavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  /// Tangani ketukan bottom-nav untuk admin.
  ///
  /// [context]       — BuildContext halaman pemanggil.
  /// [tappedIndex]   — index yang baru saja ditap.
  /// [currentIndex]  — index halaman yang sedang aktif.
  /// [onLogout]      — callback logout (ada di halaman yang punya AuthService).
  /// [nama]          — nama user (untuk FakultasProdiHubPage).
  ///
  /// Return `true` kalau navigasi sudah ditangani, `false` kalau
  /// halaman pemanggil perlu tangani sendiri (misal setState untuk index 0).
  static bool handleTap({
    required BuildContext context,
    required int tappedIndex,
    required int currentIndex,
    VoidCallback? onLogout,
    String nama = '',
  }) {
    // Kalau tap di index yang sama, abaikan.
    if (tappedIndex == currentIndex) return true;

    switch (tappedIndex) {
      case 0:
        // Kembali ke beranda (pop sampai root).
        Navigator.popUntil(context, (route) => route.isFirst);
        return true;

      case 1:
        // Jadwal → PenjadwalanPage
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PenjadwalanPage(nama: nama)),
        );
        return true;

      case 2:
        // Data → FakultasProdiHubPage (hub manajemen data)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FakultasProdiHubPage(nama: nama),
          ),
        );
        return true;

      case 3:
        // Profil → logout
        if (onLogout != null) {
          onLogout();
        } else {
          _performLogout(context);
        }
        return true;

      default:
        return false;
    }
  }

  static Future<void> _performLogout(BuildContext context) async {
    final konfirmasi = await showLogoutDialog(context);
    if (konfirmasi != true) return;

    await AuthService.logout();
    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  /// Convenience: buat SoftBottomNav yang sudah ter-wire dengan helper.
  static SoftBottomNav buildNav({
    required BuildContext context,
    required int currentIndex,
    VoidCallback? onLogout,
    String nama = '',
    /// Kalau halaman beranda perlu setState sendiri, override di sini.
    VoidCallback? onBerandaTap,
  }) {
    return SoftBottomNav(
      items: navItems,
      currentIndex: currentIndex,
      onTap: (index) {
        // Kalau di beranda (index 0) dan tap beranda, panggil override.
        if (index == 0 && currentIndex == 0 && onBerandaTap != null) {
          onBerandaTap();
          return;
        }
        handleTap(
          context: context,
          tappedIndex: index,
          currentIndex: currentIndex,
          onLogout: onLogout,
          nama: nama,
        );
      },
    );
  }
}
