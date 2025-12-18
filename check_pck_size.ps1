# PowerShell script to check exported PCK size
$exportPath = ".\build"
if (Test-Path $exportPath) {
    Get-ChildItem $exportPath -Filter "*.pck" | ForEach-Object {
        $sizeMB = [math]::Round($_.Length/1MB, 2)
        Write-Host "$($_.Name): $sizeMB MB"
        if ($sizeMB -lt 200) {
            Write-Host "✓ OK - Under 200MB limit!" -ForegroundColor Green
        } else {
            Write-Host "✗ Still too large: $($sizeMB - 200) MB over limit" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No build folder found. Export the project first."
}
