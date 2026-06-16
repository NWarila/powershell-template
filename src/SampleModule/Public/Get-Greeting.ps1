Function Get-Greeting {
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
  [OutputType([System.String])]
  Param (
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $Greeting = 'Hello',

    [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $Name
  )

  Begin {
    Write-Debug -Message:'[Get-Greeting] Entering Begin'

    # Initialize Variable(s)
    [System.String]$Private:Normalized = [System.String]::Empty
    [System.String]$Private:Result = [System.String]::Empty

    Write-Debug -Message:'[Get-Greeting] Exiting Begin'
  } Process {
    Write-Debug -Message:'[Get-Greeting] Entering Process'

    # Reset Variable(s)
    $Normalized = [System.String]::Empty
    $Result = [System.String]::Empty

    $Normalized = Format-GreetingName -Name:$Name
    [System.String]$Result = '{0}, {1}!' -f $Greeting, $Normalized
    $Result

    Write-Debug -Message:'[Get-Greeting] Exiting Process'
  } End {
    Write-Debug -Message:'[Get-Greeting] Entering End'
    Write-Debug -Message:'[Get-Greeting] Exiting End'
  }
}
