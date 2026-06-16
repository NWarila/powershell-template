# powershell-template

[![CI](https://github.com/NWarila/powershell-template/actions/workflows/ci.yaml/badge.svg)](https://github.com/NWarila/powershell-template/actions/workflows/ci.yaml)
[![PowerShell 5.1+ / 7+](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-5391FE?logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![PSScriptAnalyzer](https://img.shields.io/badge/lint-house%20PSScriptAnalyzer-blue)](PSScriptAnalyzerSettings.psd1)
[![Tested with Pester](https://img.shields.io/badge/tested%20with-Pester%20v5-green)](https://pester.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Opinionated PowerShell module template with Pester v5 tests, PSScriptAnalyzer,
and SHA-pinned CI. **Green out of the box** — create a repository from it and
the workflow passes with no edits, giving you a working reference to extend
rather than a blank canvas.

## Why this template

- **Reviewable public contract.** Functions are split into `Public/`
  (exported) and `Private/` (internal), one per file, with an explicit
  `FunctionsToExport` list — no wildcard exports.
- **Publish-ready.** The manifest satisfies the PowerShell Gallery's
  requirements, and the house PSScriptAnalyzer settings keep the module
  reviewable without rework.
- **Cross-edition.** Declares `CompatiblePSEditions = @('Core', 'Desktop')`
  with a 5.1 floor; CI exercises PowerShell 7 (Core) on Ubuntu.
- **Safe CI.** Least-privilege permissions, SHA-pinned actions, per-job
  timeouts, and concurrency cancellation.

The reasoning is recorded in
[ADR-template/0001](docs/decision-records/template/0001-module-layout.md).

## Quickstart

### 1. Create your repository

Click **Use this template** on
[NWarila/powershell-template](https://github.com/NWarila/powershell-template),
create your repository, and clone it.

### 2. Rename the sample module

```bash
git mv src/SampleModule src/<YourModule>
git mv src/<YourModule>/SampleModule.psm1 src/<YourModule>/<YourModule>.psm1
git mv src/<YourModule>/SampleModule.psd1 src/<YourModule>/<YourModule>.psd1
git mv tests/SampleModule.Tests.ps1 tests/<YourModule>.Tests.ps1
```

Then edit:

- `src/<YourModule>/<YourModule>.psd1` — set `RootModule`, a fresh `GUID`
  (`pwsh -c "[guid]::NewGuid()"`), `Author`, `Description`, and the
  `ProjectUri` / `LicenseUri`.
- `tests/<YourModule>.Tests.ps1` — set `$script:ModuleName` to your module name.

### 3. Validate locally

```bash
pwsh -c "Invoke-ScriptAnalyzer -Path . -Settings ./PSScriptAnalyzerSettings.psd1 -Recurse"
pwsh -File tests/Invoke-Tests.ps1
```

Full walkthrough: [docs/tutorials/getting-started.md](docs/tutorials/getting-started.md).

## Module structure

```text
src/<ModuleName>/
  <ModuleName>.psd1     # Manifest: export contract + metadata
  <ModuleName>.psm1     # Root module: dot-sources Public/ + Private/, exports Public/
  Public/               # Exported functions (one per file)
  Private/              # Internal helpers (not exported)
tests/
  <ModuleName>.Tests.ps1  # Pester v5 spec
  Invoke-Tests.ps1        # PesterConfiguration runner (NUnit + coverage)
docs/                     # Diátaxis documentation + ADRs + diagrams
.github/workflows/ci.yaml # actionlint + PSScriptAnalyzer + Pester
PSScriptAnalyzerSettings.psd1
```

See [docs/reference/module-structure.md](docs/reference/module-structure.md) for
the full reference and conventions.

## CI

The [CI workflow](.github/workflows/ci.yaml) runs on every push and pull request:

| Job              | What it does                                                 |
| ---------------- | ------------------------------------------------------------ |
| actionlint       | Lints GitHub Actions workflows                               |
| PSScriptAnalyzer | `Invoke-ScriptAnalyzer -Settings ./PSScriptAnalyzerSettings.psd1 -Recurse` |
| Pester           | Pester v5 suite, NUnit output, coverage target (≥ 80%)       |

## Documentation

Documentation follows the [Diátaxis framework](https://diataxis.fr/). Start at
[docs/README.md](docs/README.md).

## Security

See [SECURITY.md](SECURITY.md) for how to report a vulnerability.

## License

[MIT](LICENSE).
