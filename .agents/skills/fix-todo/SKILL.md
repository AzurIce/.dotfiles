---
name: fix-todo
description: 从已提交的 todo 文件（todo.not / TODO.md 等）读取待办条目，在当前分支原地自主修复，每个条目一个 commit 并把对应条目移入"已解决"节。当用户要求修复 todo 里的问题、处理待办列表，或调用 /fix-todo 时使用。想在 herdr worktree 里派独立 agent 执行时用 fix-todo-herdr。
---

# fix-todo

核心契约：**一个修复 commit = 代码 + 测试 + todo 条目移动**。条目从待办节移入已解决节与代码改动同 commit，git 历史即为 changelog。

本 skill 是**当前检出、当前分支上的原地操作**，自己不做 worktree 隔离。想把修复隔离到 herdr worktree 并派独立 agent 执行，用姊妹命令 `fix-todo-herdr`（编排层，内部最终也是让一个 agent 执行本 skill）。

## 前置检查（不满足则中断）

1. 发现 todo 文件：按序探测 `todo.not`、`docs/todo.not`、`TODO.md`、`todo.md`；多个命中时问用户选哪个。
2. **只读已提交版本**：`git show HEAD:<path>`，不读工作区副本。
   - 文件未被 git 跟踪（git show 失败）→ 提示用户先提交该文件，中断。
   - 已提交版本中待办节为空 → 报告"没有待办条目"，中断。
   - 工作区副本与 HEAD 不一致 → 警告"工作区有未提交改动，将被忽略"，**继续执行**。
3. 列出本次覆盖的条目清单（编号 + 首行文本），**输出后直接开干**，不等确认。用户可用参数筛选子集（如 `/fix-todo #parse`、`/fix-todo 1 3`）。

## 条目与文件结构约定

- 文件恰好一个**待办节**和一个**已解决节**；已解决集中一处（内部子章节、tag 组织随意）。
- 节标题按关键词识别：待办 = `待办` / `存在问题` / `Open` / `TODO`；已解决 = `已解决` / `Resolved` / `Done`。文件缺已解决节时创建之。
- 条目 = 节内顶层列表项；首行是标识文本（用于展示与 `git log -S` 反查），缩进的复现示例、讨论随条目一起移动。
- 语言特定形态：
  - notist：`== 存在的问题` / `== 已解决`；条目 `#[描述]@#tag`；解决时条目追加 `@date="yyyy-mm-dd"`（字符串字面量，postfix 标注，已验证可解析）；
  - markdown：`## Open` / `## Resolved`；普通 bullet；解决时追加 `(resolved: yyyy-mm-dd)`。
- 日期取执行时环境（`date +%F`），不要猜。

## 执行流程

1. **诊断可并行**：可并行派子代理做各条目的根因定位，但**落地串行**——所有修复按顺序提交到当前分支。
2. **逐条目修复**：先写复现失败的测试 → 修复 → 跑测试 → commit。commit 内容 = 代码 + 测试 + todo 条目移动（从待办节删除，附日期追加到已解决节）。message 沿用仓库既有风格（先 `git log --oneline` 观察），body 带一行 `Todo: <条目首行原文>` 供 `git log --grep` 反查。**条目不写 commit hash**——hash 无法写进自身所在 commit（自引用），且 squash 后会悬空。
3. 遵守仓库 AGENTS.md 的资源约束（如本机 cargo 需 `cargo test -j4 -- --test-threads=4`）。
4. **修不了的条目**：不移动、不假装完成，记录原因并在汇报中说明。
5. **范围外新发现的 bug**：不顺手修，追加到当前检出的 todo 文件待办节（工作区改动，不单独提交），并在汇报中提及。
6. **收尾**：逐条目汇报根因（文件:行号）、修复方式、commit hash、测试结果。

## 可追溯性

追溯不依赖条目文本里的 hash，靠两个 squash/rebase 免疫的机制：

- `git log -S "<条目文本>" -- <todo文件>`：条目移动必然包含该文本的增删；
- commit body 的 `Todo:` 行：`git log --grep` 可查。
