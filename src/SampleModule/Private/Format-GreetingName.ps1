Function Format-GreetingName {
  <#
    .SYNOPSIS
        Normalizes a name for use in a greeting.

    .DESCRIPTION
        Internal helper that trims surrounding whitespace and collapses
        repeated internal whitespace to a single space. Not exported; used to
        demonstrate the Private/ function layer. Replace with your own private
        helpers.

    .PARAMETER Name
        The raw name to normalize.

    .OUTPUTS
        System.String
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
    [ValidateNotNull()]
    [System.String]
    $Name
  )

  Begin {
    Write-Debug -Message:'[Format-GreetingName] Entering Begin'

    # Initialize Variable(s)
    [System.String]$Private:NormalizedName = [System.String]::Empty
    [System.String]$Private:Result = [System.String]::Empty

    Write-Debug -Message:'[Format-GreetingName] Exiting Begin'
  } Process {
    Write-Debug -Message:'[Format-GreetingName] Entering Process'

    # Reset Variable(s)
    $NormalizedName = [System.String]::Empty
    $Result = [System.String]::Empty

    $NormalizedName = ($Name -replace '\s+', ' ').Trim()
    [System.String]$Result = $NormalizedName
    $Result

    Write-Debug -Message:'[Format-GreetingName] Exiting Process'
  } End {
    Write-Debug -Message:'[Format-GreetingName] Entering End'
    Write-Debug -Message:'[Format-GreetingName] Exiting End'
  }
}
