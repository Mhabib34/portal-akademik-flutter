import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../config/api_config.dart';
import '../../services/api_client.dart';
import '../../widgets/admin_nav_helper.dart';

class AdminKrsPage extends StatefulWidget {
  const AdminKrsPage({super.key});

  @override
  State<AdminKrsPage> createState() => _AdminKrsPageState();
}

class _AdminKrsPageState extends State<AdminKrsPage> {
  String _activeTab = 'menunggu';
  bool _isLoading = true;
  List<dynamic> _krsList = [];

  @override
  void initState() {
    super.initState();
    _fetchKrs();
  }

  Future<void> _fetchKrs() async {
    setState(() {
      _isLoading = true;
      _krsList = [];
    });

    try {
      final response = await ApiClient.get(
        ApiConfig.getKrs,
        queryParams: {'status': _activeTab},
      );

      if (response['status'] == 'ok') {
        final data = response['data'];
        setState(() {
          if (data is List) {
            _krsList = data;
          } else if (data is Map) {
            _krsList = [data]; // If single object returned
          }
        });
      } else {
        _showError(response['message'] ?? 'Gagal memuat data KRS');
      }
    } catch (e) {
      _showError('Terjadi kesalahan koneksi');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateKrsStatus(
      String krsId, String status, String catatan) async {
    // Tampilkan loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await ApiClient.postForm(
        ApiConfig.approveKrs,
        body: {
          'krs_id': krsId,
          'status': status,
          'catatan_admin': catatan,
        },
      );

      Navigator.pop(context); // Tutup loading

      if (response['status'] == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'disetujui'
                ? 'KRS berhasil disetujui'
                : 'KRS ditolak'),
            backgroundColor: AppColorsSoft.navy,
          ),
        );
        _fetchKrs(); // Refresh list
      } else {
        _showError(response['message'] ?? 'Gagal memproses KRS');
      }
    } catch (e) {
      Navigator.pop(context); // Tutup loading
      _showError('Terjadi kesalahan koneksi');
    }
  }

  void _showTolakDialog(String krsId, String nama) {
    final catatanController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Tolak KRS $nama?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan alasan penolakan (wajib):'),
              const SizedBox(height: 12),
              TextField(
                controller: catatanController,
                decoration: const InputDecoration(
                  labelText: 'Alasan',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE05252),
              ),
              onPressed: () {
                final catatan = catatanController.text.trim();
                if (catatan.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Alasan tidak boleh kosong')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _updateKrsStatus(krsId, 'ditolak', catatan);
              },
              child: const Text('Tolak'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE05252)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: AppColorsSoft.backgroundGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 16),
              _buildTabs(),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '${_krsList.length} PERMINTAAN ${_activeTab.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColorsSoft.textGray,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _fetchKrs,
                        child: _krsList.isEmpty
                            ? _buildEmptyState()
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                                itemCount: _krsList.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  return _KrsCard(
                                    krs: _krsList[index],
                                    onApprove: () {
                                      _updateKrsStatus(
                                          _krsList[index]['id'], 'disetujui', '');
                                    },
                                    onReject: () {
                                      _showTolakDialog(
                                        _krsList[index]['id'],
                                        _krsList[index]['nama_mahasiswa'],
                                      );
                                    },
                                    activeTab: _activeTab,
                                  );
                                },
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AdminNavHelper.buildNav(
        context: context,
        currentIndex: -1, // Tidak ada tab yang aktif di halaman KRS
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(40),
      children: [
        const Icon(Icons.fact_check_outlined,
            size: 64, color: AppColorsSoft.textGray),
        const SizedBox(height: 16),
        Text(
          'Belum ada data KRS dengan status $_activeTab.',
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColorsSoft.textGray, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColorsSoft.navy, size: 20),
          ),
          const Expanded(
            child: Text(
              'Persetujuan KRS',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColorsSoft.navy,
              ),
            ),
          ),
          IconButton(
            onPressed: () {}, // placeholder notifikasi
            icon: const Icon(Icons.notifications_none_rounded,
                color: AppColorsSoft.navy),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = ['menunggu', 'disetujui', 'ditolak'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: tabs.map((tab) {
          final isSelected = _activeTab == tab;
          final label = tab == 'menunggu'
              ? 'Menunggu'
              : tab == 'disetujui'
                  ? 'Disetujui'
                  : 'Ditolak';

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_activeTab != tab) {
                  setState(() => _activeTab = tab);
                  _fetchKrs();
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColorsSoft.navy : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColorsSoft.navy.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColorsSoft.textGray,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KrsCard extends StatefulWidget {
  final Map<String, dynamic> krs;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final String activeTab;

  const _KrsCard({
    required this.krs,
    required this.onApprove,
    required this.onReject,
    required this.activeTab,
  });

  @override
  State<_KrsCard> createState() => _KrsCardState();
}

class _KrsCardState extends State<_KrsCard> {
  bool _isExpanded = false;

  String _getInitials(String name) {
    if (name.isEmpty) return 'A';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final nama = widget.krs['nama_mahasiswa'] ?? 'Tanpa Nama';
    final nim = widget.krs['nim'] ?? '-';
    final mataKuliahList = widget.krs['mata_kuliah'] as List<dynamic>? ?? [];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE8D6),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Text(
                  _getInitials(nama),
                  style: const TextStyle(
                    color: Color(0xFFB5651D),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Nama & NIM
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColorsSoft.navy,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nim,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColorsSoft.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              // Expand icon
              IconButton(
                onPressed: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
                icon: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColorsSoft.navy,
                ),
              )
            ],
          ),
          
          if (_isExpanded) ...[
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF0F0F0)),
            const SizedBox(height: 8),
            const Text(
              'Daftar Mata Kuliah',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColorsSoft.navy,
              ),
            ),
            const SizedBox(height: 8),
            ...mataKuliahList.map((mk) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColorsSoft.navy),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mk['nama_mk'] ?? '-',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColorsSoft.navy),
                          ),
                          Text(
                            'Kelas: ${mk['nama_kelas']} • SKS: ${mk['sks']}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColorsSoft.textGray),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Total: ${widget.krs['total_sks'] ?? 0} SKS',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColorsSoft.navy,
                  ),
                ),
              ],
            ),
            
            // Tampilkan catatan jika ditolak
            if (widget.activeTab == 'ditolak' && widget.krs['catatan_admin'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE0E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Color(0xFFE05252)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alasan Penolakan: ${widget.krs['catatan_admin']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE05252),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          if (widget.activeTab == 'menunggu') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFC8B8B),
                      side: const BorderSide(color: Color(0xFFFC8B8B)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Tolak',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: widget.onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34D399),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Setujui',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
