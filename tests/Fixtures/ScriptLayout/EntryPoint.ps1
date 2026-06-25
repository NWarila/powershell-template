#Requires -Version 5.1
# SPDX-FileCopyrightText: 2026 Nicholas Warila
# SPDX-License-Identifier: MIT

[CmdletBinding()]
Param (
  [Parameter(
    Mandatory = $False
  )]
  [ValidateNotNullOrEmpty()]
  [System.String]
  $Name = 'World'
)

Invoke-FixturePublic -Name $Name
