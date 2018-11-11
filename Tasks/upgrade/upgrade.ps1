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

  [string]$packageId = Get-VstsInput -Name 'packageId' -Require
  [string]$packageVersion = Get-VstsInput -Name 'packageVersion'
  [bool]$pre = Get-VstsInput -Name 'pre' -AsBool -Default $false
  [string]$source = Get-VstsInput -Name 'source'
  [string]$except = Get-VstsInput -Name 'except'
  [bool]$force = Get-VstsInput -Name 'force' -AsBool -Default $false
  [bool]$x86 = Get-VstsInput -Name 'x86' -AsBool -Default $false
  [string]$installArgs = Get-VstsInput -Name 'installargs'
  [bool]$override = Get-VstsInput -Name 'override' -AsBool -Default $false
  [string]$params = Get-VstsInput -Name 'params'
  [string]$extraArguments = Get-VstsInput -Name 'extraArguments'
  [bool]$debug = Get-VstsInput -Name 'debug' -AsBool -Default $false
  [bool]$verbose = Get-VstsInput -Name 'verbose' -AsBool -Default $false
  [bool]$trace = Get-VstsInput -Name 'trace' -AsBool -Default $false

  $chocolateyVersion = & $chocoExe --version
  Write-Output "Running Chocolatey Version: $chocolateyVersion"

  $chocolateyArguments = @()
  if([System.Version]::Parse($chocolateyVersion) -ge [System.Version]::Parse("0.9.8.33")) {
    Write-Output "Adding -y to arguments"
    $chocolateyArguments += @("-y", "")
  }

  if([System.Version]::Parse($chocolateyVersion) -ge [System.Version]::Parse("0.10.4")) {
    Write-Output "Adding --no-progress to arguments"
    $chocolateyArguments += @("--no-progress", "")
  }

  if($packageVersion) {
    Write-Output "Adding --version to arguments"
    $chocolateyArguments += @("--version", $packageVersion)
  }

  if($pre) {
    Write-Output "Adding --pre version to arguments"
    $chocolateyArguments += @("--pre", "")
  }

  if($source) {
    Write-Output "Adding --source to arguments"
    $chocolateyArguments += @("--version", $source)
  }

  if($except) {
    Write-Output "Adding --except to arguments"
    $chocolateyArguments += @("--except", $except)
  }

  if($force) {
    Write-Output "Adding --force version to arguments"
    $chocolateyArguments += @("--force", "")
  }

  if($x86) {
    Write-Output "Adding --x86 version to arguments"
    $chocolateyArguments += @("--x86", "")
  }

  if($installArgs) {
    Write-Output "Adding --install-arguments version to arguments"
    $chocolateyArguments += @("--install-arguments", $installArgs)
  }

  if($override) {
    Write-Output "Adding --override-arguments version to arguments"
    $chocolateyArguments += @("--override-arguments", "")
  }

  if($params) {
    Write-Output "Adding --package-parameters version to arguments"
    $chocolateyArguments += @("--package-parameters", $params)
  }

  if($extraArguments) {
    Write-Output "Adding extra arguments"
    $chocolateyArguments += @($extraArguments, "")
  }

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

  & $chocoExe upgrade $packageId $($chocolateyArguments)
} catch {
	Write-VstsTaskError $_.Exception.Message
	throw
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
