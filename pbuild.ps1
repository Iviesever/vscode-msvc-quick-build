param(
    [Parameter(Position = 0, ValueFromRemainingArguments)]
    [string[]]$Sources,

    [Alias('output')]
    [string]$o,

    [switch]$run,

    [ValidateSet('14', '17', '20', '23', 'latest')]
    [string]$std,

    [Alias('a')]
    [string]$ProgramArgs,

    [switch]$x86,

    [switch]$smart,

    [string[]]$I,

    [string[]]$L,

    [string[]]$libs,

    # 鈹€鈹€ msvc_list.json 1:1 瀵瑰簲鍙傛暟 鈹€鈹€
    [ValidateSet('debug', 'release')]
    [string]$config,

    [ValidateSet('unicode', 'mbcs')]
    [string]$charset,

    [ValidateSet('console', 'windows')]
    [string]$subsystem,

    [ValidateSet('off', 'size', 'speed', 'full')]
    [string]$optimize,

    [ValidateSet('dynamic', 'static')]
    [string]$runtime,

    [ValidateSet('off', 'basic', 'default', 'high', 'all')]
    [string]$warnings,

    [switch]$warn_as_error,

    [ValidateSet('off', 'pdb', 'edit', 'embedded')]
    [string]$debug_info,

    [ValidateSet('sync', 'async', 'none')]
    [string]$exceptions,

    [switch]$rtc,
    [switch]$jmc,
    [switch]$security,
    [switch]$conformance,

    [ValidateSet('precise', 'strict', 'fast')]
    [string]$fp_model,

    [switch]$ltcg,
    [switch]$incremental_link,

    [string[]]$defines,
    [string[]]$flags,
    [string[]]$link_flags,

    [Alias('h', '?')]
    [switch]$help
)

if ($help -or -not $Sources) {
    Write-Host ''
    Write-Host 'build' -NoNewline -ForegroundColor Cyan
    Write-Host ' 鈥?MSVC 蹇€熺紪璇戝伐鍏? -ForegroundColor DarkGray
    Write-Host '  鐢ㄦ硶锛? -ForegroundColor DarkCyan
    Write-Host '    build <婧愭枃浠?..> [閫夐」]'
    Write-Host ''
    Write-Host '  鍩虹閫夐」锛? -ForegroundColor DarkCyan
    Write-Host '    -o <鍚嶇О>       鎸囧畾杈撳嚭鏂囦欢鍚嶏紙涓嶅惈 .exe锛?
    Write-Host '    -run            缂栬瘧鎴愬姛鍚庤嚜鍔ㄨ繍琛?
    Write-Host '    -std <鐗堟湰>     C++ 鏍囧噯锛?4 / 17 / 20 / 23 / latest'
    Write-Host '    -a <鍙傛暟>       浼犻€掔粰绋嬪簭鐨勫懡浠よ鍙傛暟'
    Write-Host '    -x86            缂栬瘧涓?32 浣嶏紙榛樿 64 浣嶏級'
    Write-Host '    -smart          鏅鸿兘妯″紡锛氳嚜鍔ㄩ€氳繃 #include 鍜?import 杩借釜鍏宠仈鐨勬簮鏂囦欢'
    Write-Host ''
    Write-Host '  璺緞涓庨摼鎺ヤ緷璧栵細' -ForegroundColor DarkCyan
    Write-Host '    -I <璺緞...>    棰濆鐨勫ご鏂囦欢鍖呭惈璺緞 (鍙涓?'
    Write-Host '    -L <璺緞...>    棰濆鐨勫簱鏂囦欢鎼滅储璺緞 (鍙涓?'
    Write-Host '    -libs <搴撳悕...>   瑕侀摼鎺ョ殑搴擄紙涓嶅惈 .lib锛屽彲澶氫釜锛?
    Write-Host ''
    Write-Host '  宸ヤ笟绾у伐绋嬮厤缃?(涓?msvc_list.json 鐨勫瓧娈?1:1 瀵瑰簲锛孋LI 浼樺厛绾ф渶楂?锛? -ForegroundColor Magenta
    Write-Host '    -config <preset>      浣跨敤瀹樻柟閰嶇疆棰勮锛歞ebug / release'
    Write-Host '    -optimize <绾у埆>      浼樺寲绾у埆锛歰ff / size / speed / full'
    Write-Host '    -runtime <鍔ㄦ€侀潤鎬?     杩愯搴擄細dynamic (/MD) / static (/MT)'
    Write-Host '    -warnings <绾у埆>      璀﹀憡锛歰ff / basic / default / high / all'
    Write-Host '    -warn_as_error        瑙嗚鍛婁负閿欒 (/WX)'
    Write-Host '    -debug_info <妯″紡>    璋冭瘯淇℃伅锛歰ff / pdb (/Zi) / edit (/ZI) / embedded (/Z7)'
    Write-Host '    -exceptions <妯″紡>    寮傚父澶勭悊锛歴ync (/EHsc) / async (/EHa) / none'
    Write-Host '    -fp_model <妯″紡>      娴偣妯″瀷锛歱recise / strict / fast'
    Write-Host '    -charset <瀛楃闆?      鑷姩瀹忓畾涔夛細unicode (/DUNICODE) / mbcs (/D_MBCS)'
    Write-Host '    -subsystem <瀛愮郴缁?     閾炬帴鍣ㄥ瓙绯荤粺锛歝onsole / windows'
    Write-Host '    -rtc                  寮€鍚鏃舵鏌?(/RTC1)'
    Write-Host '    -jmc                  寮€鍚?Just My Code 璋冭瘯 (/JMC)'
    Write-Host '    -security             寮€鍚紦鍐插尯瀹夊叏妫€鏌?(/GS /sdl)'
    Write-Host '    -conformance          寮€鍚弗鏍兼爣鍑嗕竴鑷存€ф鏌?(/permissive- /Zc:...) '
    Write-Host '    -ltcg                 寮€鍚叏绋嬪簭浼樺寲 (LTCG)'
    Write-Host '    -incremental_link     鍚敤澧為噺閾炬帴 (/INCREMENTAL)'
    Write-Host '    -defines <瀹?..>       瀹氫箟棰勫鐞嗗櫒瀹?(鍙涓?'
    Write-Host '    -flags <鍙傛暟...>      杩藉姞鍘熷缂栬瘧鍣ㄦ爣蹇?(濡?/wd4819)'
    Write-Host '    -link_flags <鍙傛暟...> 杩藉姞鍘熷閾炬帴鍣ㄦ爣蹇?(濡?/NODEFAULTLIB)'
    Write-Host ''
    Write-Host '  绀轰緥锛? -ForegroundColor DarkCyan
    Write-Host '    build main.cpp -run'
    Write-Host '    build *.cpp -o app -std 23 -config release -run'
    Write-Host '    build main.cpp -smart -config debug -warnings high -conformance -run'
    Write-Host ''
    Write-Host '  鏀寔鏂囦欢锛? -ForegroundColor DarkCyan
    Write-Host '    .c (C), .cpp / .cxx / .cc (C++), .ixx (C++20 Modules)'
    Write-Host "    (鎵ц 'build' 鏃朵笉甯︽簮鏂囦欢锛屽彲灞忚斀 .h/.txt 绛夋棤鍏虫枃浠惰嚜鍔ㄦ彁鍙栨簮鍐呭)"
    Write-Host ''
    Write-Host '  璇︾粏鏂囨。涓庨」鐩厤缃寚鍗楋細' -NoNewline -ForegroundColor DarkCyan
    Write-Host ' 鍙傞槄椤圭洰鐩綍涓嬬殑 README.md (瀹屽叏鏀寔 msvc_list.json)' -ForegroundColor DarkGray
    Write-Host ''

    exit 0
}

