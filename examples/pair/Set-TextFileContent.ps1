#Requires -Version 5.1
# SPDX-FileCopyrightText: 2026 Nicholas Warila
# SPDX-License-Identifier: MIT

<#
    .SYNOPSIS
        Converges a text file to exact declared content with a deterministic
        Changed/NoChange verdict.

    .DESCRIPTION
        The canonical pair-convention example script. Org scripts fill steps
        Ansible cannot do effectively, so each one is a single straightforward
        process stage in the org script template's architecture: one
        [ Script ] region carrying [ Initialization ] (debug/log level
        configuration, universal trap, transport detection, input
        normalization), [ Main ] (read -> compare -> mutate only on drift ->
        re-read and verify -> build ONE result object), and [ Output ] (the
        same object to $Ansible or as JSON).

        Under ansible.windows.win_powershell the result feeds $Ansible
        (Changed/Result, honoring CheckMode); standalone the same object is
        emitted as JSON, so a development shell and the sibling
        Set-TextFileContent.pester.ps1 spec exercise exactly the payload
        Ansible would see.

    .PARAMETER Content
        The exact content the file must carry.

    .PARAMETER DebugLevel
        Three-digit control string configuring independent debugging
        functions, one digit each. First digit: ErrorActionPreference
        (0 SilentlyContinue, 1 Stop, 2 Continue, 3 Inquire, 4 Ignore,
        5 Suspend). Second digit: Set-PSDebug (0 off, 1 trace 1, 2 trace 2,
        3 trace 1 + step, 4 trace 2 + step). Third digit: Set-StrictMode
        (0 off, 1-3 that version). Default '103': stop on error, no tracing,
        strict mode 3.0.

    .PARAMETER LogLevel
        Six-digit control string mapping the Verbose, Debug, Information,
        Warning, Error, and Fatal streams (in that order) to an
        ActionPreference value per digit (0 SilentlyContinue, 1 Stop,
        2 Continue, 3 Inquire, 4 Ignore, 5 Suspend). Default '002223'.

    .PARAMETER Path
        The file to converge.

    .EXAMPLE
        PS> ./Set-TextFileContent.ps1 -Path /etc/motd -Content 'declared'

    .OUTPUTS
        System.String
    #>
[CmdletBinding(
  ConfirmImpact = 'None',
  DefaultParameterSetName = 'default',
  HelpUri = '',
  PositionalBinding = $False,
  RemotingCapability = 'PowerShell',
  SupportsPaging = $False,
  SupportsShouldProcess = $False
)]
Param (
  [Parameter(
    DontShow = $False,
    Mandatory = $True,
    ParameterSetName = 'default',
    ValueFromPipeline = $False,
    ValueFromPipelineByPropertyName = $False
  )]
  [AllowEmptyString()]
  [System.String]
  $Content,

  [Parameter(
    DontShow = $False,
    Mandatory = $False,
    ParameterSetName = 'default',
    ValueFromPipeline = $False,
    ValueFromPipelineByPropertyName = $False
  )]
  [ValidatePattern('^[0-5][0-4][0-3]$')]
  [System.String]
  $DebugLevel = '103',

  [Parameter(
    DontShow = $False,
    Mandatory = $False,
    ParameterSetName = 'default',
    ValueFromPipeline = $False,
    ValueFromPipelineByPropertyName = $False
  )]
  [ValidatePattern('^[0-5]{6}$')]
  [System.String]
  $LogLevel = '002223',

  [Parameter(
    DontShow = $False,
    Mandatory = $True,
    ParameterSetName = 'default',
    ValueFromPipeline = $False,
    ValueFromPipelineByPropertyName = $False
  )]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Path
)

#region ------ [ Script ] -------------------------------------------------------------------- #

#region ------ [ Initialization ] ------------------------------------------------------------ #
Write-Debug -Message:'Entering Stage: Initialization'

# Initialize STATIC log level names, indexed by LogLevel digit position.
New-Variable -Force -Name:'LOG_LEVELS' -Option:('Private', 'ReadOnly') -Value:(
  [System.String[]]@('Verbose', 'Debug', 'Information', 'Warning', 'Error', 'Fatal')
)

# Initialize the custom stream preferences; the built-in ones already exist.
New-Variable -Verbose:$False -Force -Name:'ErrorPreference' -Value:(
  [System.Management.Automation.ActionPreference]::Stop
)
New-Variable -Verbose:$False -Force -Name:'FatalPreference' -Value:(
  [System.Management.Automation.ActionPreference]::Stop
)

# Configure log levels based on the LogLevel parameter.
For ($L = 0; $L -lt 6; $L++) {
  Set-Variable -Verbose:$False -Force -Name:('{0}Preference' -f $LOG_LEVELS[$L]) -Value:(
    [System.Int32]::Parse([System.String]$LogLevel[$L]) -as [System.Management.Automation.ActionPreference]
  )
}

# Configure the debug levels: first digit ErrorActionPreference, second digit
# Set-PSDebug, third digit Set-StrictMode.
$ErrorActionPreference = [System.Management.Automation.ActionPreference][System.Int32]::Parse($DebugLevel.Substring(0, 1))
Switch ($DebugLevel.Substring(1, 1)) {
  '0' { Set-PSDebug -Off }
  '1' { Set-PSDebug -Trace:1 }
  '2' { Set-PSDebug -Trace:2 }
  '3' { Set-PSDebug -Trace:1 -Step }
  '4' { Set-PSDebug -Trace:2 -Step }
}
If ($DebugLevel.Substring(2, 1) -eq '0') {
  Set-StrictMode -Off
} Else {
  Set-StrictMode -Version:([System.String]$DebugLevel.Substring(2, 1))
}

