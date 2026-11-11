# 蔚蓝档案 国际服 PC（Steam）版汉化补丁

基于 [delayboy/BlueArchive-Translator](https://github.com/delayboy/BlueArchive-Translator) 的汉化工具，
**仅更新了游戏大版本更新后轮换的数据库密钥**，其余逻辑与原作者完全一致。

> Android 版汉化工具见另一个仓库：[blue-archive-gl-simplified](https://github.com/alisns1/blue-archive-gl-simplified)

## 下载

到本仓库的 [Releases](../../releases) 页面下载 `BlueArchiveCnPatcher.exe`。

## 使用方法

1. **退出游戏**（包括 Steam 客户端里的 BlueArchive 页面）
2. 把 exe 放进**游戏根目录**（和 `BlueArchive_Data` 文件夹同级）：
   `...\steamapps\common\BlueArchive\`
3. **右键 → 以管理员身份运行**
4. 等待 5–10 分钟。窗口会逐条打印繁体原文，**中途没有任何进度提示，属于正常现象，不要关窗口**
5. 完成后打开游戏，界面即为简体中文

## 适用条件

- 游戏版本需与补丁匹配：`BlueArchive.db` 大小为 **357,109,760 字节**
  （`...\BlueArchive_Data\StreamingAssets\PUB\Resource\Preload\TableBundles\ExcelDB.db`）
- **游戏每次大版本更新后数据库密钥可能再次轮换**，届时本补丁会失效（表现为闪退或「数据库连接失败」）
- 只支持国际服（GL）PC 版，不支持日服、国服

## 文件校验

`BlueArchiveCnPatcher.exe`

| 项目 | 值 |
| --- | --- |
| 大小 | 34,862,124 字节 |
| MD5 | `DF948808A19FD6F7DCDC9CC8625574DD` |
| SHA256 | `13CD7883C1F077817833B342E2D3458E56D2BB9AC2D093C53224EC700F116FD2` |

## 还原

- 补丁运行前会把原数据库备份为 `ExcelDB.db.bak`，需要还原时改回原名即可
- 或者用 Steam 的「验证游戏文件完整性」恢复

## 说明

- 只修改**本地**游戏数据文件，不涉及联机、不修改游戏客户端、不需要重装
- 本仓库**不包含任何游戏资源文件**
- 请支持官方正版

## 致谢

- [delayboy/BlueArchive-Translator](https://github.com/delayboy/BlueArchive-Translator) —— 汉化逻辑与打包工具来源，本补丁只是更新了其中失效的密钥
- [OpenCC](https://github.com/BYVoid/OpenCC) —— 繁简转换词库

## English Summary

A Simplified Chinese localization patch for **Blue Archive Global (Steam / PC)**.
Built on [delayboy/BlueArchive-Translator](https://github.com/delayboy/BlueArchive-Translator);
only the rotated database key has been updated.

Download the executable from the [Releases](../../releases) page, place it in the game root
directory (`...\steamapps\common\BlueArchive\`, next to `BlueArchive_Data`), close the game,
run it as Administrator, and wait 5–10 minutes without closing the window.
It works on the local game data only — no client modification, no reinstall, no online interaction.
