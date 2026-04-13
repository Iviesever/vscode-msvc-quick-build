$ctx = @{ Arch = 'x64'; ForceEnv = 'auto' }
. 'd:\program\buildÏîÄ¿\build.ps1'
Init-Environment $ctx
Write-Host "$ctx.VcDir="
