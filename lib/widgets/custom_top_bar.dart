import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ============================================================
// custom_top_bar.dart — Widget Header Seragam
//   Digunakan di semua halaman kecuali halaman Home dan Profil.
// ============================================================

class CustomTopBar extends StatelessWidget {
  final String title;
  final String nama;
  final VoidCallback? onBack;
  final Widget? trailing;

  const CustomTopBar({
    super.key,
    required this.title,
    required this.nama,
    this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColorsSoft.navy),
            onPressed: onBack ?? () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColorsSoft.navy,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (trailing != null) ...[
            trailing!,
            const SizedBox(width: 8),
          ],
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColorsSoft.navy,
            child: Text(
              nama.isNotEmpty ? nama[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
