#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

Describe 'InjectionHunter SAST ruleset' {
  BeforeAll {
    If (-not (Get-Module -Name PSScriptAnalyzer)) {
      Import-Module -Name PSScriptAnalyzer -ErrorAction Stop
    }

    $script:RepoRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
    $script:SettingsPath = Join-Path -Path $script:RepoRoot -ChildPath 'PSScriptAnalyzerSettings.psd1'

    # CustomRulePath entries in the settings file are repo-relative, and PSScriptAnalyzer
    # resolves them against the current directory (exactly as the CI analyze step does from
    # the repo root). Pushing there proves the settings file itself loads the vendored ruleset.
    Push-Location -LiteralPath $script:RepoRoot
  }

  AfterAll {
    Pop-Location
  }

  It 'is loaded through the house settings and fires on Invoke-Expression of untrusted input' {
    $ScriptDefinition = @'
param ([string] $UserInput)
Invoke-Expression $UserInput
'@

    $Results = Invoke-ScriptAnalyzer -ScriptDefinition $ScriptDefinition -Settings $script:SettingsPath
    $Injection = @($Results | Where-Object -FilterScript { $PSItem.RuleName -like 'InjectionRisk.*' })

    $Injection.RuleName | Should -Contain 'InjectionRisk.InvokeExpression'
  }

  It 'fires on Add-Type of a non-constant type definition' {
    $ScriptDefinition = @'
param ([string] $UserInput)
Add-Type -TypeDefinition $UserInput
'@

    $Results = Invoke-ScriptAnalyzer -ScriptDefinition $ScriptDefinition -Settings $script:SettingsPath
    $Injection = @($Results | Where-Object -FilterScript { $PSItem.RuleName -like 'InjectionRisk.*' })

    $Injection.RuleName | Should -Contain 'InjectionRisk.AddType'
  }

  It 'stays clean on a safe parameterised idiom' {
    $ScriptDefinition = @'
param ([string] $Name)
Write-Output ('Hello {0}' -f $Name)
'@

    $Results = Invoke-ScriptAnalyzer -ScriptDefinition $ScriptDefinition -Settings $script:SettingsPath
    $Injection = @($Results | Where-Object -FilterScript { $PSItem.RuleName -like 'InjectionRisk.*' })

    $Injection | Should -HaveCount 0
  }
}
