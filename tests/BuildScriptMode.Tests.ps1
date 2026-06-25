#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
  $script:BuildScriptPath = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath '../build.ps1')).Path
  $script:FixtureRoot = (Resolve-Path -LiteralPath (Join-Path -Path $PSScriptRoot -ChildPath 'Fixtures/ScriptLayout')).Path

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
      -Name ('BuildScriptUnderTest_{0}' -f [System.Guid]::NewGuid().ToString('N')) `
      -ArgumentList $Path `
      -ScriptBlock {
        Param (
          [System.String]
          $BuildScriptPath
        )

        . $BuildScriptPath
      }
  }

  Function Test-FileHasUtf8Bom {
    Param (
      [Parameter(Mandatory = $True)]
      [System.String]
      $Path
    )

    [System.Byte[]]$bytes = [System.IO.File]::ReadAllBytes($Path)
    $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
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

Describe 'build.ps1 script-mode functions' {
  BeforeEach {
    $script:BuildOutputRoot = Join-Path -Path $TestDrive -ChildPath 'script-build'
    $script:OutputFile = Join-Path -Path $script:BuildOutputRoot -ChildPath 'Fixture.ps1'
    $script:FunctionsFile = Join-Path -Path $script:BuildOutputRoot -ChildPath 'Fixture.Functions.ps1'

    & $script:BuildModule {
      Param (
        [System.String]
        $SourceRoot,

        [System.String]
        $BuildRoot,

        [System.String]
        $OutputFile,

        [System.String]
        $FunctionsFile
      )

      $script:SourceRoot = $SourceRoot
      $script:BuildRoot = $BuildRoot
      $script:OutputFile = $OutputFile
      $script:FunctionsFile = $FunctionsFile
    } -SourceRoot $script:FixtureRoot -BuildRoot $script:BuildOutputRoot -OutputFile $script:OutputFile -FunctionsFile $script:FunctionsFile
  }

  It 'loads build.ps1 without leaking caller preferences' {
    $script:CallerErrorActionPreferenceAfterDotSource | Should -BeExactly $script:CallerErrorActionPreferenceSentinel
    $script:CallerStrictModeAfterDotSource | Should -Be $script:CallerStrictModeBeforeDotSource
  }

  It 'finds the end of the fixture entry point Param block' {
    $entryPoint = & $script:BuildModule { Get-EntryPointContent }
    [System.String[]]$lines = Get-Content -LiteralPath (Join-Path -Path $script:FixtureRoot -ChildPath 'EntryPoint.ps1')
    [System.Int32]$expectedParamEnd = [System.Array]::IndexOf($lines, ')')

    $entryPoint.ParamEnd | Should -Be $expectedParamEnd
    $entryPoint.Lines[$entryPoint.ParamEnd] | Should -BeExactly ')'
    $entryPoint.Lines[$entryPoint.ParamEnd + 2] | Should -BeExactly 'Invoke-FixturePublic -Name $Name'
  }

  It 'strips script headers and wraps function files in a named region' {
    $builder = [System.Text.StringBuilder]::new()

    & $script:BuildModule {
      Param (
        [System.String]
        $Directory,

        [System.String]
        $RegionName,

        [System.Text.StringBuilder]
        $StringBuilder
      )

      Add-FunctionFileContent -Directory $Directory -RegionName $RegionName -StringBuilder $StringBuilder
    } -Directory (Join-Path -Path $script:FixtureRoot -ChildPath 'Private') -RegionName 'Private Functions' -StringBuilder $builder

    [System.String]$content = $builder.ToString()
    $content | Should -Match '(?m)^#region Private Functions\r?$'
    $content | Should -Match '(?m)^#endregion\r?$'
    $content | Should -Match 'Function Invoke-FixturePrivate'
    $content | Should -Not -Match '(?m)^#Requires'
    $content | Should -Not -Match '(?m)^# SPDX-FileCopyrightText:'
    $content | Should -Not -Match '(?m)^# SPDX-License-Identifier:'
  }

  It 'builds UTF-8 script outputs that preserve order, syntax, and dot-source round trips' {
    & $script:BuildModule { Invoke-ScriptBuild }

    $script:FunctionsFile | Should -Exist
    $script:OutputFile | Should -Exist

    ForEach ($path in @($script:FunctionsFile, $script:OutputFile)) {
      [System.String]$content = Get-Content -LiteralPath $path -Raw
      [System.Int32]$privateIndex = $content.IndexOf('#region Private Functions')
      [System.Int32]$publicIndex = $content.IndexOf('#region Public Functions')

      ($privateIndex -ge 0) | Should -BeTrue
      ($publicIndex -ge 0) | Should -BeTrue
      ($privateIndex -lt $publicIndex) | Should -BeTrue
      Test-FileHasUtf8Bom -Path $path | Should -BeFalse
    }

    { & $script:BuildModule {
        Param (
          [System.String[]]
          $SyntaxPaths
        )

        Test-Syntax -Path $SyntaxPaths
      } -SyntaxPaths @($script:FunctionsFile, $script:OutputFile) } | Should -Not -Throw

    $functionsRoundTrip = & {
      . $script:FunctionsFile
      [PSCustomObject]@{
        PublicDefined  = [System.Boolean](Get-Command -Name Invoke-FixturePublic -CommandType Function -ErrorAction SilentlyContinue)
        PrivateDefined = [System.Boolean](Get-Command -Name Invoke-FixturePrivate -CommandType Function -ErrorAction SilentlyContinue)
        Result         = Invoke-FixturePublic -Name 'Ada'
      }
    }

    $outputRoundTrip = & {
      $entryPointResult = . $script:OutputFile -Name 'Ada'
      [PSCustomObject]@{
        PublicDefined  = [System.Boolean](Get-Command -Name Invoke-FixturePublic -CommandType Function -ErrorAction SilentlyContinue)
        PrivateDefined = [System.Boolean](Get-Command -Name Invoke-FixturePrivate -CommandType Function -ErrorAction SilentlyContinue)
        Result         = $entryPointResult
      }
    }

    $functionsRoundTrip.PublicDefined | Should -BeTrue
    $functionsRoundTrip.PrivateDefined | Should -BeTrue
    $functionsRoundTrip.Result | Should -BeExactly 'Hello, Ada'
    $outputRoundTrip.PublicDefined | Should -BeTrue
    $outputRoundTrip.PrivateDefined | Should -BeTrue
    $outputRoundTrip.Result | Should -BeExactly 'Hello, Ada'
  }
}
