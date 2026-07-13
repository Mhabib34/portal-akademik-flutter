<?php
// ============================================================
// auth_helper.php — Validasi token & role
//   Di-include di setiap endpoint yang butuh autentikasi (🔒)
// ============================================================

// --- Ambil token dari header Authorization: Bearer <token> ---
function getBearerToken() {
    $authHeader = null;

    if (function_exists('getallheaders')) {
        foreach (getallheaders() as $key => $value) {
            if (strtolower($key) === 'authorization') {
                $authHeader = $value;
                break;
            }
        }
    }

    // Fallback untuk beberapa konfigurasi Apache/PHP-FPM
    if (!$authHeader && isset($_SERVER['HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['HTTP_AUTHORIZATION'];
    }
    if (!$authHeader && isset($_SERVER['REDIRECT_HTTP_AUTHORIZATION'])) {
        $authHeader = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'];
    }

    if (!$authHeader) return null;

    if (preg_match('/Bearer\s+(\S+)/i', $authHeader, $matches)) {
        return $matches[1];
    }
    return null;
}

// --- Generate token acak ---
function generateToken() {
    return bin2hex(random_bytes(32)); // 64 karakter hex
}

// --- Wajib login: validasi token, return data user atau exit dengan 401 ---
function requireAuth($conn) {
    $token = getBearerToken();

    if (!$token) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Token tidak ditemukan. Silakan login.']);
        exit();
    }

    $stmt = $conn->prepare(
        "SELECT u.id, u.nama, u.username, u.role, u.is_active, t.expires_at
         FROM auth_tokens t
         JOIN users u ON u.id = t.user_id
         WHERE t.token = ?
         LIMIT 1"
    );
    $stmt->bind_param('s', $token);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows === 0) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Token tidak valid. Silakan login ulang.']);
        $stmt->close();
        exit();
    }

    $user = $result->fetch_assoc();
    $stmt->close();

    if (strtotime($user['expires_at']) < time()) {
        http_response_code(401);
        echo json_encode(['status' => 'error', 'message' => 'Sesi Anda sudah berakhir. Silakan login ulang.']);
        exit();
    }

    if ((int)$user['is_active'] === 0) {
        http_response_code(403);
        echo json_encode(['status' => 'error', 'message' => 'Akun Anda dinonaktifkan. Hubungi administrator.']);
        exit();
    }

    // token yang dipakai request ini, berguna kalau endpoint perlu tahu (mis. logout)
    $user['token'] = $token;

    return $user; // ['id','nama','username','role','is_active','expires_at','token']
}

// --- Wajib role tertentu, dipanggil setelah requireAuth() ---
function requireRole($user, array $allowedRoles) {
    if (!in_array($user['role'], $allowedRoles, true)) {
        http_response_code(403);
        echo json_encode(['status' => 'error', 'message' => 'Anda tidak memiliki akses untuk aksi ini']);
        exit();
    }
}

// --- Ambil mahasiswa.id dari user_id yang sedang login ---
function getMahasiswaIdFromUserId($conn, $userId) {
    $stmt = $conn->prepare("SELECT id FROM mahasiswa WHERE user_id = ? LIMIT 1");
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $id = null;
    if ($row = $result->fetch_assoc()) {
        $id = $row['id'];
    }
    $stmt->close();
    return $id;
}

// --- Ambil dosen.id dari user_id yang sedang login ---
function getDosenIdFromUserId($conn, $userId) {
    $stmt = $conn->prepare("SELECT id FROM dosen WHERE user_id = ? LIMIT 1");
    $stmt->bind_param('i', $userId);
    $stmt->execute();
    $result = $stmt->get_result();
    $id = null;
    if ($row = $result->fetch_assoc()) {
        $id = $row['id'];
    }
    $stmt->close();
    return $id;
}
