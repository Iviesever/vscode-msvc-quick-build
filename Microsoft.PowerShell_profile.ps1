$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding
function build {
    if (Get-Command pwsh.exe -ErrorAction SilentlyContinue) {
        & pwsh.exe -NoProfile -File "$HOME\bin\build.ps1" @args
    } else {
        & "$HOME\bin\build.ps1" @args
    }
}