# AGENTS.md

## 命名与表述

- 永远在版本语义没有被真正定义过的时候不用 v1/v2/v3 之类的称呼指代设计或实现的
  版本。只能用什么就用什么：日期（"2026-09-03 之前的实现"）、commit hash、或
  具体的特征描述。v 几的称呼只有在项目明确定义了版本号体系时才可用。

## 有关 Nix

当需要运行某种工具而系统没有时，如果改系统有 nix，可以查询 nixpkgs 直接 通过
`nix run nixpkgs:xxx` 或者 `nix shell nixpkgs#xxx -c xxx` 来执行。

配置环境时优先在对应项目的 `flake.nix` 中配置，禁止使用 `nix profile`。

## 文档规范

在做文档修改或整理时，永远不要使用历史沿革性表述（Log 性质的文档除外），尽可能
保持简明与高信息密度，保证精准、高效。

## 资源约束

本机 32 核但内存有限（~29GB），跑 cargo 测试/基准（尤其含 wgpu、bevy 等重依赖
的工作区）时必须限制并行度，防止内存爆炸。注意 `-j` 与 `--test-threads` 是两个
不同阶段的开关：

- **编译期**：`cargo test -jN` / `cargo bench -jN` 只限制 rustc 编译并行度
  （见 cargo 文档：--jobs affects the building of the test executable but does
  not affect how many threads are used when running the tests）。
- **测试运行期**：libtest harness 默认按 CPU 核数（32）开线程执行测试，必须另加
  `-- --test-threads=N` 才生效。
- **criterion bench**（`harness = false`）：不走 libtest，bench target 串行执行、
  criterion 内部基本单线程，`cargo bench -jN` 即可。

推荐写法：

```bash
cargo test -j8 -- --test-threads=4
cargo bench -j8
```

## Git 工作流偏好

用户会在功能分支上周期性 `git reset`（soft/mixed）回 main，以便在编辑器里查看
整批改动与 main 的差异。这不是否定工作内容。

- commit 保持**正常粒度**即可；除非用户明确要求合并，否则不要 squash 成单 commit。
- commit 前可以 `git reset --soft` 恢复到 reset 前的最后一次提交，让新提交接回
  原有历史：紧随 reset 之后是 `git reset --soft ORIG_HEAD`。注意 `HEAD@{0}` 是
  当前位置本身（对它 soft reset 是 no-op），要找的是 reset 前那条提交，从
  `git reflog` 里看（`HEAD@{1}` 起）。
