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
    $chocolateyArguments.Add("--debug") > $null
  }

  if($verbose) {
    $chocolateyArguments.Add("--verbose") > $null
  }

  if($trace) {
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

      $chocolateyArguments.Add("--source=`"'$apikeySource'`"") > $null
      $chocolateyArguments.Add("--api-key=`"'$apikeyApikey'`"") > $null
    }
    "config"
    {
      [string]$configOperation = Get-VstsInput -Name 'configOperation' -Require
      [string]$configName = Get-VstsInput -Name 'configName' -Require

      $chocolateyArguments.Add("--name=`"'$configName'`"") > $null

      $commandName = "config"

      if($configOperation -eq "set") {
        [string]$configValue = Get-VstsInput -Name 'configValue' -Require

        $chocolateyArguments.Add("--value=`"'$configValue'`"") > $null
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
        $chocolateyArguments.Add($customArguments) > $null
      }

      $commandName = $customCommand
    }
    "feature"
    {
      [string]$featureOperation = Get-VstsInput -Name 'featureOperation' -Require
      [string]$featureName = Get-VstsInput -Name 'featureName' -Require

      $commandName = "feature"
      $chocolateyArguments.Add("--name=`"'$featureName'`"") > $null
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
        $chocolateyArguments.Add("-y") > $null
      }

      if([System.Version]::Parse($chocolateyVersion) -ge [System.Version]::Parse("0.10.4")) {
        $chocolateyArguments.Add("--no-progress") > $null
      }

      if($installPackageVersion) {
        $chocolateyArguments.Add("--version=`"'$installPackageVersion'`"") > $null
      }

      if($installPre) {
        $chocolateyArguments.Add("--pre") > $null
      }

      if($installSource) {
        $chocolateyArguments.Add("--source=`"'$installSource'`"") > $null
      }

      if($installForce) {
        $chocolateyArguments.Add("--force") > $null
      }

      if($installX86) {
        $chocolateyArguments.Add("--x86") > $null
      }

      if($installInstallArgs) {
        $chocolateyArguments.Add("--install-arguments=`"'$installInstallArgs'`"") > $null
      }

      if($installOverride) {
        $chocolateyArguments.Add("--override-arguments") > $null
      }

      if($installParams) {
        $chocolateyArguments.Add("--package-parameters=`"'$installParams'`"") > $null
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
        $chocolateyArguments.Add("--version=`"'$packVersion'`"") > $null
      }

      if($packOutputDirectory) {
        $chocolateyArguments.Add("--output-directory=`"'$packOutputDirectory'`"") > $null
      }

      $commandName = "pack"
    }
    "push"
    {
      [string]$pushOperation = Get-VstsInput -Name 'pushOperation' -Require
      [string]$pushWorkingDirectory = Get-VstsInput -Name 'pushWorkingDirectory' -Require
      [bool]$pushForce = Get-VstsInput -Name 'pushForce' -AsBool -Default $false
      [string]$pushTimeout = Get-VstsInput -Name 'pushTimeout'
      [string]$chocolateySourceType = Get-VstsInput -Name 'chocolateySourceType' -Require

      switch ( $chocolateySourceType )
      {
        "manual"
        {
          [string]$pushSource = Get-VstsInput -Name 'pushSource' -Default 'https://push.chocolatey.org/'
          [string]$pushApikey = Get-VstsInput -Name 'pushApikey'

          if($pushSource) {
            $chocolateyArguments.Add("--source=`"'$pushSource'`"") > $null
          }

          if($pushApikey) {
            $chocolateyArguments.Add("--apikey=`"'$pushApikey'`"") > $null
          }
        }
        "stored"
        {
          [string]$endPointGuid = Get-VstsInput -Name 'externalEndpoint' -Require
          $endPoint = Get-VstsEndpoint $endPointGuid

          if($endPoint.Auth.scheme -eq "None") {
            $chocolateyArguments.Add("--source=`"'$($endPoint.Url)'`"") > $null
            $chocolateyArguments.Add("--apikey=`"'$($endPoint.Auth.parameters.nugetkey)'`"") > $null
          } else {
            throw "This task does not support any schemes for External NuGet Feeds other than 'None'."
          }
        }
      }

      if($pushForce) {
        $chocolateyArguments.Add("--force") > $null
      }

      if($pushTimeout) {
        $chocolateyArguments.Add("-t=`"'$pushTimeout'`"") > $null
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

      $chocolateyArguments.Add("--name=`"'$sourceSourceName'`"") > $null

      if($sourcePriority) {
        $chocolateyArguments.Add("--priority=`"'$sourcePriority'`"") > $null
      }

      if($user) {
        $chocolateyArguments.Add("--user=`"'$user'`"") > $null
      }

      if($password) {
        $chocolateyArguments.Add("--password=`"'$password'`"") > $null
      }

      if($cert) {
        $chocolateyArguments.Add("--cert=`"'$cert'`"") > $null
      }

      if($certPassword) {
        $chocolateyArguments.Add("--certpassword=`"'$certPassword'`"") > $null
      }

      if($byPassProxy) {
        $chocolateyArguments.Add("--bypass-proxy") > $null
      }

      $commandName = "source"

      switch ( $sourceOperation )
      {
        "add"
        {
          [string]$sourceSource = Get-VstsInput -Name 'sourceSource' -Require
          $chocolateyArguments.Add("--source=`"'$sourceSource'`"") > $null

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
        $chocolateyArguments.Add("-y") > $null
      }

      if([System.Version]::Parse($chocolateyVersion) -ge [System.Version]::Parse("0.10.4")) {
        $chocolateyArguments.Add("--no-progress") > $null
      }

      if($upgradePackageVersion) {
        $chocolateyArguments.Add("--version=`"'$upgradePackageVersion'`"") > $null
      }

      if($upgradePre) {
        $chocolateyArguments.Add("--pre") > $null
      }

      if($upgradeSource) {
        $chocolateyArguments.Add("--source=`"'$upgradeSource'`"") > $null
      }

      if($except) {
        $chocolateyArguments.Add("--except=`"'$except'`"") > $null
      }

      if($upgradeForce) {
        $chocolateyArguments.Add("--force") > $null
      }

      if($upgradeX86) {
        $chocolateyArguments.Add("--x86") > $null
      }

      if($upgradeInstallArgs) {
        $chocolateyArguments.Add("--install-arguments=`"'$upgradeInstallArgs'`"") > $null
      }

      if($upgradeOverride) {
        $chocolateyArguments.Add("--override-arguments") > $null
      }

      if($upgradeParams) {
        $chocolateyArguments.Add("--package-parameters=`"'$upgradeParams'`"") > $null
      }

      $chocolateyArguments.Insert(0, $upgradePackageId) > $null
      $commandName = "upgrade"
    }
  }

  if($extraArguments) {
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
