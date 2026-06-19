$path = 'C:\Users\lenovo\Desktop\Rafael\Outras coisas\Godot\TADC-jogo-JuncaoKaykeRyan\Cenarios\CenarioMundoCompleto\CenarioCircoDigital.tscn'
$content = [System.IO.File]::ReadAllText($path)

$find = @"
[node name="Area3D" type="Area3D" parent="The Grounds/AguaLago" unique_id=1355663059]
script = ExtResource("ExtResource_agua_toxica")

[node name="CollisionShape3D" type="CollisionShape3D" parent="The Grounds/AguaLago/Area3D" unique_id=1285171630]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2.7005386, -1.6286471, -1.9431496)
shape = SubResource("BoxShape3D_6txre")
debug_color = Color(0.9809559, 0, 0.3792702, 0.41960785)
"@

$replace = @"
[node name="StaticBody3D" type="StaticBody3D" parent="The Grounds/AguaLago" unique_id=9999991]

[node name="CollisionShape3D" type="CollisionShape3D" parent="The Grounds/AguaLago/StaticBody3D" unique_id=9999992]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2.7005386, -1.6286471, -1.9431496)
shape = SubResource("BoxShape3D_6txre")

[node name="Area3D" type="Area3D" parent="The Grounds/AguaLago" unique_id=1355663059]
script = ExtResource("ExtResource_agua_toxica")

[node name="CollisionShape3D" type="CollisionShape3D" parent="The Grounds/AguaLago/Area3D" unique_id=1285171630]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, -2.7005386, -1.5, -1.9431496)
shape = SubResource("BoxShape3D_6txre")
debug_color = Color(0.9809559, 0, 0.3792702, 0.41960785)
"@

$content = $content.Replace($find.Replace("`r`n", "`n"), $replace.Replace("`r`n", "`n"))
$content = $content.Replace($find, $replace)

[System.IO.File]::WriteAllText($path, $content)

# Remove BOM
$bytes = [System.IO.File]::ReadAllBytes($path)
if ($bytes.Length -gt 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
    [System.IO.File]::WriteAllBytes($path, $bytes[3..($bytes.Length - 1)])
}
