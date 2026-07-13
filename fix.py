import re

path = 'lib/pages/admin_overview_nilai_page.dart'
with open(path, 'r') as f:
    content = f.read()

# Fix import
content = content.replace("import '../services/api_config.dart';", "import '../config/api_config.dart';")

# Fix AppColorsSoft.primary
content = content.replace("AppColorsSoft.primary", "AppColorsSoft.navy")

# Fix AppColorsSoft.white
content = content.replace("AppColorsSoft.white", "Colors.white")

# Fix ApiClient.postJson signature
content = content.replace("ApiClient.postJson(ApiConfig.simpanNilai, payload)", "ApiClient.postJson(ApiConfig.simpanNilai, body: payload)")

with open(path, 'w') as f:
    f.write(content)
