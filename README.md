# build — MSVC 快速编译工具

与 Visual Studio 2026 MSBuild **1:1 对齐** 的 C/C++ 快速编译工具。

**没有 `.sln`、`CMakeLists.txt`、`launch.json`，按下 F5 就能编译运行 C/C++。**

您可以选择下载 [“便携版”编译套件](https://www.123912.com/s/4Y1ovd-2sbad)（解压完仅 3.48 G），来代替下载完整的 [Visual Studio](visualstudio.microsoft.com)

> **模块化支持**：原生处理 C++20/23 Modules 及 `import std;`，内置模块缓存。
>
> **智能推导**：基于 `#include` 和 `import` 自动爬取并编译依赖文件。
>
> **增量构建**：仅重新编译修改的 `.obj` 与 `.ifc`，代码无变动则直接运行。
>
> **对齐 MSBuild**：基于 `msvc_list.json` 支持 Debug/Release 一键切换及数百个 MSVC 原生参数的平替。

------

文件目录

```cpp

```




> **首次使用 PowerShell 脚本？** 需要先在 PowerShell 中执行一次（仅需一次）：
>
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

## 一键安装



双击 `install.bat`，自动完成以下操作：

1. 部署 `build.ps1` 到 `%USERPROFILE%\bin\`
2. 部署 PowerShell profile（注册 `build` 命令）
3. 可选解压 `portable_msvc.zip` 便携版工具链

重启终端，输入 `build`，看到帮助信息即成功。



## 手动安装

```powershell
Copy-Item "build.ps1" "$HOME\bin\build.ps1" -Force
```

并在 PowerShell profile 中添加：

```powershell
function build { & pwsh.exe -NoProfile -File "$HOME\bin\build.ps1" @args }
```

解压便携版工具链，适用于在没有 VS 的机器上使用。

```powershell
# 解压编译器工具链（约 2GB）到 C:\Users\<用户名>\bin\portable_msvc
# ⚠️ Expand-Archive 解压巨量小文件极慢，强烈建议在文件管理器中手动解压！
Expand-Archive "portable_msvc.zip" "$HOME\bin\portable_msvc" -Force
```

------

## 简便使用：VS Code 按 F5 编译运行



`Ctrl+Shift+P` → `Open Keyboard Shortcuts (JSON)` → 添加：

```json
{
    "key": "f5",
    "command": "runCommands",
    "args": {
        "commands": [
            "workbench.action.terminal.focus",
            {
                "command": "workbench.action.terminal.sendSequence",
                "args": {
                    "text": "cd \"${fileDirname}\" ; build \"${fileBasename}\" -std latest -run\u000D"
                }
            }
        ]
    },
    "when": "resourceLangId == 'cpp' || resourceLangId == 'c'"
}
```



------

## 详细使用



### 方法一：命令行（CLI）

```bash
build main.cpp -run                               # 编译运行
build main.cpp -std latest -run                   # 指定 C++ 标准
build main.cpp -config debug -run                 # Debug 配置（1:1 MSBuild）
build main.cpp -config release -run               # Release 配置
build *.cpp -o app -std 23 -config release -run   # 多文件 + Release
build main.cpp mod.ixx -o app -std latest -run    # C++20 Modules
build solver.c -run -a "input.txt 42"             # 传参运行
build main.cpp -x86 -run                          # 32 位编译
build -env vs                                     # 强制使用本机 VS
```



### 方法二：配置 `msvc_list.json`

在项目目录创建 `msvc_list.json`，实现**零命令行参数的完整项目配置**。脚本会自动向上查找最多 5 层父目录。所有字段名与上表 JSON 列完全一致，CLI 传参会覆盖 JSON 同名字段。

#### 最简配置

```json
{ "config": "debug" }
```

一行即可获得完整的 VS Debug 配置（`/Od /MDd /RTC1 /JMC /ZI /GS /sdl ...`）。

#### 完整示例

```json
{
    "config": "debug",
    "std": "latest",
    "charset": "unicode",
    "output": "MyApp",
    "defines": ["WIN32_LEAN_AND_MEAN", "NOMINMAX"],
    "libs": ["d3d11", "dxgi"],
    "include": ["../vendor/include"],
    "libpath": ["../vendor/lib"],
    "exclude": ["test_*.cpp"]
}
```

切 Release 只改一行：`"config": "release"`，或命令行 `build main.cpp -config release -run`。

> **数据来源**：所有 config 预设默认值从 VS2026 v180 工具链的 `Microsoft.Cl.Common.props` 和 `Microsoft.Link.Common.props` 官方属性文件提取，与 Visual Studio 项目模板完全一致。

---

## 全部参数

> CLI 和 JSON **同名对应**。每个参数既可在命令行中使用，也可写入 `msvc_list.json`。 
>
> 优先级：**CLI > JSON > config 预设 > 内置默认值**。

| CLI | JSON | 可选值 | 说明 |
|---|---|---|---|
| **编译与运行** | | | |
| `<源文件...>` | — | 文件名 / 通配符 | 源文件（`.c` `.cpp` `.cxx` `.cc` `.ixx`） |
| `-o` | `"output"` | string | 输出文件名（不含 .exe） |
| `-run` | — | — | 编译成功后自动运行 |
| `-std` | `"std"` | `14` `17` `20` `23` `latest` | C++ 标准 |
| `-a` | — | string | 运行时传给程序的命令行参数 |
| `-x86` | — | — | 编译为 32 位（默认 64 位） |
| `-env` | — | `vs` `portable` `auto` | 强制指定编译环境 |
| **路径与依赖** | | | |
| `-I` | `"include"` | string[] | 头文件包含路径 |
| `-L` | `"libpath"` | string[] | 库文件搜索路径 |
| `-libs` | `"libs"` | string[] | 链接库（不含 .lib） |
| `-D` | `"defines"` | string[] | 预处理器宏定义 |
| — | `"exclude"` | string[] | 依赖解析时排除的文件通配符 |
| **工程配置（与 MSBuild 1:1）** | | | |
| `-config` | `"config"` | `debug` `release` | 一键 VS 官方配置预设 |
| `-optimize` | `"optimize"` | `Od` `O1` `O2` `Ox` | 优化级别 |
| `-runtime` | `"runtime"` | `MD` `MDd` `MT` `MTd` | 运行库 |
| `-warnings` | `"warnings"` | `W0` `W1` `W3` `W4` `Wall` | 警告级别 |
| `-WX` | `"WX"` | bool | 视警告为错误 → `/WX` |
| `-debug_info` | `"debug_info"` | `off` `Zi` `ZI` `Z7` | 调试信息格式 |
| `-exceptions` | `"exceptions"` | `EHsc` `EHa` `off` | 异常处理模型 |
| `-fp` | `"fp"` | `precise` `strict` `fast` | 浮点模型 → `/fp:xxx` |
| `-charset` | `"charset"` | `unicode` `mbcs` | 字符集宏 → `/DUNICODE` `/D_MBCS` |
| `-rtc1` | `"rtc1"` | bool | 运行时检查 → `/RTC1` |
| `-jmc` | `"jmc"` | bool | Just My Code → `/JMC` |
| `-sdl` | `"sdl"` | bool | 安全检查 → `/GS /sdl` |
| `-permissive` | `"permissive"` | bool | 严格标准一致性 → `/permissive-` |
| `-ltcg` | `"ltcg"` | bool | 全程序优化 → `/GL` + `/LTCG` |
| `-subsystem` | `"subsystem"` | `console` `windows` | 链接器子系统 → `/SUBSYSTEM:xxx` |
| `-incremental` | `"incremental"` | bool | 增量链接 → `/INCREMENTAL` |
| `-flags` | `"flags"` | string[] | 追加原始编译器标志（直接透传） |
| `-link_flags` | `"link_flags"` | string[] | 追加原始链接器标志（直接透传） |

> **别名**：`-o` = `-output`，`-I` = `-include`，`-L` = `-libpath`，`-D` = `-defines`。

### config 预设默认值

| 参数 | debug | release |
|---|---|---|
| `optimize` | `Od` | `O2` |
| `runtime` | `MDd` | `MD` |
| `debug_info` | `ZI` | `Zi` |
| `rtc1` | `true` → `/RTC1` | `false` |
| `jmc` | `true` → `/JMC` | `false` |
| `ltcg` | `false` | `true` → `/GL /LTCG` |
| `incremental` | `true` → `/INCREMENTAL` | `false` |

两个预设**共同启用**：`warnings=W3`、`exceptions=EHsc`、`fp=precise`、`sdl=true`、`subsystem=console`。  

两个预设**均不启用**：`permissive`、`WX`、`charset`。

> 使用 `-config` 时还会自动启用 MSBuild 链接标志（`/DEBUG` `/DYNAMICBASE` `/NXCOMPAT` `/MANIFEST` `/MACHINE:X64` 等）并链接 12 个 Windows 默认库（`kernel32` `user32` `gdi32` `winspool` `comdlg32` `advapi32` `shell32` `ole32` `oleaut32` `uuid` `odbc32` `odbccp32`）。

---


## 构建输出

输出格式与 VS2026 IDE 输出面板一致：

```
1>  正在解析源依赖项: main.cpp, mathlib.ixx

生成开始于 14:30...
1>------ 已启动生成: 项目: main, 配置: Debug x64 ------
1>  正在扫描源以查找模块依赖项...
1>  正在编译...
1>  mathlib.ixx
1>  main.cpp
1>  main -> D:\project\main.exe
========== 生成: 1 成功，0 失败，0 最新，0 已跳过 ==========
========== 生成 于 14:30 完成，耗时 1.116 秒 ==========
```

---

## 核心能力

### 源依赖解析

始终自动开启。从指定文件出发，BFS 扫描 `#include` 和 `import` 建立双向依赖图，自动发现关联文件：

```
同一个文件夹下：
├── main.cpp     ← F5：自动发现 lib.cpp + utils.ixx，一起编译
├── lib.h
├── lib.cpp      ← F5：反向追踪到 main.cpp，一起编译
├── utils.ixx
└── homework.cpp ← F5：独立文件，只编译自身
```

### 增量编译

构建管线：`cl /scanDependencies` → `cl /c /interface *.ixx` → `cl /c *.cpp` → `link.exe`

| 层级 | 行为 |
|------|------|
| 模块增量 | .ixx 按时间戳跳过未修改文件，变更自动传播到下游 |
| 源文件增量 | .cpp 按时间戳跳过未修改文件，模块接口变更时保守重编 |
| 链接增量 | 所有 .obj 均未变更时跳过 link.exe |
| std 缓存 | 按编译标志 + 工具链版本号哈希隔离，升级工具链自动失效 |

### C++20 Modules

- `.ixx` 模块自动调用 `cl /scanDependencies` 扫描依赖（P1689 JSON）
- Kahn 算法拓扑排序，按正确顺序编译（无需手动排列）
- **分层并行编译**：同一拓扑层级的独立模块批量传给 `cl /MP` 并行编译
- `import std;` / `import std.compat;` 首次编译后自动缓存

### 缓存管理

更新 Visual Studio 后若报错，清除缓存即可：

```powershell
Remove-Item "$env:TEMP\msvc_std_module_cache" -Recurse -Force   # std 模块
Remove-Item "$env:TEMP\msvc_mod_cache" -Recurse -Force          # 用户模块
Remove-Item "$env:TEMP\msvc_cpp_cache" -Recurse -Force          # 源文件
```

---

## 许可证

[MIT License](LICENSE)