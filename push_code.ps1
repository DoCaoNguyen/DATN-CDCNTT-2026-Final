$ErrorActionPreference = "Continue"

function Push-Repo($repo) {
    Write-Host "--- Processing $repo ---"
    Set-Location $repo
    git add -A
    git commit -m "Auto commit: Update features, fix bugs, and clean code"
    
    # Push to main
    git checkout main
    git pull origin main -s recursive -X ours
    git push origin main
    
    # Push to thong
    git branch --list | Out-String -Stream | ForEach-Object { $_.Trim() } | Where-Object { $_ -match 'thong' } | Set-Variable -Name hasThong
    if ($hasThong) {
        git checkout thong
    } else {
        git checkout -b thong
    }
    
    git merge main -s recursive -X ours
    git pull origin thong -s recursive -X ours
    git push origin thong
    
    # Return to main as default
    git checkout main
}

Push-Repo "d:\do_an\wallet_api_node"
Push-Repo "d:\do_an\wallet_app"
Push-Repo "d:\app_test\DATN-CDCNTT-2026-Final"
