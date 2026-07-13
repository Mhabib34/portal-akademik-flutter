import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/admin_nav_helper.dart';
import 'data_fakultas_page.dart';
import 'data_prodi_page.dart';

// ============================================================
// fakultas_prodi_hub_page.dart — Hub Manajemen Data (Fakultas & Prodi)
// ============================================================

class FakultasProdiHubPage extends StatefulWidget {
  final String nama;

  const FakultasProdiHubPage({super.key, this.nama = ''});

  @override
  State<FakultasProdiHubPage> createState() => _FakultasProdiHubPageState();
}

class _FakultasProdiHubPageState extends State<FakultasProdiHubPage> {
  // index 2 ("Data") aktif karena kita lagi di halaman manajemen data
  final int _navIndex = 2;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
            children: [
              _buildTopBar(),
              const SizedBox(height: 20),
              const Text(
                'Manajemen Data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColorsSoft.navy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pusat konfigurasi struktur akademik universitas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColorsSoft.textGray,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              _HubCard(
                icon: Icons.account_balance_rounded,
                iconBg: const Color(0xFFFCE8D6),
                iconColor: const Color(0xFFB5651D),
                title: 'Data Fakultas',
                subtitle: 'Kelola daftar fakultas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DataFakultasPage()),
                ),
              ),
              const SizedBox(height: 14),
              _HubCard(
                icon: Icons.school_rounded,
                iconBg: const Color(0xFFEEE3FF),
                iconColor: const Color(0xFF8B5CF6),
                title: 'Data Prodi',
                subtitle: 'Kelola program studi per fakultas',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DataProdiPage()),
                ),
              ),
              const SizedBox(height: 28),
              _buildIllustration(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminNavHelper.buildNav(
        context: context,
        currentIndex: _navIndex,
        nama: widget.nama,
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColorsSoft.navy),
        ),
        const Text(
          'Fakultas & Prodi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColorsSoft.navy,
          ),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 18,
          backgroundColor: AppColorsSoft.navy,
          child: Text(
            widget.nama.isNotEmpty ? widget.nama[0].toUpperCase() : 'A',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIllustration() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppColorsSoft.card(),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/fakultas_ilustrasi.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFFEDE7F6),
              alignment: Alignment.center,
              child: const Icon(
                Icons.account_balance_rounded,
                size: 40,
                color: Color(0xFF8B5CF6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppColorsSoft.card(),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: AppColorsSoft.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColorsSoft.textGray,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F3),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColorsSoft.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
