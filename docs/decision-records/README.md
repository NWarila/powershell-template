# Architecture Decision Records

This directory holds the Architecture Decision Records (ADRs) governing this PowerShell template. Per the org ADR format used across the NWarila template repos, ADRs are organized into three scopes:

- `org/` - byte-identical mirrors of org-baseline ADRs from [`NWarila/.github`](https://github.com/NWarila/.github). This scope is currently empty in this repo.
- `template/` - PowerShell-template ADRs owned by this repository and inherited by repositories created from it. This scope is currently empty.
- `repo/` - repository-specific ADRs for this repository only.

`powershell-template` owns the canonical PowerShell module scaffold, public/private function layout, Pester test harness, PSScriptAnalyzer settings, and CI surface for repositories derived from it.

## Template ADRs

| ADR | Status | Decision |
| --- | --- | --- |
| None yet. | N/A | Template-tier decisions will be recorded here when introduced. |

## Org ADRs

| ADR | Status | Decision |
| --- | --- | --- |
| None mirrored yet. | N/A | Org-tier ADR mirrors will be listed here when introduced. |

## Repo ADRs

| ADR | Status | Decision |
| --- | --- | --- |
| [ADR-repo/0001](repo/0001-module-layout.md) | Accepted | Use `src/<ModuleName>/` with `Public/` and `Private/` function folders plus explicit manifest exports. |
