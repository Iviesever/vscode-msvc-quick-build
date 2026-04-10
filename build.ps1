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

    [Alias('h', '?')]
    [switch]$help
)

if ($help -or -not $Sources) {
    Write-Host ''
    Write-Host 'build' -NoNewline -ForegroundColor Cyan
    Write-Host ' — MSVC 快速编译工具' -ForegroundColor DarkGray
    Write-Host ''
    Write-Host '  用法：' -ForegroundColor DarkCyan
    Write-Host '    build <源文件...> [选项]'
    Write-Host ''
    Write-Host '  选项：' -ForegroundColor DarkCyan
    Write-Host '    -o <名称>       指定输出文件名（不含 .exe）'
    Write-Host '    -run            编译成功后自动运行'
    Write-Host '    -std <版本>     C++ 标准：14 / 17 / 20 / 23 / latest'
    Write-Host '    -a <参数>       传递给程序的命令行参数'
    Write-Host '    -x86            编译为 32 位（默认 64 位）'
    Write-Host '    -smart          智能模式：自动追踪 #include / import 关联文件'
    Write-Host '    -I <路径...>    额外的头文件搜索路径（可多个）'
    Write-Host '    -L <路径...>    额外的库文件搜索路径（可多个）'
    Write-Host '    -libs <库名...>   要链接的库（不含 .lib，可多个）'
    Write-Host '    -help           显示此帮助'
    Write-Host ''
    Write-Host '  示例：' -ForegroundColor DarkCyan
    Write-Host '    build main.c -run                                 单文件编译运行'
    Write-Host '    build *.cpp -o app -std 23 -run                   多文件 + C++23'
    Write-Host '    build main.cpp mod.ixx -o app -std latest -run    C++ Modules'
    Write-Host '    build solver.c -run -a "input.txt 42"             传参运行'
    Write-Host '    build main.cpp -I D:\libs\SDL2\include -L D:\libs\SDL2\lib -libs SDL2,SDL2main -run'
    Write-Host '    build main.cpp -smart -std latest -run                    智能追踪依赖'
    Write-Host ''
    Write-Host '  支持的文件类型：' -ForegroundColor DarkCyan
    Write-Host '    .c              C 源文件'
    Write-Host '    .cpp .cxx .cc   C++ 源文件'
    Write-Host '    .ixx            C++ 模块接口（自动用 /interface 编译）'
    Write-Host ''
    Write-Host '  特性：' -ForegroundColor DarkCyan
    Write-Host '    · 自动检测并初始化 MSVC 编译环境（无需手动调用 vcvarsall.bat）'
    Write-Host '    · 支持 import std; 和 import std.compat;（首次自动编译，后续使用缓存）'
    Write-Host '    · 多 .ixx 模块自动分析依赖、拓扑排序，无需手动排列顺序'
    Write-Host '    · -smart 智能追踪：自动通过 #include 和 import 发现关联文件'
    Write-Host '    · 支持 -I -L -libs 指定第三方库的路径和链接'
    Write-Host '    · msvc_list.json 项目配置：定义宏、链接库、编译选项（可选）'
    Write-Host '    · 通配符自动过滤，只编译源文件，忽略 .h .hpp .txt 等'
    Write-Host '    · 增量构建：代码未修改时跳过编译，直接运行'
    Write-Host '    · 编译产物自动清理（.obj .ifc）'
    Write-Host ''
    Write-Host '  详细文档：' -NoNewline -ForegroundColor DarkCyan
    Write-Host ' README.md' -ForegroundColor DarkGray
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
        Write-Host "[错误] 文件不存在: $src" -ForegroundColor Red
        exit 1
    }
}

