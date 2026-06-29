#!/usr/bin/env -S cargo +nightly -Zscript
---
[package]
name = "dotfiles-link"
version = "0.1.0"
edition = "2021"
---

//! Dotfiles 链接脚本 —— 将 dotfiles 仓库中的配置文件链接到系统对应位置。
//!
//! 用法:
//!   cargo +nightly -Zscript scripts/link.rs                  # 创建所有链接
//!   cargo +nightly -Zscript scripts/link.rs --dry-run        # 预览操作
//!   cargo +nightly -Zscript scripts/link.rs --force          # 强制覆盖
//!   cargo +nightly -Zscript scripts/link.rs --force --bak    # 覆盖前备份到 .bak
//!
//! 已正确指向源的 symlink 会自动跳过。
//! 仅使用符号链接（Windows 需管理员权限或开启开发者模式）。

use std::env;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};

// ─── 映射表 ───────────────────────────────────────────────
//
// 格式: (仓库内相对路径, 目标绝对路径或相对路径, 是否为目录)
// 目标路径若以 ~ 开头会被展开为 HOME；相对路径相对于 HOME。
//
// 按需注释掉你不需要的条目即可。

const MAPPINGS: &[(&str, &str, bool)] = &[
    // ── 跨平台工具 ──
    // (".claude", "~/.claude", true),
    // (".codex",  "~/.codex",  true),
    (".pi", "~/.pi", true),
    // Neovim: Windows 上推荐改为 "~/AppData/Local/nvim"
    // ("nvim",    "~/.config/nvim", true),

    // ── 终端 / Shell ──
    // ("ghostty/config", "~/.config/ghostty/config", false),
    // ("ashell/config.toml", "~/.config/ashell/config.toml", false),

    // ── 编辑器 ──
    // ("opencode", "~/.config/opencode", true),

    // ── 其它工具 ──
    // ("rua/config.toml", "~/.config/rua/config.toml", false),
    // ("caddy/Caddyfile", "~/.config/caddy/Caddyfile", false),

    // ── macOS 专用 ──
    // (".yabairc", "~/.yabairc", false),

    // ── Linux 专用 ──
    // ("hypr",     "~/.config/hypr",    true),
    // ("fcitx5",   "~/.config/fcitx5",  true),
];

// ─── 工具函数 ────────────────────────────────────────────

fn home() -> PathBuf {
    #[cfg(windows)]
    {
        // Windows 优先用 USERPROFILE，其次 HOME
        env::var("USERPROFILE")
            .or_else(|_| env::var("HOME"))
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("."))
    }
    #[cfg(not(windows))]
    {
        env::var("HOME")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("."))
    }
}

fn resolve_target(raw: &str) -> PathBuf {
    if raw.starts_with("~/") {
        home().join(&raw[2..])
    } else if raw.starts_with('~') {
        home().join(&raw[1..])
    } else if Path::new(raw).is_absolute() {
        PathBuf::from(raw)
    } else {
        home().join(raw)
    }
}

// ─── 链接 / 复制逻辑 ─────────────────────────────────────

/// 检查 dst 是否已经是正确指向 src 的 symlink。
fn is_correct_symlink(src: &Path, dst: &Path) -> bool {
    if !dst.is_symlink() {
        return false;
    }
    match (fs::canonicalize(src), fs::canonicalize(dst)) {
        (Ok(s), Ok(d)) => s == d,
        _ => false,
    }
}

/// 删除目标（文件或目录）。
fn remove_target(target: &Path) -> io::Result<()> {
    if target.is_symlink() || target.is_file() {
        fs::remove_file(target)
    } else if target.is_dir() {
        fs::remove_dir_all(target)
    } else {
        Ok(())
    }
}

/// 备份目标到 target.bak（如果存在）。
fn backup_target(target: &Path) -> io::Result<Option<PathBuf>> {
    if target.exists() {
        let bak = target.with_extension(format!(
            "{}.bak",
            target.extension().unwrap_or_default().to_string_lossy()
        ));
        // 如果 .bak 已存在，先删掉
        if bak.exists() {
            if bak.is_dir() {
                fs::remove_dir_all(&bak)?;
            } else {
                fs::remove_file(&bak)?;
            }
        }
        fs::rename(target, &bak)?;
        Ok(Some(bak))
    } else {
        Ok(None)
    }
}

