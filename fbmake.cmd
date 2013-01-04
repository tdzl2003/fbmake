@echo off
setlocal

set FBMAKE_PATH=%~dp0

%FBMAKE_PATH%\luajit.exe %FBMAKE_PATH%\fbmake\main.lua %*

