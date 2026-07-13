import re

path = 'lib/pages/mahasiswa_home_page.dart'
with open(path, 'r') as f:
    content = f.read()

old_tree = """          child: RefreshIndicator(
            color: AppColorsSoft.navy,
            onRefresh: _loadData,
            child: ListView(
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
                      const SizedBox(height: 20),
                      _buildBanner(),
                      const SizedBox(height: 20),
                      _buildStatRow(),
                      const SizedBox(height: 24),
                      _buildMenuGrid(),
                      const SizedBox(height: 24),
                      _buildJadwalCard(),
                    ],
            ),
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
                    const SizedBox(height: 20),
                    _buildBanner(),
                    const SizedBox(height: 20),
                    _buildStatRow(),
                    const SizedBox(height: 24),
                    _buildMenuGrid(),
                    const SizedBox(height: 24),
                    _buildJadwalCard(),
                  ],
          ),"""

content = content.replace(old_tree, new_tree)

with open(path, 'w') as f:
    f.write(content)