if ($files.Count -eq 0) {
    Write-Host '[错误] 未指定源文件' -ForegroundColor Red
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
        # exclude 模式过滤
        if ($cfg -and $cfg.exclude) {
            $fn = [System.IO.Path]::GetFileName($_)
            foreach ($pat in $cfg.exclude) {
                if ($fn -like $pat) { return $false }
            }
        }
        return $true
    } | Sort-Object)

    if ($files.Count -eq 0) {
        Write-Host '[错误] 未发现可编译的源文件' -ForegroundColor Red
        exit 1
    }

    if ($files.Count -gt 1) {
        if ($files.Count -le 8) {
            $discoveredNames = ($files | ForEach-Object { [System.IO.Path]::GetFileName($_) }) -join ', '
            Write-Host "[智能] 关联: $discoveredNames" -ForegroundColor DarkGray
        } else {
            $first5 = ($files | Select-Object -First 5 | ForEach-Object { [System.IO.Path]::GetFileName($_) }) -join ', '
            Write-Host "[智能] 关联: $first5, ... 共 $($files.Count) 个文件" -ForegroundColor DarkGray
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
# 增量构建：代码未修改时跳过编译
if (Test-Path $exe) {
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
        Write-Host "[跳过] 代码未修改" -ForegroundColor DarkGray
        if ($run) {
            Write-Host ''
            Write-Host "[运行] $o.exe $ProgramArgs" -ForegroundColor Yellow
            Write-Host ('=' * 40) -ForegroundColor DarkGray
            if ($ProgramArgs) {
                & $exe ($ProgramArgs -split ' ')
            }
            else {
                & $exe
            }
            $code = $LASTEXITCODE
            Write-Host ('=' * 40) -ForegroundColor DarkGray
            Write-Host "[结束] 退出码: $code" -ForegroundColor DarkGray
        }
        exit 0
    }
}

# msvc_list.json 项目配置（向上查找）
$cfg = $null
$cfgFoundDir = $null
$searchDir = $PWD.Path
for ($i = 0; $i -lt 5; $i++) {
    $cfgPath = Join-Path $searchDir 'msvc_list.json'
    if (Test-Path $cfgPath) {
        $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
        $cfgFoundDir = $searchDir
        Write-Host "[配置] msvc_list.json" -ForegroundColor DarkGray
        break
    }
    $parent = [System.IO.Path]::GetDirectoryName($searchDir)
    if (-not $parent -or $parent -eq $searchDir) { break }
    $searchDir = $parent
}

if ($cfg -and -not $std -and $cfg.std) { $std = $cfg.std }
# output 优先级：命令行 -o > JSON output > 自动检测
if ($cfg -and $cfg.output -and -not $PSBoundParameters.ContainsKey('o')) { $o = $cfg.output }
$exe = Join-Path $PWD "$o.exe"

$hasCpp = ($cppFiles | Where-Object { $_ -match '\.(cpp|cxx|cc)$' }) -or ($ixxFiles.Count -gt 0)

$pf86 = [System.Environment]::GetFolderPath('ProgramFilesX86')
$vswhere = Join-Path $pf86 'Microsoft Visual Studio\Installer\vswhere.exe'
$vsPath = $null

if (Test-Path $vswhere) {
    $vsPath = (& $vswhere -latest -property installationPath 2>$null)
    if ($vsPath) { $vsPath = $vsPath.Trim() }
}

if (-not $vsPath) {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\18\Community'),
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\18\Professional'),
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\2022\Community'),
        (Join-Path $env:ProgramFiles 'Microsoft Visual Studio\2022\Professional')
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { $vsPath = $c; break }
    }
}

if (-not $vsPath) {
    Write-Host '[错误] 未找到 Visual Studio' -ForegroundColor Red
    exit 1
}

$vcvars = Join-Path $vsPath 'VC\Auxiliary\Build\vcvarsall.bat'
if (-not (Test-Path $vcvars)) {
    Write-Host '[错误] 未找到 vcvarsall.bat' -ForegroundColor Red
    exit 1
}

$warnLevel = '/W3'
if ($cfg -and $cfg.flags) {
    foreach ($flag in $cfg.flags) {
        if ($flag -match '^/W\d|^/Wall') { $warnLevel = $flag }
    }
}
$baseFlags = "/nologo $warnLevel /utf-8 /EHsc"
# charset: unicode / mbcs
if ($cfg -and $cfg.charset) {
    if ($cfg.charset -eq 'unicode') { $baseFlags += ' /DUNICODE /D_UNICODE' }
    elseif ($cfg.charset -eq 'mbcs') { $baseFlags += ' /D_MBCS' }
}
if ($cfg -and $cfg.defines) {
    foreach ($def in $cfg.defines) { $baseFlags += " /D$def" }
}
if ($cfg -and $cfg.flags) {
    foreach ($flag in $cfg.flags) {
        if ($flag -notmatch '^/W\d|^/Wall') { $baseFlags += " $flag" }
    }
}
if ($hasCpp -and $std) {
    $baseFlags += " /std:c++$std"
}
elseif ($ixxFiles.Count -gt 0 -and -not $std) {
    $baseFlags += ' /std:c++latest'
}
foreach ($inc in $I) {
    $baseFlags += " /I`"$inc`""
}
if ($cfg -and $cfg.include) {
    foreach ($inc in $cfg.include) {
        if ([System.IO.Path]::IsPathRooted($inc)) { $resolved = $inc } else { $resolved = Join-Path $cfgFoundDir $inc }
        $baseFlags += " /I`"$resolved`""
    }
}

