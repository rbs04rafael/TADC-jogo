$path = 'C:\Users\lenovo\Desktop\Rafael\Outras coisas\Godot\TADC-jogo-JuncaoKaykeRyan\Cenarios\CenarioMundoCompleto\CenarioCircoDigital.tscn'
$content = [System.IO.File]::ReadAllText($path)
$content = $content.Replace(
    '[ext_resource type="PackedScene" uid="uid://be7b5jwa47868" path="res://Personagens/Morcego/morcego.tscn" id="ExtResource_morcego"]',
    '[ext_resource type="PackedScene" uid="uid://be7b5jwa47868" path="res://Personagens/Morcego/morcego.tscn" id="ExtResource_morcego"]' + "`n" + '[ext_resource type="Script" path="res://Codigos/agua_toxica.gd" id="ExtResource_agua_toxica"]'
)
$content = $content.Replace(
    '[node name="StaticBody3D" type="StaticBody3D" parent="The Grounds/AguaLago" unique_id=1355663059]',
    '[node name="Area3D" type="Area3D" parent="The Grounds/AguaLago" unique_id=1355663059]' + "`n" + 'script = ExtResource("ExtResource_agua_toxica")'
)
$content = $content.Replace(
    '[node name="CollisionShape3D" type="CollisionShape3D" parent="The Grounds/AguaLago/StaticBody3D" unique_id=1285171630]',
    '[node name="CollisionShape3D" type="CollisionShape3D" parent="The Grounds/AguaLago/Area3D" unique_id=1285171630]'
)
[System.IO.File]::WriteAllText($path, $content)
