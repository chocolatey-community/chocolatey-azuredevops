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
	[string]$workingDirectory = Get-VstsInput -Name 'workingDirectory' -Require
  [string]$source = Get-VstsInput -Name 'source' -Default 'https://push.chocolatey.org/'
  [string]$apikey = Get-VstsInput -Name 'apikey'
  [bool]$force = Get-VstsInput -Name 'force' -AsBool -Default $false
	[string]$timeout = Get-VstsInput -Name 'timeout'
	[bool]$debug = Get-VstsInput -Name 'debug' -AsBool -Default $false
  [bool]$verbose = Get-VstsInput -Name 'verbose' -AsBool -Default $false
  [bool]$trace = Get-VstsInput -Name 'trace' -AsBool -Default $false
  [string]$extraArguments = Get-VstsInput -Name 'extraArguments'

	$chocolateyVersion = & $chocoExe --version
  Write-Output "Running Chocolatey Version: $chocolateyVersion"

  $chocolateyArguments = @()

  if($source) {
    Write-Output "Adding --source to arguments"
    $chocolateyArguments += @("--source", $source)
  }

  if($apikey) {
    Write-Output "Adding --apikey to arguments"
    $chocolateyArguments += @("--apikey", $apikey)
  }

  if($force) {
    Write-Output "Adding --force to arguments"
    $chocolateyArguments += @("--force", "")
  }

  if($timeout) {
    Write-Output "Adding -t to arguments"
    $chocolateyArguments += @("-t", $timeout)
  }

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

	if($extraArguments) {
    Write-Output "Adding extra arguments"
    $chocolateyArguments += @($extraArguments, "")
	}

	Set-Location $workingDirectory

	if($operation -eq "single") {
		[string]$nupkgFileName = Get-VstsInput -Name 'nupkgFileName' -Require
		& $chocoExe push $nupkgFileName $($chocolateyArguments)
	} else {
		$nupkgFiles = Get-ChildItem "*.nupkg"
		foreach($nupkgFile in $nupkgFiles) {
			& $chocoExe push $nupkgFile $($chocolateyArguments)
		}
	}
} catch {
	Write-VstsTaskError $_.Exception.Message
	throw
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
