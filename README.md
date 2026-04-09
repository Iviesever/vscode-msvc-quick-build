# VS Code + MSVC 快速编译工具

> **一个 PowerShell 脚本，让你在 VS Code 里按 F5 就能编译运行 C/C++。**
>
> 无需 `.sln`、`CMakeLists.txt`、`launch.json` 等配置文件。 
>
> 支持 C++20/23 Modules、`import std;`、智能依赖追踪、增量构建。

---

## 安装部署

### 前置要求

- **Visual Studio**（Community 免费版即可），勾选 **"使用 C++ 的桌面开发"** 
  下载：<https://visualstudio.microsoft.com/zh-hans/downloads/>

### 部署脚本

在本项目目录中执行：

```powershell
New-Item "$HOME\bin" -ItemType Directory -Force | Out-Null
Copy-Item "build.ps1" "$HOME\bin\build.ps1" -Force

# Windows PowerShell 5.1（系统自带）
New-Item "$HOME\Documents\WindowsPowerShell" -ItemType Directory -Force | Out-Null
Copy-Item "Microsoft.PowerShell_profile.ps1" "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1" -Force

# PowerShell 7（如果你安装了的话）
New-Item "$HOME\Documents\PowerShell" -ItemType Directory -Force | Out-Null
Copy-Item "Microsoft.PowerShell_profile.ps1" "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Force
```

部署完成后，**重启终端**，输入 `build` 看到帮助信息就成功了。

---


## 核心自动配置

配置后，在 VS Code 中编辑任何 C/C++ 文件，**按 F5 即可自动编译并运行**。

### 配置方法

`Ctrl + Shift + P` → 输入 `Open Keyboard Shortcuts (JSON)` → 在 `[]` 中加入：

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

### 它会做什么？

```
按下 F5
  │
  ├─ 自动弹出终端，cd 到当前文件目录
  ├─ 智能追踪当前文件的 #include 和 import 依赖
  ├─ 只编译相关文件，不拖入无关源文件
  ├─ 代码没改？跳过编译，直接运行上次的 exe
  └─ 代码改了？重新编译，然后运行
```

### 使用场景

```
同一个文件夹下：
├── 作业1.cpp          ← 焦点在这里按 F5：只编译运行 作业1.cpp
├── 作业2.cpp          ← 焦点在这里按 F5：只编译运行 作业2.cpp
├── main.cpp           ← 焦点在这里按 F5：自动发现 lib.cpp，一起编译
├── lib.h
└── lib.cpp            ← 焦点在这里按 F5：反向追踪到 main.cpp，一起编译
```

------


## 终端使用方式

### 基础用法

```powershell
build main.c -run                            # 编译并运行
build solver.cpp -std 23 -run                # 指定 C++ 标准
build main.cpp utils.cpp -o myapp -run       # 多文件 + 指定输出名
build *.cpp -o app -run                      # 通配符（自动过滤 .h .txt 等）
build processor.c -run -a "input.txt 42"     # 向程序传递命令行参数
build legacy.c -x86 -run                     # 32 位编译
```

### 智能追踪（`-smart`）

`-smart` 是本工具的核心能力。它从当前文件出发，自动扫描同目录下所有源文件的 `#include` 和 `import` 语句，通过 BFS（广度优先搜索）建立双向依赖图，找出完整的关联文件集合。

```powershell
build main.cpp -smart -run       # 自动追踪 main.cpp 的所有依赖并编译
build lib.cpp -smart -run        # 从 lib.cpp 反向追踪，也能找到 main.cpp
build homework1.cpp -smart -run  # 独立文件就只编译自身，不拖入其他文件
```

**技术细节：**
- 先剥离所有注释（`//` 和 `/* */`），再扫描 `#include` / `import`
- `#include "lib.h"` → 自动关联同名的 `lib.cpp`（头文件 ↔ 实现文件匹配）
- `import mymod;` → 自动关联提供该模块的 `.ixx` 文件
- `import std;` / `import std.compat;` 不参与追踪（由缓存系统处理）

### C++ Modules（`.ixx`）

```powershell
build main.cpp mymod.ixx -o app -std latest -run
```

脚本会自动处理：
1. 调用 `cl /scanDependencies` 扫描模块依赖（P1689 JSON，100% 准确）
2. 拓扑排序，按正确顺序编译（即使传入顺序是乱的）
3. `import std;` / `import std.compat;` 首次编译后自动缓存到 `%TEMP%`

### 第三方库

```powershell
build main.cpp -I D:\libs\SDL2\include -L D:\libs\SDL2\lib -libs SDL2,SDL2main -run
```

---

## 参数一览

| 参数 | 别名 | 说明 |
|------|------|------|
| `Sources` | (位置参数) | 源文件，支持通配符 |
| `-o` | `-output` | 输出文件名（不含 `.exe`） |
| `-run` | | 编译成功后自动运行 |
| `-std` | | C++ 标准：`14` / `17` / `20` / `23` / `latest` |
| `-smart` | | 智能模式：自动追踪依赖 |
| `-a` | `-ProgramArgs` | 运行时传给程序的参数 |
| `-x86` | | 编译为 32 位（默认 64 位） |
| `-I` | | 头文件搜索路径（可多个） |
| `-L` | | 库文件搜索路径（可多个） |
| `-libs` | | 链接的库名（不含 `.lib`，可多个） |

---

## 支持的文件类型

| 扩展名 | 说明 |
|--------|------|
| `.c` | C 源文件 |
| `.cpp` `.cxx` `.cc` | C++ 源文件 |
| `.ixx` | C++ 模块接口（自动用 `/interface` 编译） |

通配符 `*` 会自动过滤掉 `.h` `.hpp` `.txt` 等非源文件。

---

## 高级话题

### 模块中使用 #include

自己的头文件放在 **global module fragment**（`module;` ~ `export module` 之间）：

```cpp
module;                          // global module fragment 开始

#include "my_config.h"           // 自己的头文件
#include "some_c_library.h"      // C 库头文件

export module mymod;             // module purview 开始

import std;                      // 标准库 import

export void do_something() {
    // 可以使用 #include 引入的内容 + std:: 的所有东西
}
```

> **禁止在 `export module` 之后 `#include` 标准库头文件**，和 `import std;` 混用会导致符号重定义。

### 自定义编译选项

编辑 `~/bin/build.ps1` 中的 `$baseFlags`：

```powershell
# 默认
$baseFlags = '/nologo /W3 /utf-8 /EHsc'

# 调试
$baseFlags = '/nologo /W3 /utf-8 /EHsc /Zi /Od'

# 发布
$baseFlags = '/nologo /W3 /utf-8 /EHsc /O2'
```

### std 模块缓存

`import std;` 首次编译需要约 2-3 秒，之后自动缓存。若更新了 Visual Studio 版本导致编译报错，清除缓存即可：

```powershell
Remove-Item "$env:TEMP\msvc_std_module_cache" -Recurse -Force
```

---

## 常见问题

**Q: `import std;` 报错** 
确保使用 `-std latest` 或 `-std 23`，且安装了最新 MSVC 工具集。

**Q: 适合多大的项目？** 
适合课程作业、小型练习、快速原型。大型项目建议直接用 Visual Studio。

---

## 开源协议

本项目采用 **MIT License** 开源协议，详情见 [LICENSE](LICENSE) 文件。