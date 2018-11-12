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

  [string]$operation = Get-VstsInput -Name 'operation' -Require
  [string]$configName = Get-VstsInput -Name 'configName' -Require
  [bool]$debug = Get-VstsInput -Name 'debug' -AsBool -Default $false
  [bool]$verbose = Get-VstsInput -Name 'verbose' -AsBool -Default $false
  [bool]$trace = Get-VstsInput -Name 'trace' -AsBool -Default $false

  $chocolateyVersion = & $chocoExe --version
  Write-Output "Running Chocolatey Version: $chocolateyVersion"

  $chocolateyArguments = @()

  if($debug) {
    Write-Output "Adding --debug to arguments"
    $chocolateyArguments += @("--debug", "")
  }

  if($verbose) {
    Write-Output "Adding --verbose to arguments"
    $chocolateyArguments += @("--verbose", "")
  }

  if($trace) {
    Write-Output "Adding --trace to arguments"
    $chocolateyArguments += @("--trace", "")
  }

  if($operation -eq "set") {
    [string]$configValue = Get-VstsInput -Name 'configValue' -Require
    & $chocoExe config set --name $configName --value $configValue $($chocolateyArguments)
  } else {
    & $chocoExe config unset --name $configName $($chocolateyArguments)
  }
} catch {
	Write-VstsTaskError $_.Exception.Message
	throw
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
