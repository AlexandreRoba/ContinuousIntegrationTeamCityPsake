param(
	[Int32]$buildNumber=0,
	[String]$branchName="localbuild",
	[String]$gitCommitHash = "unknownHash",
	[Switch]$isMainBranch=$False
)

cls

# '[p]sake is the same as 'psake' but $Error is not polluted if the module is not loaded
Remove-Module [p]sake

# find psake's path
$psakeModule = (Get-ChildItem ('.\Packages\psake*\tools\psake.psm1')).FullName | Sort-Object $_ | select -Last 1

# Import the module
Import-Module $psakeModule

Invoke-psake -buildFile .\Build\default.ps1 `
	-taskList default `
	-framework 4.6.1 `
	-properties @{ "buildConfiguration" = "Debug"
					"buildPlatform" = "Any CPU"}`
	-parameters @{ "solutionFile" = "..\psake.sln"
					"buildNumber" = $buildNumber
					"branchName" = $branchName
					"gitCommitHash" = $gitCommitHash
					"isMainBranch" = $isMainBranch}

# We need to propagate the exit code of the invoke-psake otherwise the runner of this bootstrap code will not notice something went wrong
Write-Host "Build exit code:" $LastExitCode
exit $LastExitCode
