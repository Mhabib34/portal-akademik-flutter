// ============================================================
// prodi_model.dart — Model data program studi
//   namaFakultas diisi manual dari lookup lokal (bukan cuma
//   ngandelin backend join) supaya tetap aman kalau field itu
//   gak ada di response get_prodi.php
// ============================================================

class Prodi {
  final String id;
  final String fakultasId;
  final String namaProdi;
  final String namaFakultas;

  const Prodi({
    required this.id,
    required this.fakultasId,
    required this.namaProdi,
    this.namaFakultas = '',
  });

  factory Prodi.fromJson(Map<String, dynamic> json, {String namaFakultas = ''}) {
    return Prodi(
      id: (json['id'] ?? '').toString(),
      fakultasId: (json['fakultas_id'] ?? '').toString(),
      namaProdi: (json['nama_prodi'] ?? '').toString(),
      namaFakultas: namaFakultas.isNotEmpty
          ? namaFakultas
          : (json['nama_fakultas'] ?? '').toString(),
    );
  }
}