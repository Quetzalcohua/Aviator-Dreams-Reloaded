param([string]$Jar = "$PSScriptRoot/../fabric/build/libs/aviator_dreams_reloaded-fabric-1.3.3-port.1+26.1.2.jar")
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [IO.Compression.ZipFile]::OpenRead((Resolve-Path $Jar))
function Read-Entry([string]$Name) {
    $entry = $zip.GetEntry($Name)
    if (-not $entry) { throw "Missing jar entry: $Name" }
    $reader = [IO.StreamReader]::new($entry.Open())
    try { $reader.ReadToEnd() } finally { $reader.Dispose() }
}
try {
    $meta = Read-Entry 'fabric.mod.json' | ConvertFrom-Json
    if ($meta.id -ne 'aviator_dream' -or $meta.version -ne '1.3.3-port.1+26.1.2') { throw 'Wrong mod ID/version' }
    if ($meta.depends.minecraft -ne '=26.1.2' -or $meta.depends.java -ne '>=25') { throw 'Wrong game/Java requirement' }
    if ($meta.depends.fabricloader -ne '>=0.19.5' -or $meta.depends.immersive_aircraft -ne '>=1.5.2' -or $meta.depends.'fabric-api' -ne '>=0.155.3') { throw 'Wrong minimum dependencies' }
    if (-not $meta.entrypoints.main -or -not $meta.entrypoints.client) { throw 'Missing Fabric entrypoints' }
    $null = Read-Entry 'LICENSE'
    $ids = @('douglas_dc1','douglas_dc2','douglas_c47','lockheed_l1049g','test','dehavilland_dh106','fokker_fviib3m','fokker_fviia','toyota_stout_k100')
    foreach ($id in $ids) {
        $null = Read-Entry "data/aviator_dream/aircraft/$id.json" | ConvertFrom-Json
        $null = Read-Entry "assets/aviator_dream/objects/$id.bbmodel" | ConvertFrom-Json -AsHashtable -Depth 100
        $null = Read-Entry "assets/aviator_dream/items/$id.json" | ConvertFrom-Json
        if ($id -ne 'test') { $null = Read-Entry "data/aviator_dream/recipe/$id.json" | ConvertFrom-Json }
    }
    $entry = $zip.GetEntry('net/cerealcamera/aviator_dream/AviatorDreams.class')
    if (-not $entry) { throw 'Common classes absent' }
    $stream = $entry.Open()
    try { $header = [byte[]]::new(8); $null = $stream.Read($header,0,8) } finally { $stream.Dispose() }
    $major = 256 * [int]$header[6] + [int]$header[7]
    if ($major -ne 69) { throw "Expected Java25 class major69, got $major" }
    if ($zip.Entries.FullName -match '^immersive_aircraft/.*\.class$') { throw 'Aircraft must not be shaded into addon' }
    Write-Output 'PASS: Fabric metadata, Java25 bytecode, LICENSE, all 9 entity model/data/item resources and 8 recipes.'
    Write-Output 'This static package check does not verify gameplay or rendering.'
} finally { $zip.Dispose() }
Get-FileHash $Jar -Algorithm SHA256