$files = @()
foreach ($src in $Sources) {
    if ($src -eq '-run' -or $src -eq '-x86') { continue }
    $resolved = @(Resolve-Path $src -ErrorAction SilentlyContinue)
    if ($resolved.Count -gt 0) {
        foreach ($r in $resolved) {
            if ($smart) { $extRe = '\.(c|cpp|cxx|cc|ixx|h|hpp)$' } else { $extRe = '\.(c|cpp|cxx|cc|ixx)$' }
            if ($r.Path -match $extRe) {
                $files += $r.Path
            }
        }
    }
    else {
        Write-Host "[閿欒] 鏂囦欢涓嶅瓨鍦? $src" -ForegroundColor Red
        exit 1
    }
}

if ($files.Count -eq 0) {
    Write-Host '[閿欒] 鏈寚瀹氭簮鏂囦欢' -ForegroundColor Red
    exit 1
}

if ($smart -and $files.Count -gt 0) {
    $focusedFile = $files[0]
    $dir = [System.IO.Path]::GetDirectoryName($focusedFile)

    $allCandidates = @{}
    $dirItems = Get-ChildItem $dir -File -Recurse | Where-Object { $_.Extension -match '^\.(?:c|cpp|cxx|cc|ixx|h|hpp)$' }
    foreach ($f in $dirItems) {
        $raw = Get-Content $f.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $raw) { $raw = '' }
        $stripped = [regex]::Replace($raw, '/\*[\s\S]*?\*/', '')
        $stripped = [regex]::Replace($stripped, '//[^\n]*', '')
        $allCandidates[$f.FullName] = $stripped
    }

    $modProviders = @{}
    $fileModule = @{}
    foreach ($path in $allCandidates.Keys) {
        if ($path -match '\.ixx$') {
            $c = $allCandidates[$path]
            if ($c -match 'export\s+module\s+([\w.:]+)\s*;') {
                $fullModName = $Matches[1]
                $modProviders[$fullModName] = $path
                $fileModule[$path] = ($fullModName -split ':')[0]
            }
        }
    }

    $depGraph = @{}
    foreach ($path in $allCandidates.Keys) {
        $depGraph[$path] = @()
    }

    foreach ($path in $allCandidates.Keys) {
        $content = $allCandidates[$path]

        foreach ($m in [regex]::Matches($content, '#include\s+"([^"]+)"')) {
            $headerName = $m.Groups[1].Value
            $includerDir = [System.IO.Path]::GetDirectoryName($path)
            $headerPath = [System.IO.Path]::GetFullPath((Join-Path $includerDir $headerName))
            if ($allCandidates.ContainsKey($headerPath)) {
                $depGraph[$path] += $headerPath
                $depGraph[$headerPath] += $path

                $hdrBase = [System.IO.Path]::GetFileNameWithoutExtension($headerName)
                $hdrDir = [System.IO.Path]::GetDirectoryName($headerPath)
                foreach ($ext in @('.cpp', '.c', '.cxx', '.cc')) {
                    $implPath = [System.IO.Path]::GetFullPath((Join-Path $hdrDir "$hdrBase$ext"))
                    if ($allCandidates.ContainsKey($implPath)) {
                        $depGraph[$headerPath] += $implPath
                        $depGraph[$implPath] += $headerPath
                    }
                }
            }
        }

        foreach ($m in [regex]::Matches($content, '(?:export\s+)?import\s*(:[\w.]+|[\w.:]+)\s*;')) {
            $modName = $m.Groups[1].Value
            if ($modName -eq 'std' -or $modName -eq 'std.compat') { continue }
            if ($modName.StartsWith(':')) {
                $parentMod = $fileModule[$path]
                if ($parentMod) { $modName = "$parentMod$modName" }
            }
            if ($modProviders.ContainsKey($modName)) {
                $ixxPath = $modProviders[$modName]
                $depGraph[$path] += $ixxPath
                $depGraph[$ixxPath] += $path
            }
        }
    }

    $visited = @{}
    $bfsQueue = [System.Collections.Queue]::new()
    $bfsQueue.Enqueue($focusedFile)
    $visited[$focusedFile] = $true

    while ($bfsQueue.Count -gt 0) {
        $current = $bfsQueue.Dequeue()
        if ($depGraph.ContainsKey($current)) {
            foreach ($neighbor in $depGraph[$current]) {
                if (-not $visited.ContainsKey($neighbor)) {
                    $visited[$neighbor] = $true
                    $bfsQueue.Enqueue($neighbor)
                }
            }
        }
    }

    $smartAllFiles = @($visited.Keys)

    $files = @($visited.Keys | Where-Object {
        $_ -match '\.(c|cpp|cxx|cc|ixx)$'
    } | Where-Object {
        if ($_ -eq $focusedFile) { return $true }
        if ($_ -match '\.ixx$') { return $true }
        $fc = $allCandidates[$_]
        if ($fc -match '\bmain\s*\(') { return $false }
        # exclude 妯″紡杩囨护
        if ($cfg -and $cfg.exclude) {
            $fn = [System.IO.Path]::GetFileName($_)
            foreach ($pat in $cfg.exclude) {
                if ($fn -like $pat) { return $false }
            }
        }
        return $true
    } | Sort-Object)

    if ($files.Count -eq 0) {
        Write-Host '[閿欒] 鏈彂鐜板彲缂栬瘧鐨勬簮鏂囦欢' -ForegroundColor Red
        exit 1
    }

    if ($files.Count -gt 1) {
        if ($files.Count -le 8) {
            $discoveredNames = ($files | ForEach-Object { [System.IO.Path]::GetFileName($_) }) -join ', '
            Write-Host "[鏅鸿兘] 鍏宠仈: $discoveredNames" -ForegroundColor DarkGray
        } else {
            $first5 = ($files | Select-Object -First 5 | ForEach-Object { [System.IO.Path]::GetFileName($_) }) -join ', '
            Write-Host "[鏅鸿兘] 鍏宠仈: $first5, ... 鍏?$($files.Count) 涓枃浠? -ForegroundColor DarkGray
        }
    }

    if (-not $o) {
        $o = [System.IO.Path]::GetFileNameWithoutExtension($focusedFile)
    }
}

