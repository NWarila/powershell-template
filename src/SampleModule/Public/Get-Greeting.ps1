function Get-Greeting {
  <#
    .SYNOPSIS
        Builds a greeting string for the supplied name.

    .DESCRIPTION
        Get-Greeting is the worked example shipped with the PowerShell module
        template. It demonstrates comment-based help, parameter validation,
        pipeline input, and a deterministic, easily testable return value.
        Replace it with your own public functions.

    .PARAMETER Name
        The name to greet. Accepts pipeline input by value and by property
        name.

    .PARAMETER Greeting
        The salutation to prepend to the name. Defaults to 'Hello'.

    .EXAMPLE
        PS> Get-Greeting -Name 'World'
        Hello, World!

    .EXAMPLE
        PS> 'Ada', 'Grace' | Get-Greeting -Greeting 'Welcome'
        Welcome, Ada!
        Welcome, Grace!

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
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Greeting = 'Hello',

    [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [string]$Name
  )

  begin {
    Write-Debug -Message '[Get-Greeting] Entering Begin'

    # Initalize Variable(s)
    [System.String]$Private:Normalized = [System.String]::Empty

    Write-Debug -Message '[Get-Greeting] Exiting Begin'
  }

  process {
    $Normalized = [System.String]::Empty
    $Normalized = Format-GreetingName -Name $Name
    '{0}, {1}!' -f $Greeting, $Normalized
  }
}
