import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ============================================================
// logout_dialog.dart — Modal konfirmasi logout
//   Desain premium sesuai tema soft-pastel portal akademik.
//   Dipakai di semua role (admin/dosen/mahasiswa).
// ============================================================

/// Menampilkan dialog konfirmasi logout.
/// Return `true` jika user memilih keluar, `false`/null jika batal.
Future<bool?> showLogoutDialog(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Logout',
    barrierColor: AppColorsSoft.navy.withOpacity(0.45),
    transitionDuration: const Duration(milliseconds: 350),
    transitionBuilder: (ctx, anim, secondAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: curved,
        child: FadeTransition(opacity: anim, child: child),
      );
    },
    pageBuilder: (ctx, anim, secondAnim) => const _LogoutDialogContent(),
  );
}

class _LogoutDialogContent extends StatelessWidget {
  const _LogoutDialogContent();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 360),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColorsSoft.cardWhite,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColorsSoft.navy.withOpacity(0.12),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- Icon warning ---
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE0E0),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE05252).withOpacity(0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE05252),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 20),

                // --- Judul ---
                const Text(
                  'Keluar dari Portal?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColorsSoft.navy,
                  ),
                ),
                const SizedBox(height: 10),

                // --- Deskripsi ---
                const Text(
                  'Anda akan keluar dari akun ini.\nPastikan semua pekerjaan sudah tersimpan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColorsSoft.textGray,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // --- Tombol Keluar (merah) ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE05252),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Ya, Keluar',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // --- Tombol Batal ---
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColorsSoft.navy,
                      side: BorderSide(
                        color: AppColorsSoft.navy.withOpacity(0.15),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
