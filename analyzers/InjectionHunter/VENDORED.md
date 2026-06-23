# Vendored: InjectionHunter

A PSScriptAnalyzer `CustomRulePath` ruleset that taint-tracks untrusted input
into PowerShell execution contexts (`Invoke-Expression`, `Add-Type`, dynamic
member/method/property access, `cmd`/`powershell` command injection, unsafe
string escaping). It catches a defect class the built-in PSScriptAnalyzer rules
(e.g. `PSAvoidUsingInvokeExpression`) do not.

## Source and version

| Field | Value |
| --- | --- |
| Module | `InjectionHunter` |
| Version | `1.0.0` (the only published version) |
| Source | PowerShell Gallery — `https://www.powershellgallery.com/packages/InjectionHunter/1.0.0` |
| Acquired via | `Save-Module -Name InjectionHunter -RequiredVersion 1.0.0` |
| Module GUID | `a06987c9-e591-4dce-a1e9-b488c3cb26b4` |
| Author | Microsoft Corporation (Lee Holmes) |
| Published (Gallery) | 2017-09-02 |
| Vendored on | 2026-06-23 |
| Upstream status | **Frozen** — unmaintained since 2017; `v1.0.0` is the only release. **Update manually.** |

## Vendored files (SHA-256)

Both files are **byte-identical** to the PowerShell Gallery `v1.0.0` package
(verified at vendoring time).

| File | SHA-256 | Bytes | Encoding |
| --- | --- | --- | --- |
| `InjectionHunter.psm1` | `2ce83368e396c080262befca7c974888def98fb357c57e40e78352d668bf158b` | 26466 | ASCII + Authenticode `# SIG #` block |
| `InjectionHunter.psd1` | `e1d0f5ae6d8e46b871a8649098f9353a1bc7da53fb224f745a2c98e74b16f84e` | 28668 | UTF-16 LE (BOM) |

Only the manifest (`.psd1`) and root module (`.psm1`) are vendored. The Gallery
package's `InjectionHunter.cat` (catalog signature), `Test-InjectionHunter.ps1`,
and `Tests/` (upstream's own Pester suite) are intentionally **not** vendored —
they are not needed to load the ruleset via `CustomRulePath`, and the house
self-test (`tests/InjectionHunter.Tests.ps1`) proves the rules fire here.

## Audit (2026-06-23)

`InjectionHunter.psm1` was read in full before vendoring. It contains **only**
eight PSScriptAnalyzer rule functions — `Measure-InvokeExpression`,
`Measure-AddType`, `Measure-DangerousMethod`, `Measure-CommandInjection`,
`Measure-ForeachObjectInjection`, `Measure-PropertyInjection`,
`Measure-MethodInjection`, `Measure-UnsafeEscaping` — each of which inspects the
analyzed script's AST with a `.Find()` predicate and returns `DiagnosticRecord`
objects. Confirmed: **no install logic, no network calls, no filesystem writes,
no `Invoke-Expression`/`Start-Process`/reflection-load of external code, no
obfuscation** — it is a passive AST analyzer. The `.psm1` carries an expired
(2018) Microsoft Authenticode signature, retained as upstream provenance; the
module is loaded as analyzer rules, not run as a signed script, so expiry is
irrelevant.

## License

> [!IMPORTANT]
> InjectionHunter does **not** ship an explicit open-source license. The
> PowerShell Gallery package declares no `LicenseUri` and no SPDX license; its
> manifest copyright is **"(c) Microsoft Corporation 2016. All rights
> reserved."** The historical `github.com/PowerShell/InjectionHunter` repository
> (where an MIT license was once expected) is no longer reachable, and the only
> surviving GitHub fork carries no license file either.

This copy is retained solely to run InjectionHunter as a PSScriptAnalyzer
`CustomRulePath` ruleset — the use Microsoft published it for. Microsoft's
copyright notice is preserved above and in the vendored manifest. **The
redistribution terms are unverified; whether to vendor (rather than restore at
build time) is an owner decision flagged in the IH-1 REPORT.**

## How it is wired

`PSScriptAnalyzerSettings.psd1` adds `./analyzers/InjectionHunter/InjectionHunter.psd1`
to `CustomRulePath`. The CI analyze step excludes this vendored directory from
its own lint target set (third-party, pinned, not restyled to house rules) while
still loading it as a rule provider. `tests/InjectionHunter.Tests.ps1` proves the
ruleset is loaded and effective.
