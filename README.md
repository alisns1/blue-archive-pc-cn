# 蔚蓝档案 PC 版（Steam）简体中文补丁

把《蔚蓝档案》Steam 国际服（`Region: tw`，繁体中文）的**文字**替换成**简体中文**。

- 不需要改游戏文件结构、不需要 root、不需要重装
- **游戏小版本更新后，重新运行一次即可**（只要数据库密钥没变）
- 全程本地转换，不联网上传任何游戏文件

> 这是社区自制补丁，与 NEXON / Yostar 无关。请自行评估使用风险。

> **懒得看长文？** ① 把三个文件放进同一个文件夹 ② 完全退出游戏 ③ 双击 `一键汉化.bat`，UAC 点「是」，等到出现「汉化完成」。

---

## 一、准备工作

1. 已安装 Steam 版《蔚蓝档案》，并且**至少启动过一次**（确保 `ExcelDB.db` 已下载）
2. Windows 10 / 11

## 二、使用方法（两步）

### 第 1 步：下载三个文件，放在同一个文件夹里

| 文件 | 从哪下载 |
| --- | --- |
| `BlueArchiveCnPatcher.exe` | 本仓库的 [Releases](../../releases) 页面（约 33 MB） |
| `一键汉化.bat` | 本仓库根目录 |
| `localize_pc.ps1` | 本仓库根目录 |

> 也可以把这三个文件直接放进游戏根目录（`steamapps\common\BlueArchive`）。
> 找不到 `BlueArchiveCnPatcher.exe` 时，脚本会自动从 Releases 下载。

### 第 2 步：双击 `一键汉化.bat`

脚本会依次自动完成：

1. 申请管理员权限（修改游戏文件需要）
2. 自动找到游戏安装目录（读注册表 + Steam 库配置，找不到会让你手动输入）
3. 检查游戏是否在运行（请先完全退出游戏）
4. 备份 `ExcelDB.db` / `TableCatalog.bytes` / `file_check.json` 到 `_ba_cn_backup_日期时间\`
5. 运行 `BlueArchiveCnPatcher.exe` 做本地机翻（**这步比较久，几分钟，请不要关窗口**）
6. **核对 `TableCatalog.bytes` 里的 CRC 校验值**（patcher 转换时会保持 `ExcelDB.db` 的 CRC32 不变，所以通常不需要改；脚本只在实测 CRC 与 catalog 登记的旧值不一致时才改写）
7. 删除 patcher 残留的 `file_check.json`
8. 最终校验 CRC；不一致会自动从备份回滚

看到「汉化完成」就可以开游戏了。

> **实测记录（2026-11）**：Windows 11 + Steam 版 `Ver 474931`，从原版库（MD5 `A7F4A467…`）跑完整流程，patcher 输出库 CRC32 仍为 `0xB4752C76`（与原库一致，说明它自己保持了 CRC），`TableCatalog.bytes` 无需改动，游戏启动正常、界面全简体。

---

## 三、还原成繁体中文

脚本每次运行都会在游戏根目录生成 `_ba_cn_backup_日期时间` 文件夹。
把里面的 `ExcelDB.db` 和 `TableCatalog.bytes` 拷回原来的位置即可：

```
ExcelDB.db            -> BlueArchive_Data\StreamingAssets\PUB\Resource\Preload\TableBundles\
TableCatalog.bytes    -> BlueArchive_Data\StreamingAssets\PUB\Resource\Catalog\TableBundles\
```

（同时把 `file_check.json` 删掉。）

---

## 四、常见问题

**Q：游戏更新了，补丁失效了怎么办？**
A：直接再双击一次 `一键汉化.bat`。小版本更新不换数据库密钥，脚本会重新对新的 `ExcelDB.db` 做机翻并修好 CRC。

**Q：游戏更新后脚本报「数据库没有被修改」？**
A：说明这次更新换了数据库密钥，老的 `BlueArchiveCnPatcher.exe` 打不开新库了。这种情况需要等上游更新 patcher 的密钥（本项目 Releases 会跟着更新）。

**Q：`TableCatalog.bytes` 到底要不要改？**
A：游戏会拿 `TableCatalog.bytes` 里登记的 CRC32 去校验 `ExcelDB.db`，对不上就认为文件损坏、拒绝加载，表现是界面全是 `texttext` 和 `No LocalizeKey`。当前版本的 patcher 转换时会保持数据库 CRC32 不变，所以 catalog 一般不用动；但换版本后不保证，脚本每次都会实测一遍，不一致才改写。

**Q：杀毒软件报毒？**
A：`BlueArchiveCnPatcher.exe` 是 Python 打包的第三方工具，容易被误报。脚本会调用它并对游戏文件做写入，也可能触发提示。介意的话只能手动操作。

**Q：汉化会封号吗？**
A：只改本地文字资源，不碰服务器、不改内存、不改网络协议。理论上和换字体、换语言同类。但任何第三方修改都有风险，自行判断。

---

## 五、技术说明

- `ExcelDB.db` 是 SQLCipher 4 加密的 SQLite（表形如 `<Name>DBSchema(Key INTEGER, Bytes BLOB)`，内容是 FlatBuffers）。patcher 用数据库密钥解密后把繁体文本替换成简体（等长字节替换，不破坏结构）再写回。
- `TableCatalog.bytes` 是 MemoryPack 序列化的资源目录，里面为每个资源文件登记了 CRC32（本版本只存 CRC，不含文件大小）。脚本在 catalog 里定位 `ExcelDB.db` 条目（`i32 keylen + key` → `i8, i32` → `i32 namelen + name` → `i64 crc32`），实测实际 CRC32 与登记值不一致时才改写。

---

## 六、致谢

- 汉化转换器：[delayboy/BlueArchive-Translator](https://github.com/delayboy/BlueArchive-Translator)（本项目 Release 里的 `BlueArchiveCnPatcher.exe` 即基于它，仅把数据库密钥更新到当前版本）
- 简繁词表：[BYVoid/OpenCC](https://github.com/BYVoid/OpenCC)（Apache-2.0）
- catalog 条目格式参考：[asfu222/BlueArchiveLocalizationTools](https://github.com/asfu222/BlueArchiveLocalizationTools)（MIT）

## 七、English summary

A one-click Simplified-Chinese patch for the Steam (global) client of *Blue Archive*.
Put `BlueArchiveCnPatcher.exe`, `一键汉化.bat` and `localize_pc.ps1` in one folder, double-click the `.bat`, and wait a few minutes.
The script locates the game, backs up the two resource files, runs the local converter, **verifies (and if needed rewrites) the CRC32 of `ExcelDB.db` inside `TableCatalog.bytes`**, removes the `file_check.json` leftover, and verifies the result (rolling back on failure).
Re-run the same `.bat` after any minor game update (the converter only needs a new database key when the game bumps its major version).
No server interaction; text-only change. Use at your own risk.
