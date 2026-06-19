$path = 'C:\Users\lenovo\Desktop\Rafael\Outras coisas\Godot\TADC-jogo-JuncaoKaykeRyan\Cenarios\CenarioMundoCompleto\CenarioCircoDigital.tscn'
$content = [System.IO.File]::ReadAllText($path)
$find = '[ext_resource type="Script" path="res://Codigos/agua_toxica.gd" id="ExtResource_agua_toxica"]'
$replace = '[ext_resource type="Script" uid="uid://ddpc216yks1l4" path="res://Codigos/agua_toxica.gd" id="ExtResource_agua_toxica"]'
$content = $content.Replace($find, $replace)

[System.IO.File]::WriteAllText($path, $content)
