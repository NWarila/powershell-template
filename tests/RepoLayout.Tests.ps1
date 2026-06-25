#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
  $script:BuildScriptPath = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '../build.ps1')).Path

  Function Test-CallerStrictModeEnabled {
    Try {
      $null = $StrictModeProbeThatShouldNotExist
      $False
    } Catch {
      $True
    }
  }

  Function New-IsolatedBuildScriptModule {
    Param (
      [Parameter(Mandatory = $True)]
      [System.String]
      $Path
    )

    New-Module `
      -Name ('RepoLayoutUnderTest_{0}' -f [System.Guid]::NewGuid().ToString('N')) `
      -ArgumentList $Path `
      -ScriptBlock {
        Param (
          [System.String]
          $BuildScriptPath
        )

        . $BuildScriptPath
      }
  }

  $script:CallerStrictModeBeforeDotSource = Test-CallerStrictModeEnabled
  $script:CallerErrorActionPreferenceBeforeDotSource = $ErrorActionPreference
  $script:CallerErrorActionPreferenceSentinel = 'Continue'
  $ErrorActionPreference = $script:CallerErrorActionPreferenceSentinel
  $script:BuildModule = New-IsolatedBuildScriptModule -Path $script:BuildScriptPath
  $script:CallerErrorActionPreferenceAfterDotSource = $ErrorActionPreference
  $script:CallerStrictModeAfterDotSource = Test-CallerStrictModeEnabled
  $ErrorActionPreference = $script:CallerErrorActionPreferenceBeforeDotSource
}

AfterAll {
  If ($null -ne $script:BuildModule) {
    Remove-Module -ModuleInfo $script:BuildModule -Force -ErrorAction SilentlyContinue
  }
}

Describe 'Get-RepoLayout' {
  BeforeEach {
    $script:LayoutRoot = Join-Path -Path $TestDrive -ChildPath 'layout'
    $script:GitHubRoot = Join-Path -Path $script:LayoutRoot -ChildPath '.github'
    If (Test-Path -LiteralPath $script:LayoutRoot) {
      Remove-Item -LiteralPath $script:LayoutRoot -Recurse -Force
    }

    $null = New-Item -ItemType Directory -Path $script:GitHubRoot -Force

    & $script:BuildModule {
      Param (
        [System.String]
        $ProjectRoot
      )

      $script:ProjectRoot = $ProjectRoot
    } -ProjectRoot $script:LayoutRoot
  }

  It 'loads build.ps1 without leaking caller preferences' {
    $script:CallerErrorActionPreferenceAfterDotSource | Should -BeExactly $script:CallerErrorActionPreferenceSentinel
    $script:CallerStrictModeAfterDotSource | Should -Be $script:CallerStrictModeBeforeDotSource
  }

  It 'returns Script for script-only marker state' {
    $null = New-Item -ItemType File -Path (Join-Path -Path $script:GitHubRoot -ChildPath '.script')

    & $script:BuildModule { Get-RepoLayout } | Should -BeExactly 'Script'
  }

  It 'returns Module for module-only marker state' {
    $null = New-Item -ItemType File -Path (Join-Path -Path $script:GitHubRoot -ChildPath '.module')

    & $script:BuildModule { Get-RepoLayout } | Should -BeExactly 'Module'
  }

  It 'throws when both layout markers exist' {
    $null = New-Item -ItemType File -Path (Join-Path -Path $script:GitHubRoot -ChildPath '.script')
    $null = New-Item -ItemType File -Path (Join-Path -Path $script:GitHubRoot -ChildPath '.module')

    { & $script:BuildModule { Get-RepoLayout } } | Should -Throw -ExpectedMessage 'Repo layout marker invalid*'
  }

  It 'throws when neither layout marker exists' {
    { & $script:BuildModule { Get-RepoLayout } } | Should -Throw -ExpectedMessage 'Repo layout marker invalid*'
  }
}
