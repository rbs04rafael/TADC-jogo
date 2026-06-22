import sys

scene_path = "c:/Godot/Godot_Projects/TADC-jogo/Cenarios/CenarioMundoCompleto/CenarioCircoDigital.tscn"

with open(scene_path, 'r', encoding='utf-8') as f:
    content = f.read()

if "res://Codigos/trap_espinho.gd" in content:
    print("Script already injected in scene!")
    sys.exit(0)

# 1. Add the ext_resource
# We'll put it right after the first ext_resource
ext_str = '[ext_resource type="Script" path="res://Codigos/trap_espinho.gd" id="99_trapespinho"]\n'
first_ext_idx = content.find("[ext_resource")
if first_ext_idx != -1:
    content = content[:first_ext_idx] + ext_str + content[first_ext_idx:]

# 2. Modify Trap nodes
# Find all lines with [node name="Trap..." instance=ExtResource("...")]
# We want to replace it by adding `script = ExtResource("99_trapespinho")` right below it.
lines = content.split('\n')
new_lines = []
for line in lines:
    new_lines.append(line)
    if '[node name="Trap' in line and 'instance=ExtResource(' in line:
        new_lines.append('script = ExtResource("99_trapespinho")')

with open(scene_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(new_lines))

print("Successfully injected trap_espinho.gd into CenarioCircoDigital.tscn")
