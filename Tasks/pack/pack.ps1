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

	Write-Host "Chocolatey Path $chocoExe"
	Write-Host "Would run choco pack here..."
} catch {
	Write-VstsTaskError $_.Exception.Message
	throw
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
