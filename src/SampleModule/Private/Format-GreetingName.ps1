function Format-GreetingName {
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
  [OutputType([string])]
  param(
    [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
    [ValidateNotNull()]
    [string]$Name
  )

  process {
    ($Name -replace '\s+', ' ').Trim()
  }
}
