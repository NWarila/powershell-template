#Requires -Version 5.1
# SPDX-FileCopyrightText: 2026 Nicholas Warila
# SPDX-License-Identifier: MIT
<#
    Pester spec for Set-TextFileContent.ps1 -- the canonical pair-convention
    example. Every org script ships as two files: <Name>.ps1 and
    <Name>.pester.ps1; the pester-matrix workflow discovers the pairs and runs
    one matrix leg per script.

    The spec asserts BOTH transports: the standalone JSON emission (what a
    developer sees) and the $Ansible path (what the managed host sees). Pairs
    are SELF-CONTAINED: the $Ansible stand-in is the inline context below,
    not an imported module. Its Changed defaults to $True exactly like
    win_powershell, so the no-drift test proves the script SETS
    Changed=$False rather than inheriting an accidental default.

    File operations run against Pester's $TestDrive, so the spec needs no
    stubs and runs on any OS.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

BeforeAll {
  $script:ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'Set-TextFileContent.ps1'

  # Inline $Ansible stand-in (org contract: pairs are self-contained, no
  # imports). Faithful to win_powershell: Changed defaults to $True, and only
  # the ratified surface (Changed, CheckMode, Failed, Result) is modeled.
  Function New-AnsibleContext {
    Param ([Switch]$CheckMode)
    $global:Ansible = [PSCustomObject]@{
      Changed   = $True
      CheckMode = $CheckMode.IsPresent
      Failed    = $False
      Result    = $Null
    }
    $global:Ansible
  }

  Function Remove-AnsibleContext {
    Remove-Variable -Name 'Ansible' -Scope 'Global' -Force -ErrorAction 'SilentlyContinue'
  }
}

Describe 'Set-TextFileContent' {

  BeforeEach {
    # Unique per test: $TestDrive contents persist across tests in a block, and
    # a file converged by one test must not leak converged state into the next.
    $script:TargetPath = Join-Path -Path $TestDrive -ChildPath ('converge-{0}/target.conf' -f [System.Guid]::NewGuid().ToString('N'))
  }

  AfterEach {
    Remove-AnsibleContext
  }

  Context 'standalone JSON transport' {

    It 'reports NoChange and leaves the file untouched on a converged host' {
      New-Item -ItemType Directory -Path (Split-Path -Path $script:TargetPath -Parent) -Force | Out-Null
      Set-Content -LiteralPath $script:TargetPath -Value 'declared' -NoNewline
      $before = (Get-Item -LiteralPath $script:TargetPath).LastWriteTimeUtc

      $result = & $script:ScriptPath -Path $script:TargetPath -Content 'declared' | ConvertFrom-Json

      $result.changed | Should -BeFalse
      $result.drift | Should -BeNullOrEmpty
      (Get-Item -LiteralPath $script:TargetPath).LastWriteTimeUtc | Should -Be $before
    }

    It 'creates a missing file and reports the drift digests' {
      $result = & $script:ScriptPath -Path $script:TargetPath -Content 'declared' | ConvertFrom-Json

      $result.changed | Should -BeTrue
      $result.drift.before | Should -BeNullOrEmpty
      $result.drift.after | Should -Match '^[0-9a-f]{64}$'
      Get-Content -LiteralPath $script:TargetPath -Raw | Should -BeExactly 'declared'
    }

    It 'rewrites drifted content and verifies from a fresh read' {
      New-Item -ItemType Directory -Path (Split-Path -Path $script:TargetPath -Parent) -Force | Out-Null
      Set-Content -LiteralPath $script:TargetPath -Value 'stale' -NoNewline

      $result = & $script:ScriptPath -Path $script:TargetPath -Content 'declared' | ConvertFrom-Json

      $result.changed | Should -BeTrue
      $result.drift.before | Should -Not -Be $result.drift.after
      Get-Content -LiteralPath $script:TargetPath -Raw | Should -BeExactly 'declared'
    }

    It 'reports digests, never content, in the result payload' {
      $json = & $script:ScriptPath -Path $script:TargetPath -Content 'S3cr3t-value'

      $json | Should -Not -Match 'S3cr3t-value'
    }
  }

  Context '$Ansible transport' {

    It 'sets Changed=$False explicitly on a converged host (transport defaults to $True)' {
      New-Item -ItemType Directory -Path (Split-Path -Path $script:TargetPath -Parent) -Force | Out-Null
      Set-Content -LiteralPath $script:TargetPath -Value 'declared' -NoNewline
      $context = New-AnsibleContext

      $emitted = & $script:ScriptPath -Path $script:TargetPath -Content 'declared'

      $context.Changed | Should -BeFalse
      $context.Result.msg | Should -Match 'already carries'
      # Everything goes through $Ansible.Result; nothing may leak to output.
      $emitted | Should -BeNullOrEmpty
    }

    It 'reports Changed with the drift payload after converging' {
      $context = New-AnsibleContext

      & $script:ScriptPath -Path $script:TargetPath -Content 'declared' | Out-Null

      $context.Changed | Should -BeTrue
      $context.Result.drift.after | Should -Match '^[0-9a-f]{64}$'
      Get-Content -LiteralPath $script:TargetPath -Raw | Should -BeExactly 'declared'
    }

    It 'honors CheckMode: reports would-change and writes nothing' {
      $context = New-AnsibleContext -CheckMode

      & $script:ScriptPath -Path $script:TargetPath -Content 'declared' | Out-Null

      $context.Changed | Should -BeTrue
      $context.Result.check_mode | Should -BeTrue
      Test-Path -LiteralPath $script:TargetPath | Should -BeFalse
    }
  }
}
