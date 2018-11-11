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
  [string]$featureName = Get-VstsInput -Name 'featureName' -Require
  [bool]$debug = Get-VstsInput -Name 'debug' -AsBool -Default $false
  [bool]$verbose = Get-VstsInput -Name 'verbose' -AsBool -Default $false
  [bool]$trace = Get-VstsInput -Name 'trace' -AsBool -Default $false

  $chocolateyVersion = & $chocoExe --version
  Write-Output "Running Chocolatey Version: $chocolateyVersion"

  $chocolateyArguments = @()

  if($debug) {
    Write-Output "Adding --debug version to arguments"
    $chocolateyArguments += @("--debug", "")
  }

  if($verbose) {
    Write-Output "Adding --verbose version to arguments"
    $chocolateyArguments += @("--verbose", "")
  }

  if($trace) {
    Write-Output "Adding --trace version to arguments"
    $chocolateyArguments += @("--trace", "")
  }

  & $chocoExe feature $operation --name=$featureName $($chocolateyArguments)
} catch {
	Write-VstsTaskError $_.Exception.Message
	throw
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
