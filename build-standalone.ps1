$ErrorActionPreference = "Stop"

$root = [System.IO.Path]::GetFullPath($PSScriptRoot)
$sourcePath = Join-Path $root "index.html"
$cssPath = Join-Path $root "styles.css"
$jsPath = Join-Path $root "app.js"
$outputPath = Join-Path (Split-Path $root -Parent) "GitHub-Pages-Domain-Guide-Standalone.html"

$html = Get-Content -LiteralPath $sourcePath -Raw -Encoding UTF8
$css = Get-Content -LiteralPath $cssPath -Raw -Encoding UTF8
$js = Get-Content -LiteralPath $jsPath -Raw -Encoding UTF8

$html = $html.Replace(
    '<link rel="stylesheet" href="styles.css">',
    "<style>`r`n$css`r`n</style>"
)
$html = $html.Replace(
    '<script src="app.js"></script>',
    "<script>`r`n$js`r`n</script>"
)

$imagePaths = [regex]::Matches(
    $html,
    'assets/[A-Za-z0-9._-]+\.png'
) | ForEach-Object {
    $_.Value
} | Sort-Object -Unique

foreach ($relativePath in $imagePaths) {
    $imagePath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $imagePath)) {
        throw "Missing image: $relativePath"
    }
    $base64 = [Convert]::ToBase64String(
        [System.IO.File]::ReadAllBytes($imagePath)
    )
    $html = $html.Replace(
        $relativePath,
        "data:image/png;base64,$base64"
    )
}

$utf8WithBom = [System.Text.UTF8Encoding]::new($true)
[System.IO.File]::WriteAllText($outputPath, $html, $utf8WithBom)

Write-Host "Created: $outputPath"
Write-Host "Images embedded: $($imagePaths.Count)"
Write-Host "Size: $((Get-Item -LiteralPath $outputPath).Length) bytes"
