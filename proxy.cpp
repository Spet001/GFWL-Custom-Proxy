// proxy.cpp - Proxy GFWL para Quantum of Solace
// Intercepta apenas funções críticas, resto usa GFWL real
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <cstdint> // Necessário para uintptr_t

// instrui o linker a incluir a biblioteca User32.lib, que contém MessageBoxA
#pragma comment(lib, "user32.lib")

static HMODULE g_hReal = NULL;
static FILE* g_log = NULL;

static void Log(const char* fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    if (!g_log) {
        char tmpPath[MAX_PATH];
        GetTempPathA(MAX_PATH, tmpPath);
        strcat_s(tmpPath, "\\xlive_proxy.log");
        fopen_s(&g_log, tmpPath, "a");
        if (g_log) {
            fprintf(g_log, "\n=== Quantum GFWL Proxy ===\n");
        }
    }
    if (g_log) {
        SYSTEMTIME st;
        GetLocalTime(&st);
        fprintf(g_log, "[%02d:%02d:%02d] ", st.wHour, st.wMinute, st.wSecond);
        vfprintf(g_log, fmt, ap);
        fprintf(g_log, "\n");
        fflush(g_log);
    }
    va_end(ap);
}

static HMODULE LoadReal()
{
    if (g_hReal) return g_hReal;
    
    wchar_t path[MAX_PATH];
    GetModuleFileNameW(NULL, path, MAX_PATH);
    wchar_t* p = wcsrchr(path, L'\\');
    if (p) {
        *(p + 1) = 0;
        wcscat_s(path, MAX_PATH, L"xlive_real.dll");
        g_hReal = LoadLibraryW(path);
        if (g_hReal) {
            Log("Carregado: xlive_real.dll (local)");
            return g_hReal;
        }
    }
    
    GetSystemDirectoryW(path, MAX_PATH);
    wcscat_s(path, L"\\xlive.dll");
    g_hReal = LoadLibraryW(path);
    if (g_hReal) {
        Log("Carregado: xlive.dll (System32)");
        return g_hReal;
    }
    
    Log("ERRO: GFWL nao encontrado!");
    MessageBoxA(NULL, "xlive_real.dll (GFWL Original) nao foi encontrado na pasta do jogo ou no System32.", "Erro do Proxy GFWL", MB_OK | MB_ICONERROR);
    return NULL;
}

static FARPROC GetReal(WORD ord)
{
    HMODULE h = LoadReal();
    if (!h) return NULL;
    return GetProcAddress(h, (LPCSTR)(uintptr_t)ord);
}

// === Funções Interceptadas ===
extern "C" int __stdcall XNetStartup(void* params) { Log("XNetStartup(%p)", params); FARPROC p = GetReal(51); if (p) { int r = ((int(__stdcall*)(void*))p)(params); Log("  Real => 0x%08X", r); if (r == 0) return 0; if (r == (int)0x80004005) Log("  E_FAIL detectado (SecuROM), forcando OK"); } return 0; }
extern "C" int __stdcall XNetCleanup(void) { FARPROC p = GetReal(52); return p ? ((int(__stdcall*)(void))p)() : 0; }
extern "C" int __stdcall XLiveInitialize(void* params) { Log("XLiveInitialize(%p)", params); FARPROC p = GetReal(5000); if (p) { int r = ((int(__stdcall*)(void*))p)(params); Log("  Real => 0x%08X", r); if (r == 0) return 0; Log("  Falhou, forcando OK"); } return 0; }
extern "C" int __stdcall XLiveInput(DWORD* p) { FARPROC f = GetReal(5001); if (f) return ((int(__stdcall*)(DWORD*))f)(p); if (p) p[5] = 0; return 1; }
extern "C" int __stdcall XLiveRender(void) { FARPROC f = GetReal(5002); return f ? ((int(__stdcall*)(void))f)() : 0; }
extern "C" int __stdcall XLiveUninitialize(void) { FARPROC p = GetReal(5003); return p ? ((int(__stdcall*)(void))p)() : 0; }
extern "C" int __stdcall XOnlineStartup(void) { Log("XOnlineStartup()"); FARPROC p = GetReal(5310); if (p) { int r = ((int(__stdcall*)(void))p)(); Log("  Real => 0x%08X", r); if (r == 0) return 0; Log("  Falhou, forcando OK"); } return 0; }
extern "C" int __stdcall XOnlineCleanup(void) { FARPROC p = GetReal(5311); return p ? ((int(__stdcall*)(void))p)() : 0; }
extern "C" int __stdcall XUserGetSigninState(DWORD i) { FARPROC f = GetReal(5262); return f ? ((int(__stdcall*)(DWORD))f)(i) : 1; }
extern "C" int __stdcall XNotifyGetNext(HANDLE h, DWORD m, DWORD* id, void* p) { FARPROC f = GetReal(651); return f ? ((int(__stdcall*)(HANDLE, DWORD, DWORD*, void*))f)(h, m, id, p) : 0; }
extern "C" int __stdcall XShowSigninUI(DWORD c, DWORD f) { Log("XShowSigninUI(%d, 0x%X)", c, f); FARPROC func = GetReal(5260); int r = func ? ((int(__stdcall*)(DWORD, DWORD))func)(c, f) : 0; Log("  Real => 0x%08X", r); return r; }

// DllMain
BOOL WINAPI DllMain(HMODULE hModule, DWORD reason, LPVOID lpReserved)
{
    if (reason == DLL_PROCESS_ATTACH) { DisableThreadLibraryCalls(hModule); } 
    else if (reason == DLL_PROCESS_DETACH) { if (g_hReal) { FreeLibrary(g_hReal); g_hReal = NULL; } if (g_log) { fclose(g_log); g_log = NULL; } }
    return TRUE;
}