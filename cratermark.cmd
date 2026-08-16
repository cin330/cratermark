@echo off
setlocal

set "CRATERMARK_ROOT=%~dp0"
set "CRATERMARK_NODE=node.exe"
set "CRATERMARK_MOON=moon.exe"

where node.exe >nul 2>&1
if not errorlevel 1 goto node_ready

set "CRATERMARK_NODE=%USERPROFILE%\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe"

if not exist "%CRATERMARK_NODE%" (
  echo CraterMark requires Node.js for the JavaScript target.
  echo Install Node.js and make sure node.exe is available in PATH.
  exit /b 1
)

:node_ready

where moon.exe >nul 2>&1
if not errorlevel 1 goto moon_ready

set "CRATERMARK_MOON=%USERPROFILE%\.moon\bin\moon.exe"
if not exist "%CRATERMARK_MOON%" (
  echo CraterMark requires the MoonBit toolchain in PATH.
  exit /b 1
)

:moon_ready

pushd "%CRATERMARK_ROOT%"
"%CRATERMARK_MOON%" build --target js >nul
if errorlevel 1 (
  popd
  exit /b 1
)
popd

"%CRATERMARK_NODE%" "%CRATERMARK_ROOT%_build\js\debug\build\cmd\cratermark\cratermark.js" %*
set "CRATERMARK_EXIT=%ERRORLEVEL%"
exit /b %CRATERMARK_EXIT%
