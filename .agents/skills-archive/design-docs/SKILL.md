---
name: design-docs
description: Create, refine, reconcile, archive, and validate project design documents that explain a topic's chosen model, reasoning, consequences, and durable boundaries. Use when the user explicitly asks to work with design docs, invokes /design-status, asks which designs remain unaligned, when an existing design must be brought up to date without losing its explanatory structure, and before user-requested commits that materially touch a design.
---

# Design Docs

Design documents are explanations another engineer can follow. Each active design describes one topic's model, why it was chosen, and the consequences that follow for implementation. A good design is a coherent explanation, not a checklist, a status report, or a file inventory.

## Repository model

Keep current designs under `docs/designs/`, organized by the same layers as the design index:

```text
docs/designs/
├── README.not                  # reading order and design index
├── overview.not                # language overview, if the project has one
├── language/                   # semantics independent of any implementation host
├── world/                      # vault, module, import, reference, and boundary model
├── host/                       # CLI, LSP, daemon, analyzer, renderer, and build architecture
└── archive/                    # retired designs
```

Filenames are semantic and stable, for example `language/type-system.not` or `host/analyzer-snapshot.not`. There are no D-numbers, no sequence prefixes, and no `Design:` commit trailers. Git history is the audit trail; the directory location records whether a design currently governs or is archived.

The design index in `README.not` is the authoritative reading order. It is a curated path through the concepts, not a generated file list. Update it whenever a document is added, moved, renamed, or retired.

## Writing and updating

Before writing, read the repository instructions, the related active and archived designs, and the best explanatory version in Git history. Preserve the repository's documentation language and style. Keep the structure that best explains the topic; do not impose a universal template.

Organize the document around reader questions and concrete models. Prefer headings such as `Transparent Scope`, `Nested Vaults`, `Why Structuring Is Separate`, or `Atomic Rebuild` over generic template headings. Start with the smallest concrete model that lets a reader orient themselves: a claim, a source example, a tree, an event sequence, or a data relationship.

Explain causes and consequences together. Keep rejected alternatives when their failure explains the chosen design. State real constraints with `must`, `cannot`, or `不得`, and say what failure each constraint prevents. Diagrams, tables, type shapes, and command examples are part of the explanation, not decoration.

Update an existing design in place when its central question and model remain useful. Archive only when the governing answer has changed enough that updating would erase a meaningful former philosophy. Retire a design by moving it to `archive/` in the same change that ends its authority; preserve its historical content and link its replacement where helpful.

## Current state and implementation alignment

The only machine-readable state kept in a design file is an optional module attribute at the very top:

```notist
@![implementation = "aligned"]
= Type System
```

Allowed values are:

- `aligned`: the current implementation realizes this design.
- `partial`: the design governs, but implementation is not complete or not fully conformant.
- `missing`: the design is not implemented yet.

The attribute describes the resulting tree, not the commit message and not a work plan. Do not put implementation status, migration phases, task lists, or development diary entries in the prose. Active location means "this design governs"; the attribute means "the repository currently matches it to this degree".

## Commit gate

Before every user-requested commit or amend:

1. Inspect the exact staged snapshot. If nothing is staged, stop rather than infer scope, except for a user-requested message-only correction.
2. Identify affected designs: documents added, edited, moved, or archived, plus active designs whose model or boundaries the staged code materially touches.
3. Check the complete resulting tree against every governing claim of each affected design.
4. Resolve mismatches by completing the implementation, updating or retiring the design, or leaving an intentional `implementation = "partial"` or `"missing"` state.
5. Move or rename files with ordinary Git operations; update `docs/designs/README.not` and every module reference in the same change.
6. Inspect the staged snapshot and commit message again. Do not add design trailers.

After committing, report the commit ID and every active design whose `implementation` attribute is not `aligned`.

## Design status

When the user invokes `/design-status` or asks which designs remain unaligned, run the status script from this skill directory:

```bash
python <skill-dir>/scripts/design_status.py --repo <repository>
```

The script reads the current design tree and Notist module attributes, not Git trailers. It reports:

- active designs by location;
- `aligned`, `partial`, `missing`, and unmarked counts;
- open implementation gaps with their paths;
- uncommitted changes under `docs/designs`.

Use `--all` for the complete per-document state and `--check` when a nonzero exit is useful for CI.

## Verify before handoff

1. Confirm the file location, semantic filename, README entry, and module references match repository conventions.
2. Read only the headings in order. They should describe the topic's reasoning path.
3. Check the opening gives a concrete mental model before dense constraints appear.
4. Confirm the prose explains the model and consequences and contains no delivery status or diary content.
5. Validate factual claims against the code or interfaces they describe without reducing the document to an inventory of those files.
6. Run `notist check` and, when applicable, the repository's normal tests.
