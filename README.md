# VS Code + MSVC 快速编译工具

一个专为 VS Code 编写的单文件编译脚本：**没有 `.sln`、`CMakeLists.txt`、`launch.json`，按下 F5 就能编译运行 C/C++。**

> **模块化支持**：原生处理 C++20/23 Modules 及 `import std;`，内置模块缓存。
>
> **智能推导**：基于 `#include` 和 `import` 自动爬取并编译依赖文件。
>
> **增量构建**：仅重新编译修改的 `.obj` 与 `.ifc`，代码无变动则直接运行。
>
> **对齐 MSBuild**：基于 `msvc_list.json` 支持 Debug/Release 一键切换及数百个 MSVC 原生参数的平替。

------

## 安装

有两种使用方式。选一种即可。

### 方式一：本机已装 Visual Studio

> 适用于自己开发用。需要 Visual Studio（Community 免费版即可），勾选 **"使用 C++ 的桌面开发"**。

```powershell
# 创建脚本目录
New-Item "$HOME\bin" -ItemType Directory -Force | Out-Null
Copy-Item "build.ps1" "$HOME\bin\build.ps1" -Force

# Windows PowerShell 5.1
New-Item "$HOME\Documents\WindowsPowerShell" -ItemType Directory -Force | Out-Null
Copy-Item "Microsoft.PowerShell_profile.ps1" "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Force

# PowerShell 7（可选）
New-Item "$HOME\Documents\PowerShell" -ItemType Directory -Force | Out-Null
Copy-Item "Microsoft.PowerShell_profile.ps1" "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Force
```

重启终端，输入 `build`，看到帮助信息即成功。

### 方式二：便携版（免装 Visual Studio）

> 适用于发给别人，或在没有 VS 的机器上使用。`portable_msvc.zip` 已包含完整的编译器和 SDK。

```powershell
# 创建脚本目录
New-Item "$HOME\bin" -ItemType Directory -Force | Out-Null

# 部署便携版脚本
Copy-Item "pbuild.ps1" "$HOME\bin\pbuild.ps1" -Force

# 解压编译器工具链（约 2GB）
# ⚠️ 注意：PowerShell 自带的 Expand-Archive 解压巨量小文件极其缓慢！
# 强烈建议：直接在文件管理器中【右键 portable_msvc.zip -> 提取全部】，解压到 $HOME\bin\portable_msvc
Expand-Archive "portable_msvc.zip" "$HOME\bin\portable_msvc" -Force

# Windows PowerShell 5.1
New-Item "$HOME\Documents\WindowsPowerShell" -ItemType Directory -Force | Out-Null
Copy-Item "Microsoft.PowerShell_profile.ps1" "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Force

# PowerShell 7（可选）
New-Item "$HOME\Documents\PowerShell" -ItemType Directory -Force | Out-Null
Copy-Item "Microsoft.PowerShell_profile.ps1" "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Force
```

重启终端，输入 `pbuild`，看到帮助信息即成功。用法与 `build` 完全一致。

### VS Code 按 F5 编译运行（可选）

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
                    "text": "cd \"${fileDirname}\" ; build \"${fileBasename}\" -smart -std latest -run\u000D"
                }
            }
        ]
    },
    "when": "resourceLangId == 'cpp' || resourceLangId == 'c'"
}
```

---

## 基本用法

```powershell
build main.cpp -run                              # 单文件编译运行
build *.cpp -o app -std 23 -run                  # 多文件 + C++23
build main.cpp mod.ixx -o app -std latest -run   # C++ Modules
build solver.c -run -a "input.txt 42"            # 传参运行
build main.cpp -x86 -run                         # 32 位编译
build main.cpp -smart -config debug -run         # 智能追踪 + Debug 配置
build main.cpp -config release -ltcg -run        # Release + 全程序优化
```

---

## 命令行参数

### 基础选项

| 参数 | 说明 |
|------|------|
| `<源文件...>` | 源文件名，支持通配符 `*.cpp` |
| `-o <名称>` | 输出文件名（不含 .exe） |
| `-run` | 编译后自动运行 |
| `-std <版本>` | C++ 标准：`14` / `17` / `20` / `23` / `latest` |
| `-smart` | 智能模式：自动追踪 `#include` / `import` 依赖 |
| `-a <参数>` | 运行时传给程序的参数 |
| `-x86` | 编译为 32 位（默认 64 位） |

