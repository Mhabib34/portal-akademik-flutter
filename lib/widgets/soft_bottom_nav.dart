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

/// Gaya tab aktif:
/// - [dot]: icon (+ label opsional) berwarna navy, dot kecil di bawahnya
/// - [solidCircle]: tab aktif jadi lingkaran solid navy tanpa label,
///   tab non-aktif tetap tampil icon + label
enum SoftNavActiveStyle { dot, solidCircle }

class SoftBottomNav extends StatelessWidget {
  final List<SoftNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showLabels;
  final SoftNavActiveStyle activeStyle;
  final IconData? centerActionIcon;
  final VoidCallback? centerActionOnTap;

  const SoftBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = false,
    this.activeStyle = SoftNavActiveStyle.dot,
    this.centerActionIcon,
    this.centerActionOnTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasCenter = centerActionIcon != null;
    final half = (items.length / 2).ceil();
    final leftItems = hasCenter ? items.sublist(0, half) : items;
    final rightItems = hasCenter ? items.sublist(half) : const <SoftNavItem>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SizedBox(
        height: hasCenter ? 76 : 64,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
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
                children: [
                  ...List.generate(
                    leftItems.length,
                    (i) => Expanded(child: _buildItem(i, leftItems[i])),
                  ),
                  if (hasCenter) const SizedBox(width: 56),
                  ...List.generate(
                    rightItems.length,
                    (i) => Expanded(child: _buildItem(half + i, rightItems[i])),
                  ),
                ],
              ),
            ),
            if (hasCenter)
              Positioned(
                top: 0,
                child: GestureDetector(
                  onTap: centerActionOnTap,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColorsSoft.navy,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColorsSoft.navy.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      centerActionIcon,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(int index, SoftNavItem item) {
    final selected = index == currentIndex;

    if (selected && activeStyle == SoftNavActiveStyle.solidCircle) {
      return InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(32),
        child: Center(
          child: Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColorsSoft.navy,
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, size: 20, color: Colors.white),
          ),
        ),
      );
    }

    final color = selected ? AppColorsSoft.navy : AppColorsSoft.textGrayLight;

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 22, color: color),
          if (showLabels) ...[
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
          if (selected &&
              showLabels &&
              activeStyle == SoftNavActiveStyle.dot) ...[
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColorsSoft.navy,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
