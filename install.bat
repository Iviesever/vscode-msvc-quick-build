@echo off
echo ========================================
echo   VS Code MSVC 快速编译工具 - 安装向导
echo ========================================
echo.

set "BIN_DIR=%USERPROFILE%\bin"
set "PS4_DIR=%USERPROFILE%\Documents\WindowsPowerShell"
set "PS7_DIR=%USERPROFILE%\Documents\PowerShell"

echo [1/3] 创建目录结构...
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"
if not exist "%PS4_DIR%" mkdir "%PS4_DIR%"
if not exist "%PS7_DIR%" mkdir "%PS7_DIR%"

echo [2/3] 部署脚本文件...
powershell -NoProfile -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" >nul 2>&1
copy /Y "build.ps1" "%BIN_DIR%\build.ps1" >nul
copy /Y "Microsoft.PowerShell_profile.ps1" "%PS4_DIR%\Microsoft.PowerShell_profile.ps1" >nul
copy /Y "Microsoft.PowerShell_profile.ps1" "%PS7_DIR%\Microsoft.PowerShell_profile.ps1" >nul
echo 脚本部署完毕。
echo.

echo [3/3] 便携版工具链 (可选)
echo 如果您没有安装 Visual Studio，可以解压自带的编译器。
echo 如果按 y，请耐心等待解压完成。
set /p "UNZIP=是否解压 portable_msvc.zip? [y/N]: "

if /I "%UNZIP%"=="y" (
    if exist "portable_msvc.zip" (
        echo.
        echo 正在解压 portable_msvc.zip ...
        if not exist "%BIN_DIR%\portable_msvc" mkdir "%BIN_DIR%\portable_msvc"
        tar -xf portable_msvc.zip -C "%BIN_DIR%\portable_msvc"
        if errorlevel 1 (
            echo 原生解压失败，用 PowerShell 解压...
            powershell -NoProfile -Command "Expand-Archive -Force 'portable_msvc.zip' '%BIN_DIR%\portable_msvc'"
        )
        echo 解压完成！
    ) else (
        echo 未找到 portable_msvc.zip
    )
) else (
    echo 已跳过解压。
)

echo.
echo ========================================
echo 安装完成！请重启终端后输入 build 测试。
echo ========================================
pause