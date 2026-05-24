# Claude Agent Skills · HVA Framework

Skills derived from the four normative documents under `docs/documenta/`:

- [`ARCHITECTURE.md`](../../docs/documenta/ARCHITECTURE.md)
- [`GLOSARIO..md`](../../docs/documenta/GLOSARIO..md)
- [`METODOLOGIA.md`](../../docs/documenta/METODOLOGIA.md)
- [`SPEC_TECNICA.md`](../../docs/documenta/SPEC_TECNICA.md)

Each skill is a folder with a `SKILL.md` (YAML frontmatter + body). Claude Code loads the frontmatter eagerly and reads the body when the description matches the task.

| Skill | When to invoke |
|---|---|
| [`hva-architecture`](hva-architecture/SKILL.md) | Planning module location, layer boundaries, load order, ADRs. |
| [`hva-methodology`](hva-methodology/SKILL.md) | Opening/closing a session, traceability, deviations, formal debt. |
| [`hva-glossary-fma`](hva-glossary-fma/SKILL.md) | Naming any public symbol, accessor, message head or test ID. |
| [`hva-module-authoring`](hva-module-authoring/SKILL.md) | Creating/editing a `.wl` module (header, `BeginPackage`, `::usage`). |
| [`hva-testing`](hva-testing/SKILL.md) | Creating/editing a `.wlt`, defining `VerificationTest`, `TestID`s. |
| [`hva-verification-certificates`](hva-verification-certificates/SKILL.md) | Emitting/validating certificates, fragments, A/G composition. |

## Invocation conventions

- The descriptions are written in the Anthropic skill style: a precise *when to USE* and a *DO NOT use for* pointer to sibling skills. Avoid loading more than one skill at a time unless the task explicitly straddles concerns.
- All canonical references use workspace-relative links to the normative `docs/documenta/` files. When a doc changes, update the skill that cites it.
- Spanish comments are preserved as quotations from the source documents (per METHODOLOGY §5.7); skill prose is in English to align with the rest of the agent toolchain.

## Adding a new skill

1. Create `.claude/skills/<kebab-name>/SKILL.md` with frontmatter `name` + `description`.
2. Keep the description action-oriented and disjoint from existing skills.
3. Cite normative documents by section and link to workspace paths.
4. Update this README's table.
