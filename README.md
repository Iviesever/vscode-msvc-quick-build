# VS Code + MSVC 快速编译工具

> 不需要 `.sln`、`.vcxproj`、`CMakeLists.txt`、`launch.json`、`tasks.json`、`c_cpp_properties.json`、`settings.json` 等。
>
> 一行命令，直接在 VS Code 的终端使用 VS 2026 的 MSVC 编译器编译 C/C++ 文件。 
>
> **支持 C++20/23 Modules（`.ixx`）和 `import std;` / `import std.compat;`（自动缓存）**。

---

## 前置要求

### 1. 安装 Visual Studio

需要安装 Visual Studio（Community 版免费），并勾选 **"使用 C++ 的桌面开发"** 工作负载。

下载地址：<https://visualstudio.microsoft.com/zh-hans/downloads/>

### 2. 安装 PowerShell 7（pwsh）

本工具 **必须在 pwsh（PowerShell 7）中运行**，不兼容 Windows 自带的 Windows PowerShell 5.1。

#### 怎么区分 PS5 和 PS7？

| | Windows PowerShell 5.1（系统自带） | PowerShell 7（需要安装） |
|---|---|---|
| 可执行文件 | `powershell.exe` | `pwsh.exe` |
| 默认路径 | `C:\Windows\System32\WindowsPowerShell\` | `C:\Program Files\PowerShell\7\` |
| Profile 目录 | `Documents\WindowsPowerShell\` | `Documents\PowerShell\` |
| 图标 | 蓝底白字 | 黑底蓝字 |

#### 下载安装 PS7

**官网下载 MSI 安装包**

1. 打开 <https://github.com/PowerShell/PowerShell/releases/latest>
2. 在 Assets 区域下载 `PowerShell-7.x.x-win-x64.msi`
3. 双击安装，一路默认即可

#### 验证安装

安装后打开任意终端执行：

```
pwsh --version
```

能看到 `PowerShell 7.x.x` 就对了。

### 3. 将 VS Code 默认终端设为 pwsh

VS Code 默认使用的可能是 Windows PowerShell 5.1（`powershell.exe`），需要切换到 PS7 才能使用 `build` 命令。

#### 设置页面

1. 打开 VS Code
2. `Ctrl + ,` 打开设置
3. 搜索 `terminal default profile windows`
4. 在 **Terminal › Integrated › Default Profile: Windows** 下拉菜单中选择 **PowerShell**（不是 "Windows PowerShell"）

> 下拉菜单中有两个选项容易混淆：
> - **Windows PowerShell** → 这是 5.1，不要选
> - **PowerShell** → 这是 7.x，选这个

---

## 安装部署

项目包含两个文件，需要手动复制到指定位置：

| 文件 | 复制到 | 说明 |
|------|--------|------|
| `build.ps1` | `C:\Users\<用户名>\bin\build.ps1` | 编译脚本本体 |
| `Microsoft.PowerShell_profile.ps1` | `C:\Users\<用户名>\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` | PS7 Profile，注册 `build` 命令 |

可以手动复制，也可以跑以下命令一键部署：

```powershell
# 在本项目目录中执行
New-Item "$HOME\bin" -ItemType Directory -Force | Out-Null
Copy-Item "build.ps1" "$HOME\bin\build.ps1" -Force
Copy-Item "Microsoft.PowerShell_profile.ps1" "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1" -Force
```

部署完成后，**重启 VS Code 终端**（或新开一个 pwsh 终端），输入 `build` 看到用法提示就成功了。

> Profile 在每次打开 pwsh 时自动加载。如果修改了 Profile 文件，需要重开终端才能生效。

---

## 快速开始

```powershell
# 编译并运行
build hello.c -run

# C++ 多文件
build main.cpp utils.cpp -o myapp -run

# C++ Modules
build main.cpp mymod.ixx -o app -std latest -run

