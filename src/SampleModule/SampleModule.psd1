@{
    # Root module / entry point loaded when the module is imported.
    RootModule           = 'SampleModule.psm1'

    # Bump on every release. Renovate and release tooling key off this value.
    ModuleVersion        = '0.1.0'

    # Stable identity for this module. Regenerate when you rename the module
    # for your own project: pwsh -c "[guid]::NewGuid()".
    GUID                 = 'b2ba5dff-0bf0-444e-b5a1-0f78ab77f371'

    Author               = 'Nick Warila'
    CompanyName          = 'NWarila'
    Copyright            = '(c) Nick Warila. All rights reserved.'

    Description          = 'Opinionated PowerShell module template with Pester v5 tests, PSScriptAnalyzer, and SHA-pinned CI. Replace SampleModule with your module name.'

    # Lowest engine version the module supports. 5.1 keeps Windows PowerShell
    # compatibility; CI runs on PowerShell 7 (Core) via pwsh.
    PowerShellVersion    = '5.1'

    # Works on both Windows PowerShell (Desktop) and PowerShell 7+ (Core).
    CompatiblePSEditions = @('Core', 'Desktop')

    # Explicit export contract. Never use '*'; wildcard exports slow module
    # load and hide the public surface. List each public function by name.
    FunctionsToExport    = @('Get-Greeting')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()

    PrivateData          = @{
        PSData = @{
            Tags         = @('Template', 'Module', 'Pester', 'CI', 'PSScriptAnalyzer', 'PSEdition_Core', 'PSEdition_Desktop')
            LicenseUri   = 'https://github.com/NWarila/powershell-template/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/NWarila/powershell-template'
            ReleaseNotes = 'Initial template scaffold: example public function, Pester v5 tests, PSScriptAnalyzer settings, and SHA-pinned CI.'
        }
    }
}
