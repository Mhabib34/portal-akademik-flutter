import re

path = 'lib/pages/mahasiswa_profil_page.dart'
with open(path, 'r') as f:
    content = f.read()

old_tree = """          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColorsSoft.navy),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 24),
                    _buildAvatar(),
                    const SizedBox(height: 16),
                    _buildIdentity(),
                    const SizedBox(height: 28),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildActionCard(),
                  ],
                ),"""

new_tree = """          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: _isLoading
                ? [
                    _buildTopBar(),
                    const SizedBox(height: 150),
                    const Center(child: CircularProgressIndicator(color: AppColorsSoft.navy)),
                  ]
                : [
                    _buildTopBar(),
                    const SizedBox(height: 24),
                    _buildAvatar(),
                    const SizedBox(height: 16),
                    _buildIdentity(),
                    const SizedBox(height: 28),
                    _buildInfoCard(),
                    const SizedBox(height: 16),
                    _buildActionCard(),
                  ],
          ),"""

content = content.replace(old_tree, new_tree)

with open(path, 'w') as f:
    f.write(content)