# 传参
build solver.c -run -a "input.txt 42"
```

---

## 一键编译运行（F5 / F6）

不想每次手打命令？可以配置 VS Code 快捷键，按 F5 / F6 自动编译运行当前文件。

打开 VS Code 键盘快捷方式配置：`Ctrl + Shift + P` → 输入 `Open Keyboard Shortcuts (JSON)`，在 `[]` 中加入：

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
                    "text": "cd \"${fileDirname}\" ; build * -std latest -run\u000D"
                }
            }
        ]
    },
    "when": "resourceLangId == 'cpp' || resourceLangId == 'c'"
},
{
    "key": "f6",
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

| 快捷键 | 行为 |
|--------|------|
| `F5` | 编译当前文件所在目录的**所有源文件**并运行 |
| `F6` | 只编译**当前打开的单个文件**并运行 |

> 终端会自动弹出，自动 `cd` 到文件所在目录，无需手动操作。

## 参数一览

| 参数 | 别名 | 类型 | 说明 |
|------|------|------|------|
| `Sources` | (位置参数) | `string[]` | 源文件，支持通配符 `*.c` `*.cpp` `*.ixx` |
| `-o` | `-output` | `string` | 输出文件名（不含 `.exe`），默认取第一个源文件名 |
| `-run` | | `switch` | 编译成功后自动运行 |
| `-std` | | `string` | C++ 标准：`14` / `17` / `20` / `23` / `latest` |
| `-ProgramArgs` | `-a` | `string` | 运行时传给程序的命令行参数 |
| `-x86` | | `switch` | 编译为 32 位（默认 64 位） |
| `-I` | | `string[]` | 额外的头文件搜索路径（可多个） |
| `-L` | | `string[]` | 额外的库文件搜索路径（可多个） |
| `-libs` | | `string[]` | 要链接的库（不含 `.lib`，可多个） |

---

## 使用示例

### 1. 单个 C 文件

```powershell
build main.c -run
```

```powershell
[编译] main.c -> main.exe
main.c
[成功] main.exe

[运行] main.exe
========================================
Hello, World!
========================================
[结束] 退出码: 0
```

### 2. C++ + 指定标准

```powershell
build solver.cpp -std 23 -run
```

### 3. 多文件项目

```powershell
build main.cpp utils.cpp math.cpp -o myapp -run
```

### 4. 通配符 `*`

```powershell
build *.c -o myapp -run
build *.cpp -o myapp -std 20 -run
```

> 通配符自动过滤，只接受 `.c` `.cpp` `.cxx` `.cc` `.ixx` 文件。  
> 
> 即使目录里有 `.h` `.txt` 等文件也不会误传给编译器。

### 5. C++ Modules（`.ixx` + `import`）

```
project/
├── main.cpp       # import std; import mymod;
└── mymod.ixx      # export module mymod; import std;
```

```powershell
build main.cpp mymod.ixx -o app -std latest -run
```

### 6. 传参给程序

```powershell
build processor.c -run -a "input.txt output.txt"
```

### 7. 32 位编译

```powershell
build legacy.c -x86 -run
```

### 8. 第三方库

```powershell
build main.cpp -I D:\libs\SDL2\include -L D:\libs\SDL2\lib -libs SDL2,SDL2main -run
```

多个路径用多个 `-I` / `-L`：

```powershell
build main.cpp -I D:\libs\SDL2\include -I D:\libs\glew\include -L D:\libs\SDL2\lib -L D:\libs\glew\lib -libs SDL2,SDL2main,glew32 -run
```

---

## C++ Modules 工作原理

检测到 `.ixx` 文件时，脚本使用 MSVC 原生的 `/scanDependencies` 扫描模块依赖（P1689 JSON），然后自动拓扑排序、多阶段编译：

```
build main.cpp top.ixx mid.ixx base.ixx -o app -std latest -run
  │
  ├─ [模块]  调用 cl /scanDependencies 扫描每个 .ixx 的依赖关系
  │          由编译器自己做词法分析，100% 准确
  │          正确处理注释、字符串、export import、模块分区等
  │
  ├─ [标准]  检测到 'import std;' 或 'import std.compat;'
  │          → 首次编译并缓存到 %TEMP%\msvc_std_module_cache\
  │          → 后续直接使用缓存
  │
  ├─ [模块]  按拓扑排序结果逐个编译 .ixx
  │          → base.ixx（无依赖，最先编译）
  │          → mid.ixx（依赖 base，第二编译）
  │          → top.ixx（依赖 base + mid，最后编译）
  │          即使传入顺序是乱的，也能自动推断正确编译顺序
  │
  ├─ [链接]  编译 .cpp 并链接所有 .obj
  │
  └─ 自动清理 .obj / .ifc 中间文件
