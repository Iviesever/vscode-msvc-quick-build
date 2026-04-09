$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding
function build { & pwsh.exe -NoProfile -File "$HOME\bin\build.ps1" @args }