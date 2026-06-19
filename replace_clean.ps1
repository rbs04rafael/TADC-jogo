$path = 'C:\Users\lenovo\Desktop\Rafael\Outras coisas\Godot\TADC-jogo-JuncaoKaykeRyan\Cenarios\CenarioMundoCompleto\CenarioCircoDigital.tscn'
$content = [System.IO.File]::ReadAllText($path)
$find = '[ext_resource type="PackedScene" uid="uid://be7b5jwa47868" path="res://Personagens/Morcego/morcego.tscn" id="ExtResource_morcego"]'
$replace = '[ext_resource type="PackedScene" uid="uid://be7b5jwa47868" path="res://Personagens/Morcego/morcego.tscn" id="ExtResource_morcego"]' + "`n" + '[ext_resource type="Script" uid="uid://ddpc216yks1l4" path="res://Codigos/agua_toxica.gd" id="ExtResource_agua_toxica"]'
$content = $content.Replace($find, $replace)

$find2 = '[node name="StaticBody3D" type="StaticBody3D" parent="The Grounds/AguaLago" unique_id=1355663059]'
$replace2 = '[node name="Area3D" type="Area3D" parent="The Grounds/AguaLago" unique_id=1355663059]' + "`n" + 'script = ExtResource("ExtResource_agua_toxica")'
$content = $content.Replace($find2, $replace2)

$find3 = '[node name="CollisionShape3D" type="CollisionShape3D" parent="The Grounds/AguaLago/StaticBody3D" unique_id=1285171630]'
$replace3 = '[node name="CollisionShape3D" type="CollisionShape3D" parent="The Grounds/AguaLago/Area3D" unique_id=1285171630]'
$content = $content.Replace($find3, $replace3)

[System.IO.File]::WriteAllText($path, $content)

# Remove BOM
$bytes = [System.IO.File]::ReadAllBytes($path)
if ($bytes.Length -gt 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
    [System.IO.File]::WriteAllBytes($path, $bytes[3..($bytes.Length - 1)])
}
