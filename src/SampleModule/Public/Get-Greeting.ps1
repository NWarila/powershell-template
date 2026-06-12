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
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Greeting = 'Hello'
    )

    begin {
        New-Variable -Name 'Normalized' -Force -Option Private -Value ([System.String]::Empty)
    }

    process {
        Clear-Variable -Name 'Normalized' -Force -ErrorAction SilentlyContinue
        $Normalized = Format-GreetingName -Name $Name
        '{0}, {1}!' -f $Greeting, $Normalized
    }
}
