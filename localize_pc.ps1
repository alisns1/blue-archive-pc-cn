<#
  蔚蓝档案 PC 版(Steam) 一键汉化
  流程：定位游戏 -> 备份 -> 运行 BlueArchiveCnPatcher.exe 机翻 -> 修正 TableCatalog.bytes 的 CRC -> 清理 file_check.json -> 校验
  这样游戏小版本更新(密钥不变)时，重新双击一次即可。
#>

$ErrorActionPreference = 'Stop'

# ---------- 自动提权 ----------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "正在申请管理员权限..." -ForegroundColor Yellow
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',$PSCommandPath)
    } catch {
        Write-Host "提权被拒绝。请右键本文件 -> 以管理员身份运行。" -ForegroundColor Red
        Read-Host "按回车退出"
    }
    exit
}

function Write-Step($t) { Write-Host ""; Write-Host "==> $t" -ForegroundColor Cyan }
function Write-Ok($t)   { Write-Host "    [OK] $t" -ForegroundColor Green }
function Write-Warn2($t){ Write-Host "    [!!] $t" -ForegroundColor Yellow }
function Write-Err2($t) { Write-Host "    [XX] $t" -ForegroundColor Red }

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "   蔚蓝档案 PC 版 一键汉化" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan

# ---------- CRC32 (编译 C# 实现，速度快) ----------
if (-not ('Crc32Util' -as [type])) {
    Add-Type -TypeDefinition @"
using System;
using System.IO;
public static class Crc32Util {
    static uint[] table;
    static Crc32Util() {
        table = new uint[256];
        for (uint i = 0; i < 256; i++) {
            uint c = i;
            for (int k = 0; k < 8; k++) c = ((c & 1) != 0) ? 0xEDB88320u ^ (c >> 1) : c >> 1;
            table[i] = c;
        }
    }
    public static uint ComputeFile(string path) {
        uint crc = 0xFFFFFFFFu;
        using (FileStream fs = File.OpenRead(path)) {
            byte[] buf = new byte[1 << 20];
            int n;
            while ((n = fs.Read(buf, 0, buf.Length)) > 0)
                for (int i = 0; i < n; i++) crc = (crc >> 8) ^ table[(crc ^ buf[i]) & 0xFF];
        }
        return crc ^ 0xFFFFFFFFu;
    }
}
"@
}

# ---------- 1. 定位游戏 ----------
Write-Step "查找游戏目录"

