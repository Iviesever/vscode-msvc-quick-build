$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding
$psExe = if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) { "pwsh.exe" } else { "powershell.exe" }
Invoke-Expression "function build { & $psExe -NoProfile -File `"$HOME\bin\build.ps1`" @args }"
Invoke-Expression "function pbuild { & $psExe -NoProfile -File `"$HOME\bin\pbuild.ps1`" @args }"