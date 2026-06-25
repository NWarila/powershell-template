#Requires -Version 5.1
# SPDX-FileCopyrightText: 2026 Nicholas Warila
# SPDX-License-Identifier: MIT

Function Invoke-FixturePublic {
  [CmdletBinding()]
  [OutputType([System.String])]
  Param (
    [Parameter(
      Mandatory = $True
    )]
    [ValidateNotNullOrEmpty()]
    [System.String]
    $Name
  )

  Invoke-FixturePrivate -Name $Name
}
