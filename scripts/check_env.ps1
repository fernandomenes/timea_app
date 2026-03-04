@"
Write-Host "== Timea: Environment check =="

Write-Host "`n[Flutter]"
flutter --version

Write-Host "`n[Doctor]"
flutter doctor

Write-Host "`n[Devices]"
flutter devices

Write-Host "`nDone."
"@ | Set-Content -Encoding UTF8 scripts\check_env.ps1