```

### std 模块缓存

`import std;` 和 `import std.compat;` 需要预编译标准库模块（约 2-3 秒）。脚本会自动将编译产物缓存到 `%TEMP%\msvc_std_module_cache\`，后续构建直接复用：

```
首次编译：[标准] 首次编译 std 模块（编译后将缓存）...
后续编译：[标准] 使用缓存的 std 模块
```

> 若更新了 Visual Studio 版本，删除缓存目录即可重建：
> ```powershell
> Remove-Item "$env:TEMP\msvc_std_module_cache" -Recurse -Force
> ```

### 模块中使用 #include

自己的头文件放在 **global module fragment** 中（`module;` ~ `export module` 之间）：

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

> **禁止在 `export module` 之后 `#include` 标准库头文件**  
> 
> 和 `import std;` 混用会导致符号重定义。自己的头文件放 global module 没问题。

---

## 默认编译选项

| 选项 | 说明 |
|------|------|
| `/nologo` | 不显示编译器版本横幅 |
| `/W3` | 警告等级 3（推荐） |
| `/utf-8` | UTF-8 编码 |
| `/EHsc` | C++ 异常处理 |

---

## 支持的文件类型

| 扩展名 | 语言 | 说明 |
|--------|------|------|
| `.c` | C | 标准 C 源文件 |
| `.cpp` `.cxx` `.cc` | C++ | C++ 源文件 |
| `.ixx` | C++ Module | 模块接口，自动用 `/interface` 编译 |

其他文件（`.h` `.hpp` `.txt` 等）会被通配符自动过滤掉。


---

## 常见问题

### Q: `build` 提示 "无法识别的命令"

**原因：** 你可能在 Windows PowerShell 5.1 中运行，而不是 PS7。

**解决：**
1. 确认已安装 PS7（见上方 [安装 PowerShell 7](#2-安装-powershell-7pwsh) 部分）
2. 确认 VS Code 默认终端已设为 pwsh（见上方 [VS Code 设置](#3-将-vs-code-默认终端设为-pwsh) 部分）
3. 确认 Profile 文件已部署到 `Documents\PowerShell\`（而不是 `Documents\WindowsPowerShell\`）

### Q: "Visual Studio not found"

确认安装了 VS 并勾选了 **"使用 C++ 的桌面开发"** 工作负载。

### Q: `import std;` 报错

确保使用 `-std latest` 或 `-std 23`，且安装了最新 MSVC 工具集。

### Q: 想加调试 / 优化选项

编辑 `~/bin/build.ps1` 中的 `$baseFlags`：

```powershell
# 调试
$baseFlags = '/nologo /W3 /utf-8 /EHsc /Zi /Od'

# 发布
$baseFlags = '/nologo /W3 /utf-8 /EHsc /O2'
```

### Q: 适合多大的项目？

适合**课程作业、小型练习、快速原型**。 
大型项目（复杂工具链、大规模依赖管理）建议直接用 VS2026。

---

## 开源协议

本项目采用 **MIT License** 开源协议，详情见 [LICENSE](LICENSE) 文件。