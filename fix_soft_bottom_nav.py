import re

path = 'lib/widgets/soft_bottom_nav.dart'
with open(path, 'r') as f:
    content = f.read()

# Tambahkan import dart:math
if "import 'dart:math' as math;" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'dart:math' as math;")

# Fix itemWidth
old_line = "final itemWidth = (constraints.maxWidth - centerWidth) / items.length;"
new_line = "final itemWidth = math.max(0.0, (constraints.maxWidth - centerWidth) / items.length);"

content = content.replace(old_line, new_line)

with open(path, 'w') as f:
    f.write(content)
