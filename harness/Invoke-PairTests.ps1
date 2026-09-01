#Requires -Version 5.1
<#
    Invoke-PairTests: the execution half of the org's script pair convention.

    Every org PowerShell script ships as two files: <Name>.ps1 (the script)
    and <Name>.pester.ps1 (its spec). This runner enforces and executes that
    contract two ways:

      Scan mode   (-Path <dir>):   discover every pair under a directory,
                                   fail on any unpaired script or orphan spec,
                                   then run every pair.
      Single mode (-Script/-Pester): run exactly one pair -- the shape one
                                   matrix leg of the pester-matrix workflow
                                   executes.

    Per pair: the canonical-anatomy check (the full Script template shape,
    hand-written), then PSScriptAnalyzer over the SCRIPT with the house
    settings (zero findings at any severity), then the spec via Pester. Pairs
    are fully self-contained -- a spec carries its own stubs and its own
    inline $Ansible context, so this runner adds nothing to the session.
    Specs are exercised by running rather than analyzed, because several
    analyzer rules misread Pester's scoping model.

    Requires: PSScriptAnalyzer and Pester v5+.
#>
[CmdletBinding(
  ConfirmImpact = 'None',
  DefaultParameterSetName = 'scan',
  HelpUri = '',
  PositionalBinding = $False,
  SupportsPaging = $False,
  SupportsShouldProcess = $False
)]
Param (
  [Parameter(
    DontShow = $False,
    Mandatory = $True,
    ParameterSetName = 'scan',
    ValueFromPipeline = $False,
    ValueFromPipelineByPropertyName = $False
  )]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Path,

  [Parameter(
    DontShow = $False,
    Mandatory = $True,
    ParameterSetName = 'single',
    ValueFromPipeline = $False,
    ValueFromPipelineByPropertyName = $False
  )]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Pester,

  [Parameter(
    DontShow = $False,
    Mandatory = $True,
    ParameterSetName = 'single',
    ValueFromPipeline = $False,
    ValueFromPipelineByPropertyName = $False
  )]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Script
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Function Get-PairSet {
  <#
    .SYNOPSIS
        Discovers script/spec pairs under a directory, failing on orphans.

    .DESCRIPTION
        Enumerates every *.ps1 under the scan root. Each plain script must
        have a sibling <Name>.pester.ps1 and each spec must have a sibling
        <Name>.ps1; either orphan fails discovery, because an untested script
        and a spec testing nothing are both contract violations.

    .PARAMETER ScanRoot
        Directory to scan recursively.

    .OUTPUTS
        System.Object[]
    #>
  [CmdletBinding(
    ConfirmImpact = 'None',
    DefaultParameterSetName = 'default',
    HelpUri = '',
    PositionalBinding = $False,
    SupportsPaging = $False,
    SupportsShouldProcess = $False
  )]
  [OutputType([System.Object[]])]
  Param (
    [Parameter(
      DontShow = $False,
      Mandatory = $True,
      ParameterSetName = 'default',
      ValueFromPipeline = $False,
      ValueFromPipelineByPropertyName = $False
    )]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ScanRoot
  )
  Write-Debug -Message:'[Get-PairSet] Entering'

  # Initialize Variable(s)
  [System.IO.FileInfo[]]$Private:AllFiles = @()
  [System.Collections.Generic.List[System.String]]$Private:Orphans = [System.Collections.Generic.List[System.String]]::new()
  [System.Collections.Generic.List[System.Object]]$Private:Pairs = [System.Collections.Generic.List[System.Object]]::new()
  [System.String]$Private:Sibling = [System.String]::Empty
  [System.Object[]]$Private:Result = @()

  $AllFiles = @(Get-ChildItem -LiteralPath:$ScanRoot -Filter:'*.ps1' -File -Recurse -ErrorAction:'Stop')

  ForEach ($File In $AllFiles) {
    If ($File.Name -like '*.pester.ps1') {
      $Sibling = Join-Path -Path:$File.DirectoryName -ChildPath:($File.Name -replace '\.pester\.ps1$', '.ps1')
      If (-not (Test-Path -LiteralPath:$Sibling -PathType:'Leaf')) {
        [void]$Orphans.Add(('{0} has no sibling script {1}' -f $File.FullName, $Sibling))
      }
    } Else {
      $Sibling = Join-Path -Path:$File.DirectoryName -ChildPath:($File.Name -replace '\.ps1$', '.pester.ps1')
      If (Test-Path -LiteralPath:$Sibling -PathType:'Leaf') {
        [void]$Pairs.Add([PSCustomObject]@{
            Name   = $File.BaseName
            Pester = $Sibling
            Script = $File.FullName
          })
      } Else {
        [void]$Orphans.Add(('{0} has no sibling spec {1}' -f $File.FullName, $Sibling))
      }
    }
  }

  If ($Orphans.Count -gt 0) {
    Throw ('Pair convention violated: {0}' -f ($Orphans -join '; '))
  }
  If ($Pairs.Count -eq 0) {
    Throw ('No script pairs found under {0}; an empty scan passing would hide a broken path.' -f $ScanRoot)
  }

  [System.Object[]]$Result = $Pairs.ToArray()
  $Result

  Write-Debug -Message:'[Get-PairSet] Exiting'
}

Function Test-PairAnatomy {
  <#
    .SYNOPSIS
        Enforces the canonical single-file anatomy of the full Script template.

    .DESCRIPTION
        Org scripts fill steps Ansible cannot do effectively, so each one is a
        single straightforward process stage in the org script template's
        region architecture, with no function decomposition. Mechanically
        checked here: the #Requires first line, the SPDX header pair, and the
        ordered banner regions [ Script ], [ Initialization ], [ Main ],
        [ Output ]. The sibling spec must open with the same #Requires + SPDX
        header.

    .PARAMETER PesterPath
        The spec file to check.

    .PARAMETER ScriptPath
        The script file to check.

    .OUTPUTS
        System.Void
    #>
  [CmdletBinding(
    ConfirmImpact = 'None',
    DefaultParameterSetName = 'default',
    HelpUri = '',
    PositionalBinding = $False,
    SupportsPaging = $False,
    SupportsShouldProcess = $False
  )]
  [OutputType([System.Void])]
  Param (
    [Parameter(
      DontShow = $False,
      Mandatory = $True,
      ParameterSetName = 'default',
      ValueFromPipeline = $False,
      ValueFromPipelineByPropertyName = $False
    )]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $PesterPath,

    [Parameter(
      DontShow = $False,
      Mandatory = $True,
      ParameterSetName = 'default',
      ValueFromPipeline = $False,
      ValueFromPipelineByPropertyName = $False
    )]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ScriptPath
  )
  Write-Debug -Message:'[Test-PairAnatomy] Entering'

  # Initialize Variable(s)
  [System.String[]]$Private:ScriptLines = @()
  [System.Collections.Generic.List[System.String]]$Private:Violations = [System.Collections.Generic.List[System.String]]::new()
  [System.Int32]$Private:LastMarkerIndex = -1
  [System.Int32]$Private:MarkerIndex = -1

  ForEach ($Target In @($ScriptPath, $PesterPath)) {
    $ScriptLines = [System.String[]]@(Get-Content -LiteralPath:$Target)
    If ($ScriptLines.Count -lt 3 -or $ScriptLines[0] -ne '#Requires -Version 5.1') {
      [void]$Violations.Add(('{0}: line 1 must be exactly ''#Requires -Version 5.1''' -f $Target))
    }
    If ($ScriptLines.Count -ge 3 -and ($ScriptLines[1] -notmatch '^# SPDX-FileCopyrightText: ' -or $ScriptLines[2] -notmatch '^# SPDX-License-Identifier: ')) {
      [void]$Violations.Add(('{0}: lines 2-3 must be the SPDX FileCopyrightText / License-Identifier pair' -f $Target))
    }
  }

  $ScriptLines = [System.String[]]@(Get-Content -LiteralPath:$ScriptPath)
  $LastMarkerIndex = -1
  ForEach ($MarkerName In @('Script', 'Initialization', 'Main', 'Output')) {
    $MarkerIndex = -1
    For ($LineIndex = 0; $LineIndex -lt $ScriptLines.Count; $LineIndex++) {
      If ($ScriptLines[$LineIndex] -match ('^#region [-]+ \[ {0} \] [-]+ #$' -f [System.Text.RegularExpressions.Regex]::Escape($MarkerName))) {
        $MarkerIndex = $LineIndex
        Break
      }
    }
    If ($MarkerIndex -lt 0) {
      [void]$Violations.Add(('{0}: missing required banner region ''[ {1} ]''' -f $ScriptPath, $MarkerName))
    } ElseIf ($MarkerIndex -lt $LastMarkerIndex) {
      [void]$Violations.Add(('{0}: banner region ''[ {1} ]'' is out of canonical order' -f $ScriptPath, $MarkerName))
    } Else {
      $LastMarkerIndex = $MarkerIndex
    }
  }
  # Full-template machinery: the DebugLevel/LogLevel control parameters and
  # the universal trap are part of every script's Initialization stage.
  ForEach ($RequiredFragment In @('$DebugLevel', '$LogLevel', 'Trap {')) {
    If (@($ScriptLines | Where-Object -FilterScript { $PSItem.Contains($RequiredFragment) }).Count -eq 0) {
      [void]$Violations.Add(('{0}: missing the script template''s ''{1}'' machinery' -f $ScriptPath, $RequiredFragment))
    }
  }

  If ($Violations.Count -gt 0) {
    If ($env:GITHUB_ACTIONS -eq 'true') {
      ForEach ($Violation In $Violations) {
        Write-Information -MessageData:('::error title=Canonical anatomy::{0}' -f $Violation) -InformationAction:'Continue'
      }
    }
    Throw ('Canonical anatomy violated (see docs/reference/pester-pair-testing.md): {0}' -f ($Violations -join '; '))
  }
  Write-Information -MessageData:'Anatomy: canonical.' -InformationAction:'Continue'

  Write-Debug -Message:'[Test-PairAnatomy] Exiting'
}

Function Invoke-PairLeg {
  <#
    .SYNOPSIS
        Analyzes one script and runs its spec.

    .DESCRIPTION
        The unit of work one matrix leg performs: PSScriptAnalyzer over the
        script with the house settings (zero findings at any severity is the
        bar), then the sibling spec via Pester with Run.Throw so a failing
        test fails the leg.

    .PARAMETER PesterPath
        The spec file to run.

    .PARAMETER ScriptPath
        The script file to analyze.

    .OUTPUTS
        System.Void
    #>
  [CmdletBinding(
    ConfirmImpact = 'None',
    DefaultParameterSetName = 'default',
    HelpUri = '',
    PositionalBinding = $False,
    SupportsPaging = $False,
    SupportsShouldProcess = $False
  )]
  [OutputType([System.Void])]
  Param (
    [Parameter(
      DontShow = $False,
      Mandatory = $True,
      ParameterSetName = 'default',
      ValueFromPipeline = $False,
      ValueFromPipelineByPropertyName = $False
    )]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $PesterPath,

    [Parameter(
      DontShow = $False,
      Mandatory = $True,
      ParameterSetName = 'default',
      ValueFromPipeline = $False,
      ValueFromPipelineByPropertyName = $False
    )]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $ScriptPath
  )
  Write-Debug -Message:'[Invoke-PairLeg] Entering'

  # Initialize Variable(s)
  [System.Object[]]$Private:Findings = @()
  [System.String]$Private:FindingText = [System.String]::Empty
  [System.Object]$Private:Configuration = $Null
  [System.Object]$Private:PesterRun = $Null
  [System.Boolean]$Private:InGithubActions = ($env:GITHUB_ACTIONS -eq 'true')
  [System.String]$Private:PairName = [System.String]::Empty
  [System.String]$Private:AnnotationPath = [System.String]::Empty
  [System.String]$Private:ResultsDirectory = [System.String]::Empty
  [System.Collections.Hashtable]$Private:SarifLevelBySeverity = @{}
  [System.Object[]]$Private:SarifArtifacts = @()
  [System.Object[]]$Private:SarifResults = @()
  [System.Object[]]$Private:SarifRules = @()
  [System.String]$Private:AnalyzerVersion = [System.String]::Empty
  [System.Collections.Hashtable]$Private:SarifDocument = @{}
  [System.String]$Private:ResolvedPester = [System.String]::Empty
  [System.String]$Private:ResolvedScript = [System.String]::Empty

  # Resolve to absolute paths BEFORE any location change: analysis runs from
  # the template root (CustomRulePath is relative to it), and a relative
  # caller path must not silently re-resolve against that root.
  $ResolvedPester = (Resolve-Path -LiteralPath:$PesterPath).Path
  $ResolvedScript = (Resolve-Path -LiteralPath:$ScriptPath).Path
  $PairName = [System.IO.Path]::GetFileNameWithoutExtension($ResolvedScript)
  $AnnotationPath = $ResolvedScript
  If ($InGithubActions -and -not [System.String]::IsNullOrEmpty($env:GITHUB_WORKSPACE)) {
    # Annotations attach to the PR diff only with workspace-relative paths.
    $AnnotationPath = [System.IO.Path]::GetRelativePath($env:GITHUB_WORKSPACE, $ResolvedScript)
  }
  If ($InGithubActions) {
    $ResultsDirectory = $env:PAIR_RESULTS_DIR
    If ([System.String]::IsNullOrEmpty($ResultsDirectory)) {
      $ResultsDirectory = Join-Path -Path:(Get-Location).Path -ChildPath:'TestResults'
    }
    $Null = New-Item -ItemType:'Directory' -Path:$ResultsDirectory -Force
  }

  Write-Information -MessageData:('=== Pair: {0} ===' -f $ResolvedScript) -InformationAction:'Continue'

  Test-PairAnatomy -PesterPath:$ResolvedPester -ScriptPath:$ResolvedScript

  # The settings file names a CustomRulePath relative to the template root, so
  # analysis runs from there regardless of the caller's working directory.
  Push-Location -LiteralPath:$script:TemplateRoot
  Try {
    $Findings = @(Invoke-ScriptAnalyzer -Path:$ResolvedScript -Settings:$script:SettingsPath)
  } Finally {
    Pop-Location
  }
  If ($InGithubActions) {
    # SARIF 2.1.0 for GitHub code scanning, hand-emitted (the PSSA converter
    # module is archived). Written BEFORE the zero-findings gate so a failing
    # leg still publishes exactly what it found; a zero-result run registers
    # the tool against the ref. automationDetails.id takes precedence over the
    # upload action's category input, and GitHub parses it as
    # '<category>/<run-correlation>' -- the category is everything before the
    # LAST slash (verified live: 'a/b' -> 'a', slashless -> empty). The
    # trailing-slash form makes the whole per-pair string the category, so
    # pairs never last-writer-win each other's analyses.
    $SarifLevelBySeverity = @{ 'Error' = 'error'; 'ParseError' = 'error'; 'Warning' = 'warning'; 'Information' = 'note' }
    $SarifResults = @(
      ForEach ($Finding In $Findings) {
        @{
          ruleId    = [System.String]$Finding.RuleName
          level     = [System.String]$(If ($SarifLevelBySeverity.ContainsKey([System.String]$Finding.Severity)) { $SarifLevelBySeverity[[System.String]$Finding.Severity] } Else { 'note' })
          message   = @{ text = [System.String]$Finding.Message }
          locations = @(
            @{
              physicalLocation = @{
                artifactLocation = @{ uri = $AnnotationPath.Replace('\', '/') }
                region           = @{ startLine = [System.Math]::Max(1, [System.Int32]$Finding.Line) }
              }
            }
          )
        }
      }
    )
    $SarifRules = @(
      $Findings | ForEach-Object -Process { [System.String]$PSItem.RuleName } | Sort-Object -Unique | ForEach-Object -Process { @{ id = $PSItem } }
    )
    # The artifacts array is what code scanning reports as the analysis's
    # scanned files; without it a zero-result run says nothing about coverage.
    $SarifArtifacts = @(
      @{ location = @{ uri = $AnnotationPath.Replace('\', '/') } }
    )
    $AnalyzerVersion = [System.String](Get-Module -ListAvailable -Name:'PSScriptAnalyzer' | Sort-Object -Property:'Version' -Descending | Select-Object -First:1).Version
    $SarifDocument = @{
      version   = '2.1.0'
      '$schema' = 'https://json.schemastore.org/sarif-2.1.0.json'
      runs      = @(
        @{
          tool              = @{ driver = @{ name = 'PSScriptAnalyzer'; version = $AnalyzerVersion; informationUri = 'https://github.com/NWarila/powershell-template'; rules = $SarifRules } }
          automationDetails = @{ id = ('pester-matrix-{0}/' -f $PairName) }
          artifacts         = $SarifArtifacts
          results           = $SarifResults
        }
      )
    }
    Set-Content -LiteralPath:(Join-Path -Path:$ResultsDirectory -ChildPath:('{0}.sarif' -f $PairName)) -Value:(ConvertTo-Json -InputObject:$SarifDocument -Depth:12)
  }

  If ($Findings.Count -gt 0) {
    If ($InGithubActions) {
      ForEach ($Finding In $Findings) {
        Write-Information -MessageData:('::warning file={0},line={1},title=PSScriptAnalyzer {2}::{3}' -f $AnnotationPath, $Finding.Line, $Finding.RuleName, $Finding.Message) -InformationAction:'Continue'
      }
    }
    $FindingText = $Findings |
      Format-Table -Property:@('RuleName', 'Severity', 'Line', 'Message') -AutoSize |
      Out-String -Width:220
    Write-Information -MessageData:$FindingText -InformationAction:'Continue'
    Throw ('{0} analyzer finding(s) for {1}; zero is the bar.' -f $Findings.Count, $ResolvedScript)
  }
  Write-Information -MessageData:'Analyzer: zero findings.' -InformationAction:'Continue'

  $Configuration = New-PesterConfiguration
  $Configuration.Run.Path = $ResolvedPester
  $Configuration.Run.PassThru = $True
  $Configuration.Output.Verbosity = 'Detailed'
  If ($InGithubActions) {
    # JUnit XML is the interchange format GitHub tooling consumes; the matrix
    # uploads the whole directory as a per-leg artifact.
    $Configuration.TestResult.Enabled = $True
    $Configuration.TestResult.OutputFormat = 'JUnitXml'
    $Configuration.TestResult.OutputPath = Join-Path -Path:$ResultsDirectory -ChildPath:('{0}.junit.xml' -f $PairName)
  }
  $PesterRun = Invoke-Pester -Configuration:$Configuration

  If ($InGithubActions -and -not [System.String]::IsNullOrEmpty($env:GITHUB_STEP_SUMMARY)) {
    Add-Content -LiteralPath:$env:GITHUB_STEP_SUMMARY -Value:(
      ('### Pair: {0}' -f $PairName),
      '',
      '| Check | Result |',
      '| --- | --- |',
      '| Anatomy | canonical |',
      '| Analyzer | zero findings |',
      ('| Specs | {0} passed, {1} failed, {2} skipped ({3:N1}s) |' -f $PesterRun.PassedCount, $PesterRun.FailedCount, $PesterRun.SkippedCount, $PesterRun.Duration.TotalSeconds),
      ''
    )
  }
  If ($Null -eq $PesterRun -or $PesterRun.FailedCount -gt 0 -or $PesterRun.TotalCount -eq 0) {
    Throw ('Spec run failed for {0}: {1} failed of {2} total.' -f $PairName, $PesterRun.FailedCount, $PesterRun.TotalCount)
  }

  Write-Debug -Message:'[Invoke-PairLeg] Exiting'
}

# Initialize Variable(s)
[System.String]$script:TemplateRoot = (Resolve-Path -LiteralPath:(Join-Path -Path:$PSScriptRoot -ChildPath:'..')).Path
[System.String]$script:SettingsPath = Join-Path -Path:$TemplateRoot -ChildPath:'PSScriptAnalyzerSettings.psd1'
[System.Object[]]$Private:PairSet = @()

ForEach ($ModuleName In @('PSScriptAnalyzer', 'Pester')) {
  If ($Null -eq (Get-Module -ListAvailable -Name:$ModuleName)) {
    Throw ('Required module {0} is not installed; install it and re-run.' -f $ModuleName)
  }
}

If ($PSCmdlet.ParameterSetName -eq 'single') {
  Invoke-PairLeg -PesterPath:$Pester -ScriptPath:$Script
} Else {
  $PairSet = Get-PairSet -ScanRoot:$Path
  Write-Information -MessageData:('Discovered {0} pair(s) under {1}.' -f $PairSet.Count, $Path) -InformationAction:'Continue'
  ForEach ($Pair In $PairSet) {
    Invoke-PairLeg -PesterPath:$Pair.Pester -ScriptPath:$Pair.Script
  }
}
