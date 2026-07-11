import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ============================================================
// soft_bottom_nav.dart — Navbar bawah reusable
//   Dipakai di semua role (admin/dosen/mahasiswa) biar konsisten.
//   Selalu center (margin kiri-kanan sama) — lihat Padding di bawah.
// ============================================================

class SoftNavItem {
  final IconData icon;
  final String label;
  const SoftNavItem({required this.icon, required this.label});
}

class SoftBottomNav extends StatelessWidget {
  final List<SoftNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SoftBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColorsSoft.cardWhite,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColorsSoft.navy.withOpacity(0.10),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (i) {
            final selected = i == currentIndex;
            final item = items[i];
            return Expanded(
              child: InkWell(
                onTap: () => onTap(i),
                borderRadius: BorderRadius.circular(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColorsSoft.navy.withOpacity(0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        item.icon,
                        size: 22,
                        color: selected
                            ? AppColorsSoft.navy
                            : AppColorsSoft.textGrayLight,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
