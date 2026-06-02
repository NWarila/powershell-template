# Tutorial: From template to your first passing module

This tutorial takes you from a freshly created repository to a green CI run
with your own module name. It assumes [PowerShell 7+](https://learn.microsoft.com/powershell/scripting/install/installing-powershell)
is installed. Allow about 15 minutes.

## 1. Create your repository

On GitHub, open `NWarila/powershell-template`, click **Use this template**, and
create a new repository. Clone it locally:

```bash
git clone https://github.com/<you>/<your-repo>
cd <your-repo>
```

## 2. Rename the sample module

The template ships a module called `SampleModule`. Rename it to yours
(`Acme.Tools` in this example):

```bash
git mv src/SampleModule src/Acme.Tools
git mv src/Acme.Tools/SampleModule.psm1 src/Acme.Tools/Acme.Tools.psm1
git mv src/Acme.Tools/SampleModule.psd1 src/Acme.Tools/Acme.Tools.psd1
git mv tests/SampleModule.Tests.ps1 tests/Acme.Tools.Tests.ps1
```

Then update the references:

- In `src/Acme.Tools/Acme.Tools.psd1`, set `RootModule = 'Acme.Tools.psm1'`,
  a fresh `GUID` (run `pwsh -c "[guid]::NewGuid()"`), your `Author`,
  `Description`, and the `ProjectUri` / `LicenseUri` to your repo.
- In `tests/Acme.Tools.Tests.ps1`, set `$script:ModuleName = 'Acme.Tools'`.

## 3. Run the checks locally

```bash
pwsh -c "Invoke-ScriptAnalyzer -Path . -Settings PSGallery -Recurse"
pwsh -File tests/Invoke-Tests.ps1
```

Both should pass. The Pester run prints a coverage summary and writes NUnit and
JaCoCo reports under `TestResults/`.

## 4. Add your first function

Drop a new file under `src/Acme.Tools/Public/` (one function per file). The root
module dot-sources it automatically. Add the function name to
`FunctionsToExport` in the manifest, then add a matching test under `tests/`.

## 5. Push and watch CI

```bash
git checkout -b feat/first-function
git add -A
git commit -m "feat: add first function"
git push -u origin feat/first-function
```

Open a pull request. The CI workflow runs actionlint, PSScriptAnalyzer, and
Pester. When all three are green, merge.
