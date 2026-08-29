# ADR-template/0003: Use a Layout-Aware Canonical Build Script

| Field          | Value                                          |
| -------------- | ---------------------------------------------- |
| Status         | Accepted                                       |
| Date           | 2026-06-23                                     |
| Authors        | Nick Warila (@NWarila)                          |
| Decision-maker | Nick Warila (sole portfolio maintainer)        |
| Consulted      | Layout-aware build-model implementation work from T1a, T1b, and T1c. |
| Informed       | Consumers that create repositories from this template. |
| Reversibility  | Medium                                         |
| Review-by      | N/A (Accepted)                                 |
| Last reviewed  | 2026-06-23                                     |

## TL;DR

PowerShell repositories created from this template declare their build layout
with exactly one blank sentinel marker: `.github/.script` for single-script
repositories or `.github/.module` for module repositories. A single canonical
`build.ps1` authored here detects that marker and dispatches the same public
task verbs for both layouts: `Build`, `Analyze`, `Test`, `Smoke`, `Clean`, and
`All`. Single-script mode consolidates source files into a byte-identical
release script; module mode is intentionally skeletal and delegates to syntax
checks plus the existing Pester suite. This decision extends
[ADR-template/0001](0001-module-layout.md): module layout remains the module-mode
source shape.

## Context and Problem Statement

The template now supports two repository shapes with different build needs.
ADR-template/0001 establishes the module source layout under `src/<ModuleName>/`
with explicit public and private function boundaries. Single-script consumers
have a different release contract: they ship one `.ps1` artifact produced by
folding an entry point, private functions, and public functions into a stable
output file.

Before the layout-aware build model, these needs were easy to confuse. A build
could infer intent from files on disk, accidentally run the wrong path, or skip
the path that CI did not exercise for a particular repository type. That is
dangerous for single-script consumers because their released artifact and SLSA
provenance depend on byte-identical output, and it is noisy for module consumers
because packaging-style script consolidation has nothing to do with a module
that is dot-sourced at load.

The template needs one build entry point that is safe to push-sync to consumers,
keeps the public command surface stable, and fails closed when a repository does
not clearly identify its layout.

## Decision Drivers

1. **Fail-closed layout selection.** A repository must declare exactly one
   layout, and ambiguity must fail before any build path can hide it.
2. **One public build surface.** Consumers should use the same task verbs
   regardless of layout; layout-specific behavior belongs behind those verbs.
3. **Byte-identical script releases.** Single-script consolidation must preserve
   released output exactly because artifact provenance depends on it.
4. **Respect the module model.** Module builds should reinforce
   ADR-template/0001 instead of adding packaging or export-sync work that belongs
   to the module's own tests.
5. **Coverage gates that mean what they say.** Low coverage must fail even when
   the test run has no failed tests.
6. **CI coverage for invisible paths.** Build behavior that a module repository
   cannot naturally exercise in CI still needs dedicated unit coverage.
7. **Archive-visible markers.** Layout markers must survive `git archive` and
   source tarballs so downstream tooling can see them.

## Considered Options

1. One canonical `build.ps1` that detects an explicit layout marker and dispatches layout-aware task verbs.
2. Separate build scripts for module and single-script repositories.
3. Infer the layout from repository contents such as manifests, entry points, or function folders.

## Decision Outcome

Chosen option: **Option 1, one canonical `build.ps1` that detects an explicit layout marker and dispatches layout-aware task verbs.**

- A blank sentinel `.github/.script` marks single-script repositories, and a
  blank sentinel `.github/.module` marks module repositories.
- Exactly one marker MUST exist. This is enforced in two independent places:
  `Get-RepoLayout` in `build.ps1` for runtime and offline use, and the
  `layout-marker` CI job so marker drift cannot be masked by a broken build or
  by Ubuntu jobs that do not run `build.ps1`.
- The template-authored `build.ps1` is the canonical copy intended to be
  push-synced byte-identically to consumers.
- The public build surface is limited to `Build`, `Analyze`, `Test`, `Smoke`,
  `Clean`, and `All`. Layout-awareness lives inside those verbs.
- In single-script mode, `EntryPoint`, `Private`, and `Public` source files are
  consolidated into one `.ps1` plus a functions file for tests.
- Single-script output is a hard byte-identical contract. The consolidation
  logic is promoted verbatim and is not reformatted.
- In module mode, `Build` is deliberately skeletal: syntax check the module
  files and delegate to the existing Pester suite. It does not consolidate,
  package, run `Test-ModuleManifest`, or synchronize exports.
- The `-MinimumCoverage` sentinel resolves to layout defaults: 90 percent for
  single-script repositories and 80 percent for module repositories.
- Coverage is enforced explicitly by capturing the Pester result and throwing on
  shortfall because Pester's `Run.Throw` fails on failed tests, not on low
  coverage.
