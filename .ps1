# generate_def_fixed.ps1
# Corrige geração do .def a partir do exports.txt com ordinais apenas.
$exportFile = ".\exports.txt"
$outDef = ".\xlive.def"
if (!(Test-Path $exportFile)) { Write-Error "exports.txt not found."; exit 1 }

$lines = Get-Content $exportFile
$ordinals = @()
foreach ($l in $lines) {
    if ($l -match "^\s*([0-9]{1,5})\s+") {
        $ordinals += [int]$matches[1]
    }
}
$ordinals = $ordinals | Sort-Object -Unique

$out = @()
$out += "LIBRARY xlive"
$out += "EXPORTS"
$out += "XNetStartup @5000"
$out += "XNetCleanup @5001"

foreach ($o in $ordinals) {
    if ($o -eq 5000 -or $o -eq 5001) { continue }
    $out += ("@{0}=xlive_real.#@{0}" -f $o)
}

$out | Set-Content -Encoding ASCII $outDef
Write-Host "Gerado xlive.def limpo com" ($ordinals.Count) "ordinals (5000/5001 locais)."
