[CmdletBinding()]
param()

Trace-VstsEnteringInvocation $MyInvocation

try {
  Write-Host "Would run choco push here..."
} catch {
	Write-VstsTaskError $_.Exception.Message
	throw
} finally {
  Trace-VstsLeavingInvocation $MyInvocation
}