- Dedicated unit tests cover the single-script consolidation path that module CI
  does not naturally execute. `BuildScriptMode.Tests.ps1` and
  `RepoLayout.Tests.ps1` dot-source `build.ps1` inside an isolated dynamic module
  so its `Set-StrictMode` and `$ErrorActionPreference` settings do not leak.
- `build.ps1` is not added to coverage measurement. It contains functions that
  no unit test exercises directly, and wholesale inclusion would pull the gate
  below target without improving product coverage.
- `.github/` is no longer `export-ignore`d in `.gitattributes`, so the layout
  marker survives `git archive`, source tarballs, and OpenSSF Scorecard checks.

## Pros and Cons of the Options

### Option 1: One canonical `build.ps1` with explicit layout markers

- **Good, because** the repository layout is declared by a small, reviewable sentinel file.
- **Good, because** the same five task verbs plus `All` remain the only public build surface.
- **Good, because** marker validation happens both at runtime and in CI.
- **Good, because** single-script consumers keep their byte-identical release contract.
- **Good, because** module consumers keep the ADR-template/0001 module model without extra packaging work.
- **Bad, because** the build script carries both layout paths, so one repository type has code that its normal CI path does not execute.
- **Bad, because** the canonical script currently includes some consumer-specific literals until another single-script consumer justifies deriving them.

### Option 2: Separate build scripts

- **Good, because** each repository type could carry only the code path it uses.
- **Bad, because** public build behavior would drift across consumers.
- **Bad, because** push-based sync would need to coordinate multiple build entry points.
- **Bad, because** shared fixes to task verbs and coverage enforcement would be easier to apply unevenly.

### Option 3: Infer layout from repository contents

- **Good, because** no marker files would be needed.
- **Bad, because** inference can be ambiguous when a repository contains both scaffolding and generated or transitional files.
- **Bad, because** a missing or malformed layout would fail late, after the build has guessed.
- **Bad, because** CI would not have a simple independent assertion that the intended layout is declared.

## Confirmation

1. Exactly one of `.github/.script` or `.github/.module` MUST exist.
2. `Get-RepoLayout` in `build.ps1` MUST fail when no marker or both markers are present.
3. CI MUST include an independent `layout-marker` job that enforces the same marker rule.
4. The canonical `build.ps1` public surface MUST remain `Build`, `Analyze`, `Test`, `Smoke`, `Clean`, and `All`.
5. Single-script mode MUST preserve byte-identical consolidation output and MUST NOT reformat the promoted consolidation logic.
6. Module mode MUST NOT consolidate, package, run `Test-ModuleManifest`, or synchronize exports as part of `Build`.
7. The `-MinimumCoverage` sentinel MUST resolve to 90 percent for single-script repositories and 80 percent for module repositories.
8. Coverage shortfall MUST be enforced explicitly from the captured Pester result.
9. Unit tests MUST cover the single-script build path even when the template itself is in module mode.
10. `build.ps1` MUST remain outside the coverage-measurement path unless its unexercised helper functions receive meaningful coverage.
11. `.github/` MUST remain present in archives so the layout marker is visible downstream.

## Consequences

### Positive

- Repositories fail closed when their layout is missing or ambiguous.
- Consumers get one stable build entry point and one stable task surface.
- Single-script releases preserve byte-identical artifacts and provenance.
- Module repositories keep the ADR-template/0001 source layout as the authority.
- CI can catch marker drift even when a build path is broken or not naturally executed.

### Negative

- The canonical `build.ps1` currently carries one consumer's specifics,
  including `$ProjectName` and some `HelpUri` literals.
- Push-based drift-sync to consumers and the GitHub App that authenticates it are
  not part of this decision's implementation.
- The template's CI does not yet use `step-security/harden-runner`.

### Neutral

- Deriving consumer-specific literals is deferred until a second single-script
  consumer exists; no speculative configuration plumbing is added yet.
- Module build asymmetry is intentional. A dot-sourced module has nothing to
  consolidate, and its tests plus ADR-template/0001 remain the export and layout
  authority.
- `build.ps1` coverage is guarded by targeted unit tests rather than broad
  coverage measurement.

## Assumptions

1. Template consumers can keep one blank layout marker under `.github/`.
2. Single-script consumers need byte-identical release output more than they need reformatted consolidation code.
3. Module consumers continue to rely on ADR-template/0001 for their source shape and export contract.
4. A second single-script consumer will provide the evidence needed before introducing derived project metadata.

## Supersedes

None.

## Superseded by

None (current).

## Implementing PRs

- T1a, T1b, and T1c implement the layout-aware build model recorded here.

## Related ADRs

- Extends: [ADR-template/0001: Use Public and Private Function Folders with Explicit Manifest Exports](0001-module-layout.md)

## Compliance Notes

This ADR records the as-built layout-aware build model. It does not change code,
CI behavior, tests, or layout markers.
