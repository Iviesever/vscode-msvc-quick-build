# build — MSVC 快速编译工具

> **一个 PowerShell 脚本，让你在 VS Code 里按 F5 就能编译运行 C/C++。**
>
> 无需 `.sln`、`CMakeLists.txt`、`launch.json`。
> 支持 C++23 Modules、`import std;`、智能依赖追踪、增量编译、Debug/Release 一键切换。

## 安装

### 前置要求

- **Visual Studio**（Community 免费版即可），勾选 **"使用 C++ 的桌面开发"**
  下载：<https://visualstudio.microsoft.com/zh-hans/downloads/>

### 部署

```powershell
New-Item "$HOME\bin" -ItemType Directory -Force | Out-Null
Copy-Item "build.ps1" "$HOME\bin\build.ps1" -Force

# Windows PowerShell 5.1
New-Item "$HOME\Documents\WindowsPowerShell" -ItemType Directory -Force | Out-Null
Copy-Item "Microsoft.PowerShell_profile.ps1" "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Force

# PowerShell 7（可选）
New-Item "$HOME\Documents\PowerShell" -ItemType Directory -Force | Out-Null
Copy-Item "Microsoft.PowerShell_profile.ps1" "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Force
```

重启终端，输入 `build` 看到帮助信息即部署成功。

### VS Code F5 一键编译运行

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
build main.c -run                                # 单文件编译运行
build *.cpp -o app -std 23 -run                  # 多文件 + C++23
build main.cpp mod.ixx -o app -std latest -run   # C++ Modules
build solver.c -run -a "input.txt 42"            # 传参运行
build main.cpp -x86 -run                         # 32 位编译
```

### 命令行参数

| 参数 | 说明 |
|------|------|
| `<源文件...>` | 源文件名，支持通配符 `*.cpp` |
| `-o <名称>` | 输出文件名（不含 .exe） |
| `-run` | 编译后自动运行 |
| `-std <版本>` | C++ 标准：`14` / `17` / `20` / `23` / `latest` |
| `-smart` | 智能模式：自动追踪 `#include` / `import` 依赖 |
| `-a <参数>` | 运行时传给程序的参数 |
| `-x86` | 编译为 32 位（默认 64 位） |
| `-I <路径>` | 头文件搜索路径（可多个） |
| `-L <路径>` | 库文件搜索路径（可多个） |
| `-libs <库名>` | 链接库名（不含 .lib，可多个） |

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

---

## 项目配置 `msvc_list.json`

在项目目录创建 `msvc_list.json`，实现**零命令行参数的完整项目配置**。脚本会自动向上查找最多 5 层父目录。

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

切 Release 只改一行：`"config": "release"`。

### 全部字段

**所有字段均可选。** `config` 设置的默认值可被其他字段覆盖。

#### 项目配置

| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `config` | string | `"debug"` / `"release"` — 一键 VS 配置 | `"debug"` |
| `std` | string | C++ 标准 | `"latest"` |
| `output` | string | 输出名（命令行 `-o` 优先） | `"MyApp"` |
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

## 高级话题

### 模块中使用 #include

自己的头文件放在 **global module fragment**（`module;` ~ `export module` 之间）：

```cpp
module;                          // global module fragment
#include "my_config.h"
#include "some_c_library.h"

export module mymod;             // module purview
import std;

export void do_something() { /* ... */ }
```

> 禁止在 `export module` 之后 `#include` 标准库头文件，和 `import std;` 混用会导致符号重定义。

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