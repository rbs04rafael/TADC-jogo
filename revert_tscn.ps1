$path = 'C:\Users\lenovo\Desktop\Rafael\Outras coisas\Godot\TADC-jogo-JuncaoKaykeRyan\Cenarios\CenarioMundoCompleto\CenarioCircoDigital.tscn'
$content = [System.IO.File]::ReadAllText($path)

$find = '[node name="Area3D" type="Area3D" parent="The Grounds/AguaLago" unique_id=1355663059]' + "`n" + 'script = ExtResource("ExtResource_agua_toxica")'
$replace = '[node name="StaticBody3D" type="StaticBody3D" parent="The Grounds/AguaLago" unique_id=1355663059]'
$content = $content.Replace($find, $replace)

$find2 = '[node name="Area3D" type="Area3D" parent="The Grounds/AguaLago" unique_id=1355663059]' + "`r`n" + 'script = ExtResource("ExtResource_agua_toxica")'
$content = $content.Replace($find2, $replace)

$find3 = '[node name="CollisionShape3D" type="CollisionShape3D" parent="The Grounds/AguaLago/Area3D" unique_id=1285171630]'
$replace3 = '[node name="CollisionShape3D" type="CollisionShape3D" parent="The Grounds/AguaLago/StaticBody3D" unique_id=1285171630]'
$content = $content.Replace($find3, $replace3)

[System.IO.File]::WriteAllText($path, $content)
