---
name: design-docs
description: Create, refine, reconcile, replace, archive, and validate project design documents that explain a topic's chosen model, reasoning, consequences, and durable boundaries in a human-readable form. Use when the user explicitly asks to work with design docs, when an existing design must be brought up to date without losing its explanatory structure, and before user-requested commits or amends to validate affected designs and Design trailers. Preserve topic-driven narrative and repository-local writing style; do not normalize designs into a universal template or compress them into summaries.
---

# Design Docs

Preserve the result of design thinking as an explanation another engineer can follow, not as a checklist they must decode. Make the reader understand the model, why it was chosen, and how its consequences apply to new work.

## Scope

Use the full workflow only when the user explicitly asks to create, update, reconcile, replace, archive, or otherwise use design docs.

Create a new design only when:

- the user explicitly requests one; or
- a material missing design record is identified, proposed, and approved by the user.

Do not infer a new document from architecture work, an implementation task, or the presence of `docs/designs/`. Run the commit gate before every user-requested commit or amend, but do not create a document or trailer when no design state changes.

## Recover the local design voice

Before writing:

1. Read applicable repository instructions and documentation conventions.
2. Read the related active and archived designs before broad implementation detail.
3. For an existing design, inspect its Git history and nearby designs. Identify the version whose organization best explains the topic, even if its facts are stale.
4. Use that explanatory structure as the baseline. Update obsolete concepts, examples, and claims in place instead of replacing the document with a shorter summary.
5. Inspect only the code, interfaces, diffs, and external references needed to validate real constraints.
6. Follow the repository's documentation language and established level of formality.

Treat the user's discussion and established design decisions as the source of intent. Use repository evidence to avoid invention, not to turn the document into an inventory of current files.

## Organize around the topic

Make each document answer a concrete question such as:

- How do scopes and attributes relate to the content tree?
- Why is a vault marker necessary, and how is a root discovered?
- Why are lowering and structuring separate?
- How does a runtime distinguish committed conversation from external actions?

Organize sections by the concepts, scenarios, or reader questions that develop the answer. Prefer headings such as `Transparent Scope`, `Nested Vaults`, `Why Structuring Is Separate`, `Position Encoding`, or `Atomic Rebuild`.

Do not impose a universal sequence such as `Design stance / Conceptual model / Boundaries / Invariants / Scope`. Use a heading like `Invariants` only when collecting rules genuinely makes the topic easier to understand; otherwise state each rule beside the concept and reason that govern it.

Allow different documents to have different shapes and lengths. A directory-to-module rule may need one analogy and one tree; a language-server design may need lifecycle, position, concurrency, and safety sections. Completeness is relative to the topic, not to a template.

## Write for understanding

Start with the smallest concrete model that lets the reader orient themselves: a direct claim, motivating failure, source example, directory tree, event sequence, or data relationship. Introduce terminology as the reader needs it.

Keep causes and consequences together:

- explain why a boundary exists, not only that implementations must obey it;
- show a representative example before or beside abstract rules;
- use explicit contrasts to prevent category errors;
- retain a rejected alternative when its failure explains the chosen design;
- allow limited local repetition when it makes a section independently understandable.

Prefer explanatory prose over legalistic assertion. Use `must`, `cannot`, or `不得` for real constraints, but accompany important constraints with the failure they prevent. A paragraph that only says what is forbidden usually needs either a reason, an example, or removal.

Use diagrams, tables, pseudotypes, APIs, and commands when they make a relationship concrete. Treat sample types as semantic contracts unless exact syntax is itself the design.

Do not equate density with brevity. Preserve the intermediate reasoning that lets a reader reconstruct the design. Remove repetition that adds no understanding, but do not collapse a detailed design into a conclusion index.

## Keep design separate from delivery

Write active designs as current project direction, even when implementation is incomplete. It is appropriate to explain parser behavior, component ownership, CLI/LSP behavior, recovery algorithms, or renderer consequences when they reveal how the design works.

Do not use active design prose to report:

- current implementation status or missing features;
- migration phases, implementation order, milestones, or task lists;
- test plans or completion criteria;
- temporary workarounds or development diary entries;
- file-by-file implementation inventories.

