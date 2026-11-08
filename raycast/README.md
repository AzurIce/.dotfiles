# Raycast

## Script Commands

在 Raycast Settings → Extensions → Script Commands 中添加本仓库的
`raycast/scripts` 目录。Raycast 直接读取这些脚本，无需复制或软链接。

- `New Ghostty Window`：执行 `open -na Ghostty`。
  在 Raycast 中为该命令设置全局快捷键 `Option + Enter`。

快捷键由 Raycast 保存，脚本头部不能声明全局快捷键。

## 设置备份

使用 Raycast 的 `Export Settings & Data` / `Import Settings & Data`
导出和恢复设置、快捷键等。导出内容和加密选项随 Raycast 版本不同而异。
导出文件可能包含私人数据，审查后再决定是否纳入 Git。

不要将 `~/.config/raycast` 整体提交：其中可能包含访问令牌。
也不要将 `~/Library/Application Support/com.raycast.macos` 中运行时数据库
移入仓库或软链接到 Git；它们不是可声明式编辑的配置文件。
