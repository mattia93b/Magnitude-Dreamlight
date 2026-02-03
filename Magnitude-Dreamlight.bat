@echo off
setlocal EnableDelayedExpansion

set SHADERCROSS=utils\SDL_shadercross\shadercross.exe
set SHADER_DIR=shaders
set OUT_DIR=shaders\compiled

set ODIN_MAIN=main.odin
set ODIN_EXE=app.exe

mkdir %OUT_DIR%\dx12 2>nul
mkdir %OUT_DIR%\vulkan 2>nul
mkdir %OUT_DIR%\metal 2>nul

set BUILD_FAILED=0
set REBUILT_COUNT=0

echo.
echo =============================
echo SHADER BUILD
echo =============================

for %%f in (%SHADER_DIR%\*.hlsl) do (

    set "SRC=%%f"
    set "NAME=%%~nf"
    set "STAGE="

    echo %%f | find ".vert." >nul && set STAGE=vertex
    echo %%f | find ".frag." >nul && set STAGE=fragment

    if defined STAGE (

        call :compile_shader "%%f" "!NAME!" spirv "%OUT_DIR%\vulkan\!NAME!.spv"
        call :compile_shader "%%f" "!NAME!" dxil  "%OUT_DIR%\dx12\!NAME!.dxil"
        call :compile_shader "%%f" "!NAME!" metal "%OUT_DIR%\metal\!NAME!.msl"

    ) else (
        echo [SKIP] %%f stage non riconosciuto
    )
)

echo.
echo Shader rebuilt: %REBUILT_COUNT%

if %BUILD_FAILED%==1 (
    echo BUILD SHADER FALLITA
    pause
    exit /b 1
)

echo.
REM =============================
REM ODIN BUILD
REM =============================

odin build %ODIN_MAIN% -out:%ODIN_EXE% -file
if errorlevel 1 (
    echo Odin build failed
    pause
    exit /b 1
)
REM 
%ODIN_EXE%

pause
exit /b

REM =====================================
REM COMPILE SHADER
REM =====================================
:compile_shader

set SRC=%~1
set NAME=%~2
set TARGET=%~3
set OUTFILE=%~4

if exist "%OUTFILE%" (
    for %%A in ("%SRC%") do set SRC_TIME=%%~tA
    for %%A in ("%OUTFILE%") do set OUT_TIME=%%~tA
)

REM echo DEBUG: %SHADERCROSS% "%SRC%" -o "%OUTFILE%"
REM pause

%SHADERCROSS% "%SRC%" -o "%OUTFILE%"

if errorlevel 1 (
    echo [ERROR] %NAME% %TARGET%
    set BUILD_FAILED=1
    goto :eof
)

set /a REBUILT_COUNT+=1
goto :eof
