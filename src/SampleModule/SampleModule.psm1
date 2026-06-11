#Requires -Version 5.1

Set-StrictMode -Version Latest

<#
    Root module for SampleModule.

    This template dot-sources every function file under Private/ and Public/
    and exports only the public functions. Replace SampleModule with your
    module name and add your own functions under the Public/ and Private/
    directories. See docs/decision-records/template/0001-module-layout.md for the
    rationale behind this layout.
#>

$ErrorActionPreference = 'Stop'

# Resolve the function source folders relative to this module file.
$publicRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Public'
$privateRoot = Join-Path -Path $PSScriptRoot -ChildPath 'Private'

$publicFunctions = @()
if (Test-Path -LiteralPath $publicRoot) {
    $publicFunctions = @(Get-ChildItem -LiteralPath $publicRoot -Filter '*.ps1' -File -ErrorAction SilentlyContinue)
}

$privateFunctions = @()
if (Test-Path -LiteralPath $privateRoot) {
    $privateFunctions = @(Get-ChildItem -LiteralPath $privateRoot -Filter '*.ps1' -File -ErrorAction SilentlyContinue)
}

foreach ($file in @($privateFunctions) + @($publicFunctions)) {
    try {
        . $file.FullName
    }
    catch {
        throw "Failed to import function file '$($file.FullName)': $($_.Exception.Message)"
    }
}

# Export only the public functions by base name. The manifest's
# FunctionsToExport remains the authoritative export contract; this keeps the
# in-memory module surface aligned with the files on disk.
Export-ModuleMember -Function $publicFunctions.BaseName