### 路径与链接

| 参数 | 说明 |
|------|------|
| `-I <路径>` | 头文件搜索路径（可多个） |
| `-L <路径>` | 库文件搜索路径（可多个） |
| `-libs <库名>` | 链接库名（不含 .lib，可多个） |

### 工程配置参数

> 以下参数与 `msvc_list.json` 的字段 **1:1 同名对应**，优先级：**CLI > JSON > config 预设 > 内置默认值**。

| 参数 | 说明 |
|------|------|
| `-config debug/release` | 一键使用 VS 官方配置预设 |
| `-optimize off/size/speed/full` | 优化级别 |
| `-runtime dynamic/static` | 运行库（`/MD` / `/MT`，debug 自动加 `d`） |
| `-warnings off/basic/default/high/all` | 警告级别 |
| `-warn_as_error` | 视警告为错误 (`/WX`) |
| `-debug_info off/pdb/edit/embedded` | 调试信息格式 |
| `-exceptions sync/async/none` | 异常处理模型 |
| `-fp_model precise/strict/fast` | 浮点模型 |
| `-charset unicode/mbcs` | 字符集宏定义 |
| `-subsystem console/windows` | 链接器子系统 |
| `-rtc` | 运行时检查 (`/RTC1`) |
| `-jmc` | Just My Code (`/JMC`) |
| `-security` | 缓冲区安全检查 (`/GS /sdl`) |
| `-conformance` | 严格标准一致性 (`/permissive- /Zc:...`) |
| `-ltcg` | 全程序优化 (`/GL /LTCG`) |
| `-incremental_link` | 增量链接 (`/INCREMENTAL`) |
| `-defines <宏...>` | 预处理器宏（可多个，与 JSON 合并） |
| `-flags <标志...>` | 追加原始编译器标志（与 JSON 合并） |
| `-link_flags <标志...>` | 追加原始链接器标志（与 JSON 合并） |

---

## 项目配置 `msvc_list.json`

在项目目录创建 `msvc_list.json`，实现**零命令行参数的完整项目配置**。脚本会自动向上查找最多 5 层父目录。

> **所有字段均可通过同名 CLI 参数覆盖。** 例如 JSON 写 `"config": "debug"`，CLI 传 `-config release` 即可临时切换。

### 最简配置

```json
{ "config": "debug" }
```

一行即可获得完整的 VS Debug 配置（`/Od /MDd /RTC1 /JMC /ZI /GS /sdl ...`）。

### 完整示例

```json
{
    "config": "debug",
    "std": "latest",
    "charset": "unicode",
    "output": "MyApp",
    "warnings": "high",
    "defines": ["WIN32_LEAN_AND_MEAN", "NOMINMAX"],
    "libs": ["d3d11", "dxgi", "user32", "gdi32"],
    "include": ["../vendor/include"],
    "libpath": ["../vendor/lib"]
}
```

切 Release 只改一行：`"config": "release"`，或命令行 `build main.cpp -config release -run`。

### 全部字段

**所有字段均可选。** `config` 预设的默认值可被 JSON 其他字段或 CLI 参数覆盖。

#### 项目配置

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `config` | string | `"debug"` / `"release"` — 一键 VS 配置 | `"debug"` |
| `std` | string | C++ 标准 | `"latest"` |
| `output` | string | 输出名（CLI `-o` 优先） | `"MyApp"` |
| `charset` | string | `"unicode"` / `"mbcs"` — 自动定义宏 | `"unicode"` |
| `subsystem` | string | `"console"` / `"windows"` — 链接器子系统 | `"windows"` |
| `exclude` | string[] | 智能追踪时排除的文件模式 | `["test_*.cpp"]` |

