[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try {
  $chocoInstallLocation = [Environment]::GetEnvironmentVariable("ChocolateyInstall", "Machine")
	if(-not (Test-Path $chocoInstallLocation)) {
		Write-Output "Environment variable 'ChocolateyInstall' was not found in the system variables. Attempting to find it in the user variables..."
		$chocoInstallLocation = [Environment]::GetEnvironmentVariable("ChocolateyInstall", "User")
	}

	$chocoExe = "$chocoInstallLocation\choco.exe"

	if (-not (Test-Path $chocoExe)) {
		throw "Chocolatey was not found."
  }

  $chocolateyVersion = & $chocoExe --version
  Write-Output "Running Chocolatey Version: $chocolateyVersion"

  $chocolateyArguments = New-Object System.Collections.ArrayList

  [bool]$debug = Get-VstsInput -Name 'debug' -AsBool -Default $false
  [bool]$verbose = Get-VstsInput -Name 'verbose' -AsBool -Default $false
  [bool]$trace = Get-VstsInput -Name 'trace' -AsBool -Default $false
  [string]$extraArguments = Get-VstsInput -Name 'extraArguments'
  [string]$commandName = ""

  if($debug) {
    Write-Output "Adding --debug to arguments"
    $chocolateyArguments.Add("--debug") > $null
  }

  if($verbose) {
    Write-Output "Adding --verbose to arguments"
    $chocolateyArguments.Add("--verbose") > $null
  }

  if($trace) {
    Write-Output "Adding --trace to arguments"
    $chocolateyArguments.Add("--trace") > $null
  }

  [string]$command = Get-VstsInput -Name 'command' -Require

  switch ( $command )
  {
    "apikey"
    {
      [string]$apiKeysource = Get-VstsInput -Name 'apikeySource' -Require
      [string]$apikeyApikey = Get-VstsInput -Name 'apikeyApikey' -Require
      $commandName = "apikey"

      $chocolateyArguments.Add("--source") > $null
      $chocolateyArguments.Add($apikeySource) > $null
      $chocolateyArguments.Add("--api-key") > $null
      $chocolateyArguments.Add($apikeyApikey) > $null
    }
    "config"
    {
      [string]$configOperation = Get-VstsInput -Name 'configOperation' -Require
      [string]$configName = Get-VstsInput -Name 'configName' -Require

      $chocolateyArguments.Add("--name") > $null
      $chocolateyArguments.Add($configName) > $null

      $commandName = "config"

      if($configOperation -eq "set") {
        [string]$configValue = Get-VstsInput -Name 'configValue' -Require

        $chocolateyArguments.Add("--value") > $null
        $chocolateyArguments.Add($configValue) > $null
        $chocolateyArguments.Insert(0, "set") > $null
      } else {
        $chocolateyArguments.Insert(0, "unset") > $null
      }
    }
    "custom"
    {
      [string]$customCommand = Get-VstsInput -Name 'customCommand' -Require
      [string]$customArguments = Get-VstsInput -Name 'customArguments'

      if($customArguments) {
        Write-Output "Adding custom arguments"
        $chocolateyArguments.Add($customArguments) > $null
      }

      $commandName = $customCommand
    }
    "feature"
    {
      [string]$featureOperation = Get-VstsInput -Name 'featureOperation' -Require
      [string]$featureName = Get-VstsInput -Name 'featureName' -Require

      $commandName = "feature"
      $chocolateyArguments.Add("--name") > $null
      $chocolateyArguments.Add($featureName) > $null
      $chocolateyArguments.Insert(0, $featureOperation) > $null

    }
    "install"
    {
      [string]$installPackageId = Get-VstsInput -Name 'installPackageId' -Require
      [string]$installPackageVersion = Get-VstsInput -Name 'installPackageVersion'
      [bool]$installPre = Get-VstsInput -Name 'installPre' -AsBool -Default $false
      [string]$installSource = Get-VstsInput -Name 'installSource'
      [bool]$installForce = Get-VstsInput -Name 'installForce' -AsBool -Default $false
      [bool]$installX86 = Get-VstsInput -Name 'installX86' -AsBool -Default $false
      [string]$installInstallArgs = Get-VstsInput -Name 'installInstallargs'
      [bool]$installOverride = Get-VstsInput -Name 'installOverride' -AsBool -Default $false
      [string]$installParams = Get-VstsInput -Name 'installParams'

      if([System.Version]::Parse($chocolateyVersion) -ge [System.Version]::Parse("0.9.8.33")) {
        Write-Output "Adding -y to arguments"
        $chocolateyArguments.Add("-y") > $null
      }

      if([System.Version]::Parse($chocolateyVersion) -ge [System.Version]::Parse("0.10.4")) {
        Write-Output "Adding --no-progress to arguments"
        $chocolateyArguments.Add("--no-progress") > $null
      }

      if($installPackageVersion) {
        Write-Output "Adding --version to arguments"
        $chocolateyArguments.Add("--version") > $null
        $chocolateyArguments.Add($installPackageVersion) > $null
      }

      if($installPre) {
        Write-Output "Adding --pre to arguments"
        $chocolateyArguments.Add("--pre") > $null
      }

      if($installSource) {
        Write-Output "Adding --source to arguments"
        $chocolateyArguments.Add("--version") > $null
        $chocolateyArguments.Add($installSource) > $null
      }

      if($installForce) {
        Write-Output "Adding --force to arguments"
        $chocolateyArguments.Add("--force") > $null
      }

      if($installX86) {
        Write-Output "Adding --x86 to arguments"
        $chocolateyArguments.Add("--x86") > $null
      }

      if($installInstallArgs) {
        Write-Output "Adding --install-arguments to arguments"
        $chocolateyArguments.Add("--install-arguments") > $null
        $chocolateyArguments.Add($installInstallArgs) > $null
      }

      if($installOverride) {
        Write-Output "Adding --override-arguments to arguments"
        $chocolateyArguments.Add("--override-arguments") > $null
      }

      if($installParams) {
        Write-Output "Adding --package-parameters to arguments"
        $chocolateyArguments.Add("--package-parameters") > $null
        $chocolateyArguments.Add($installParams) > $null
      }

      $chocolateyArguments.Insert(0, $installPackageId) > $null
      $commandName = "install"
    }
    "pack"
    {
      [string]$packOperation = Get-VstsInput -Name 'packOperation' -Require
      [string]$packWorkingDirectory = Get-VstsInput -Name 'packWorkingDirectory' -Require
      [string]$packVersion = Get-VstsInput -Name 'packVersion'
      [string]$packOutputDirectory = Get-VstsInput -Name 'packOutputDirectory'

      if($packVersion) {
        Write-Output "Adding --version to arguments"
        $chocolateyArguments.Add("--version") > $null
        $chocolateyArguments.Add($packVersion) > $null
      }

      if($packOutputDirectory) {
        Write-Output "Adding --output-directory to arguments"
        $chocolateyArguments.Add("--output-directory") > $null
        $chocolateyArguments.Add($packOutputDirectory) > $null
      }

      $commandName = "pack"
    }
    "push"
    {
      [string]$pushOperation = Get-VstsInput -Name 'pushOperation' -Require
      [string]$pushWorkingDirectory = Get-VstsInput -Name 'pushWorkingDirectory' -Require
      [string]$pushSource = Get-VstsInput -Name 'pushSource' -Default 'https://push.chocolatey.org/'
      [string]$pushApikey = Get-VstsInput -Name 'pushApikey'
      [bool]$pushForce = Get-VstsInput -Name 'pushForce' -AsBool -Default $false
      [string]$pushTimeout = Get-VstsInput -Name 'pushTimeout'

      if($pushSource) {
        Write-Output "Adding --source to arguments"
        $chocolateyArguments.Add("--source") > $null
        $chocolateyArguments.Add($pushSource) > $null
      }

      if($pushApikey) {
        Write-Output "Adding --apikey to arguments"
        $chocolateyArguments.Add("--apikey") > $null
        $chocolateyArguments.Add($pushApikey) > $null
      }

      if($pushForce) {
        Write-Output "Adding --force to arguments"
        $chocolateyArguments.Add("--force") > $null
      }

      if($pushTimeout) {
        Write-Output "Adding -t to arguments"
        $chocolateyArguments.Add("-t") > $null
        $chocolateyArguments.Add($pushTimeout) > $null
      }

      $commandName = "push"
    }
    "source"
    {
      [string]$sourceOperation = Get-VstsInput -Name 'sourceOperation' -Require
      [string]$sourceSourceName = Get-VstsInput -Name 'sourceSourceName' -Require
      [string]$sourcePriority = Get-VstsInput -Name 'sourcePriority'
      [string]$user = Get-VstsInput -Name 'user'
      [string]$password = Get-VstsInput -Name 'password'
      [string]$cert = Get-VstsInput -Name 'cert'
      [string]$certPassword = Get-VstsInput -Name 'certPassword'
      [bool]$byPassProxy = Get-VstsInput -Name 'byPassProxy' -AsBool -Default $false

      $chocolateyArguments.Add("--name") > $null
      $chocolateyArguments.Add($sourceSourceName) > $null

      if($sourcePriority) {
        Write-Output "Adding --priority to arguments"
        $chocolateyArguments.Add("--priority") > $null
        $chocolateyArguments.Add($sourcePriority) > $null
      }

      if($user) {
        Write-Output "Adding --user to arguments"
        $chocolateyArguments.Add("--user") > $null
        $chocolateyArguments.Add($user) > $null
      }

      if($password) {
        Write-Output "Adding --password to arguments"
        $chocolateyArguments.Add("--password") > $null
        $chocolateyArguments.Add($password) > $null
      }

      if($cert) {
        Write-Output "Adding --cert to arguments"
        $chocolateyArguments.Add("--cert") > $null
        $chocolateyArguments.Add($cert) > $null
      }

      if($certPassword) {
        Write-Output "Adding --certpassword to arguments"
        $chocolateyArguments.Add("--certpassword") > $null
        $chocolateyArguments.Add($certPassword) > $null
      }

      if($byPassProxy) {
        Write-Output "Adding --bypass-proxy to arguments"
        $chocolateyArguments.Add("--bypass-proxy") > $null
      }

      $commandName = "source"

      switch ( $sourceOperation )
      {
        "add"
        {
          [string]$sourceSource = Get-VstsInput -Name 'sourceSource' -Require
          $chocolateyArguments.Add("--source") > $null
          $chocolateyArguments.Add($sourceSource) > $null

          $chocolateyArguments.Insert(0, "add") > $null
        }
        "remove"
        {
          $chocolateyArguments.Insert(0, "remove") > $null
        }
        "enable"
        {
          $chocolateyArguments.Insert(0, "enable") > $null
        }
        "disable"
        {
          $chocolateyArguments.Insert(0, "disable") > $null
        }
      }
    }
    "upgrade"
    {
      [string]$upgradePackageId = Get-VstsInput -Name 'upgradePackageId' -Require
      [string]$upgradePackageVersion = Get-VstsInput -Name 'upgradePackageVersion'
      [bool]$upgradePre = Get-VstsInput -Name 'upgradePre' -AsBool -Default $false
      [string]$upgradeSource = Get-VstsInput -Name 'upgradeSource'
      [string]$except = Get-VstsInput -Name 'except'
      [bool]$upgradeForce = Get-VstsInput -Name 'upgradeForce' -AsBool -Default $false
      [bool]$upgradeX86 = Get-VstsInput -Name 'upgradeX86' -AsBool -Default $false
      [string]$upgradeInstallArgs = Get-VstsInput -Name 'upgradeInstallArgs'
      [bool]$upgradeOverride = Get-VstsInput -Name 'upgradeOverride' -AsBool -Default $false
      [string]$upgradeParams = Get-VstsInput -Name 'upgradeParams'

      if([System.Version]::Parse($chocolateyVersion) -ge [System.Version]::Parse("0.9.8.33")) {
        Write-Output "Adding -y to arguments"
        $chocolateyArguments.Add("-y") > $null
      }

      if([System.Version]::Parse($chocolateyVersion) -ge [System.Version]::Parse("0.10.4")) {
        Write-Output "Adding --no-progress to arguments"
        $chocolateyArguments.Add("--no-progress") > $null
      }

      if($upgradePackageVersion) {
        Write-Output "Adding --version to arguments"
        $chocolateyArguments.Add("--version") > $null
        $chocolateyArguments.Add($upgradePackageVersion) > $null
      }

      if($upgradePre) {
        Write-Output "Adding --pre to arguments"
        $chocolateyArguments.Add("--pre") > $null
      }

      if($upgradeSource) {
        Write-Output "Adding --source to arguments"
        $chocolateyArguments.Add("--version") > $null
        $chocolateyArguments.Add($upgradeSource) > $null
      }

      if($except) {
        Write-Output "Adding --except to arguments"
        $chocolateyArguments.Add("--except") > $null
        $chocolateyArguments.Add($except) > $null
      }

      if($upgradeForce) {
        Write-Output "Adding --force to arguments"
        $chocolateyArguments.Add("--force") > $null
      }

      if($upgradeX86) {
        Write-Output "Adding --x86 to arguments"
        $chocolateyArguments.Add("--x86") > $null
      }

      if($upgradeInstallArgs) {
        Write-Output "Adding --install-arguments to arguments"
        $chocolateyArguments.Add("--install-arguments") > $null
        $chocolateyArguments.Add($upgradeInstallArgs) > $null
      }

      if($upgradeOverride) {
        Write-Output "Adding --override-arguments to arguments"
        $chocolateyArguments.Add("--override-arguments") > $null
      }

      if($upgradeParams) {
        Write-Output "Adding --package-parameters to arguments"
        $chocolateyArguments.Add("--package-parameters") > $null
        $chocolateyArguments.Add($upgradeParams) > $null
      }

      $chocolateyArguments.Insert(0, $upgradePackageId) > $null
      $commandName = "upgrade"
    }
  }

  if($extraArguments) {
    Write-Output "Adding extra arguments"
    $chocolateyArguments.Add($extraArguments)
  }

  # Execute Chocolatey
  if($commandName -eq 'pack') {
    Set-Location $packWorkingDirectory

    Remove-Item "\*.nupkg"

    # TODO: Need to add a globber pattern here for finding all nuspec's
    if($packOperation -eq "single") {
      [string]$packNuspecFileName = Get-VstsInput -Name 'packNuspecFileName' -Require
      & $chocoExe $commandName $packNuspecFileName $($chocolateyArguments)

      if($LASTEXITCODE -ne 0) {
        throw "Something went wrong with Chocolatey execution.  Check log for additional information."
      }
    } else {
      $nuspecFiles = Get-ChildItem "*.nuspec"
      foreach($nuspecFile in $nuspecFiles) {
        & $chocoExe $commandName $nuspecFile $($chocolateyArguments)

        if($LASTEXITCODE -ne 0) {
          throw "Something went wrong with Chocolatey execution.  Check log for additional information."
        }
      }
    }
  } elseif($commandName -eq 'push') {
    Set-Location $pushWorkingDirectory

    # TODO: Need to add a globber patter here for finding all nupkg's
    if($pushOperation -eq "single") {
      [string]$pushNupkgFileName = Get-VstsInput -Name 'pushNupkgFileName' -Require
      & $chocoExe $commandName $pushNupkgFileName $($chocolateyArguments)

      if($LASTEXITCODE -ne 0) {
        throw "Something went wrong with Chocolatey execution.  Check log for additional information."
      }
    } else {
      $nupkgFiles = Get-ChildItem "*.nupkg"
      foreach($nupkgFile in $nupkgFiles) {
        & $chocoExe $commandName $nupkgFile $($chocolateyArguments)

        if($LASTEXITCODE -ne 0) {
          throw "Something went wrong with Chocolatey execution.  Check log for additional information."
        }
      }
    }
  } else {
    & $chocoExe $commandName $($chocolateyArguments)

    if($LASTEXITCODE -ne 0) {
      throw "Something went wrong with Chocolatey execution.  Check log for additional information."
    }
  }
} catch {
	Write-VstsTaskError $_.Exception.Message
	throw
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
