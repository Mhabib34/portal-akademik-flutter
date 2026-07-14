import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../config/api_config.dart';
import '../services/api_client.dart';
import '../utils/app_toast.dart';

class AjukanKrsBottomSheet {
  static Future<void> show(BuildContext context, {VoidCallback? onSuccess}) async {
    List<Map<String, dynamic>> kelasTersedia = [];
    bool isLoadingKelas = true;
    bool isSubmitting = false;
    final Set<String> selectedIds = {};

    try {
      final res = await ApiClient.get(ApiConfig.getKelasTersedia);
      if (res['status'] == 'ok') {
        final List list = res['data'] as List? ?? [];
        kelasTersedia = list
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
    } catch (_) {
      // biarkan list kosong, ditangani di UI
    }
    isLoadingKelas = false;

    // Pastikan context masih valid sebelum memunculkan bottom sheet
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final totalSksDipilih = kelasTersedia
              .where((k) => selectedIds.contains(k['id'].toString()))
              .fold<int>(
                0,
                (sum, k) =>
                    sum + (int.tryParse(k['sks']?.toString() ?? '0') ?? 0),
              );

          Future<void> submit() async {
            if (selectedIds.isEmpty) {
              _showSnackBar(ctx, 'Pilih minimal 1 kelas', isError: true);
              return;
            }
            setSheetState(() => isSubmitting = true);
            try {
              final res = await ApiClient.postJson(
                ApiConfig.ajukanKrs,
                body: {'kelas_ids': selectedIds.toList()},
              );
              if (res['status'] == 'ok') {
                if (ctx.mounted) Navigator.pop(ctx);
                _showSnackBar(
                  context,
                  'KRS berhasil diajukan, menunggu persetujuan admin',
                );
                if (onSuccess != null) {
                  onSuccess();
                }
              } else {
                setSheetState(() => isSubmitting = false);
                _showSnackBar(
                  ctx,
                  res['message']?.toString() ?? 'Gagal mengajukan KRS',
                  isError: true,
                );
              }
            } catch (_) {
              setSheetState(() => isSubmitting = false);
              _showSnackBar(ctx, 'Gagal terhubung ke server', isError: true);
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.75,
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                color: AppColorsSoft.cardWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColorsSoft.fieldFill,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const Text(
                    'Ajukan KRS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColorsSoft.navy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total SKS dipilih: $totalSksDipilih',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColorsSoft.textGray,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: isLoadingKelas
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColorsSoft.navy,
                            ),
                          )
                        : kelasTersedia.isEmpty
                        ? const Center(
                            child: Text(
                              'Tidak ada kelas tersedia',
                              style: TextStyle(color: AppColorsSoft.textGray),
                            ),
                          )
                        : ListView.separated(
                            itemCount: kelasTersedia.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final k = kelasTersedia[i];
                              final id = k['id'].toString();
                              final checked = selectedIds.contains(id);
                              
                              final hari = k['hari'] ?? '-';
                              final jamMulai = k['jam_mulai'] ?? '-';
                              final jamSelesai = k['jam_selesai'] ?? '-';
                              final ruang = k['nama_ruang'] ?? '-';
                              final jadwalStr = '$hari, $jamMulai - $jamSelesai (R. $ruang)';

                              return InkWell(
                                onTap: () => setSheetState(
                                  () => checked
                                      ? selectedIds.remove(id)
                                      : selectedIds.add(id),
                                ),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: checked
                                        ? AppColorsSoft.navy.withOpacity(0.06)
                                        : AppColorsSoft.fieldFill,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Checkbox(
                                        value: checked,
                                        activeColor: AppColorsSoft.navy,
                                        onChanged: (_) => setSheetState(
                                          () => checked
                                              ? selectedIds.remove(id)
                                              : selectedIds.add(id),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${k['nama_mk'] ?? '-'} (${k['nama_kelas'] ?? '-'})',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: AppColorsSoft.navy,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              '${k['sks'] ?? 0} SKS • ${k['nama_dosen'] ?? '-'}',
                                              style: const TextStyle(
                                                fontSize: 11.5,
                                                color: AppColorsSoft.textGray,
                                              ),
                                            ),
                                            Text(
                                              jadwalStr,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColorsSoft.textGray,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColorsSoft.navy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Ajukan KRS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static void _showSnackBar(BuildContext context, String msg, {bool isError = false}) {
    AppToast.show(context, msg, isError: isError);
  }
}
