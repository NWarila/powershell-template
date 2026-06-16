#Requires -Version 5.1

Function Get-TemplateGreeting {
  <#
    .SYNOPSIS
        Returns an analyzer-clean greeting.

    .DESCRIPTION
        Demonstrates the template's preferred function shape: comment-based
        help, CmdletBinding, OutputType, explicit parameter metadata, and
        Begin/Process/End blocks with debug markers.

    .PARAMETER Name
        Name to include in the greeting.

    .EXAMPLE
        Get-TemplateGreeting -Name World

    .OUTPUTS
        [System.String]
    #>
  [CmdletBinding(
    ConfirmImpact = 'None',
    DefaultParameterSetName = 'default',
    HelpUri = 'https://github.com/NWarila/powershell-template/blob/main/docs/README.md',
    PositionalBinding = $False,
    SupportsPaging = $False,
    SupportsShouldProcess = $False
  )]
  [OutputType([System.String])]
  Param (
    [Parameter(
      DontShow = $False,
      Mandatory = $True,
      ParameterSetName = 'default',
      ValueFromPipeline = $True,
      ValueFromPipelineByPropertyName = $False
    )]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $Name
  )

  Begin {
    Write-Debug -Message:'[Get-TemplateGreeting] Entering Begin'

    # Initialize Variable(s)
    [System.String]$Private:TrimmedName = [System.String]::Empty
    [System.String]$Private:Result = [System.String]::Empty

    Write-Debug -Message:'[Get-TemplateGreeting] Exiting Begin'
  } Process {
    Write-Debug -Message:'[Get-TemplateGreeting] Entering Process'

    # Reset Variable(s)
    $TrimmedName = [System.String]::Empty
    $Result = [System.String]::Empty

    $TrimmedName = $Name.Trim()
    [System.String]$Result = 'Hello, {0}!' -f $TrimmedName
    $Result

    Write-Debug -Message:'[Get-TemplateGreeting] Exiting Process'
  } End {
    Write-Debug -Message:'[Get-TemplateGreeting] Entering End'
    Write-Debug -Message:'[Get-TemplateGreeting] Exiting End'
  }
}
