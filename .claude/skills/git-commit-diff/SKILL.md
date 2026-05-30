---
name: git-commit-diff
description: >
  将工作区的全部 Git 变更（staged + unstaged）根据 diff 内容自动生成合适的 commit message 并提交。
  当用户说"commit"、"提交"、"commit all changes"、"submit changes"、"把改动提交一下"、
  "帮我生成 commit message"、"commit these changes" 等类似意图时触发。
  也适用于用户要求"看看有什么改动需要提交"、"staging area 有什么"、"check what needs committing" 等场景。
  无论用户是否明确使用"commit"这个词，只要涉及查看工作区变更并准备提交，都应使用此 skill。
---

# Git Commit Diff

根据工作区全部变更自动生成 commit message 并提交。

## 触发条件

用户表达以下任意意图时：
- "commit"
- "提交"
- "commit all changes"
- "submit changes"
- "把改动提交一下"
- "帮我生成 commit message"
- "commit these changes"
- "看看有什么改动需要提交"
- "check what needs committing"
- 任何涉及查看工作区变更并准备提交的请求

## 工作流程

### 1. 查看变更状态

运行以下命令获取完整变更信息：

```bash
git status            # 查看文件状态（新增/修改/删除）
git diff --staged     # 查看已暂存的变更
git diff              # 查看未暂存的变更
```

如果 `git diff --staged` 没有输出（没有 staged 变更），则只关注 `git diff` 的未暂存变更。

### 2. 分析变更内容

根据 diff 内容分析：
- 变更涉及多少文件
- 变更的性质（新增功能、修复 bug、重构、文档更新、配置变更等）
- 变更的规模（少量修改 vs 大量重构）
- 变更是否跨越多个领域（前端、后端、配置等）

### 3. 生成 Commit Message

#### 小改动（修改文件 ≤3，且每处变更简洁明了）

使用单行 conventional commits 格式：

```
<type>(<scope>): <description>
```

Type 选择：
- `feat` — 新功能
- `fix` — Bug 修复
- `docs` — 文档更新
- `style` — 代码格式调整（不影响逻辑）
- `refactor` — 重构
- `perf` — 性能优化
- `test` — 测试相关
- `chore` — 构建/工具链/依赖等

示例：
```
feat(auth): add JWT token validation
fix(db): handle null pointer in query builder
docs(readme): update installation instructions
```

#### 大改动（修改文件 >3，或有复杂逻辑变更、跨模块修改）

使用多行格式：

```
<type>(<scope>): <简短标题>

<详细描述，说明为什么做这个变更、解决了什么问题>

- <变更点 1>
- <变更点 2>
- <变更点 3>
```

示例：
```
feat(api): implement user authentication middleware

Replace the legacy session-based auth with JWT tokens to support
stateless API requests and improve scalability.

- Add JWT signing/verification in auth middleware
- Update user model with token refresh fields
- Add token expiration handling
- Update API docs with new auth headers
```

#### 混合类型变更

如果变更包含多种类型（如既有 bug 修复又有新功能），选择最主要的变更类型作为 type，在描述中提及其他变更。

如果两种类型同等重要，优先使用 `feat`，在描述中说明修复内容。

### 4. 展示变更

执行提交前，向用户展示：

1. 先用 `git status -s` 展示变更文件列表（简洁格式）
2. 展示生成的 commit message

格式示例：
```
变更文件：
 M src/auth.ts
 M src/middleware.ts
 A src/utils/jwt.ts

Commit message:
feat(auth): implement JWT-based authentication

...详细描述...
```

### 5. 执行提交

直接执行，不再询问确认：

1. 如果有未暂存的变更，先运行 `git add -A` 暂存所有变更
2. 使用 `git commit` 提交（不要加 `-m`，用 HEREDOC 传 message 以支持多行）
3. 提交后展示 commit hash 和简短状态

```bash
git add -A
git commit -m "$(cat <<'EOF'
   <commit message>
   EOF
   )"
```

### 6. 安全约束

- **绝不**使用 `git push`，只执行本地 commit
- 如果工作区有大量未跟踪文件（>20 个），展示警告信息后直接继续
- 如果检测到 secrets/credentials 文件（如 `.env`, `*.key`, `id_rsa` 等），展示警告信息后直接继续
- 如果用户要求跳过 hooks（`--no-verify`），拒绝并说明原因，建议修复 hook 问题

## 注意事项

- 始终读取当前项目的 `git log` 来了解团队的 commit message 风格偏好，并尽量保持一致
- 如果 `CLAUDE.md` 或项目文档中有 commit message 规范，优先遵循
- 变更分析要准确：不要根据文件名猜测，要根据 diff 内容判断
- 英文项目用英文 message，中文项目用中文 message，混合项目根据主要代码语言判断
