import re

with open(r'C:\Godot\Godot_Projects\TADC-jogo\Personagens\Abstracao\Abstracao.tscn', 'r', encoding='utf-8') as f:
    content = f.read()

ext_ids = re.findall(r'\[ext_resource .*? id="(\d+)_.*?"\]', content)
if not ext_ids:
    next_id = '1_abstr'
else:
    max_id = max([int(x) for x in ext_ids])
    next_id = str(max_id + 1) + '_abstr'

new_ext = f'[ext_resource type="Script" path="res://Personagens/Abstracao/Abstracao.gd" id="{next_id}"]\n'

matches = list(re.finditer(r'\[ext_resource .*?\]\n', content))
if matches:
    pos = matches[-1].end()
    content = content[:pos] + new_ext + content[pos:]

content = re.sub(r'(\[node name="NoAbstracao".*?\]\n)', r'\1script = ExtResource("' + next_id + '")\n', content)

with open(r'C:\Godot\Godot_Projects\TADC-jogo\Personagens\Abstracao\Abstracao.tscn', 'w', encoding='utf-8') as f:
    f.write(content)

print("Attached script to Abstracao.tscn")
