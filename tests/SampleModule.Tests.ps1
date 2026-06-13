#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
  # Resolve and import the module under test from source. $PSScriptRoot points
  # at tests/; the module manifest lives under ../src/SampleModule.
  $script:ModuleName = 'SampleModule'
  $script:ManifestPath = Join-Path -Path $PSScriptRoot -ChildPath "../src/$script:ModuleName/$script:ModuleName.psd1"
  $script:ManifestPath = (Resolve-Path -LiteralPath $script:ManifestPath).Path

  Get-Module -Name $script:ModuleName -All | Remove-Module -Force -ErrorAction SilentlyContinue
  Import-Module -Name $script:ManifestPath -Force -ErrorAction Stop
}

AfterAll {
  Get-Module -Name $script:ModuleName -All | Remove-Module -Force -ErrorAction SilentlyContinue
}

Describe 'SampleModule manifest' {
  BeforeAll {
    $script:Manifest = Test-ModuleManifest -Path $script:ManifestPath -ErrorAction Stop
  }

  It 'is a valid module manifest' {
    $script:Manifest | Should -Not -BeNullOrEmpty
  }

  It 'declares an explicit (non-wildcard) FunctionsToExport list' {
    $script:Manifest.ExportedFunctions.Keys | Should -Contain 'Get-Greeting'
    $script:Manifest.ExportedFunctions.Keys | Should -Not -Contain '*'
  }

  It 'targets both Core and Desktop editions' {
    $script:Manifest.CompatiblePSEditions | Should -Contain 'Core'
    $script:Manifest.CompatiblePSEditions | Should -Contain 'Desktop'
  }

  It 'exports no cmdlets or aliases' {
    $script:Manifest.ExportedCmdlets.Count | Should -Be 0
    $script:Manifest.ExportedAliases.Count | Should -Be 0
  }
}

Describe 'Get-Greeting' {
  Context 'default behavior' {
    It 'greets the supplied name with the default salutation' {
      Get-Greeting -Name 'World' | Should -BeExactly 'Hello, World!'
    }

    It 'returns a single string' {
      $result = Get-Greeting -Name 'Ada'
      $result | Should -BeOfType [string]
      @($result).Count | Should -Be 1
    }
  }

  Context 'custom salutation' {
    It 'uses the supplied greeting' {
      Get-Greeting -Name 'Grace' -Greeting 'Welcome' | Should -BeExactly 'Welcome, Grace!'
    }
  }

  Context 'input normalization' {
    It 'collapses internal whitespace and trims edges' {
      Get-Greeting -Name '  Ada   Lovelace  ' | Should -BeExactly 'Hello, Ada Lovelace!'
    }
  }

  Context 'pipeline input' {
    It 'processes multiple names from the pipeline' {
      $results = 'Ada', 'Grace' | Get-Greeting -Greeting 'Hi'
      $results | Should -HaveCount 2
      $results[0] | Should -BeExactly 'Hi, Ada!'
      $results[1] | Should -BeExactly 'Hi, Grace!'
    }
  }

  Context 'parameter validation' {
    It 'rejects an empty name' {
      { Get-Greeting -Name '' } | Should -Throw
    }
  }
}
