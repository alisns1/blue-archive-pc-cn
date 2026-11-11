@echo off
chcp 65001 >nul
cd /d "%~dp0"
title Blue Archive PC - Simplified Chinese
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0localize_pc.ps1"