#### 编译器（覆盖 config 默认值）

| 字段 | 说明 | debug 默认 | release 默认 |
|------|------|-----------|-------------|
| `optimize` | `"off"` `"size"` `"speed"` `"full"` | `"off"` → `/Od` | `"speed"` → `/O2 /Oi` |
| `runtime` | `"dynamic"` `"static"` | `/MDd` | `/MD` |
| `warnings` | `"off"` `"basic"` `"default"` `"high"` `"all"` | `/W3` | `/W3` |
| `warn_as_error` | bool | `false` | `false` |
| `debug_info` | `"off"` `"pdb"` `"edit"` `"embedded"` | `"edit"` → `/ZI` | `"pdb"` → `/Zi` |
| `exceptions` | `"sync"` `"async"` `"none"` | `/EHsc` | `/EHsc` |
| `rtc` | bool — 运行时检查 | `true` → `/RTC1` | `false` |
| `jmc` | bool — Just My Code | `true` → `/JMC` | `false` |
| `security` | bool — 缓冲区安全 | `true` → `/GS /sdl` | `true` |
| `conformance` | bool — 标准一致性 | `false` | `false` |
| `fp_model` | `"precise"` `"strict"` `"fast"` | `/fp:precise` | `/fp:precise` |

#### 链接器（覆盖 config 默认值）

| 字段 | 说明 | debug 默认 | release 默认 |
|------|------|-----------|-------------|
| `ltcg` | bool — 全程序优化 | `false` | `true` → `/GL /LTCG` |
| `incremental_link` | bool — 增量链接 | `true` | `false` |

#### 原始参数

| 字段 | 类型 | 说明 |
|------|------|------|
| `defines` | string[] | 预处理器宏 |
| `libs` | string[] | 链接库（不含 .lib） |
| `include` | string[] | 头文件路径（相对于 JSON 所在目录） |
| `libpath` | string[] | 库路径（相对于 JSON 所在目录） |
| `flags` | string[] | 追加的原始编译器标志 |
| `link_flags` | string[] | 追加的原始链接器标志 |

> **数据来源**：所有预设默认值从 VS2026 v180 工具链的 `Microsoft.Cl.Common.props` 和 `Microsoft.Link.Common.props` 官方属性文件提取，与 Visual Studio 项目模板完全一致。

---

## 核心能力

### 智能追踪（`-smart`）

从当前文件出发，BFS 扫描 `#include` 和 `import` 建立双向依赖图，自动发现关联文件：

```
同一个文件夹下：
├── main.cpp     ← F5：自动发现 lib.cpp + utils.ixx，一起编译
├── lib.h
├── lib.cpp      ← F5：反向追踪到 main.cpp，一起编译
├── utils.ixx
└── homework.cpp ← F5：独立文件，只编译自身
```

### C++ Modules

- `.ixx` 模块自动调用 `cl /scanDependencies` 扫描依赖（P1689 JSON）
- 拓扑排序，按正确顺序编译（无需手动排列）
- `import std;` / `import std.compat;` 首次编译后自动缓存到 `%TEMP%`
- **模块级增量编译**：仅重编修改的 `.ixx` 及其下游依赖，缓存存放在 `%TEMP%\msvc_mod_cache`

### 增量构建

- 源文件未修改 → 跳过编译，直接运行
- 模块级缓存 → 只重编有变化的 `.ixx`，依赖感知级联

### std 模块缓存

`import std;` 首次编译需约 2-3 秒，之后自动缓存。更新 Visual Studio 后若报错，清除缓存：

```powershell
Remove-Item "$env:TEMP\msvc_std_module_cache" -Recurse -Force
```

模块增量编译缓存也可清除：

```powershell
Remove-Item "$env:TEMP\msvc_mod_cache" -Recurse -Force
```

---

## 许可证

[MIT License](LICENSE)