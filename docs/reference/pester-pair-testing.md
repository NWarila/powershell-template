# Pester pair testing — the org script contract

This repository is the single definition of PowerShell for the organization. This document is
the contract every org PowerShell **script** (as opposed to module function) is written,
tested, and shipped to: the three-file convention, the Change/NoChange result contract for
scripts Ansible executes, the spec requirements, and the one workflow matrix that tests every
script in every consuming repository.

Module-shaped code follows [STYLE-GUIDE.md](../STYLE-GUIDE.md) and the module layout ADRs
unchanged; everything below is additive for standalone scripts.

## 1. The three-file convention

Every script exists as exactly these files:

| File | Where | Purpose |
|---|---|---|
| `<Name>.ps1` | The consuming repo's `scripts/` directory (its generic script home, shared with Python/bash tooling; only `.ps1` files join the matrix) | The script itself. House style; analyzer-clean against this repo's `PSScriptAnalyzerSettings.psd1`. |
| `<Name>.pester.ps1` | Sibling of the script | The spec. Discovered by filename pairing; an unpaired script or an orphan spec fails the matrix. |
| `<Name>.ps1.stub` | An Ansible role's `files/` directory (consumers that ship the script through Ansible) | Build marker. The ansible-build resolves each stub by copying the real script from the central directory into the role at `<Name>.ps1`, so the role runs effortlessly while the script is developed, reviewed, and tested in exactly one place. |

Stub content is the repo-relative path of the source script (comments and blank lines
ignored), and the stub's own basename must equal the source script's basename plus `.stub`,
so a copy-pasted stub pointing at the wrong script fails the build rather than shipping it.
The materialized `<Name>.ps1` next to a stub is a build artifact: never commit it.

## 2. The script contract

Scripts consumed by Ansible run through `ansible.windows.win_powershell` — never `win_shell`
blocks — and follow the worked example
[`examples/pair/Set-TextFileContent.ps1`](../../examples/pair/Set-TextFileContent.ps1):

1. **The canonical script anatomy: a single process stage in the script template's region
   architecture.** These scripts exist to fill steps Ansible cannot do effectively — they
   are gap-fillers, not applications, and each one reads like the task it replaces: one
   linear pass someone can audit top to bottom. **No function decomposition** — a script
   that wants functions has outgrown a gap-filler and belongs in a Script-template
   repository with the `src/` layout and build. Reused logic shrinks to inline idioms
   instead (e.g. normalized comparison is stringify + trim + PowerShell's default
   case-insensitive `-ne`).

   The architecture comes from the original org script template: one bannered `[ Script ]`
   region carrying the ordered stages, `Write-Debug 'Entering Stage: …'` anchors, and all
   input normalization completed in `[ Initialization ]` before `[ Main ]` touches
   anything. **Precedence rule:** the original template defines the architecture; where
   its conventions conflict with the ratified [STYLE-GUIDE](../STYLE-GUIDE.md)/HouseRules,
   the style guide wins (so: no `Remove-Variable` cleanup, no `Position =`, trailing-comma
   formatting, `PositionalBinding = $False` honored). The harness enforces the mechanical
   parts before anything else runs:

   Every script carries the template's operator controls: `-DebugLevel` (three digits:
   ErrorActionPreference, `Set-PSDebug`, `Set-StrictMode`; default `'103'` = stop on error,
   no tracing, strict mode 3.0) and `-LogLevel` (six digits mapping the Verbose, Debug,
   Information, Warning, Error, Fatal streams to ActionPreference values; default
   `'002223'`), plus the universal `Trap`. The harness enforces their presence.

   ```powershell
   #Requires -Version 5.1
   # SPDX-FileCopyrightText: <year> <owner>
   # SPDX-License-Identifier: MIT

   <# comment-based help #>
   [CmdletBinding( <maximal-explicit surface incl. RemotingCapability; HelpUri = ''> )]
   Param ( <task params + DebugLevel + LogLevel; alphabetical, maximal-explicit, SG-5/SG-7> )

   #region ------ [ Script ] ------------------------------------------------- #

   #region ------ [ Initialization ] ----------------------------------------- #
   # Write-Debug anchor; LogLevel stream-preference configuration; DebugLevel
   # (ErrorActionPreference / Set-PSDebug / Set-StrictMode); the universal
   # Trap (diagnostics wrapped so they can never mask the original failure,
   # then Break to rethrow -- never Wait-Debugger/Exit under the transport);
   # $Ansible stub creation when standalone; ALL input normalization --
   # Main starts clean and reads $Ansible.CheckMode directly
   #endregion --- [ Initialization ] ----------------------------------------- #

   #region ------ [ Main ] ---------------------------------------------------- #
   # read -> compare -> mutate only the drift -> re-acquire and verify ->
   # build ONE result object
   #endregion --- [ Main ] ---------------------------------------------------- #

   #region ------ [ Output ] -------------------------------------------------- #
   # ALWAYS assign $Ansible.Changed/.Result; serialize the stub as JSON only
   # when the script created it; ends with Write-Debug 'Exiting Script'
   #endregion --- [ Output ] -------------------------------------------------- #

   #endregion --- [ Script ] -------------------------------------------------- #
   ```

   User-facing strings are inline, formatted at the point of use (the SG-8 message table is
   module/tool machinery and does not apply here). The exporter-style `Trap`/exit-code
   machinery is CLI-tool territory; Ansible-transport scripts fail by `Throw`. House style
   throughout — the matrix analyzes every script with this repo's settings, custom rules
   included; zero findings at any severity.
