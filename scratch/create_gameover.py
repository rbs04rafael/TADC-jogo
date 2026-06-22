import os

scene_content = """[gd_scene load_steps=5 format=3 uid="uid://gameovertadc"]

[ext_resource type="Script" path="res://Codigos/game_over.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://Assets/UI/tadc_gameover_bg.png" id="2_bg"]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_btn1"]
bg_color = Color(0.8, 0.1, 0.1, 1)
border_width_left = 5
border_width_top = 5
border_width_right = 5
border_width_bottom = 5
border_color = Color(1, 0.9, 0, 1)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_btn2"]
bg_color = Color(0.1, 0.3, 0.9, 1)
border_width_left = 5
border_width_top = 5
border_width_right = 5
border_width_bottom = 5
border_color = Color(1, 0.9, 0, 1)
corner_radius_top_left = 10
corner_radius_top_right = 10
corner_radius_bottom_right = 10
corner_radius_bottom_left = 10

[node name="GameOver" type="CanvasLayer"]
process_mode = 3
script = ExtResource("1_script")

[node name="Background" type="TextureRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
texture = ExtResource("2_bg")
expand_mode = 1

[node name="ColorRect" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.4)

[node name="CenterContainer" type="CenterContainer" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="VBoxContainer" type="VBoxContainer" parent="CenterContainer"]
layout_mode = 2
theme_override_constants/separation = 40

[node name="Label" type="Label" parent="CenterContainer/VBoxContainer"]
layout_mode = 2
theme_override_colors/font_color = Color(1, 1, 0, 1)
theme_override_colors/font_shadow_color = Color(0.8, 0, 0, 1)
theme_override_constants/shadow_offset_x = 4
theme_override_constants/shadow_offset_y = 4
theme_override_font_sizes/font_size = 80
text = "GAME OVER"
horizontal_alignment = 1

[node name="BtnRestart" type="Button" parent="CenterContainer/VBoxContainer"]
custom_minimum_size = Vector2(300, 80)
layout_mode = 2
size_flags_horizontal = 4
theme_override_font_sizes/font_size = 40
theme_override_styles/normal = SubResource("StyleBoxFlat_btn1")
text = "RESTART"

[node name="BtnQuit" type="Button" parent="CenterContainer/VBoxContainer"]
custom_minimum_size = Vector2(300, 80)
layout_mode = 2
size_flags_horizontal = 4
theme_override_font_sizes/font_size = 40
theme_override_styles/normal = SubResource("StyleBoxFlat_btn2")
text = "QUIT"

[connection signal="pressed" from="CenterContainer/VBoxContainer/BtnRestart" to="." method="_on_restart_pressed"]
[connection signal="pressed" from="CenterContainer/VBoxContainer/BtnQuit" to="." method="_on_quit_pressed"]
"""

with open("c:/Godot/Godot_Projects/TADC-jogo/Cenarios/GameOver.tscn", "w", encoding="utf-8") as f:
    f.write(scene_content)
