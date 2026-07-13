import re

path = 'lib/pages/mahasiswa_profil_page.dart'
with open(path, 'r') as f:
    content = f.read()

old_logout = """  Future<void> _logout() async {
    final konfirmasi = await showLogoutDialog(context);
    if (konfirmasi != true) return;

    await AuthService.logout();
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }"""

new_logout = """  Future<void> _logout() async {
    final konfirmasi = await showLogoutDialog(context);
    if (konfirmasi != true) return;

    await AuthService.logout();
    // Tunggu animasi dialog selesai sebelum destroy rute
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }"""

content = content.replace(old_logout, new_logout)

with open(path, 'w') as f:
    f.write(content)
