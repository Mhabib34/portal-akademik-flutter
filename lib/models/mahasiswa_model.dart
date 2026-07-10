// ============================================================
// mahasiswa_model.dart — Model data mahasiswa
// ============================================================

class Mahasiswa {
  final String id;
  final String nim;
  final String nama;
  final String jurusan;
  final String alamat;
  final String? userId;
  final bool isActive; // dari kolom is_active di tabel users
  final bool mustChangePw; // dari kolom must_change_password di tabel users

  const Mahasiswa({
    required this.id,
    required this.nim,
    required this.nama,
    required this.jurusan,
    required this.alamat,
    this.userId,
    required this.isActive,
    required this.mustChangePw,
  });

  factory Mahasiswa.fromJson(Map<String, dynamic> json) {
    return Mahasiswa(
      id: (json['id'] ?? '').toString(),
      nim: (json['nim'] ?? '').toString(),
      nama: (json['nama'] ?? '').toString(),
      jurusan: (json['jurusan'] ?? '').toString(),
      alamat: (json['alamat'] ?? '').toString(),
      userId: json['user_id']?.toString(),
      isActive: _parseBool(json['is_active']),
      mustChangePw: _parseBool(json['must_change_password']),
    );
  }

  // Helper: terima int (0/1) atau bool
  static bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    return value.toString() == '1' || value.toString().toLowerCase() == 'true';
  }

  Mahasiswa copyWith({
    String? id,
    String? nim,
    String? nama,
    String? jurusan,
    String? alamat,
    String? userId,
    bool? isActive,
    bool? mustChangePw,
  }) {
    return Mahasiswa(
      id: id ?? this.id,
      nim: nim ?? this.nim,
      nama: nama ?? this.nama,
      jurusan: jurusan ?? this.jurusan,
      alamat: alamat ?? this.alamat,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      mustChangePw: mustChangePw ?? this.mustChangePw,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nim': nim,
    'nama': nama,
    'jurusan': jurusan,
    'alamat': alamat,
    'user_id': userId,
    'is_active': isActive ? 1 : 0,
    'must_change_password': mustChangePw ? 1 : 0,
  };

  @override
  String toString() =>
      'Mahasiswa(id: $id, nim: $nim, nama: $nama, jurusan: $jurusan)';
}
