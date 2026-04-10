param(
    [switch]$Force
)

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  MSVC 渚挎惡寮忓伐鍏烽摼鎻愬彇鍣?(Portable Exporter)" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "姝ｅ湪鎼滅储鏈湴鏈€鏂扮殑 Visual Studio 宸ュ叿閾?.."

# 1. 瀹氫綅 VS 瀹夎鐩綍
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) {
    Write-Host "[閿欒] 鏈壘鍒?vswhere.exe锛屾棤娉曞畾浣?Visual Studio銆? -ForegroundColor Red
    exit 1
}

$vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vsPath) {
    Write-Host "[閿欒] 鏈娴嬪埌瀹夎浜?C++ 妗岄潰宸ヤ綔璐熻浇鐨?Visual Studio銆? -ForegroundColor Red
    exit 1
}

Write-Host "[鎵惧埌 VS 鐩綍] $vsPath" -ForegroundColor Green

# 2. 鑾峰彇鏈€楂樼増鏈殑 VC Tools 鐩綍
$vcBase = Join-Path $vsPath "VC\Tools\MSVC"
$vcVersionDir = (Get-ChildItem $vcBase -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName
Write-Host "[鑾峰彇 VC Tools] $vcVersionDir" -ForegroundColor Green

# 3. 鑾峰彇鏈€楂樼増鏈殑 Windows Kits 10 鐩綍
$winKitsBase = "${env:ProgramFiles(x86)}\Windows Kits\10"
if (-not (Test-Path $winKitsBase)) {
    Write-Host "[閿欒] 鏈壘鍒?Windows Kits 10 鐩綍銆傝纭繚瀹夎浜?Win10/Win11 SDK銆? -ForegroundColor Red
    exit 1
}

$incBase = Join-Path $winKitsBase "Include"
$libBase = Join-Path $winKitsBase "Lib"
$binBase = Join-Path $winKitsBase "bin"

$sdkVersion = (Get-ChildItem $incBase -Directory | Sort-Object Name -Descending | Select-Object -First 1).Name
Write-Host "[鑾峰彇 Windows SDK] 鐗堟湰: $sdkVersion" -ForegroundColor Green

$wkIncDirs = Join-Path $incBase $sdkVersion
$wkLibDirs = Join-Path $libBase $sdkVersion
$wkBinDirs = Join-Path $binBase $sdkVersion

# 4. 璁剧疆鐩爣瀵煎嚭鐩綍锛堜笌 pbuild.ps1 鍚岀洰褰曪級
$targetBase = Join-Path $HOME "bin\portable_msvc"
Write-Host "`n鐩爣瀵煎嚭鍖呰矾寰? $targetBase" -ForegroundColor Magenta
Write-Host "棰勮灏嗗崰鐢ㄧ害 2GB ~ 2.5GB 纾佺洏绌洪棿銆? -ForegroundColor Magenta

if (-not $Force) {
    $confirm = Read-Host "鏄惁鐜板湪寮€濮嬫墽琛?robocopy 澶ф枃浠舵彁鍙?鍚屾锛?y/N)"
    if ($confirm -notmatch "^y(es)?`$") {
        Write-Host "宸插彇娑堛€? -ForegroundColor Yellow
        exit 0
    }
}

New-Item $targetBase -ItemType Directory -Force | Out-Null

$robocopyArgs = @("/NDL", "/NFL", "/NJH", "/NJS", "/nc", "/ns", "/np", "/MT:16")

# 杈呭姪鍑芥暟锛氳皟鐢?robocopy 闀滃儚鐩綍
function Sync-Folder {
    param([string]$src, [string]$dst, [string]$desc)
    Write-Host "`n-> 姝ｅ湪闀滃儚鍚屾 [$desc] ..." -ForegroundColor Cyan
    cmd.exe /c "robocopy `"$src`" `"$dst`" /MIR $( $robocopyArgs -join ' ' )"
    $rc = $LASTEXITCODE
    if ($rc -lt 8) {
        Write-Host "   鍚屾鎴愬姛锛? -ForegroundColor Green
    } else {
        Write-Host "   [璀﹀憡] robocopy 鍙戠敓寮傚父锛岄€€鍑虹爜: $rc" -ForegroundColor Red
    }
}

# 5. 鎵ц鍚屾
$targetVC = Join-Path $targetBase "VC\Tools\MSVC\$($vcVersionDir | Split-Path -Leaf)"
$targetWkInc = Join-Path $targetBase "Windows Kits\10\Include\$sdkVersion"
$targetWkLib = Join-Path $targetBase "Windows Kits\10\Lib\$sdkVersion"
$targetWkBin = Join-Path $targetBase "Windows Kits\10\bin\$sdkVersion"

Sync-Folder -src $vcVersionDir -dst $targetVC -desc "缂栬瘧鍣ㄤ笌鏈湴搴?(VC Tools)"
Sync-Folder -src $wkIncDirs -dst $targetWkInc -desc "绯荤粺澶存枃浠?(SDK Include)"
Sync-Folder -src $wkLibDirs -dst $targetWkLib -desc "绯荤粺闈欐€佸簱 (SDK Lib)"
Sync-Folder -src $wkBinDirs -dst $targetWkBin -desc "绯荤粺浜岃繘鍒跺伐鍏?(SDK bin, e.g. rc.exe)"

Write-Host "`n=========================================" -ForegroundColor Cyan
Write-Host "  鉁?MSVC 宸ュ叿閾炬墦鍖呭畬鎴愶紒" -ForegroundColor Green
Write-Host "  鎵撳寘鐩綍: $targetBase" -ForegroundColor Green
Write-Host "  浣犵幇鍦ㄥ彲浠ュ皢姝?portable_msvc 鏂囦欢澶逛笌 build-portable.ps1 浣滀负鍘嬬缉鍖呭彂缁欏叾浠栦汉浜嗐€? -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
