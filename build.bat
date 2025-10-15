@echo off
setlocal
echo === GFWL Proxy Builder (Versao Final) ===
echo.
echo Procurando pelo ambiente de compilacao do Visual Studio...

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" set "VSWHERE=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" (
    echo ERRO: Nao foi possivel encontrar o vswhere.exe. O Visual Studio esta instalado?
    goto :error
)
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -property installationPath`) do (
    set "VS_PATH=%%i"
)
if not defined VS_PATH (
    echo ERRO: Nao foi possivel encontrar o caminho de instalacao do Visual Studio.
    goto :error
)
set "VCVARSALL_PATH=%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat"
if not exist "%VCVARSALL_PATH%" (
    echo ERRO: Nao foi possivel encontrar vcvarsall.bat.
    echo Verifique se a carga de trabalho "Desenvolvimento para desktop com C++" esta instalada.
    goto :error
)

echo Usando o ambiente do Visual Studio de: "%VS_PATH%"
echo.
call "%VCVARSALL_PATH%" x86
echo Compilando proxy.cpp...
cl.exe /LD /O2 /MT /W3 /EHsc proxy.cpp /Fe:xlive.dll /link /DEF:proxy.def
echo.

if errorlevel 1 (
    echo **************************************
    echo      ERRO: A COMPILACAO FALHOU!
    echo **************************************
    goto :error
)

echo ******************************************
echo      DLL compilada com sucesso!
echo ******************************************
echo.
echo Proximos passos:
echo 1. Copie o xlive.dll (este arquivo) para a pasta do jogo.
echo 2. Pegue a xlive.dll ORIGINAL do GFWL (da pasta C:\Windows\SysWOW64 ou System32).
echo 3. Renomeie essa DLL original para 'xlive_real.dll' e coloque-a na pasta do jogo.
echo 4. Execute o jogo!
echo.

:success
endlocal
pause
exit /b 0

:error
endlocal
pause
exit /b 1