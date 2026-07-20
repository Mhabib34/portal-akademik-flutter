import 'package:flutter/material.dart';

import './soft_bottom_nav.dart';
import '../pages/mahasiswa/mahasiswa_profil_page.dart';
import '../pages/mahasiswa/mahasiswa_nilai_page.dart';
import '../pages/mahasiswa/mahasiswa_jadwal_page.dart';

class MahasiswaNavHelper {
  MahasiswaNavHelper._();

  /// Item-item bottom nav — urutan tetap di semua halaman mahasiswa.
  static const List<SoftNavItem> navItems = [
    SoftNavItem(icon: Icons.home_rounded, label: 'Beranda'),
    SoftNavItem(icon: Icons.calendar_month_rounded, label: 'Jadwal'),
    SoftNavItem(icon: Icons.school_rounded, label: 'Nilai'),
    SoftNavItem(icon: Icons.person_rounded, label: 'Profil'),
  ];

  /// Tangani ketukan bottom-nav untuk mahasiswa.
  ///
  /// [context]       — BuildContext halaman pemanggil.
  /// [tappedIndex]   — index yang baru saja ditap.
  /// [currentIndex]  — index halaman yang sedang aktif.
  /// [userId], [nama], [username], [nim] — data profil mahasiswa (untuk navigasi ke profil).
  ///
  /// Return `true` kalau navigasi sudah ditangani, `false` kalau belum.
  static bool handleTap({
    required BuildContext context,
    required int tappedIndex,
    required int currentIndex,
    required String userId,
    required String nama,
    required String username,
    required String nim,
  }) {
    // Kalau tap di index yang sama, abaikan.
    if (tappedIndex == currentIndex) return true;

    switch (tappedIndex) {
      case 0:
        // Kembali ke beranda (pop sampai root).
        Navigator.popUntil(context, (route) => route.isFirst);
        return true;

      case 1:
        // Jadwal
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MahasiswaJadwalPage(
              userId: userId,
              nama: nama,
              username: username,
              nim: nim,
            ),
          ),
        );
        return true;

      case 2:
        // Nilai
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MahasiswaNilaiPage(
              userId: userId,
              nama: nama,
              username: username,
              nim: nim,
            ),
          ),
        );
        return true;

      case 3:
        // Profil → MahasiswaProfilPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MahasiswaProfilPage(
              userId: userId,
              nama: nama,
              username: username,
              nim: nim,
            ),
          ),
        );
        return true;

      default:
        return false;
    }
  }

  /// Convenience: buat SoftBottomNav yang sudah ter-wire dengan helper.
  /// [centerActionOnTap] — callback untuk FAB tengah (Ajukan KRS).
  static SoftBottomNav buildNav({
    required BuildContext context,
    required int currentIndex,
    required String userId,
    required String nama,
    required String username,
    required String nim,
    VoidCallback? centerActionOnTap,
    VoidCallback? onBerandaTap,
  }) {
    return SoftBottomNav(
      items: navItems,
      currentIndex: currentIndex,
      centerActionIcon: Icons.add_rounded,
      centerActionOnTap: centerActionOnTap,
      onTap: (index) {
        if (index == 0 && currentIndex == 0 && onBerandaTap != null) {
          onBerandaTap();
          return;
        }
        handleTap(
          context: context,
          tappedIndex: index,
          currentIndex: currentIndex,
          userId: userId,
          nama: nama,
          username: username,
          nim: nim,
        );
      },
    );
  }
}
