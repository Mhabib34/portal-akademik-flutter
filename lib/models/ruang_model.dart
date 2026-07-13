class Ruang {
  final String id;
  final String namaRuang;
  final String gedung;
  final int kapasitas;

  Ruang({
    required this.id,
    required this.namaRuang,
    required this.gedung,
    required this.kapasitas,
  });

  factory Ruang.fromJson(Map<String, dynamic> json) {
    return Ruang(
      id: json['id']?.toString() ?? '',
      namaRuang: json['nama_ruang']?.toString() ?? '',
      gedung: json['gedung']?.toString() ?? '',
      kapasitas: int.tryParse(json['kapasitas']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_ruang': namaRuang,
      'gedung': gedung,
      'kapasitas': kapasitas,
    };
  }
}
