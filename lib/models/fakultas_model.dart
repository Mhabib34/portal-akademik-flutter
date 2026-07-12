// ============================================================
// fakultas_model.dart — Model data fakultas
// ============================================================

class Fakultas {
  final String id;
  final String namaFakultas;

  const Fakultas({
    required this.id,
    required this.namaFakultas,
  });

  factory Fakultas.fromJson(Map<String, dynamic> json) {
    return Fakultas(
      id: (json['id'] ?? '').toString(),
      namaFakultas: (json['nama_fakultas'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama_fakultas': namaFakultas,
      };
}