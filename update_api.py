import re

path = 'api.specs.yaml'
with open(path, 'r') as f:
    content = f.read()

# Add to Nilai schema
nilai_schema_addition = """        tugas:
          type: number
          format: float
        quiz_1:
          type: number
          format: float
        quiz_2:
          type: number
          format: float
        uts:"""
content = content.replace("        tugas:\n          type: number\n          format: float\n        uts:", nilai_schema_addition)

kehadiran_schema_addition = """        kehadiran:
          type: number
          format: float
        uas:"""
content = content.replace("        uts:\n          type: number\n          format: float\n        uas:", "        uts:\n          type: number\n          format: float\n" + kehadiran_schema_addition)

with open(path, 'w') as f:
    f.write(content)
