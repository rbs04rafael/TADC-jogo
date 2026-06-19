$path = 'C:\Users\lenovo\Desktop\Rafael\Outras coisas\Godot\TADC-jogo-JuncaoKaykeRyan\Cenarios\CenarioMundoCompleto\CenarioCircoDigital.tscn'
$content = [System.IO.File]::ReadAllText($path)
$find = '[ext_resource type="Script" path="res://Codigos/agua_toxica.gd" id="ExtResource_agua_toxica"]' + "`n" + '[ext_resource type="Script" path="res://Codigos/agua_toxica.gd" id="ExtResource_agua_toxica"]'
$replace = '[ext_resource type="Script" path="res://Codigos/agua_toxica.gd" id="ExtResource_agua_toxica"]'
$content = $content.Replace($find, $replace)

# Also let's handle if it was `\r\n` instead of `\n`
$find2 = '[ext_resource type="Script" path="res://Codigos/agua_toxica.gd" id="ExtResource_agua_toxica"]' + "`r`n" + '[ext_resource type="Script" path="res://Codigos/agua_toxica.gd" id="ExtResource_agua_toxica"]'
$content = $content.Replace($find2, $replace)

[System.IO.File]::WriteAllText($path, $content)
