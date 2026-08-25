---
name: fix-todo-herdr
description: 在 Herdr 会话里为 fix-todo 创建 worktree 并派一个独立 agent 去执行：默认与调用者同种 agent，可手动指定，自动权限模式无人值守运行。当用户在 Herdr 中要求把 todo 修复隔离到 worktree、派 agent 自主修复，或调用 /fix-todo-herdr 时使用。原地修复（不开 worktree）用 fix-todo。
---

# fix-todo-herdr

fix-todo 的 Herdr 编排层：开 worktree → 处理启动门 → 起 agent（自动权限）→ 让它执行 fix-todo → 监控并汇报。修复逻辑本身不在本 skill 里，见 `fix-todo`。

前置：必须在 Herdr 会话内（`test "${HERDR_ENV:-}" = 1`），否则告知用户并中断。herdr 的操作细节遵循 herdr skill。

## 流程

1. **确定 agent kind**：默认用"自己的"——`herdr agent list` 找到当前 pane（`$HERDR_PANE_ID`）上的 agent，取其 kind。识别不出（unknown / 当前 pane 没有 agent）时要求用户显式指定。用户可传参覆盖，如 `/fix-todo-herdr codex`。可用 kind 列表用 `herdr agent` 查看。
2. **建 worktree**：`herdr worktree create --cwd "$PWD" --branch fix/todo-issues --no-focus`，从返回 JSON 读 `.result.workspace.workspace_id` 和 `.result.root_pane.pane_id`。
3. **处理启动门**（新 worktree 必然命中，缺了会导致 agent 起不来或环境不全）：
   - **direnv**：worktree 根有 `.envrc` 时，新路径的 direnv 默认 blocked。在 root pane 跑 `herdr pane run <pane> "direnv allow"`，并等 shell 回到提示符（nix flake 首次求值可能要几分钟，`wait-output` 的 timeout 给足）。
   - **trust 对话框**：kimi 等 agent 在未信任的目录首启会弹 "Trust this folder?"，无人应答时默认选择是 "Don't trust" 直接退出。见第 5 步的应答方法。
4. **起 agent（自动权限）**：dispatch 场景要无人值守，用 agent 的自动审批参数启动（kimi 是 `--yolo`，其他 agent 用等价物）：
   ```bash
   herdr agent start todo-fixer --kind kimi --pane <pane_id> -- --yolo
   ```
   name 取有意义的唯一名。若 agent start 超时，读 pane 看是否卡在 trust 对话框，应答后再确认检测。
5. **应答 trust 对话框**（kimi；其他 agent 按其 UI 调整）：
   - 用 `herdr pane wait-output <pane> --match "Trust this folder?" --source visible` 等对话框出现——**必须 `--source visible`**，`recent` 会命中旧滚动内容里的上一次对话框导致误判；
   - 光标默认在 "Don't trust"，逐键发送：`send-keys up`，**先 read 确认光标移到 "Trust this folder" 再 send enter**，不要一口气发 `up enter`（按键可能先于 TUI 就绪被丢掉）。
6. **派活**：用 `herdr agent prompt` 让新 agent 执行 fix-todo。**用文件路径而不是 slash command**——slash command 依赖具体 agent 的 skill 机制，读文件照做则任何 agent 都行：
   ```
   阅读 ~/.agents/skills/fix-todo/SKILL.md 并严格按它执行。<筛选参数透传，如 "只处理 #parse 条目">
   ```
7. **监控**：`herdr agent wait <name> --timeout 590000` 循环等 settled 状态（修复含编译测试，可能很长，超时属正常，继续等）。**关键坑：agent 跑子代理/swarm 期间 herdr 的状态检测会 flap 出假 `done`**——每次 wait 返回后不要直接下结论，用地面真相核实进度：`git log --oneline <base>..<branch>`（worktree 分支在主仓库的 git dir 里可见，主检出直接查）和 `--source visible` 的屏幕内容。确认 settled 后再进入汇报。yolo 模式下常规工具调用不再弹审批，但 agent 仍可能提问（blocked）——遇到 blocked 看清状况后报告用户，不代为回答。
8. **汇报**：agent 最终汇报渲染在 alternate screen，用 `herdr agent read <name> --source visible --lines 60` 读最后一屏通常即可拿到；`recent-unwrapped` 只含 host scrollback，抓不到 TUI 帧。读不全时按 herdr skill 的 fallback 让它把完整汇报写成文件再读。向用户汇总：各条目修复结果、commit 列表、行为变化、遗留问题，并用 `git show <branch>:<todo文件>` 核实条目确已移入已解决节。
9. **不主动合并分支、不删除 worktree**，等用户确认。合并时提醒：todo 文件的"移入已解决"改动在分支上，冲突按 union 保留双方处理。

## 注意

- 新 agent 在 worktree 里工作，todo 文件的条目移动 commit 也在 worktree 分支上——这正是隔离的意义。
- 全程 `--no-focus`，不切走用户的焦点。
- `--yolo` 只自动审批常规工具调用，不代表可以为它回答问题或替它做决策。
