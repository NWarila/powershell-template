# ADR-repo/0001: Module layout — src/Public+Private with explicit manifest exports

| Field          | Value                                          |
| -------------- | ---------------------------------------------- |
| Status         | Accepted                                       |
| Date           | 2026-06-02                                     |
| Authors        | Nick Warila (@NWarila)                          |
| Decision-maker | Nick Warila (sole portfolio maintainer)        |
| Consulted      | PowerShell Gallery publishing requirements; PSScriptAnalyzer PSGallery ruleset. |
| Informed       | Consumers that create repositories from this template. |
| Reversibility  | Medium                                         |
| Review-by      | N/A (Accepted)                                 |

## TL;DR

PowerShell modules created from this template keep shippable code under
`src/<ModuleName>/`, split functions into `Public/` (exported) and `Private/`
(internal) folders with one function per file, and declare an explicit
`FunctionsToExport` list in the manifest. Wildcard exports (`'*'`) are
prohibited. `CmdletsToExport`, `AliasesToExport`, and `VariablesToExport` are
empty arrays unless the module genuinely ships those. The manifest declares
`CompatiblePSEditions = @('Core', 'Desktop')` with a `PowerShellVersion = '5.1'`
floor.

## Context and Problem Statement

A template's job is to make the right structure the path of least resistance.
PowerShell gives module authors a lot of latitude: code can live anywhere, the
manifest can export with wildcards, and there is no enforced separation between
public and internal functions. That latitude produces inconsistent modules that
are slow to load, hard to review, and surprising to consume.

Three concrete problems recur in modules that grow without an enforced layout:

1. **Wildcard exports.** `FunctionsToExport = '*'` forces PowerShell to load and
   parse the entire module to discover its exports. This slows `Import-Module`
   and `Get-Command -Module`, and it makes the public surface invisible until
   runtime. It also trips the PSScriptAnalyzer `PSUseToExportFieldsInManifest`
   rule that the PSGallery ruleset enforces.
2. **No public/private boundary.** Without a structural split, internal helpers
   leak into the consumer's command surface, and there is no diffable signal
   when the public API changes.
3. **Single-file modules.** A monolithic `.psm1` makes blame useless and merge
   conflicts frequent as the module grows.

## Decision Drivers

1. **Fast, predictable module load.** Explicit exports let PowerShell skip the
   load-and-analyze step.
2. **Reviewable public contract.** Changing the public surface should be a
   deliberate, diffable edit to one line of the manifest.
3. **PSGallery readiness.** The layout must satisfy the rules the PowerShell
   Gallery and the PSGallery PSScriptAnalyzer preset enforce, so a module can be
   published without rework.
4. **Cross-edition support.** Modules should run on both Windows PowerShell and
   PowerShell 7+ unless they declare otherwise.
5. **Green out of the box.** A freshly created repository must pass CI with no
   edits, giving new maintainers a working reference.

## Considered Options

1. **`src/` with `Public/`+`Private/`, one function per file, explicit
   exports** (chosen).
2. **Flat root layout** — `.psm1` and `.psd1` at the repository root with all
   functions inline.
3. **`src/` but a single `.psm1`** — separates code from scaffolding but keeps
   all functions in one file.

## Decision Outcome

Chosen: option 1.

- `src/<ModuleName>/` holds the manifest, root module, and `Public/` +
  `Private/` function folders.
- The root module dot-sources every `*.ps1` under `Private/` then `Public/`,
  and exports only the public base names via `Export-ModuleMember`.
- The manifest's `FunctionsToExport` is the authoritative export contract and
  lists each public function by name. `CmdletsToExport`, `AliasesToExport`, and
  `VariablesToExport` are `@()`.
- `CompatiblePSEditions = @('Core', 'Desktop')`; `PowerShellVersion = '5.1'`.

### Consequences

- **Positive:** fast load; reviewable API; PSGallery-publishable without
  rework; clear internal/external boundary; small, conflict-resistant diffs.
- **Negative:** more files than a flat layout; maintainers must remember to add
  new public functions to `FunctionsToExport`. The test suite guards this by
  asserting the manifest exports the expected functions and no wildcard.

## More Information

- Reference: [docs/reference/module-structure.md](../../reference/module-structure.md)
- Rationale: [docs/explanation/why-this-layout.md](../../explanation/why-this-layout.md)
- Diagram: [docs/diagrams/module-layout.mmd](../../diagrams/module-layout.mmd)
