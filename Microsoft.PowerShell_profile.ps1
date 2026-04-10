$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding
function build { & "$HOME\bin\build.ps1" @args }
function pbuild { & "$HOME\bin\pbuild.ps1" @args }