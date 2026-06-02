@{
    # PSScriptAnalyzer settings for this template. Aligned with the PSGallery
    # ruleset that PowerShell Gallery enforces on publish, with a couple of
    # template-appropriate carve-outs documented inline.
    #
    # CI invokes the analyzer with the built-in PSGallery preset
    # (Invoke-ScriptAnalyzer -Settings PSGallery -Recurse). This file documents
    # the local/editor configuration and keeps it consistent with that preset.
    Severity = @('Error', 'Warning')

    IncludeDefaultRules = $true

    # Rules excluded from local runs. The example module intentionally returns
    # plain strings rather than declaring SupportsShouldProcess, so the
    # state-changing-verb rule does not apply to the shipped sample.
    ExcludeRules = @(
        'PSUseShouldProcessForStateChangingFunctions'
    )

    Rules = @{
        PSPlaceOpenBrace = @{
            Enable             = $true
            OnSameLine         = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
        }

        PSPlaceCloseBrace = @{
            Enable             = $true
            NewLineAfter       = $true
            IgnoreOneLineBlock = $true
            NoEmptyLineBefore  = $false
        }

        PSUseConsistentIndentation = @{
            Enable          = $true
            Kind            = 'space'
            IndentationSize = 4
        }

        PSUseConsistentWhitespace = @{
            Enable          = $true
            CheckInnerBrace = $true
            CheckOpenBrace  = $true
            CheckOpenParen  = $true
            CheckOperator   = $true
            CheckSeparator  = $true
        }

        PSAlignAssignmentStatement = @{
            Enable         = $true
            CheckHashtable = $true
        }

        PSUseCorrectCasing = @{
            Enable = $true
        }
    }
}
