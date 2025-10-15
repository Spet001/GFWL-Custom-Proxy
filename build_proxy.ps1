# build_proxy.ps1
# Script para compilar o proxy GFWL para Quantum of Solace

Write-Host "=== GFWL Proxy Builder ===" -ForegroundColor Cyan
Write-Host ""

# Verificar arquivos essenciais
if (!(Test-Path "proxy.cpp") -or !(Test-Path "proxy.def")) {
    Write-Host "ERRO: proxy.cpp ou proxy.def nao encontrado!" -ForegroundColor Red
    Write-Host "Certifique-se de que ambos os arquivos estao na mesma pasta que este script." -ForegroundColor Yellow
    exit 1
}

# Localizar Visual Studio
Write-Host "[1/2] Localizando Visual Studio..." -ForegroundColor Yellow

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (!(Test-Path $vswhere)) {
    $vswhere = "${env:ProgramFiles}\Microsoft Visual Studio\Installer\vswhere.exe"
}

if (!(Test-Path $vswhere)) {
    Write-Host "ERRO: vswhere.exe do instalador do Visual Studio nao foi encontrado!" -ForegroundColor Red
    exit 1
}

$vsPath = & $vswhere -latest -property installationPath
if (!$vsPath) {
    Write-Host "ERRO: Nao foi possivel localizar uma instalacao do Visual Studio com o compilador C++." -ForegroundColor Red
    exit 1
}

Write-Host "  Visual Studio encontrado em: $vsPath" -ForegroundColor Gray

$vcvarsall = Join-Path $vsPath "VC\Auxiliary\Build\vcvarsall.bat"
if (!(Test-Path $vcvarsall)) {
    Write-Host "ERRO: vcvarsall.bat nao foi encontrado no caminho do VS. A carga de trabalho 'Desenvolvimento para desktop com C++' esta instalada?" -ForegroundColor Red
    exit 1
}

# Compilar
Write-Host "[2/2] Compilando proxy.cpp..." -ForegroundColor Yellow

$tempDir = Join-Path $env:TEMP "xlive_build_$(Get-Random)"
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

try {
    Copy-Item "proxy.cpp" $tempDir
    Copy-Item "proxy.def" $tempDir
    
    $buildBat = Join-Path $tempDir "build.bat"
    # Comando de compilação: /LD (cria DLL), /O2 (otimização), /MT (link estático com runtime), /W3 (warnings)
    # /link /DEF:proxy.def (usa nosso arquivo .def), /OUT:xlive.dll (nome do arquivo de saída)
    $buildScript = @"
@echo off
call "$vcvarsall" x86 >nul 2>&1
if errorlevel 1 exit /b 1
cl.exe /LD /O2 /MT /W3 proxy.cpp /link /DEF:proxy.def /MACHINE:X86 /OUT:xlive.dll >nul 2>&1
exit /b %errorlevel%
"@
    
    $buildScript | Out-File -FilePath $buildBat -Encoding ASCII
    
    Push-Location $tempDir
    
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    $processInfo.FileName = "cmd.exe"
    $processInfo.Arguments = "/c `"$buildBat`""
    $processInfo.RedirectStandardOutput = $true
    $processInfo.RedirectStandardError = $true
    $processInfo.UseShellExecute = $false
    $processInfo.CreateNoWindow = $true
    $processInfo.WorkingDirectory = $tempDir
    
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.Start() | Out-Null
    
    # Timeout de 30 segundos para a compilação
    if (!$process.WaitForExit(30000)) {
        Write-Host "ERRO: A compilacao demorou demais (timeout)." -ForegroundColor Red
        $process.Kill()
        exit 1
    }
    
    Pop-Location
    
    $dllPath = Join-Path $tempDir "xlive.dll"
    
    if ($process.ExitCode -eq 0 -and (Test-Path $dllPath)) {
        Copy-Item $dllPath ".\xlive.dll" -Force
        
        $libPath = Join-Path $tempDir "xlive.lib"
        if (Test-Path $libPath) {
            Copy-Item $libPath ".\xlive.lib" -Force
        }
        
        Write-Host "  xlive.dll compilado com sucesso!" -ForegroundColor Green
    }
    else {
        Write-Host "ERRO: A compilacao falhou! Verifique a saida do compilador se houver." -ForegroundColor Red
        exit 1
    }
}
finally {
    if (Test-Path $tempDir) {
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Verificar resultado
if (!(Test-Path "xlive.dll")) {
    Write-Host "ERRO FATAL: xlive.dll nao foi gerado!" -ForegroundColor Red
    exit 1
}

$dllSize = (Get-Item "xlive.dll").Length
Write-Host ""
Write-Host "=== BUILD CONCLUIDO ===" -ForegroundColor Green
Write-Host "  Arquivo gerado: xlive.dll ($([math]::Round($dllSize/1KB, 2)) KB)"
Write-Host ""
Write-Host "Proximos passos:" -ForegroundColor Cyan
Write-Host "1. Copie o xlive.dll gerado para a pasta do jogo."
Write-Host "2. Na pasta do jogo, renomeie a xlive.dll ORIGINAL (se existir) para xlive_real.dll."
Write-Host "3. Execute o jogo e verifique o log em: %TEMP%\xlive_proxy.log"
Write-Host ""