#[cfg(windows)]
fn symlink_file_win(src: &Path, dst: &Path) -> io::Result<()> {
    std::os::windows::fs::symlink_file(src, dst)
}

#[cfg(not(windows))]
fn symlink_file_win(src: &Path, dst: &Path) -> io::Result<()> {
    std::os::unix::fs::symlink(src, dst)
}

#[cfg(windows)]
fn symlink_dir_win(src: &Path, dst: &Path) -> io::Result<()> {
    std::os::windows::fs::symlink_dir(src, dst)
}

#[cfg(not(windows))]
fn symlink_dir_win(src: &Path, dst: &Path) -> io::Result<()> {
    std::os::unix::fs::symlink(src, dst)
}

fn link_dir(src: &Path, dst: &Path) -> io::Result<()> {
    symlink_dir_win(src, dst)
}

fn link_file(src: &Path, dst: &Path) -> io::Result<()> {
    symlink_file_win(src, dst)
}

// ─── 主逻辑 ──────────────────────────────────────────────

fn main() {
    let args: Vec<String> = env::args().collect();
    let dry_run = args.iter().any(|a| a == "--dry-run" || a == "-n");
    let force = args.iter().any(|a| a == "--force" || a == "-f");

    // dotfiles 根目录 = 当前工作目录（从这里执行脚本）
    let dotfiles_root = env::current_dir().unwrap_or_else(|_| PathBuf::from("."));

    let bak = args.iter().any(|a| a == "--bak");

    println!("🔗 Dotfiles Linker");
    println!("   源目录: {}", dotfiles_root.display());
    println!("   HOME:   {}", home().display());
    if dry_run {
        println!("   *** DRY RUN 模式 — 不会实际修改文件 ***");
    }
    if force {
        println!("   *** FORCE 模式 — 直接覆盖已有目标 ***");
    }
    if bak {
        println!("   *** BAK 模式 — 覆盖前备份到 .bak ***");
    }
    println!();

    let mut ok = 0;
    let mut skipped = 0;
    let mut failed = 0;

    for (src_rel, target_raw, is_dir) in MAPPINGS {
        let src = dotfiles_root.join(src_rel);
        let target = resolve_target(target_raw);

        // 检查源是否存在
        if !src.exists() {
            println!("⏭ 跳过: 源不存在  {}", src_rel);
            skipped += 1;
            continue;
        }

        print!(
            "{} {}  →  {}",
            if dry_run { "🔍" } else { "🔗" },
            src_rel,
            target.display()
        );

        // 已经是正确的 symlink
        if is_correct_symlink(&src, &target) {
            if dry_run {
                println!(" ✓ 已链接");
            }
            ok += 1;
            continue;
        }

        if dry_run {
            if target.exists() {
                if force {
                    print!(" (将覆盖{})", if bak { "，备份到 .bak" } else { "" });
                } else {
                    print!(" (已存在, 加 --force 覆盖)");
                }
            } else {
                print!(" (新创建)");
            }
            println!();
            ok += 1;
            continue;
        }

        // ── 实际执行 ──

        // 目标已存在但不是正确 symlink
        if target.exists() {
            if !force {
                println!(" ❌ 目标已存在 (用 --force 覆盖)");
                skipped += 1;
                continue;
            }
            if bak {
                match backup_target(&target) {
                    Ok(Some(bak_path)) => print!(" [已备份到 {}]", bak_path.display()),
                    Ok(None) => {}
                    Err(e) => {
                        println!(" ❌ 备份失败: {e}");
                        failed += 1;
                        continue;
                    }
                }
            } else {
                remove_target(&target).unwrap_or(());
            }
        }

        // 确保父目录存在
        if let Some(parent) = target.parent() {
            if let Err(e) = fs::create_dir_all(parent) {
                println!(" ❌ 创建父目录失败: {e}");
                failed += 1;
                continue;
            }
        }

        // 创建链接
        let result = if *is_dir {
            link_dir(&src, &target)
        } else {
            link_file(&src, &target)
        };

        match result {
            Ok(()) => {
                println!(" ✓");
                ok += 1;
            }
            Err(e) => {
                println!(" ❌ {e}");
                failed += 1;
            }
        }
    }

    println!();
    println!(
        "─── 结果: {} 成功, {} 跳过, {} 失败 ───",
        ok, skipped, failed
    );
}
