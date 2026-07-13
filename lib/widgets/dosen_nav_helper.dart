import 'package:flutter/material.dart';

import './soft_bottom_nav.dart';

// ============================================================
// dosen_nav_helper.dart — Logika navigasi bottom-nav Dosen
//   SATU tempat definisi nav items + routing.
//   Semua halaman dosen cukup import helper ini.
// ============================================================

class DosenNavHelper {
  DosenNavHelper._();

  /// Item-item bottom nav — urutan tetap di semua halaman dosen.
  static const List<SoftNavItem> navItems = [
    SoftNavItem(icon: Icons.home_rounded, label: 'Beranda'),
    SoftNavItem(icon: Icons.calendar_month_rounded, label: 'Jadwal'),
    SoftNavItem(icon: Icons.star_rounded, label: 'Nilai'),
    SoftNavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  /// Tangani ketukan bottom-nav untuk dosen.
  ///
  /// [context]       — BuildContext halaman pemanggil.
  /// [tappedIndex]   — index yang baru saja ditap.
  /// [currentIndex]  — index halaman yang sedang aktif.
  /// [onLogout]      — callback logout.
  ///
  /// Return `true` kalau navigasi sudah ditangani, `false` kalau belum.
  static bool handleTap({
    required BuildContext context,
    required int tappedIndex,
    required int currentIndex,
    VoidCallback? onLogout,
  }) {
    // Kalau tap di index yang sama, abaikan.
    if (tappedIndex == currentIndex) return true;

    switch (tappedIndex) {
      case 0:
        // Kembali ke beranda (pop sampai root).
        Navigator.popUntil(context, (route) => route.isFirst);
        return true;

      case 1:
        // Jadwal — placeholder, nanti bisa dihubungkan ke halaman jadwal dosen
        _showPlaceholder(context, 'Jadwal');
        return true;

      case 2:
        // Nilai — placeholder, nanti bisa dihubungkan ke halaman input nilai
        _showPlaceholder(context, 'Nilai');
        return true;

      case 3:
        // Profil → logout
        if (onLogout != null) onLogout();
        return true;

      default:
        return false;
    }
  }

  static void _showPlaceholder(BuildContext context, String fitur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$fitur akan segera hadir'),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  /// Convenience: buat SoftBottomNav yang sudah ter-wire dengan helper.
  static SoftBottomNav buildNav({
    required BuildContext context,
    required int currentIndex,
    VoidCallback? onLogout,
    VoidCallback? onBerandaTap,
  }) {
    return SoftBottomNav(
      items: navItems,
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 0 && currentIndex == 0 && onBerandaTap != null) {
          onBerandaTap();
          return;
        }
        handleTap(
          context: context,
          tappedIndex: index,
          currentIndex: currentIndex,
          onLogout: onLogout,
        );
      },
    );
  }
}
