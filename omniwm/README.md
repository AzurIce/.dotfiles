# OmniWM

由 `hosts/azurmac-macos/home.nix` 使用 Home Manager 的
`mkOutOfStoreSymlink` 将整个目录链接到 `~/.config/omniwm`。

首次启动 OmniWM 时自动生成完整的 `settings.toml`。此后可通过 GUI 或直接编辑
该文件调整配置，修改会保存在本目录中，无需 rebuild。

软件包和 launchd 登录启动由 `programs.omniwm.enable` 管理；不要额外启用
应用内的 Start at Login。yabai 和 skhd 已在此主机的 Nix 配置中停用。

生成配置后，在 `.dotfiles` 仓库中将 `settings.toml` 纳入 Git 管理。
