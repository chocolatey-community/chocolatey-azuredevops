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
  [string]$sourceName = Get-VstsInput -Name 'sourceName' -Require
  [string]$priority = Get-VstsInput -Name 'priority'
  [string]$user = Get-VstsInput -Name 'user'
  [string]$password = Get-VstsInput -Name 'password'
  [string]$cert = Get-VstsInput -Name 'cert'
  [string]$certpassword = Get-VstsInput -Name 'certpassword'
  [bool]$debug = Get-VstsInput -Name 'debug' -AsBool -Default $false
  [bool]$verbose = Get-VstsInput -Name 'verbose' -AsBool -Default $false
  [bool]$trace = Get-VstsInput -Name 'trace' -AsBool -Default $false
  [string]$extraArguments = Get-VstsInput -Name 'extraArguments'

  $chocolateyVersion = & $chocoExe --version
  Write-Output "Running Chocolatey Version: $chocolateyVersion"

  $chocolateyArguments = @()

  $chocolateyArguments += @("--name", $sourceName)

  if($priority) {
    Write-Output "Adding --priority version to arguments"
    $chocolateyArguments += @("--priority", $priority)
  }

  if($user) {
    Write-Output "Adding --user version to arguments"
    $chocolateyArguments += @("--user", $user)
  }

  if($password) {
    Write-Output "Adding --password version to arguments"
    $chocolateyArguments += @("--password", $password)
  }

  if($cert) {
    Write-Output "Adding --cert version to arguments"
    $chocolateyArguments += @("--cert", $cert)
  }

  if($certpassword) {
    Write-Output "Adding --certpassword version to arguments"
    $chocolateyArguments += @("--certpassword", $certpassword)
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

  if($extraArguments) {
    Write-Output "Adding extra arguments"
    $chocolateyArguments += @($extraArguments, "")
  }

  switch ( $operation )
    {
        "add"
        {
          [string]$source = Get-VstsInput -Name 'source' -Require
          & $chocoExe source add --source $source $($chocolateyArguments)
        }
        "remove"
        {
            & $chocoExe source remove $($chocolateyArguments)
        }
        "enable"
        {
            & $chocoExe source enable $($chocolateyArguments)
        }
        "disable"
        {
            & $chocoExe source disable $($chocolateyArguments)
        }
    }
} catch {
	Write-VstsTaskError $_.Exception.Message
	throw
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