$ixxFiles = @($files | Where-Object { $_ -match '\.ixx$' })
$cppFiles = @($files | Where-Object { $_ -match '\.(cpp|cxx|cc|c)$' })

if (-not $o) {
    $firstCpp = $cppFiles | Select-Object -First 1
    if ($firstCpp) {
        $o = [System.IO.Path]::GetFileNameWithoutExtension($firstCpp)
    }
    elseif ($ixxFiles.Count -gt 0) {
        $o = [System.IO.Path]::GetFileNameWithoutExtension($ixxFiles[0])
    }
}

$exe = Join-Path $PWD "$o.exe"
# 澧為噺鏋勫缓锛氫唬鐮佹湭淇敼鏃惰烦杩囩紪璇?if (Test-Path $exe) {
    $exeTime = (Get-Item $exe).LastWriteTime
    if ($smart -and $smartAllFiles) { $checkFiles = $smartAllFiles } else { $checkFiles = $files }
    $needsBuild = $false
    foreach ($cf in $checkFiles) {
        if (Test-Path $cf) {
            if ((Get-Item $cf).LastWriteTime -gt $exeTime) {
                $needsBuild = $true
                break
            }
        }
    }
    if (-not $needsBuild) {
        Write-Host ''
        Write-Host "[璺宠繃] 浠ｇ爜鏈慨鏀? -ForegroundColor DarkGray
        if ($run) {
            Write-Host ''
            Write-Host "[杩愯] $o.exe $ProgramArgs" -ForegroundColor Yellow
            Write-Host ('=' * 40) -ForegroundColor DarkGray
            if ($ProgramArgs) {
                & $exe ($ProgramArgs -split ' ')
            }
            else {
                & $exe
            }
            $code = $LASTEXITCODE
            Write-Host ('=' * 40) -ForegroundColor DarkGray
            Write-Host "[缁撴潫] 閫€鍑虹爜: $code" -ForegroundColor DarkGray
        }
        exit 0
    }
}

# msvc_list.json 椤圭洰閰嶇疆锛堝悜涓婃煡鎵撅級
$cfg = $null
$cfgFoundDir = $null
$searchDir = $PWD.Path
for ($lvl = 0; $lvl -lt 5; $lvl++) {
    $cfgPath = Join-Path $searchDir 'msvc_list.json'
    if (Test-Path $cfgPath) {
        $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
        $cfgFoundDir = $searchDir
        Write-Host "[閰嶇疆] msvc_list.json" -ForegroundColor DarkGray
        break
    }
    $parent = [System.IO.Path]::GetDirectoryName($searchDir)
    if (-not $parent -or $parent -eq $searchDir) { break }
    $searchDir = $parent
}

