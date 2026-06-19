$path = 'C:\Users\lenovo\Desktop\Rafael\Outras coisas\Godot\TADC-jogo-JuncaoKaykeRyan\Cenarios\CenarioMundoCompleto\CenarioCircoDigital.tscn'
$lines = Get-Content $path
$trees = @()
foreach ($line in $lines) {
    if ($line -match '\[node name="(Circle_\d+)" type="MeshInstance3D" parent="The Grounds/ArvoresLago"') {
        $trees += $matches[1]
    }
}

$newBlocks = "`n"
$rand = New-Object Random
foreach ($tree in $trees) {
    # Skip Circle_019 if the user actually wanted me to just copy from it, 
    # but since I'm appending children named "LuzArvore", I can just do it for all trees.
    $uid = $rand.Next(1000000000, 2147483647)
    $newBlocks += @"
[node name="LuzArvore" type="OmniLight3D" parent="The Grounds/ArvoresLago/$tree" unique_id=$uid]
transform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1.06, 0)
light_color = Color(0.7983094, 0.9947768, 0.5613247, 1)
light_energy = 3.376
light_size = 0.02

"@
}

$content = [System.IO.File]::ReadAllText($path) + $newBlocks
[System.IO.File]::WriteAllText($path, $content)

# Remove BOM
$bytes = [System.IO.File]::ReadAllBytes($path)
if ($bytes.Length -gt 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
    [System.IO.File]::WriteAllBytes($path, $bytes[3..($bytes.Length - 1)])
}
