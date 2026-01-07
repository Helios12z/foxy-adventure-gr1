# Script to optimize PNG import settings
Write-Host "Starting PNG optimization..."

# Get current directory
$basePath = "E:\SE116\Đồ án\foxy-adventure-gr1\asset"

# Get all PNG import files
$allPngImports = Get-ChildItem -Path $basePath -Recurse -Filter "*.png.import"
Write-Host "Found $($allPngImports.Count) PNG import files"

# Get PNG files over 1MB
$pngFilesOver1MB = Get-ChildItem -Path $basePath -Recurse -Filter "*.png" | Where-Object { $_.Length -gt 1MB }
Write-Host "Found $($pngFilesOver1MB.Count) PNG files > 1MB"

# Create hashtable of large file names for fast lookup
$largeFileNames = @{}
foreach ($file in $pngFilesOver1MB) {
    $largeFileNames[$file.Name] = $true
}

$countLossless = 0
$countLossy = 0

# Process each import file
foreach ($importFile in $allPngImports) {
    $pngFileName = $importFile.Name -replace '\.import$', ''
    $content = Get-Content $importFile.FullName -Raw
    
    if ($largeFileNames.ContainsKey($pngFileName)) {
        # File > 1MB: mode=1 (Lossy), quality=0.95
        $newContent = $content -replace 'compress/mode=\d+', 'compress/mode=1'
        $newContent = $newContent -replace 'compress/lossy_quality=[0-9.]+', 'compress/lossy_quality=0.95'
        Set-Content -Path $importFile.FullName -Value $newContent -NoNewline
        $countLossy++
    } else {
        # File <= 1MB: mode=0 (Lossless)
        $newContent = $content -replace 'compress/mode=\d+', 'compress/mode=0'
        Set-Content -Path $importFile.FullName -Value $newContent -NoNewline
        $countLossless++
    }
}

Write-Host "`nCompleted!"
Write-Host "  - $countLossless PNG files set to LOSSLESS (mode=0)"
Write-Host "  - $countLossy PNG files > 1MB set to LOSSY 95% (mode=1, quality=0.95)"