if ($cfg -and -not $std -and $cfg.std) { $std = $cfg.std }
# output 浼樺厛绾э細鍛戒护琛?-o > JSON output > 鑷姩妫€娴?if ($cfg -and $cfg.output -and -not $PSBoundParameters.ContainsKey('o')) { $o = $cfg.output }
$exe = Join-Path $PWD "$o.exe"

$hasCpp = ($cppFiles | Where-Object { $_ -match '\.(cpp|cxx|cc)$' }) -or ($ixxFiles.Count -gt 0)

Write-Host "[鐜] 閰嶇疆渚挎惡鐗?MSVC 宸ュ叿閾惧唴瀛樼幆澧?.." -ForegroundColor Green
$portableBase = Join-Path $PSScriptRoot "portable_msvc"
if (-not (Test-Path $portableBase)) {
    Write-Host "[閿欒] 鏈壘鍒?portable_msvc 鏂囦欢澶广€傝鍏堣繍琛?export-msvc.ps1 鐢熸垚渚挎惡鏋勫缓鍖呫€? -ForegroundColor Red
    exit 1
}

$vcBase = Join-Path $portableBase "VC\Tools\MSVC"
$vcDir = (Get-ChildItem $vcBase -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName
$wkIncBase = Join-Path $portableBase "Windows Kits\10\Include"
$wkInc = (Get-ChildItem $wkIncBase -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName
$wkLibBase = Join-Path $portableBase "Windows Kits\10\Lib"
$wkLib = (Get-ChildItem $wkLibBase -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName
$wkBinBase = Join-Path $portableBase "Windows Kits\10\bin"
$wkBin = (Get-ChildItem $wkBinBase -Directory | Sort-Object Name -Descending | Select-Object -First 1).FullName

if ($x86) { 
    $arch = 'x86'
    $hostArch = 'Hostx86'
} else { 
    $arch = 'x64' 
    $hostArch = 'Hostx64'
}

$env:PATH = "$vcDir\bin\$hostArch\$arch;$wkBin\$arch;" + $env:PATH

$sysIncludes = @(
    "$vcDir\include",
    "$wkInc\ucrt",
    "$wkInc\shared",
    "$wkInc\um",
    "$wkInc\winrt",
    "$wkInc\cppwinrt"
)
$env:INCLUDE = ($sysIncludes -join ";") + ";" + $env:INCLUDE

$sysLibs = @(
    "$vcDir\lib\$arch",
    "$wkLib\ucrt\$arch",
    "$wkLib\um\$arch"
)
$env:LIB = ($sysLibs -join ";") + ";" + $env:LIB

# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?# 缂栬瘧/閾炬帴鏍囧織鏋勫缓锛坈onfig 棰勮 + 瀛楁瑕嗙洊锛?# 鍩轰簬 VS2026 v180 MSBuild 瀹樻柟灞炴€?(Microsoft.Cl.Common.props / Microsoft.Link.Common.props)
# 鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺愨晲鈺?
# config 棰勮瀹氫箟锛堝榻?VS 椤圭洰妯℃澘锛岄潪 toolset 瑁搁粯璁わ級
$presets = @{
    debug = @{
        optimize = 'off';       runtime = 'dynamic';   warnings = 'default'
        warn_as_error = $false; debug_info = 'edit';    exceptions = 'sync'
        rtc = $true;            jmc = $true;            security = $true
        conformance = $false;   fp_model = 'precise';   ltcg = $false
        incremental_link = $true
        auto_defines = @('_DEBUG')
    }
    release = @{
        optimize = 'speed';     runtime = 'dynamic';   warnings = 'default'
        warn_as_error = $false; debug_info = 'pdb';     exceptions = 'sync'
        rtc = $false;           jmc = $false;           security = $true
        conformance = $false;   fp_model = 'precise';   ltcg = $true
        incremental_link = $false
        auto_defines = @('NDEBUG')
    }
}

# 瑙ｆ瀽棰勮锛圕LI -config > JSON config锛?$preset = $null
$cfgConfigSrc = if ($PSBoundParameters.ContainsKey('config')) { $config } elseif ($cfg -and $cfg.config) { $cfg.config } else { $null }
if ($cfgConfigSrc) {
    if ($presets.ContainsKey($cfgConfigSrc)) {
        $preset = $presets[$cfgConfigSrc]
    } else {
        Write-Host "[璀﹀憡] 鏈煡 config: $cfgConfigSrc锛屽拷鐣? -ForegroundColor Yellow
    }
}

# 杈呭姪鍑芥暟锛欳LI > JSON > 棰勮 > fallback
function Get-CfgVal($field, $fallback) {
    # CLI 鍙傛暟鏈€浼樺厛
    if ($PSBoundParameters.ContainsKey($field)) { return $PSBoundParameters[$field] }
    # JSON 瀛楁
    if ($cfg -and $null -ne (& { try { $cfg.$field } catch { $null } })) {
        return $cfg.$field
    }
    if ($preset -and $preset.ContainsKey($field)) { return $preset[$field] }
    return $fallback
}

# 瑙ｆ瀽鍚勫瓧娈?$cfgOptimize        = Get-CfgVal 'optimize'         $null
$cfgRuntime         = Get-CfgVal 'runtime'           $null
$cfgWarnings        = Get-CfgVal 'warnings'          'default'
$cfgWarnAsError     = Get-CfgVal 'warn_as_error'     $false
$cfgDebugInfo       = Get-CfgVal 'debug_info'        $null
$cfgExceptions      = Get-CfgVal 'exceptions'        'sync'
$cfgRtc             = Get-CfgVal 'rtc'               $false
$cfgJmc             = Get-CfgVal 'jmc'               $false
$cfgSecurity        = Get-CfgVal 'security'          $false
$cfgConformance     = Get-CfgVal 'conformance'       $false
$cfgFpModel         = Get-CfgVal 'fp_model'          $null
$cfgLtcg            = Get-CfgVal 'ltcg'              $false
$cfgIncrLink        = Get-CfgVal 'incremental_link'  $null
# config 鏉ユ簮锛欳LI > JSON
$activeConfig = if ($PSBoundParameters.ContainsKey('config')) { $config } elseif ($cfg -and $cfg.config) { $cfg.config } else { $null }
$isDebug = ($activeConfig -eq 'debug')

# 鈹€鈹€ 缂栬瘧鏍囧織 鈹€鈹€
$baseFlags = '/nologo /utf-8'

# warnings
$warnMap = @{ off = '/W0'; basic = '/W1'; default = '/W3'; high = '/W4'; all = '/Wall' }
if ($warnMap.ContainsKey($cfgWarnings)) { $baseFlags += " $($warnMap[$cfgWarnings])" }
else { $baseFlags += ' /W3' }
if ($cfgWarnAsError) { $baseFlags += ' /WX' }

# exceptions
$excMap = @{ sync = '/EHsc'; async = '/EHa'; none = '' }
if ($excMap.ContainsKey($cfgExceptions) -and $excMap[$cfgExceptions]) {
    $baseFlags += " $($excMap[$cfgExceptions])"
}

# optimize
$optMap = @{ off = '/Od'; size = '/O1'; speed = '/O2'; full = '/Ox' }
if ($cfgOptimize -and $optMap.ContainsKey($cfgOptimize)) {
    $baseFlags += " $($optMap[$cfgOptimize])"
    if ($cfgOptimize -eq 'speed') { $baseFlags += ' /Oi' }
}

# runtime
if ($cfgRuntime) {
    $rtMap = @{ dynamic = '/MD'; static = '/MT' }
    if ($rtMap.ContainsKey($cfgRuntime)) {
        $rtFlag = $rtMap[$cfgRuntime]
        if ($isDebug) { $rtFlag += 'd' }
        $baseFlags += " $rtFlag"
    }
}

# debug info
$diMap = @{ off = ''; pdb = '/Zi'; edit = '/ZI'; embedded = '/Z7' }
if ($cfgDebugInfo -and $diMap.ContainsKey($cfgDebugInfo) -and $diMap[$cfgDebugInfo]) {
    $baseFlags += " $($diMap[$cfgDebugInfo])"
}

# runtime checks (debug only)
if ($cfgRtc -and $isDebug) { $baseFlags += ' /RTC1' }

# Just My Code (debug only)
if ($cfgJmc -and $isDebug) { $baseFlags += ' /JMC' }

# security
if ($cfgSecurity) { $baseFlags += ' /GS /sdl' }

# floating point model
$fpMap = @{ precise = '/fp:precise'; strict = '/fp:strict'; fast = '/fp:fast' }
if ($cfgFpModel -and $fpMap.ContainsKey($cfgFpModel)) {
    $baseFlags += " $($fpMap[$cfgFpModel])"
}

# conformance
if ($cfgConformance) { $baseFlags += ' /permissive- /Zc:__cplusplus /Zc:preprocessor' }

# LTCG (compiler side)
if ($cfgLtcg -and -not $isDebug) { $baseFlags += ' /GL /Gy' }

# 鍥哄畾鏍囧織锛圡SBuild 榛樿濮嬬粓寮€鍚級
$baseFlags += ' /Zc:forScope /Zc:wchar_t /FC /diagnostics:column'

# config 鑷姩 defines
if ($preset -and $preset.auto_defines) {
    foreach ($ad in $preset.auto_defines) { $baseFlags += " /D$ad" }
}

# charset (CLI > JSON)
$cfgCharset = if ($PSBoundParameters.ContainsKey('charset')) { $charset } elseif ($cfg -and $cfg.charset) { $cfg.charset } else { $null }
if ($cfgCharset) {
    if ($cfgCharset -eq 'unicode') { $baseFlags += ' /DUNICODE /D_UNICODE' }
    elseif ($cfgCharset -eq 'mbcs') { $baseFlags += ' /D_MBCS' }
}

# 鐢ㄦ埛 defines锛圝SON + CLI 鍚堝苟锛?if ($cfg -and $cfg.defines) {
    foreach ($def in $cfg.defines) { $baseFlags += " /D$def" }
}
if ($defines) {
    foreach ($def in $defines) { $baseFlags += " /D$def" }
}

# 鍘熷 flags锛圝SON + CLI 鍚堝苟锛?if ($cfg -and $cfg.flags) {
    foreach ($flag in $cfg.flags) { $baseFlags += " $flag" }
}
if ($PSBoundParameters.ContainsKey('flags') -and $flags) {
    foreach ($flag in $flags) { $baseFlags += " $flag" }
}

# C++ 鏍囧噯
if ($hasCpp -and $std) {
    $baseFlags += " /std:c++$std"
}
elseif ($ixxFiles.Count -gt 0 -and -not $std) {
    $baseFlags += ' /std:c++latest'
}

# include 璺緞
foreach ($inc in $I) {
    $baseFlags += " /I`"$inc`""
}
if ($cfg -and $cfg.include) {
    foreach ($inc in $cfg.include) {
        if ([System.IO.Path]::IsPathRooted($inc)) { $resolved = $inc } else { $resolved = Join-Path $cfgFoundDir $inc }
        $baseFlags += " /I`"$resolved`""
    }
}

