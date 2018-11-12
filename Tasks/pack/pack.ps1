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
	[string]$version = Get-VstsInput -Name 'version'
	[string]$outputDirectory = Get-VstsInput -Name 'outputDirectory'
	[string]$timeout = Get-VstsInput -Name 'timeout'
	[bool]$pushPackages = Get-VstsInput -Name 'pushPackages' -AsBool
	[bool]$debug = Get-VstsInput -Name 'debug' -AsBool -Default $false
  [bool]$verbose = Get-VstsInput -Name 'verbose' -AsBool -Default $false
  [bool]$trace = Get-VstsInput -Name 'trace' -AsBool -Default $false
  [string]$extraArguments = Get-VstsInput -Name 'extraArguments'

	$chocolateyVersion = & $chocoExe --version
  Write-Output "Running Chocolatey Version: $chocolateyVersion"

	$chocolateyArguments = @()
	$chocolateyPushArguments = @()

	if($version) {
    Write-Output "Adding --version to arguments"
    $chocolateyArguments += @("--version", $version)
	}

	if($outputDirectory) {
    Write-Output "Adding --output-directory to arguments"
    $chocolateyArguments += @("--output-directory", $outputDirectory)
	}

	if($pushPackages) {
		[string]$source = Get-VstsInput -Name 'source' -Default 'https://push.chocolatey.org/'
		[string]$apikey = Get-VstsInput -Name 'apikey'
		[bool]$force = Get-VstsInput -Name 'force' -AsBool -Default $false

		if($source) {
			Write-Output "Adding --source to arguments"
			$chocolateyPushArguments += @("--source", $source)
		}

		if($apikey) {
			Write-Output "Adding --apikey to arguments"
			$chocolateyPushArguments += @("--apikey", $apikey)
		}

		if($force) {
			Write-Output "Adding --force to arguments"
			$chocolateyPushArguments += @("--force", "")
		}

		if($timeout) {
			Write-Output "Adding -t to arguments"
			$chocolateyPushArguments += @("-t", $timeout)
		}
	}

	if($debug) {
    Write-Output "Adding --debug to arguments"
		$chocolateyArguments += @("--debug", "")
		$chocolateyPushArguments += @("--debug", "")
  }

  if($verbose) {
    Write-Output "Adding --verbose to arguments"
    $chocolateyArguments += @("--verbose", "")
    $chocolateyPushArguments += @("--verbose", "")
  }

  if($trace) {
    Write-Output "Adding --trace to arguments"
    $chocolateyArguments += @("--trace", "")
    $chocolateyPushArguments += @("--trace", "")
	}

	if($extraArguments) {
    Write-Output "Adding extra arguments"
    $chocolateyArguments += @($extraArguments, "")
	}

	Set-Location $workingDirectory

	Remove-Item "\*.nupkg"

	if($operation -eq "single") {
		[string]$nuspecFileName = Get-VstsInput -Name 'nuspecFileName' -Require
		& $chocoExe pack $nuspecFileName $($chocolateyArguments)
	} else {
		$nuspecFiles = Get-ChildItem "*.nuspec"
		foreach($nuspecFile in $nuspecFiles) {
			& $chocoExe pack $nuspecFile $($chocolateyArguments)
		}
	}

	if($pushPackages) {
		if($outputDirectory){
			Set-Location $outputDirectory
		}

		$nupkgFiles = Get-ChildItem "*.nupkg"
		foreach($nupkgFile in $nupkgFiles) {
			& $chocoExe push $nupkgFile $($chocolateyPushArguments)
		}
	}
} catch {
	Write-VstsTaskError $_.Exception.Message
	throw
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
