$path = 'C:\Users\lenovo\Desktop\Rafael\Outras coisas\Godot\TADC-jogo-JuncaoKaykeRyan\Cenarios\CenarioMundoCompleto\CenarioCircoDigital.tscn'
$content = [System.IO.File]::ReadAllText($path)

$find = @"
[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_jb8ss"]
roughness = 0.0
"@

$replace = @"
[sub_resource type="StandardMaterial3D" id="StandardMaterial3D_jb8ss"]
albedo_color = Color(0.6, 0.6, 0.6, 1)
roughness = 0.9
"@

$content = $content.Replace($find.Replace("`r`n", "`n"), $replace.Replace("`r`n", "`n"))
$content = $content.Replace($find, $replace)

[System.IO.File]::WriteAllText($path, $content)

# Remove BOM
$bytes = [System.IO.File]::ReadAllBytes($path)
if ($bytes.Length -gt 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
    [System.IO.File]::WriteAllBytes($path, $bytes[3..($bytes.Length - 1)])
}
