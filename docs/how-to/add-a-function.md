# How-to: add a public function

Goal: add a new exported function to the module and keep CI green.

1. **Create the function file.** Add one file per function under
   `src/<ModuleName>/Public/`. Name the file after the function:

   ```powershell
   # src/SampleModule/Public/Get-Widget.ps1
   function Get-Widget {
       [CmdletBinding()]
       [OutputType([string])]
       param(
           [Parameter(Mandatory)]
           [ValidateNotNullOrEmpty()]
           [string]$Id
       )
       process { "widget:$Id" }
   }
   ```

2. **Register the export.** Add the function name to `FunctionsToExport` in
   `src/<ModuleName>/<ModuleName>.psd1`:

   ```powershell
   FunctionsToExport = @('Get-Greeting', 'Get-Widget')
   ```

3. **Add a test.** Cover the function in `tests/<ModuleName>.Tests.ps1` inside a
   `Describe` block, with setup in `BeforeAll`.

4. **Validate locally.**

   ```bash
   pwsh -c "Invoke-ScriptAnalyzer -Path . -Settings PSGallery -Recurse"
   pwsh -File tests/Invoke-Tests.ps1
   ```

5. **Open a PR.** CI re-runs the same checks. Merge when green.

## Notes

- Internal helpers go under `Private/` and are *not* added to
  `FunctionsToExport`.
- Keep functions deterministic where possible — it makes them trivial to test.