Rewrite an implementation fact as a durable consequence when it matters. Put delivery state in issues, plans, commits, or project-management artifacts. Put temporary implementation/design mismatch in the `Design:` transition, not in the document.

## Update, replace, or archive

Update the existing document when its central question and chosen model remain useful, even if syntax, APIs, terminology, or implementation details changed substantially. Preserve its stable ID and explanatory skeleton where possible.

Do not archive a design merely because:

- some sections are obsolete;
- a later document summarizes or overlaps it;
- several topics could be merged into a broader architecture overview;
- implementation is incomplete or temporarily inconsistent;
- its filename or format needs normalization.

Replace and archive only when the governing answer has changed enough that updating in place would erase a meaningful former philosophy or foundational assumption. Archive a retired design in the same change that ends its authority, preserve its historical content, and link its replacement where helpful.

If a summary document adds no independent model, treat it as an index or remove it; do not let it supersede detailed topic designs.

## Organize files

Keep active designs directly under `docs/designs` and historical designs under `docs/designs/archive`:

```text
docs/designs/D0001-topic-name.md
docs/designs/archive/D0001-topic-name.md
```

Use a stable uppercase `D` plus four-digit repository-wide ID in the heading, filename, links, and `Design:` trailer. Allocate the next ID by scanning active and archive directories and incrementing the greatest ID; never reuse one.

Follow an established repository convention when it differs. If the repository uses lowercase filenames or a non-Markdown extension, do not mix conventions or migrate casing incidentally.

Do not require frontmatter, status fields, dates, owners, or document-level project state. Git records evolution; active versus archive records whether the design remains governing.

## Keep design and repository aligned

Treat an active design as normative direction, not a claim that every described capability is already implemented. Incompleteness does not make a design false; implementation that contradicts its model or boundary does.

For work that materially touches an active design:

- check whether the change conforms to its chosen model and consequences;
- do not rewrite the design merely to mirror the latest implementation;
- fix accidental contradictions in implementation;
- update or replace the design explicitly when intended direction changes;
- record temporary inconsistency outside the prose.

Do not reconcile unrelated designs. Do not create commits unless the user requests them.

## Commit gate

Before every user-requested commit or amend:

1. Inspect the exact staged snapshot. If nothing is staged, stop rather than infer scope. If `docs/designs/` does not exist, no design trailer check applies.
2. Identify affected designs: documents added, edited, or archived, plus active designs whose model or boundaries staged code materially touches.
3. Check staged work against their governing claims. Distinguish incompleteness from contradiction.
4. Resolve contradictions by changing implementation, updating/replacing the design, or explicitly opening/retaining a WIP mismatch.
5. Compute actual design transitions and add exactly one `Design:` trailer only when a state changes.
6. Inspect the final commit message and staged snapshot again before committing.

After committing, report the commit ID and every open `*Dxxxx` mismatch.

## Design trailers

Keep design operations orthogonal to Conventional Commits:

```text
feat(auth): replace the session model

Design: =D0008, -D0003
```

Use comma-and-space-separated operations matching `[*=-]D[0-9]{4}`; include an operator on every ID and mention each ID at most once:

- `*D0008`: implementation may temporarily contradict D0008 until a later `=D0008` or `-D0008`.
- `=D0008`: D0008 is active and the resulting implementation does not contradict it. Use for a new active design and to close WIP.
- `-D0008`: D0008 no longer governs; archive it in the same commit.

Order operations as `*`, then `=`, then `-`, ascending by ID within each group. Do not repeat an operation because a design was merely consulted.

## Verify before handoff

1. Confirm IDs, filenames, links, archive placement, and language follow repository conventions.
2. Compare the result with the best explanatory version in Git history. Confirm useful examples and reasoning were not lost merely for uniformity.
3. Read only the headings in order. They should describe the topic's reasoning path, not a reusable template.
4. Check that the opening gives a reader a concrete mental model before dense constraints appear.
5. Remove delivery status and diary content while preserving implementation consequences that explain the design.
6. Compare factual claims with relevant evidence without reducing the document to that evidence.
7. If committing, validate every `Design:` operation against the resulting tree and report open WIP mismatches.
