---
name: record-design
description: Create, update, reconcile, replace, and archive lightweight RFC-like project design documents that record implementation ideas, key decisions, tradeoffs, boundaries, and useful project state. Invoke only when the user explicitly names record-design or directly asks to use this design-record protocol; do not infer invocation from ordinary implementation, documentation, planning, or commit tasks.
---

# Record Design

Maintain design documents as concise, durable project memory. Explain why a design exists, how it works at the architectural level, what choices matter, and what the repository currently implements. Avoid turning a design into a line-by-line implementation guide or a development diary.

## Respect invocation and task scope

Use this protocol only after explicit user invocation. Do not introduce it merely because a repository contains `docs/designs`, a task involves architecture, or an implementation could benefit from documentation.

Explicit invocation does not mean every change needs a design update. Create or update a design only when the user requests a design record or when the invoked task materially changes an active design's durable claims, key decisions, boundaries, or meaningful implementation state.

Leave designs and `Design:` trailers untouched for temporary experiments, exploratory work, mechanical edits, formatting, dependency refreshes, localized fixes, incidental implementation details, and changes unrelated to an active design. If the invoked task has no material design impact, complete the task normally and state briefly that no design update was needed when useful.

## Discover repository conventions

Before writing:

1. Read applicable repository instructions and documentation conventions.
2. Inspect only the designs, documentation, implementation, and Git history or diffs materially related to the requested work.
3. Follow the language used by the repository's relevant documentation. If no convention is evident, use the language of the user's request. Do not assume English.
4. Follow an established repository-specific design convention when one exists. Otherwise, use the convention below.

Ground statements in the discussion and repository evidence. Preserve distinctions between implemented behavior, agreed design, and incomplete work. Do not invent decisions or history.

## Organize design documents

Keep current designs directly under `docs/designs`:

```text
docs/designs/d0001-topic-name.md
```

Keep historical designs under:

```text
docs/designs/archive/d0001-topic-name.md
```

Use a stable four-digit repository-wide design ID. To allocate one, scan both the active and archive directories, take the greatest existing ID, and add one. Never reuse an archived ID. Recheck the ID before committing when concurrent branches may have allocated the same number.

Use a short kebab-case topic in the filename. Start the document with a normal heading such as:

```markdown
# D0001: Topic name
```

Do not require YAML frontmatter, a status field, or other hidden document state. Git records when the design changed; the directory records whether it is current or historical.

When a current design is replaced or retired, move it to `docs/designs/archive` in the commit that retires it. Keep its useful historical content intact. Explain replacements or relationships in ordinary prose and links when that context helps readers.

## Write at the design level

Cover only the sections useful to the design. Common subjects include:

- the motivating context or problem;
- goals, constraints, and explicit non-goals;
- the design idea, component relationships, or data flow;
- important decisions, alternatives, and tradeoffs;
- compatibility, migration, operational, or security consequences;
- the repository's meaningful current implementation state.

Use headings appropriate to the repository and topic rather than forcing a fixed template. Include file, module, command, or API names when they make the design traceable. Omit volatile line-level detail unless it is itself a design constraint.

Update an existing design while its central idea remains the same. Create a new ID when the central approach or key assumptions change enough that rewriting the old document would obscure project history.

## Keep the repository aligned

Treat active designs as assertions about the repository, subject only to an explicit WIP transition. When editing without committing, compare designs with the resulting worktree and report any intentional mismatch. When preparing a commit, compare them with the staged snapshot; unstaged implementation work does not make a staged design truthful.

Do not reconcile the entire design collection for an unrelated or narrowly scoped change. Check only active designs whose claims the requested work could materially alter.

Do not create commits unless the user requests them. If a requested ordinary commit would leave an affected active design inconsistent, update the implementation or design first. Otherwise, record the temporary mismatch with the WIP operation described below.

Archived designs are historical records and need not describe the current implementation.

## Record transitions with Design trailers

Keep design operations orthogonal to Conventional Commits. Put one `Design:` trailer at the end of a commit message only when a design state changes:

```text
feat(auth): replace the session model

Design: =D0008, -D0003
```

Accept one or more comma-separated operations. Require a comma followed by one space, include an operator on every ID, and mention each ID at most once per commit:

```text
Design: <operation>, <operation>, ...
```

Each operation must match `[*=-]D[0-9]{4}`:

- `*D0008` — after this commit, D0008 may temporarily differ from the repository. This WIP exception persists until a later `=D0008` or `-D0008`.
- `=D0008` — after this commit, D0008 is active and verified against the committed repository snapshot. Use this for an aligned new design and to close WIP.
- `-D0008` — after this commit, D0008 is no longer current. Move its file from the active directory to the archive directory in the same commit.

Use the trailer only for actual transitions, never merely because the skill was invoked or a commit mentions design-related code. A commit without a `Design:` trailer does not change design state and must preserve alignment for every affected active design not covered by an open `*Dxxxx` exception. Mentioning `D0008` in ordinary commit prose is only a reference and has no state meaning.

Prefer a stable ordering within a trailer: `*`, then `=`, then `-`, with IDs ascending inside each group.

## Handle common transitions

Create an already-aligned design and implementation together:

```text
feat(cache): add generation-based invalidation

Design: =D0012
```

Commit an incomplete implementation of a design:

```text
refactor(auth): begin the session migration

Design: *D0008
```

Restore alignment after one or more WIP commits:

```text
refactor(auth): complete the session migration

Design: =D0008
```

Replace a design atomically by adding the new design, aligning the implementation, and archiving the old design:

```text
refactor(auth): adopt rotating refresh tokens

Design: =D0008, -D0003
```

For a replacement implemented over several commits, leave the old design active while it still describes the implementation. Open the new design with `*Dxxxx`; archive the old design only in the final commit that aligns the new design.

## Verify before handoff

Before declaring the work complete:

1. Confirm active and archived filenames, IDs, links, and language follow repository conventions.
2. Compare factual claims with the relevant implementation and diff.
3. Ensure the design emphasizes reasoning and boundaries rather than incidental implementation detail.
4. If committing, inspect the exact staged snapshot and validate every `Design:` operation against the resulting tree.
5. Report any open `*Dxxxx` exception or uncommitted mismatch clearly.