$linkFlags = ''
$allLibPaths = @()
if ($L) { $allLibPaths += $L }
if ($cfg -and $cfg.libpath) {
    foreach ($lp in $cfg.libpath) {
        if ([System.IO.Path]::IsPathRooted($lp)) { $resolved = $lp } else { $resolved = Join-Path $cfgFoundDir $lp }
        $allLibPaths += $resolved
    }
}
if ($allLibPaths.Count -gt 0 -or ($cfg -and $cfg.subsystem)) {
    $linkFlags = ' /link'
    foreach ($lp in $allLibPaths) { $linkFlags += " /LIBPATH:`"$lp`"" }
    if ($cfg -and $cfg.subsystem) {
        $linkFlags += " /SUBSYSTEM:$($cfg.subsystem.ToUpper())"
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
Write-Host "[编译] $allFileNames -> $o.exe" -ForegroundColor Cyan

if ($ixxFiles.Count -gt 0) {
    Write-Host "[模块] 检测到 .ixx 模块，扫描依赖关系..." -ForegroundColor Magenta

    $scanDir = Join-Path $env:TEMP "msvc_build_scan_$$"
    New-Item $scanDir -ItemType Directory -Force | Out-Null

    # 批量扫描：只调一次 vcvarsall，所有 .ixx 一起扫
    $scanBat = Join-Path $scanDir '_scan_all.bat'
    $batLines = @("@echo off", "call `"$vcvars`" $arch >nul 2>&1")
    foreach ($ixx in $ixxFiles) {
        $ixxName = [System.IO.Path]::GetFileNameWithoutExtension($ixx)
        $depJson = Join-Path $scanDir "$ixxName.dep.json"
        $batLines += "cl $baseFlags /scanDependencies `"$depJson`" /c `"$ixx`" >nul 2>&1"
        $batLines += "if errorlevel 1 exit /b 1"
    }
    $batLines -join "`r`n" | Set-Content $scanBat -Encoding ASCII
    cmd.exe /c "`"$scanBat`"" 2>$null >$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[错误] 依赖扫描失败" -ForegroundColor Red
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
            Write-Host "[错误] 依赖扫描失败: $([System.IO.Path]::GetFileName($ixx))" -ForegroundColor Red
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
            Write-Host "[标准] 使用缓存的 std 模块" -ForegroundColor DarkGray
            Copy-Item $stdObjCached, $stdIfcCached $PWD -Force
        }
        else {
            $msvcToolsDir = Join-Path $vsPath 'VC\Tools\MSVC'
            $msvcVer = Get-ChildItem $msvcToolsDir -Directory | Sort-Object Name -Descending | Select-Object -First 1
            $stdIxx = Join-Path $msvcVer.FullName 'modules\std.ixx'
            if (-not (Test-Path $stdIxx)) {
                Write-Host "[错误] 未找到 std.ixx: $stdIxx" -ForegroundColor Red
                exit 1
            }

            Write-Host "[标准] 首次编译 std 模块（编译后将缓存）..." -ForegroundColor DarkGray
            $stdCmd = "call `"$vcvars`" $arch >nul 2>&1 && cl $baseFlags /c /interface `"$stdIxx`""
            cmd.exe /c $stdCmd
            if ($LASTEXITCODE -ne 0) {
                Write-Host '[错误] std 模块编译失败' -ForegroundColor Red
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
            Write-Host "[标准] 使用缓存的 std.compat 模块" -ForegroundColor DarkGray
            Copy-Item $compatObjCached, $compatIfcCached $PWD -Force
        }
        else {
            $msvcToolsDir = Join-Path $vsPath 'VC\Tools\MSVC'
            $msvcVer = Get-ChildItem $msvcToolsDir -Directory | Sort-Object Name -Descending | Select-Object -First 1
            $compatIxx = Join-Path $msvcVer.FullName 'modules\std.compat.ixx'
            if (-not (Test-Path $compatIxx)) {
                Write-Host "[错误] 未找到 std.compat.ixx: $compatIxx" -ForegroundColor Red
                exit 1
            }

            Write-Host "[标准] 首次编译 std.compat 模块（编译后将缓存）..." -ForegroundColor DarkGray
            $compatCmd = "call `"$vcvars`" $arch >nul 2>&1 && cl $baseFlags /c /interface `"$compatIxx`""
            cmd.exe /c $compatCmd
            if ($LASTEXITCODE -ne 0) {
                Write-Host '[错误] std.compat 模块编译失败' -ForegroundColor Red
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
        Write-Host '[错误] 模块之间存在循环依赖' -ForegroundColor Red
        exit 1
    }

    # 模块增量编译缓存（使用确定性哈希）
    $projPath = [System.IO.Path]::GetFullPath($PWD.Path).ToLower()
    $projHash = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($projPath))).Replace('-','').Substring(0,8)
    $modCacheDir = Join-Path $env:TEMP "msvc_mod_cache\$projHash"
    if (-not (Test-Path $modCacheDir)) { New-Item $modCacheDir -ItemType Directory -Force | Out-Null }

    # 预先恢复所有缓存的 .ifc（MSVC 按模块名命名，非源文件名）
    Get-ChildItem $modCacheDir -Filter '*.ifc' -ErrorAction SilentlyContinue | ForEach-Object {
        Copy-Item $_.FullName (Join-Path $PWD $_.Name) -Force
    }

    $recompiled = @{}
    $skippedCount = 0

    foreach ($ixx in $sorted) {
        $ixxName = [System.IO.Path]::GetFileName($ixx)
        $objName = [System.IO.Path]::ChangeExtension($ixxName, '.obj')
        $cachedObj = Join-Path $modCacheDir $objName

        # 判断是否需要重编：缓存不存在 / 源文件更新 / 依赖被重编
        $needRecompile = $false
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
            Write-Host "[模块] 编译 $ixxName" -ForegroundColor Magenta
            $ixxCmd = "call `"$vcvars`" $arch >nul 2>&1 && cl $baseFlags /c /interface `"$ixx`""
            cmd.exe /c $ixxCmd
            if ($LASTEXITCODE -ne 0) {
                Write-Host "[错误] 模块编译失败: $ixxName" -ForegroundColor Red
                exit 1
            }
            # 缓存 .obj
            $localObj = Join-Path $PWD $objName
            if (Test-Path $localObj) { Copy-Item $localObj $cachedObj -Force }
            # 缓存所有新产生的 .ifc
            Get-ChildItem $PWD -Filter '*.ifc' -ErrorAction SilentlyContinue | ForEach-Object {
                Copy-Item $_.FullName (Join-Path $modCacheDir $_.Name) -Force
            }
            $recompiled[$ixx] = $true
        }
        else {
            $skippedCount++
            # 恢复 .obj
            Copy-Item $cachedObj (Join-Path $PWD $objName) -Force
        }
    }

    if ($skippedCount -gt 0) {
        Write-Host "[模块] $skippedCount 个模块未修改，使用缓存" -ForegroundColor DarkGray
    }

    $modObjs = @()
    $modObjs += $stdModObjs
    foreach ($ixx in $ixxFiles) {
        $modObjs += [System.IO.Path]::ChangeExtension([System.IO.Path]::GetFileName($ixx), '.obj')
    }
    $modObjList = ($modObjs | ForEach-Object { "`"$_`"" }) -join ' '

    if ($cppFiles.Count -gt 0) {
        $cppQuoted = ($cppFiles | ForEach-Object { "`"$_`"" }) -join ' '
        Write-Host "[链接] 编译源文件并链接..." -ForegroundColor Magenta
        $linkCmd = "call `"$vcvars`" $arch >nul 2>&1 && cl $baseFlags /Fe:`"$exe`" $cppQuoted $modObjList$libFiles$linkFlags"
        cmd.exe /c $linkCmd
    }
    else {
        $linkCmd = "call `"$vcvars`" $arch >nul 2>&1 && cl $baseFlags /Fe:`"$exe`" $modObjList$libFiles$linkFlags"
        cmd.exe /c $linkCmd
    }
}
else {
    $srcList = ($files | ForEach-Object { "`"$_`"" }) -join ' '
    $cmdLine = "call `"$vcvars`" $arch >nul 2>&1 && cl $baseFlags /Fe:`"$exe`" $srcList$libFiles$linkFlags"
    cmd.exe /c $cmdLine
}

if ($LASTEXITCODE -ne 0) {
    Write-Host '[错误] 编译失败' -ForegroundColor Red
    exit 1
}
Write-Host "[成功] $o.exe" -ForegroundColor Green

Get-ChildItem $PWD -Filter '*.obj' -File -ErrorAction SilentlyContinue | Remove-Item -Force
Get-ChildItem $PWD -Filter '*.ifc' -File -ErrorAction SilentlyContinue | Remove-Item -Force

if ($run) {
    Write-Host ''
    Write-Host "[运行] $o.exe $ProgramArgs" -ForegroundColor Yellow
    Write-Host ('=' * 40) -ForegroundColor DarkGray
    if ($ProgramArgs) {
        & $exe ($ProgramArgs -split ' ')
    }
    else {
        & $exe
    }
    $code = $LASTEXITCODE
    Write-Host ('=' * 40) -ForegroundColor DarkGray
    Write-Host "[结束] 退出码: $code" -ForegroundColor DarkGray
}
