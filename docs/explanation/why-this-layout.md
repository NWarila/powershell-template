# Explanation: why this layout

This template encodes a small number of opinions that pay off as a module
grows. This page explains the reasoning; the binding decision is recorded in
[ADR repo/0001](../decision-records/repo/0001-module-layout.md).

## Source under `src/`, one function per file

Keeping module code under `src/` (rather than at the repo root) separates
shippable code from project scaffolding (tests, docs, CI). One function per
file keeps diffs small, makes blame useful, and lets the root module
mechanically discover what to load and export.

## Public / Private split

The `Public/` and `Private/` folders make the export boundary visible on disk
before you even read the manifest. The root module dot-sources both but only
exports `Public/`. This mirrors how most mature PowerShell modules organize
themselves and keeps internal helpers out of the consumer's command surface.

## Explicit `FunctionsToExport`

`FunctionsToExport = '*'` forces PowerShell to load and analyze the module to
discover its exports, which slows `Import-Module` and `Get-Command -Module`.
Listing functions explicitly keeps load fast and makes the public contract a
reviewable artifact: adding to the public surface is a deliberate, diffable act.

## Cross-edition compatibility

Declaring `CompatiblePSEditions = @('Core', 'Desktop')` and a `5.1` floor lets
the module run on both Windows PowerShell and PowerShell 7+. CI runs on
`ubuntu-latest`, which ships PowerShell 7 (Core), so the Core path is always
exercised; the Desktop path is exercised by anyone running the suite on
Windows PowerShell.

## Green out of the box

The shipped sample (`Get-Greeting` plus a private helper) exists so that a
freshly created repository passes actionlint, PSScriptAnalyzer, and Pester
without any edits. New maintainers get a working reference to copy rather than
a blank canvas.