$steamRoots = @()
try { $p = (Get-ItemProperty 'HKCU:\Software\Valve\Steam' -Name SteamPath -ErrorAction Stop).SteamPath; if ($p) { $steamRoots += ($p -replace '/','\') } } catch { }
try { $p2 = (Get-ItemProperty 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam' -Name InstallPath -ErrorAction Stop).InstallPath; if ($p2) { $steamRoots += ($p2 -replace '/','\') } } catch { }

$candidates = @()
foreach ($s in $steamRoots) {
    $candidates += $s
    $vf = Join-Path $s 'steamapps\libraryfolders.vdf'
    if (Test-Path $vf) {
        $txt = Get-Content $vf -Raw
        foreach ($m in [regex]::Matches($txt, '"path"\s+"([^"]+)"')) { $candidates += ($m.Groups[1].Value -replace '\\\\','\') }
    }
}
foreach ($d in @('C','D','E','F','G','H')) {
    $candidates += "${d}:\SteamLibrary"
    $candidates += "${d}:\Steam"
    $candidates += "${d}:\Program Files (x86)\Steam"
}
$candidates = $candidates | Where-Object { $_ } | Select-Object -Unique

$gameRoot = $null
foreach ($c in $candidates) {
    $g = Join-Path $c 'steamapps\common\BlueArchive'
    if (Test-Path (Join-Path $g 'BlueArchive_Data')) { $gameRoot = $g; break }
}

# 脚本自己就在游戏根目录的情况
if (-not $gameRoot -and (Test-Path (Join-Path $PSScriptRoot 'BlueArchive_Data'))) { $gameRoot = $PSScriptRoot }

if (-not $gameRoot) {
    Write-Err2 "没找到蔚蓝档案(Steam版)安装目录。"
    $manual = Read-Host "请手动输入游戏根目录（例：F:\SteamLibrary\steamapps\common\BlueArchive），回车退出"
    if ($manual -and (Test-Path (Join-Path $manual 'BlueArchive_Data'))) { $gameRoot = $manual } else { exit 1 }
}
Write-Ok "游戏目录: $gameRoot"

$resDir  = Join-Path $gameRoot 'BlueArchive_Data\StreamingAssets\PUB\Resource'
$dbPath  = Join-Path $resDir 'Preload\TableBundles\ExcelDB.db'
$catPath = Join-Path $resDir 'Catalog\TableBundles\TableCatalog.bytes'
$fcPath  = Join-Path $gameRoot 'file_check.json'

if (-not (Test-Path $dbPath))  { Write-Err2 "找不到数据库: $dbPath"; Read-Host "按回车退出"; exit 1 }
if (-not (Test-Path $catPath)) { Write-Err2 "找不到目录文件: $catPath"; Read-Host "按回车退出"; exit 1 }

# ---------- 2. 检查游戏是否在运行 ----------
$proc = Get-Process -Name 'BlueArchive' -ErrorAction SilentlyContinue
if ($proc) {
    Write-Warn2 "游戏正在运行，请先完全退出游戏。"
    Read-Host "退出游戏后按回车继续（直接回车=退出脚本）"
    $proc = Get-Process -Name 'BlueArchive' -ErrorAction SilentlyContinue
    if ($proc) { Write-Err2 "游戏仍在运行，退出脚本。"; Read-Host "按回车退出"; exit 1 }
}

# ---------- 3. 找 patcher exe ----------
Write-Step "查找汉化程序 BlueArchiveCnPatcher.exe"
$exeCandidates = @(
    (Join-Path $PSScriptRoot 'BlueArchiveCnPatcher.exe'),
    (Join-Path $gameRoot 'BlueArchiveCnPatcher.exe')
)
$exePath = $null
foreach ($e in $exeCandidates) { if (Test-Path $e) { $exePath = $e; break } }

if (-not $exePath) {
    Write-Host "    本地没有，正在从 GitHub Release 下载（约 33 MB）..." -ForegroundColor Gray
    $dl = Join-Path $env:TEMP 'BlueArchiveCnPatcher.exe'
    try {
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add('User-Agent','Mozilla/5.0')
        $wc.DownloadFile('https://github.com/alisns1/blue-archive-pc-cn/releases/download/1.0.0/BlueArchiveCnPatcher.exe', $dl)
        $wc.Dispose()
        $exePath = $dl
        Write-Ok "下载完成"
    } catch {
        Write-Err2 "下载失败: $($_.Exception.Message)"
        Read-Host "按回车退出"; exit 1
    }
} else {
    Write-Ok "找到: $exePath"
}

# ---------- 4. 备份 ----------
Write-Step "备份原文件"
$stamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupDir = Join-Path $gameRoot ("_ba_cn_backup_" + $stamp)
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
Copy-Item $dbPath  (Join-Path $backupDir 'ExcelDB.db') -Force
Copy-Item $catPath (Join-Path $backupDir 'TableCatalog.bytes') -Force
if (Test-Path $fcPath) { Copy-Item $fcPath (Join-Path $backupDir 'file_check.json') -Force }
$bakDb  = Join-Path $backupDir 'ExcelDB.db'
$bakCat = Join-Path $backupDir 'TableCatalog.bytes'
Write-Ok "已备份到: $backupDir"

$oldDbSize = (Get-Item $bakDb).Length
$oldCrc = [Crc32Util]::ComputeFile($bakDb)
Write-Ok ("原数据库 {0:N0} 字节, CRC32 = 0x{1:X8}" -f $oldDbSize, $oldCrc)

# ---------- 5. 运行 patcher ----------
Write-Step "运行汉化程序（它会联网机翻，可能需要几分钟，请勿关闭窗口）"
Write-Host "    程序位置: $exePath" -ForegroundColor Gray
$beforeHash = (Get-FileHash $dbPath -Algorithm MD5).Hash
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$p = Start-Process -FilePath $exePath -WorkingDirectory $gameRoot -PassThru -Wait
$sw.Stop()
Write-Ok ("汉化程序已结束，用时 {0:N0} 秒 (退出码 {1})" -f $sw.Elapsed.TotalSeconds, $p.ExitCode)

$afterHash = (Get-FileHash $dbPath -Algorithm MD5).Hash
if ($afterHash -eq $beforeHash) {
    Write-Err2 "数据库没有被修改 —— 汉化程序可能失败了。"
    Write-Warn2 "已保留备份: $backupDir"
    Read-Host "按回车退出"; exit 1
}
Write-Ok "数据库已被修改"

# ---------- 6. 修正 TableCatalog 里的 CRC ----------
Write-Step "修正 TableCatalog.bytes 里的 CRC 校验值"
$newCrc = [Crc32Util]::ComputeFile($dbPath)
Write-Ok ("新数据库 CRC32 = 0x{0:X8}" -f $newCrc)

$data = [System.IO.File]::ReadAllBytes($catPath)
$needle = [System.Text.Encoding]::ASCII.GetBytes('ExcelDB.db')

function Find-Needle([byte[]]$hay, [byte[]]$need, [int]$start) {
    $limit = $hay.Length - $need.Length
    for ($i = $start; $i -le $limit; $i++) {
        $ok = $true
        for ($j = 0; $j -lt $need.Length; $j++) {
            if ($hay[$i + $j] -ne $need[$j]) { $ok = $false; break }
        }
        if ($ok) { return $i }
    }
    return -1
}

$idx = 0
$patched = $false
while ($true) {
    $i = Find-Needle $data $needle $idx
    if ($i -lt 4) { break }
    $idx = $i + 1
    $keylen = [BitConverter]::ToInt32($data, $i - 4)
    if ($keylen -ne $needle.Length) { continue }
    $pp = $i + $needle.Length + 5          # i8 + i32
    if ($pp + 4 -gt $data.Length) { continue }
    $namelen = [BitConverter]::ToInt32($data, $pp)
    if ($namelen -lt 0 -or $namelen -gt 200) { continue }
    $pp += 4
    if ($pp + $namelen + 8 -gt $data.Length) { continue }
    $name = [System.Text.Encoding]::UTF8.GetString($data, $pp, $namelen)
    $pp += $namelen
    $curCrc = [uint32]([BitConverter]::ToInt64($data, $pp) -band 0xFFFFFFFF)
    Write-Host ("    条目: name='{0}' 原CRC=0x{1:X8} @{2}" -f $name, $curCrc, $pp) -ForegroundColor Gray
    if ($curCrc -ne $oldCrc) {
        Write-Warn2 ("该条目 CRC 与原库不符 (0x{0:X8} != 0x{1:X8})，跳过" -f $curCrc, $oldCrc)
        continue
    }
    [BitConverter]::GetBytes([uint32]$newCrc).CopyTo($data, $pp)
    $data[$pp + 4] = 0; $data[$pp + 5] = 0; $data[$pp + 6] = 0; $data[$pp + 7] = 0
    $patched = $true
    Write-Ok ("已写入新 CRC 0x{0:X8}" -f $newCrc)
    break
}

if (-not $patched) {
    Write-Err2 "没能在 catalog 里找到匹配的 ExcelDB.db 条目，未修改。"
    Read-Host "按回车退出"; exit 1
}

[System.IO.File]::WriteAllBytes($catPath, $data)
Write-Ok "TableCatalog.bytes 已更新"

# ---------- 7. 清理 file_check.json ----------
if (Test-Path $fcPath) {
    Remove-Item $fcPath -Force -ErrorAction SilentlyContinue
    Write-Ok "已删除 patcher 残留的 file_check.json"
} else {
    Write-Ok "没有 file_check.json，跳过"
}

# ---------- 8. 最终校验 ----------
Write-Step "最终校验"
$check = [uint32]([BitConverter]::ToInt64([System.IO.File]::ReadAllBytes($catPath), $pp) -band 0xFFFFFFFF)
$real = [Crc32Util]::ComputeFile($dbPath)
if ($check -ne $real) {
    Write-Err2 ("校验失败: catalog=0x{0:X8} 实际=0x{1:X8}" -f $check, $real)
    Write-Warn2 "正在回滚..."
    Copy-Item $bakDb  $dbPath  -Force
    Copy-Item $bakCat $catPath -Force
    Write-Warn2 "已回滚到原版。"
    Read-Host "按回车退出"; exit 1
}
Write-Ok ("catalog CRC = 0x{0:X8} = 数据库实际 CRC，匹配" -f $real)

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host "   汉化完成！现在可以打开游戏了。" -ForegroundColor Green
Write-Host "   备份目录: $backupDir" -ForegroundColor Gray
Write-Host "   还原：把备份目录里的两个文件拷回原位即可。" -ForegroundColor Gray
Write-Host "   游戏小更新后，重新双击本脚本即可再汉化。" -ForegroundColor Gray
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""
Read-Host "按回车退出"