# Universal trap used to help with debugging efforts. The original template's
# Wait-Debugger/Exit are interactive-host machinery; under the Ansible
# transport the trap logs and rethrows (Break) so the task fails honestly.
Trap {
  # Diagnostics are wrapped so a partially-populated error record can never
  # replace the original failure with a StrictMode property error.
  Try {
    # Write debug statement if the invoking line is available.
    If ($PSItem.Exception.PSObject.Properties.Name -contains 'ErrorRecord') {
      Write-Debug -Message:(
        'Failed to execute command: {0}' -f [System.String]$PSItem.Exception.ErrorRecord.InvocationInfo.Line
      )
    }

    # Write the error text. The original template uses Write-Host red here;
    # PSAvoidUsingWriteHost is ratified, so the warning stream carries it.
    Write-Warning -Message:(
      '[{0:0000}] {1} [{2}]' -f @(
        [System.Int64]$PSItem.InvocationInfo.ScriptLineNumber
        [System.String]$PSItem.Exception.Message
        [System.String]$PSItem.Exception.GetBaseException().GetType().FullName
      )
    )
  } Catch {
    Write-Debug -Message:'Trap diagnostics unavailable for this error record.'
  }

  Break
}

# Under win_powershell the transport provides $Ansible; standalone (a dev
# shell or a Pester spec) it does not, so the script creates a faithful stub.
# Either way the rest of the script has exactly ONE code path: the outcome is
# always written to $Ansible, and Output serializes the stub as JSON when the
# script created it. Changed defaults to $True like the real transport and is
# set explicitly on every path.
$StandaloneRun = $Null -eq (Get-Variable -Name:'Ansible' -ValueOnly -ErrorAction:'SilentlyContinue')
If ($StandaloneRun) {
  $Ansible = [PSCustomObject]@{
    Changed   = $True
    CheckMode = $False
    Failed    = $False
    Result    = $Null
  }
}

#endregion --- [ Initialization ] ------------------------------------------------------------ #

#region ------ [ Main ] ---------------------------------------------------------------------- #
Write-Debug -Message:'Entering Stage: Main'

# Read the current content raw; an absent file is legitimate pre-convergence
# state, not an error. Content compares case-SENSITIVELY (-cne): the file must
# carry the exact declared bytes-as-text.
$CurrentContent = $Null
If (Test-Path -LiteralPath:$Path -PathType:'Leaf') {
  $CurrentContent = Get-Content -LiteralPath:$Path -Raw -ErrorAction:'Stop'
}

If ($CurrentContent -cne $Content) {
  # The result payload reports SHA-256 digests, never content, so a secret
  # never leaks into task output.
  $Sha256 = [System.Security.Cryptography.SHA256]::Create()
  $BeforeDigest = $Null
  If ($Null -ne $CurrentContent) {
    $BeforeDigest = [System.BitConverter]::ToString($Sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($CurrentContent))).Replace('-', '').ToLowerInvariant()
  }
  $AfterDigest = [System.BitConverter]::ToString($Sha256.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Content))).Replace('-', '').ToLowerInvariant()
  $Sha256.Dispose()

  If ($Ansible.CheckMode) {
    $Result = [PSCustomObject]@{
      changed    = $True
      check_mode = $True
      drift      = [PSCustomObject]@{ before = $BeforeDigest; after = $AfterDigest }
      msg        = ('Check mode: would rewrite {0}.' -f $Path)
    }
  } Else {
    $ParentDirectory = Split-Path -Path:$Path -Parent
    If (-not [System.String]::IsNullOrEmpty($ParentDirectory) -and -not (Test-Path -LiteralPath:$ParentDirectory -PathType:'Container')) {
      $Null = New-Item -ItemType:'Directory' -Path:$ParentDirectory -Force
    }
    Set-Content -LiteralPath:$Path -Value:$Content -NoNewline -Encoding:'utf8' -ErrorAction:'Stop'

    # Re-read and verify: 'changed' is proven from a fresh read, never assumed
    # from the write returning without error.
    If ((Get-Content -LiteralPath:$Path -Raw -ErrorAction:'Stop') -cne $Content) {
      Throw ('Set-Content returned without error, but {0} still differs from the declared content. Refusing to report convergence.' -f $Path)
    }

    $Result = [PSCustomObject]@{
      changed    = $True
      check_mode = $False
      drift      = [PSCustomObject]@{ before = $BeforeDigest; after = $AfterDigest }
      msg        = ('Converged {0} to the declared content.' -f $Path)
    }
  }
} Else {
  $Result = [PSCustomObject]@{
    changed    = $False
    check_mode = $Ansible.CheckMode
    drift      = $Null
    msg        = ('File {0} already carries the declared content.' -f $Path)
  }
}

#endregion --- [ Main ] ---------------------------------------------------------------------- #

#region ------ [ Output ] -------------------------------------------------------------------- #
Write-Debug -Message:'Entering Stage: Output'

$Ansible.Changed = $Result.changed
$Ansible.Result = $Result
If ($StandaloneRun) {
  $Ansible.Result | ConvertTo-Json -Depth:4
}

Write-Debug -Message:'Exiting Script'
#endregion --- [ Output ] -------------------------------------------------------------------- #

#endregion --- [ Script ] -------------------------------------------------------------------- #