2. Read live state → **normalized** compare → mutate **only the drift** → **re-acquire and
   verify** → emit ONE result object. `changed` is only ever reported from a fresh
   post-mutation read; a converged host performs zero mutations.
3. **Stubbed transport, single code path.** When `Get-Variable` finds no `$Ansible`
   (standalone: a dev shell or a spec), Initialization creates a faithful stub
   (`Changed = $True`, like the real transport). The rest of the script is written as if
   Ansible is always present -- the outcome is always assigned to `$Ansible.Changed` /
   `$Ansible.Result`, Main reads `$Ansible.CheckMode` directly, and Output serializes the
   stub as JSON only when the script created it. What a developer sees standalone is
   therefore 1-to-1 what Ansible sees. `Changed` is set explicitly on **every** path.
4. The result object always carries `changed`, `check_mode`, `msg` (one human sentence — the
   play recap is the product), and a machine payload (`drift` or equivalent) that reports
   digests or names, never secret content.
5. **Check mode is honored**: full read/diff, would-change reporting, zero mutation.
6. Failure is `Throw` with an actionable message; input-shape violations throw before the
   first mutation. No exit codes, no host output.
7. Inputs cross as typed `parameters:` on the Ansible side — never Jinja spliced into the
   script source. Dictionary parameters are accepted loosely typed and normalized, because
   the transport may deliver a `Hashtable` or a `PSCustomObject`.

## 3. The spec contract

Every spec (`<Name>.pester.ps1`) asserts at minimum:

- **converged → NoChange** with zero writes — via the shim's deliberate `Changed = $True`
  default this also proves the explicit `Changed = $False` assignment;
- **drift → Change**, asserting the mutation set contains only the drifted subset;
- **check mode**: would-change reported, zero writes;
- **verify failure** (the mutation reports success but state did not land): the script
  refuses to report convergence;
- **invalid input**: throws before any mutation.

**Pairs are self-contained.** A spec imports nothing and dot-sources nothing — it must run
under bare `Invoke-Pester` with only Pester installed. The `$Ansible` stand-in is therefore
an inline helper every spec defines in its own `BeforeAll`, faithful to the real transport
surface (`Changed` defaults `$True`; only `Changed`, `CheckMode`, `Failed`, `Result` exist,
so a script that strays outside the contract fails its spec):

```powershell
Function New-AnsibleContext {
  Param ([Switch]$CheckMode)
  $global:Ansible = [PSCustomObject]@{
    Changed   = $True
    CheckMode = $CheckMode.IsPresent
    Failed    = $False
    Result    = $Null
  }
  $global:Ansible
}

Function Remove-AnsibleContext {
  Remove-Variable -Name 'Ansible' -Scope 'Global' -Force -ErrorAction 'SilentlyContinue'
}
```

