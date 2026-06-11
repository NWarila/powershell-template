# Reference: module structure

This template lays out a PowerShell module as follows.

```text
.
├── src/
│   └── SampleModule/
│       ├── SampleModule.psd1     # Module manifest (export contract, metadata)
│       ├── SampleModule.psm1     # Root module: dot-sources and exports
│       ├── Public/               # Exported functions (one per file)
│       │   └── Get-Greeting.ps1
│       └── Private/              # Internal helpers (not exported)
│           └── Format-GreetingName.ps1
├── tests/
│   ├── SampleModule.Tests.ps1    # Pester v5 spec
│   └── Invoke-Tests.ps1          # PesterConfiguration runner (NUnit + coverage)
├── docs/                         # Diátaxis documentation
├── .github/workflows/ci.yaml     # actionlint + PSScriptAnalyzer + Pester
└── PSScriptAnalyzerSettings.psd1 # Lint configuration
```

## Conventions

- **One function per file.** File base name equals the function name.
- **Public vs Private.** Files under `Public/` are dot-sourced and exported;
  files under `Private/` are dot-sourced but not exported.
- **Explicit exports.** `FunctionsToExport` in the manifest lists each public
  function by name. Wildcards (`'*'`) are never used — they slow module load
  and obscure the public surface.
- **Empty cmdlet/alias/variable exports.** `CmdletsToExport`,
  `AliasesToExport`, and `VariablesToExport` are all `@()` unless the module
  genuinely ships those.
- **Cross-edition.** `CompatiblePSEditions = @('Core', 'Desktop')` and
  `PowerShellVersion = '5.1'`; CI exercises PowerShell 7 (Core).
- **Analyzer-clean idiom.** See
  [clean-function-idiom.ps1](clean-function-idiom.ps1) for a small function that
  is clean under this template's `PSScriptAnalyzerSettings.psd1`.

## CI surface

| Check            | Tool             | Gate                                    |
| ---------------- | ---------------- | --------------------------------------- |
| Workflow lint    | actionlint       | Errors fail the job                     |
| Static analysis  | PSScriptAnalyzer | PSGallery ruleset; errors/warnings fail |
| Tests + coverage | Pester v5        | All tests pass; coverage ≥ 80%          |
