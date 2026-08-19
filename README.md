# Dotfiles

面向 Windows 和 Linux 的终端配置仓库，包含 Neovim、WezTerm、tmux 和 Yazi。

本仓库只部署配置，不负责通过 apt、dnf、pacman、Scoop 或其他包管理器安装应用。Linux 安装脚本唯一会下载的内容是 tmux Plugin Manager（TPM）。

## 目录

```text
.
├── install/   # 安装预览、配置链接和只读环境诊断
├── nvim/      # LazyVim 配置及插件锁文件
├── tmux/      # tmux 主配置和本地覆盖
├── wezterm/   # 模块化 WezTerm 配置
└── yazi/      # Yazi 配置
```

## 前置条件

安装脚本需要：

- Windows：PowerShell；建议安装 Git。
- Linux：Bash、Git、`mkdir`、`mv`、`ln`、`readlink`、`date`。

按需安装的应用：

- Neovim
- WezTerm
- tmux（Linux）
- Yazi
- `rg`、`fd`、`fzf`
- JetBrains Mono 或 Nerd Font

脚本不会因为某个可选应用尚未安装而拒绝链接其配置。可以先部署配置，之后再安装应用。

## 部署前诊断

诊断脚本只读取环境并输出 `OK`、`WARN`、`FAIL`，不会安装软件或修改配置。

Linux：

```bash
cd ~/.dotfiles
bash install/doctor_linux.sh
```

Windows：

```powershell
Set-Location "$HOME\.dotfiles"
.\install\doctor_windows.ps1
```

`FAIL` 表示安装脚本或仓库的必要条件缺失；`WARN` 通常表示某个应用、字体或可选工具尚未安装。

## Linux 首次部署

将仓库放在一个长期不移动的位置：

```bash
git clone git@github.com:x-7461destiny/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

先检查环境和预览操作：

```bash
bash install/doctor_linux.sh
bash install/install_linux.sh --dry-run
```

没有冲突时正式部署：

```bash
bash install/install_linux.sh
```

如果目标位置已有配置，并确认需要保留为时间戳备份：

```bash
bash install/install_linux.sh --dry-run --backup-existing
bash install/install_linux.sh --backup-existing
```

脚本会部署：

| 仓库路径 | Linux 目标 |
| --- | --- |
| `nvim/` | `${XDG_CONFIG_HOME:-$HOME/.config}/nvim` |
| `tmux/.tmux/.tmux.conf` | `~/.tmux.conf` |
| `tmux/.tmux/.tmux.conf.local` | `~/.tmux.conf.local` |
| `wezterm/` | `${XDG_CONFIG_HOME:-$HOME/.config}/wezterm` |
| `yazi/config/` | `${XDG_CONFIG_HOME:-$HOME/.config}/yazi` |

## Windows 首次部署

```powershell
git clone git@github.com:x-7461destiny/dotfiles.git "$HOME\.dotfiles"
Set-Location "$HOME\.dotfiles"
```

诊断和预览：

```powershell
.\install\doctor_windows.ps1
.\install\install_windows.ps1 -WhatIf
```

正式部署：

```powershell
.\install\install_windows.ps1
```

如果目标位置已有配置，并确认需要备份后替换：

```powershell
.\install\install_windows.ps1 -BackupExisting -WhatIf
.\install\install_windows.ps1 -BackupExisting
```

Windows 会部署 Neovim、WezTerm 和 Yazi。创建符号链接可能需要启用 Windows Developer Mode 或使用提升权限的 PowerShell。

## 本机私有配置

通用 WezTerm 配置不保存 SSH 地址、用户名、私钥路径、代理地址、WSL 用户或本机程序绝对路径。

为当前机器创建私有配置：

Linux：

```bash
cp wezterm/config/machine.example.lua wezterm/config/machine_local.lua
```

Windows：

```powershell
Copy-Item wezterm\config\machine.example.lua wezterm\config\machine_local.lua
```

然后编辑 `machine_local.lua`。该文件已被 Git 忽略，不会通过普通提交推送到远端。推荐在 `launch_menu` 中使用 `~/.ssh/config` 定义的 Host alias，避免重复保存 IP、端口和用户名。

如果没有 `machine_local.lua`，WezTerm 会使用可移植默认值：Windows 使用 PATH 中的 `pwsh`/`bash`，Linux/macOS 使用 `$SHELL`，不创建私人 SSH Domain，也不启用特定 WSL Domain。

### 本机背景图片

背景图片应放在仓库外，避免再次增大 Git 历史。推荐位置：

- Windows：`$HOME/Pictures/WezTerm/background.jpg`
- Linux：`$HOME/.local/share/wezterm/background.jpg`

在 `wezterm/config/machine_local.lua` 中配置：

```lua
local wezterm = require('wezterm')

return {
   background = {
      image = wezterm.home_dir .. '/Pictures/WezTerm/background.jpg',
      overlay_color = '#000000',
      overlay_opacity = 0.85,
   },
}
```

`overlay_opacity` 越大，图片越暗，终端文字越清晰；设为 `0` 表示不增加黑色遮罩。图片会保持宽高比、居中并裁剪填满窗口。建议使用接近显示器分辨率的 JPEG 或 PNG，例如 1920×1080、2560×1440；没有硬性尺寸限制，但过大的图片会增加解码时间和显存占用。

## 更新

配置通过符号链接指向仓库，更新仓库即可更新大部分配置：

```bash
cd ~/.dotfiles
git pull
```

- WezTerm 通常会自动重载。
- Neovim 和 Yazi 建议重启。
- tmux 可执行 `tmux source-file ~/.tmux.conf`。
- 只有部署目标发生变化时才需要重新运行安装脚本。

不要移动或删除仓库目录，否则现有符号链接会失效。

## 备份和恢复

使用 `--backup-existing` 或 `-BackupExisting` 时，旧配置会被移动为：

```text
<原路径>.dotfiles-backup-YYYYMMDD-HHMMSS
```

恢复时先移除对应的 dotfiles 符号链接，再把备份移动回原路径。执行恢复前应通过 `readlink`（Linux）或 `Get-Item`（Windows）确认目标确实是符号链接，避免误删真实目录。

## 安全约定

- 安装脚本默认不会覆盖已有配置。
- 始终先运行 `--dry-run` 或 `-WhatIf`。
- 私钥、令牌、密码和 `machine_local.lua` 不应提交到仓库。
- `machine.example.lua` 只提供无敏感信息的结构示例。
