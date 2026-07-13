import re

path = 'lib/pages/mahasiswa_home_page.dart'
with open(path, 'r') as f:
    content = f.read()

old_tree = """          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColorsSoft.navy),
                )
              : RefreshIndicator(
                  color: AppColorsSoft.navy,
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    children: [
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

new_tree = """          child: RefreshIndicator(
            color: AppColorsSoft.navy,
            onRefresh: _loadData,
            child: _isLoading
                ? ListView(
                    padding: const EdgeInsets.only(top: 150),
                    children: const [
                      Center(child: CircularProgressIndicator(color: AppColorsSoft.navy)),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                    children: [
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

content = content.replace(old_tree, new_tree)

with open(path, 'w') as f:
    f.write(content)
