#Requires -Version 5.1

function Get-TemplateGreeting {
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
    param (
        [Parameter(
            Mandatory = $True,
            ValueFromPipeline = $True
        )]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Name
    )

    begin {
        Write-Debug -Message '[Get-TemplateGreeting] Entering Begin'
        Write-Debug -Message '[Get-TemplateGreeting] Exiting Begin'
    }

    process {
        Write-Debug -Message '[Get-TemplateGreeting] Entering Process'

        [System.String]('Hello, {0}!' -f $Name.Trim())

        Write-Debug -Message '[Get-TemplateGreeting] Exiting Process'
    }

    end {
        Write-Debug -Message '[Get-TemplateGreeting] Entering End'
        Write-Debug -Message '[Get-TemplateGreeting] Exiting End'
    }
}
