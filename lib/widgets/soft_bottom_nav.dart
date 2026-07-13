import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// ============================================================
// soft_bottom_nav.dart — Navbar bawah reusable
//   Dipakai di semua role (admin/dosen/mahasiswa) biar konsisten.
//   Desain:
//   - Tidak aktif: icon + label teks di bawahnya
//   - Aktif: icon di dalam lingkaran hitam bulat (tanpa label)
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
  final IconData? centerActionIcon;
  final VoidCallback? centerActionOnTap;

  const SoftBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: SizedBox(
        height: hasCenter ? 76 : 70,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 70,
              decoration: BoxDecoration(
                color: AppColorsSoft.cardWhite,
                borderRadius: BorderRadius.circular(35),
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

    return InkWell(
      onTap: () => onTap(index),
      borderRadius: BorderRadius.circular(35),
      child: SizedBox(
        height: 70,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            ),
            child: selected ? _buildActiveItem(item) : _buildInactiveItem(item),
          ),
        ),
      ),
    );
  }

  /// Aktif: icon di dalam lingkaran hitam, tanpa label
  Widget _buildActiveItem(SoftNavItem item) {
    return Container(
      key: const ValueKey('active'),
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        color: AppColorsSoft.navy,
        shape: BoxShape.circle,
      ),
      child: Icon(item.icon, size: 22, color: Colors.white),
    );
  }

  /// Tidak aktif: icon + label teks di bawahnya
  Widget _buildInactiveItem(SoftNavItem item) {
    return Column(
      key: const ValueKey('inactive'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(item.icon, size: 22, color: AppColorsSoft.textGrayLight),
        const SizedBox(height: 4),
        Text(
          item.label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColorsSoft.textGrayLight,
            letterSpacing: 0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