# 鈹€鈹€ 閾炬帴鏍囧織 鈹€鈹€
$linkFlags = ''
$allLibPaths = @()
if ($L) { $allLibPaths += $L }
if ($cfg -and $cfg.libpath) {
    foreach ($lp in $cfg.libpath) {
        if ([System.IO.Path]::IsPathRooted($lp)) { $resolved = $lp } else { $resolved = Join-Path $cfgFoundDir $lp }
        $allLibPaths += $resolved
    }
}

# 鍒ゆ柇鏄惁闇€瑕?/link 娈?$cfgSubsystem = if ($PSBoundParameters.ContainsKey('subsystem')) { $subsystem } elseif ($cfg -and $cfg.subsystem) { $cfg.subsystem } else { $null }
$needLinkSection = ($allLibPaths.Count -gt 0) -or $cfgSubsystem -or $preset -or ($cfg -and $cfg.link_flags) -or ($PSBoundParameters.ContainsKey('link_flags') -and $link_flags)
if ($needLinkSection) {
    $linkFlags = ' /link'
    foreach ($lp in $allLibPaths) { $linkFlags += " /LIBPATH:`"$lp`"" }
    if ($cfgSubsystem) {
        $linkFlags += " /SUBSYSTEM:$($cfgSubsystem.ToUpper())"
    }
    # config 閾炬帴棰勮
    if ($preset) {
        $linkFlags += ' /DEBUG:FULL /DYNAMICBASE /NXCOMPAT'
        if ($cfgLtcg -and -not $isDebug) {
            $linkFlags += ' /LTCG /OPT:REF /OPT:ICF /INCREMENTAL:NO'
        }
        elseif ($cfgIncrLink) {
            $linkFlags += ' /INCREMENTAL'
        }
        else {
            $linkFlags += ' /INCREMENTAL:NO'
        }
    }
    # 鍘熷 link_flags锛圝SON + CLI 鍚堝苟锛?    if ($cfg -and $cfg.link_flags) {
        foreach ($lf in $cfg.link_flags) { $linkFlags += " $lf" }
    }
    if ($PSBoundParameters.ContainsKey('link_flags') -and $link_flags) {
        foreach ($lf in $link_flags) { $linkFlags += " $lf" }
    }
}
$libFiles = ''
$allLibs = @()
if ($libs) { $allLibs += $libs }
if ($cfg -and $cfg.libs) { $allLibs += $cfg.libs }
foreach ($lib in $allLibs) {
    $libFiles += " `"$lib.lib`""
}

if ($x86) { $arch = 'x86' } else { $arch = 'x64' }

Write-Host ''
$allFileNames = ($files | ForEach-Object { [System.IO.Path]::GetFileName($_) }) -join ', '
Write-Host "[缂栬瘧] $allFileNames -> $o.exe" -ForegroundColor Cyan

if ($ixxFiles.Count -gt 0) {
    Write-Host "[妯″潡] 妫€娴嬪埌 .ixx 妯″潡锛屾壂鎻忎緷璧栧叧绯?.." -ForegroundColor Magenta

    $scanDir = Join-Path $env:TEMP "msvc_build_scan_$$"
    New-Item $scanDir -ItemType Directory -Force | Out-Null

    # 鎵归噺鎵弿锛氬彧璋冧竴娆?vcvarsall锛屾墍鏈?.ixx 涓€璧锋壂
    $scanBat = Join-Path $scanDir '_scan_all.bat'
    $batLines = @("@echo off", "chcp 65001 >nul")
    foreach ($ixx in $ixxFiles) {
        $ixxName = [System.IO.Path]::GetFileNameWithoutExtension($ixx)
        $depJson = Join-Path $scanDir "$ixxName.dep.json"
        $batLines += "cl $baseFlags /scanDependencies `"$depJson`" /c `"$ixx`" >nul 2>&1"
        $batLines += "if errorlevel 1 exit /b 1"
    }
    $batLines -join "`r`n" | Set-Content $scanBat -Encoding utf8
    cmd.exe /c "`"$scanBat`"" 2>$null >$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[閿欒] 渚濊禆鎵弿澶辫触" -ForegroundColor Red
        Remove-Item $scanDir -Recurse -Force -ErrorAction SilentlyContinue
        exit 1
    }

    $modNameToFile = @{}
    $modFileToRequires = @{}
    $usesImportStd = $false
    $usesImportStdCompat = $false

    foreach ($ixx in $ixxFiles) {
        $ixxName = [System.IO.Path]::GetFileNameWithoutExtension($ixx)
        $depJson = Join-Path $scanDir "$ixxName.dep.json"
        if (-not (Test-Path $depJson)) {
            Write-Host "[閿欒] 渚濊禆鎵弿澶辫触: $([System.IO.Path]::GetFileName($ixx))" -ForegroundColor Red
            Remove-Item $scanDir -Recurse -Force -ErrorAction SilentlyContinue
            exit 1
        }

        $dep = Get-Content $depJson -Raw | ConvertFrom-Json
        $rule = $dep.rules[0]

        if ($rule.provides) {
            foreach ($p in $rule.provides) {
                $modNameToFile[$p.'logical-name'] = $ixx
            }
        }

        $requires = @()
        if ($rule.requires) {
            foreach ($r in $rule.requires) {
                $name = $r.'logical-name'
                if ($name -eq 'std') { $usesImportStd = $true }
                elseif ($name -eq 'std.compat') { $usesImportStdCompat = $true; $usesImportStd = $true }
                else { $requires += $name }
            }
        }
        $modFileToRequires[$ixx] = $requires
    }

    Remove-Item $scanDir -Recurse -Force -ErrorAction SilentlyContinue

    $stdModObjs = @()
    if ($usesImportStd) {
        $cacheDir = Join-Path $env:TEMP 'msvc_std_module_cache'
        $stdObjCached = Join-Path $cacheDir 'std.obj'
        $stdIfcCached = Join-Path $cacheDir 'std.ifc'

        if ((Test-Path $stdObjCached) -and (Test-Path $stdIfcCached)) {
            Write-Host "[鏍囧噯] 浣跨敤缂撳瓨鐨?std 妯″潡" -ForegroundColor DarkGray
            Copy-Item $stdObjCached, $stdIfcCached $PWD -Force
        }
        else {
            $msvcToolsDir = Join-Path $vsPath 'VC\Tools\MSVC'
            $msvcVer = Get-ChildItem $msvcToolsDir -Directory | Sort-Object Name -Descending | Select-Object -First 1
            $stdIxx = Join-Path $msvcVer.FullName 'modules\std.ixx'
            if (-not (Test-Path $stdIxx)) {
                Write-Host "[閿欒] 鏈壘鍒?std.ixx: $stdIxx" -ForegroundColor Red
                exit 1
            }

            Write-Host "[鏍囧噯] 棣栨缂栬瘧 std 妯″潡锛堢紪璇戝悗灏嗙紦瀛橈級..." -ForegroundColor DarkGray
            $stdCmd = "cl $baseFlags /c /interface `"$stdIxx`""
            cmd.exe /c $stdCmd
            if ($LASTEXITCODE -ne 0) {
                Write-Host '[閿欒] std 妯″潡缂栬瘧澶辫触' -ForegroundColor Red
                exit 1
            }

            if (-not (Test-Path $cacheDir)) { New-Item $cacheDir -ItemType Directory -Force | Out-Null }
            Copy-Item (Join-Path $PWD 'std.obj'), (Join-Path $PWD 'std.ifc') $cacheDir -Force
        }
        $stdModObjs += 'std.obj'
    }

    if ($usesImportStdCompat) {
        $cacheDir = Join-Path $env:TEMP 'msvc_std_module_cache'
        $compatObjCached = Join-Path $cacheDir 'std.compat.obj'
        $compatIfcCached = Join-Path $cacheDir 'std.compat.ifc'

        if ((Test-Path $compatObjCached) -and (Test-Path $compatIfcCached)) {
            Write-Host "[鏍囧噯] 浣跨敤缂撳瓨鐨?std.compat 妯″潡" -ForegroundColor DarkGray
            Copy-Item $compatObjCached, $compatIfcCached $PWD -Force
        }
        else {
            $msvcToolsDir = Join-Path $vsPath 'VC\Tools\MSVC'
            $msvcVer = Get-ChildItem $msvcToolsDir -Directory | Sort-Object Name -Descending | Select-Object -First 1
            $compatIxx = Join-Path $msvcVer.FullName 'modules\std.compat.ixx'
            if (-not (Test-Path $compatIxx)) {
                Write-Host "[閿欒] 鏈壘鍒?std.compat.ixx: $compatIxx" -ForegroundColor Red
                exit 1
            }

            Write-Host "[鏍囧噯] 棣栨缂栬瘧 std.compat 妯″潡锛堢紪璇戝悗灏嗙紦瀛橈級..." -ForegroundColor DarkGray
            $compatCmd = "cl $baseFlags /c /interface `"$compatIxx`""
            cmd.exe /c $compatCmd
            if ($LASTEXITCODE -ne 0) {
                Write-Host '[閿欒] std.compat 妯″潡缂栬瘧澶辫触' -ForegroundColor Red
                exit 1
            }

            if (-not (Test-Path $cacheDir)) { New-Item $cacheDir -ItemType Directory -Force | Out-Null }
            Copy-Item (Join-Path $PWD 'std.compat.obj'), (Join-Path $PWD 'std.compat.ifc') $cacheDir -Force
        }
        $stdModObjs += 'std.compat.obj'
    }

    $inDegree = @{}
    $graph = @{}
    foreach ($ixx in $ixxFiles) {
        $inDegree[$ixx] = 0
        $graph[$ixx] = @()
    }
    foreach ($ixx in $ixxFiles) {
        foreach ($dep in $modFileToRequires[$ixx]) {
            if ($modNameToFile.ContainsKey($dep)) {
                $depFile = $modNameToFile[$dep]
                $graph[$depFile] += $ixx
                $inDegree[$ixx]++
            }
        }
    }

    $queue = [System.Collections.Queue]::new()
    foreach ($ixx in $ixxFiles) {
        if ($inDegree[$ixx] -eq 0) { $queue.Enqueue($ixx) }
    }
    $sorted = @()
    while ($queue.Count -gt 0) {
        $cur = $queue.Dequeue()
        $sorted += $cur
        foreach ($next in $graph[$cur]) {
            $inDegree[$next]--
            if ($inDegree[$next] -eq 0) { $queue.Enqueue($next) }
        }
    }

    if ($sorted.Count -ne $ixxFiles.Count) {
        Write-Host '[閿欒] 妯″潡涔嬮棿瀛樺湪寰幆渚濊禆' -ForegroundColor Red
        exit 1
    }

    # 妯″潡澧為噺缂栬瘧缂撳瓨锛堜娇鐢ㄧ‘瀹氭€у搱甯岋級
    $projPath = [System.IO.Path]::GetFullPath($PWD.Path).ToLower()
    $projHash = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($projPath))).Replace('-','').Substring(0,8)
    $modCacheDir = Join-Path $env:TEMP "msvc_mod_cache\$projHash"
    if (-not (Test-Path $modCacheDir)) { New-Item $modCacheDir -ItemType Directory -Force | Out-Null }

    # 棰勫厛鎭㈠鎵€鏈夌紦瀛樼殑 .ifc锛圡SVC 鎸夋ā鍧楀悕鍛藉悕锛岄潪婧愭枃浠跺悕锛?    Get-ChildItem $modCacheDir -Filter '*.ifc' -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $PWD $_.Name) -Force
    }

    $recompiled = @{}
    $skippedCount = 0

    foreach ($ixx in $sorted) {
        $ixxName = [System.IO.Path]::GetFileName($ixx)
        $objName = [System.IO.Path]::ChangeExtension($ixxName, '.obj')
        $cachedObj = Join-Path $modCacheDir $objName

        # 鍒ゆ柇鏄惁闇€瑕侀噸缂栵細缂撳瓨涓嶅瓨鍦?/ 婧愭枃浠舵洿鏂?/ 渚濊禆琚噸缂?        $needRecompile = $false
        if (-not (Test-Path $cachedObj)) {
            $needRecompile = $true
        }
        elseif ((Get-Item $ixx).LastWriteTime -gt (Get-Item $cachedObj).LastWriteTime) {
            $needRecompile = $true
        }
        else {
            foreach ($dep in $modFileToRequires[$ixx]) {
                if ($modNameToFile.ContainsKey($dep) -and $recompiled.ContainsKey($modNameToFile[$dep])) {
                    $needRecompile = $true; break
                }
            }
        }

        if ($needRecompile) {
            Write-Host "[妯″潡] 缂栬瘧 $ixxName" -ForegroundColor Magenta
            $ixxCmd = "cl $baseFlags /c /interface `"$ixx`""
            cmd.exe /c $ixxCmd
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[閿欒] 妯″潡缂栬瘧澶辫触: $ixxName" -ForegroundColor Red
                exit 1
            }
            # 缂撳瓨 .obj
            $localObj = Join-Path $PWD $objName
            if (Test-Path $localObj) { Copy-Item $localObj $cachedObj -Force }
            # 缂撳瓨鎵€鏈夋柊浜х敓鐨?.ifc
            Get-ChildItem $PWD -Filter '*.ifc' -ErrorAction SilentlyContinue | ForEach-Object {
                Copy-Item $_.FullName (Join-Path $modCacheDir $_.Name) -Force
            }
            $recompiled[$ixx] = $true
        }
        else {
            $skippedCount++
            # 鎭㈠ .obj
            Copy-Item $cachedObj (Join-Path $PWD $objName) -Force
        }
    }

    if ($skippedCount -gt 0) {
        Write-Host "[妯″潡] $skippedCount 涓ā鍧楁湭淇敼锛屼娇鐢ㄧ紦瀛? -ForegroundColor DarkGray
    }

    $modObjs = @()
    $modObjs += $stdModObjs
    foreach ($ixx in $ixxFiles) {
        $modObjs += [System.IO.Path]::ChangeExtension([System.IO.Path]::GetFileName($ixx), '.obj')
    }
    $modObjList = ($modObjs | ForEach-Object { "`"$_`"" }) -join ' '

    if ($cppFiles.Count -gt 0) {
        $cppQuoted = ($cppFiles | ForEach-Object { "`"$_`"" }) -join ' '
        Write-Host "[閾炬帴] 缂栬瘧婧愭枃浠跺苟閾炬帴..." -ForegroundColor Magenta
        $linkCmd = "cl $baseFlags /Fe:`"$exe`" $cppQuoted $modObjList$libFiles$linkFlags"
        cmd.exe /c $linkCmd
    }
    else {
        $linkCmd = "cl $baseFlags /Fe:`"$exe`" $modObjList$libFiles$linkFlags"
        cmd.exe /c $linkCmd
    }
}
else {
    $srcList = ($files | ForEach-Object { "`"$_`"" }) -join ' '
    $cmdLine = "cl $baseFlags /Fe:`"$exe`" $srcList$libFiles$linkFlags"
    cmd.exe /c $cmdLine
}

if ($LASTEXITCODE -ne 0) {
    Write-Host '[閿欒] 缂栬瘧澶辫触' -ForegroundColor Red
    exit 1
}
Write-Host "[鎴愬姛] $o.exe" -ForegroundColor Green

Get-ChildItem $PWD -Filter '*.obj' -File -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem $PWD -Filter '*.ifc' -File -ErrorAction SilentlyContinue | Remove-Item -Force

if ($run) {
    Write-Host ''
    Write-Host "[杩愯] $o.exe $ProgramArgs" -ForegroundColor Yellow
    Write-Host ('=' * 40) -ForegroundColor DarkGray
    if ($ProgramArgs) {
        & $exe ($ProgramArgs -split ' ')
    }
    else {
        & $exe
    }
    $code = $LASTEXITCODE
    Write-Host ('=' * 40) -ForegroundColor DarkGray
    Write-Host "[缁撴潫] 閫€鍑虹爜: $code" -ForegroundColor DarkGray
}
