param(
    [switch]$Force
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  MSVC 便携式工具链提取器 (Portable Exporter)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "正在搜索本地最新的 Visual Studio 工具链..."

# 1. 定位 VS 安装目录
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) {
    Write-Host "[错误] 未找到 vswhere.exe，无法定位 Visual Studio。" -ForegroundColor Red
    exit 1
}

$vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsPath) {
    Write-Host "[错误] 未检测到安装了 C++ 桌面工作负载的 Visual Studio。" -ForegroundColor Red
    exit 1
}

Write-Host "[找到 VS 目录] $vsPath" -ForegroundColor Green

# 2. 获取最高版本的 VC Tools 目录
$vcBase = Join-Path $vsPath "VC\Tools\MSVC"
$vcVersionDir = (Get-ChildItem $vcBase -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName
Write-Host "[获取 VC Tools] $vcVersionDir" -ForegroundColor Green

# 3. 获取最高版本的 Windows Kits 10 目录
$winKitsBase = "${env:ProgramFiles(x86)}\Windows Kits\10"
if (-not (Test-Path $winKitsBase)) {
    Write-Host "[错误] 未找到 Windows Kits 10 目录。请确保安装了 Win10/Win11 SDK。" -ForegroundColor Red
    exit 1
}

$incBase = Join-Path $winKitsBase "Include"
$libBase = Join-Path $winKitsBase "Lib"
$binBase = Join-Path $winKitsBase "bin"

$sdkVersion = (Get-ChildItem $incBase -Directory | Sort-Object Name -Descending | Select-Object -First 1).Name
Write-Host "[获取 Windows SDK] 版本: $sdkVersion" -ForegroundColor Green

$wkIncDirs = Join-Path $incBase $sdkVersion
$wkLibDirs = Join-Path $libBase $sdkVersion
$wkBinDirs = Join-Path $binBase $sdkVersion

# 4. 设置目标导出目录（与 pbuild.ps1 同目录）
$targetBase = Join-Path $PSScriptRoot "portable_msvc"
Write-Host "`n目标导出包路径: $targetBase" -ForegroundColor Magenta
Write-Host "预计将占用约 2GB ~ 2.5GB 磁盘空间。" -ForegroundColor Magenta

if (-not $Force) {
    $confirm = Read-Host "是否现在开始执行 robocopy 大文件提取/同步？(y/N)"
    if ($confirm -notmatch "^y(es)?`$") {
        Write-Host "已取消。" -ForegroundColor Yellow
        exit 0
    }
}

New-Item $targetBase -ItemType Directory -Force | Out-Null

$robocopyArgs = @("/NDL", "/NFL", "/NJH", "/NJS", "/nc", "/ns", "/np", "/MT:16")

# 辅助函数：调用 robocopy 镜像目录
function Sync-Folder {
    param([string]$src, [string]$dst, [string]$desc)
    Write-Host "`n-> 正在镜像同步 [$desc] ..." -ForegroundColor Cyan
    cmd.exe /c "robocopy `"$src`" `"$dst`" /MIR $( $robocopyArgs -join ' ' )"
    $rc = $LASTEXITCODE
    if ($rc -lt 8) {
        Write-Host "   同步成功！" -ForegroundColor Green
    } else {
        Write-Host "   [警告] robocopy 发生异常，退出码: $rc" -ForegroundColor Red
    }
}

# 5. 执行同步
$targetVC = Join-Path $targetBase "VC\Tools\MSVC\$($vcVersionDir | Split-Path -Leaf)"
$targetWkInc = Join-Path $targetBase "Windows Kits\10\Include\$sdkVersion"
$targetWkLib = Join-Path $targetBase "Windows Kits\10\Lib\$sdkVersion"
$targetWkBin = Join-Path $targetBase "Windows Kits\10\bin\$sdkVersion"

Sync-Folder -src $vcVersionDir -dst $targetVC -desc "编译器与本地库 (VC Tools)"
Sync-Folder -src $wkIncDirs -dst $targetWkInc -desc "系统头文件 (SDK Include)"
Sync-Folder -src $wkLibDirs -dst $targetWkLib -desc "系统静态库 (SDK Lib)"
Sync-Folder -src $wkBinDirs -dst $targetWkBin -desc "系统二进制工具 (SDK bin, e.g. rc.exe)"

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  ✅ MSVC 工具链打包完成！" -ForegroundColor Green
Write-Host "  打包目录: $targetBase" -ForegroundColor Green
Write-Host "  你现在可以将此 portable_msvc 文件夹与 build-portable.ps1 作为压缩包发给其他人了。" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