Call `Remove-AnsibleContext` from `AfterEach`. Copy these helpers verbatim from the worked
example — the exact object shape is contract, not implementation detail.

Mechanics that bite (all learned empirically — do not rediscover them):

- **Stub state must be `$global:`.** Platform cmdlets the runner OS lacks are stubbed as
  functions in the spec; the script resolves them as a *child scope*. Inside a function
  called from a child **script**, `$script:` resolves to the *child script's* scope — state
  the spec wrote via `$script:` is invisible there. Keep shared stub state in
  distinctively-named `$global:` variables and remove them in `AfterAll`.
- **`$TestDrive` persists across tests in a block.** A file one test converged leaks
  converged state into the next; derive a unique path per test.
- Make write-stubs actually apply their arguments to the in-memory state, so the script's
  re-acquire-and-verify pass is genuinely exercised — canned "converged" data proves nothing.

## 4. The workflow matrix

[`pester-matrix.yaml`](../../.github/workflows/pester-matrix.yaml) is a reusable workflow: it
discovers every pair under `scan-path` (failing on orphans either direction) and runs **one
matrix leg per script** — analyzer, then spec — via
[`harness/Invoke-PairTests.ps1`](../../harness/Invoke-PairTests.ps1) at the pinned
`template-ref`.

A consuming repository adds exactly one thin workflow, triggered only when a PowerShell file
changes in a pull request:

```yaml
name: PowerShell

on:
  pull_request:
    paths:
      - 'scripts/**.ps1'   # script pairs (<Name>.ps1 + <Name>.pester.ps1)

jobs:
  pester-matrix:
    permissions:
      contents: read
      checks: write          # report job: check run with per-test results
      pull-requests: write   # report job: sticky results comment on the PR
      security-events: write # test legs: SARIF upload to code scanning
    uses: NWarila/powershell-template/.github/workflows/pester-matrix.yaml@<pinned-sha>
    with:
      scan-path: scripts
```

Pin `@<pinned-sha>` like every other action; bumping the pin is how a consumer adopts new
organizational tests, because every standardized check this repo adds to the matrix reaches
consumers through that single `uses:` line.

## 5. Results surfaced to developers

GitHub has no native test-format ingestion, so the matrix uses its three real surfaces —
all emitted by the harness only when `GITHUB_ACTIONS` is set (local runs write no files):

- **Per-leg artifacts**: each leg writes `<Pair>.junit.xml` (Pester's native JUnit output)
  and uploads it as `pester-results-<pair>` — the downloadable, machine-readable record.
- **Annotations**: analyzer findings become `::warning` annotations pinned to file/line on
  the PR diff; anatomy violations become `::error` annotations. Both still fail the leg.
- **Job summary**: each leg appends a markdown table (anatomy / analyzer / spec counts and
  duration) to `$GITHUB_STEP_SUMMARY`, readable on the run page without opening logs.
- **Code scanning (SARIF)**: each leg hand-emits SARIF 2.1.0 (one code-scanning category
  per pair via `automationDetails.id`) and uploads it with GitHub's first-party
  `upload-sarif` action, `if: always()` — so a failing leg still publishes exactly what it
  found as tracked alerts under Security > Code scanning. Free on public repositories;
  requires the caller to grant `security-events: write`.
- **Check run + sticky PR comment**: an aggregate `report` job feeds every leg's JUnit file
  to the SHA-pinned `EnricoMi/publish-unit-test-result-action`, producing a named check run
  and ONE edited-in-place PR comment with run-over-run deltas. Requires the caller to grant
  `checks: write` and `pull-requests: write`; presentation runs `if: always()` so failing
  legs still report.

## 6. The local loop

```sh
# Everything the matrix runs, for every pair under a directory:
pwsh -File <template-checkout>/harness/Invoke-PairTests.ps1 -Path scripts

# One pair (exactly one matrix leg):
pwsh -File <template-checkout>/harness/Invoke-PairTests.ps1 \
  -Script scripts/Set-Example.ps1 -Pester scripts/Set-Example.pester.ps1
```

Requires `pwsh` with `PSScriptAnalyzer` and `Pester` v5+. This repository's own CI runs the
matrix against `examples/pair` at the current revision, so the harness cannot silently rot.
