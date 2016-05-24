Include ".\helpers.ps1"

properties{
	$cleanMessage = "Executed Clean!"
	$testMessage = "Executed unit tests!"

	$solutionDirectory = (Get-Item $solutionFile).DirectoryName
	$outputDirectory = "$solutionDirectory\.build"
	$temporaryOutputDirectory = "$outputDirectory\temp"

	$publishedNUnitTestsDirectory = "$temporaryOutputDirectory\_PublishedNUnitTests"
	$publishedXUnitTestsDirectory = "$temporaryOutputDirectory\_PublishedXUnitTests"

	$testResultsDirectory = "$outputDirectory\TestResults"
	$NUnitTestResultsDirectory = "$testResultsdirectory\NUnit"
	$XUnitTestResultsDirectory = "$testResultsdirectory\XUnit"


	$buildConfiguration = "Release"
	$buildPlatform = "Any CPU"

	$packagesPath = "$solutionDirectory\packages"
	$NUnitExe = (Find-PackagePath $packagesPath "NUnit.ConsoleRunner") + "\Tools\nunit3-console.exe"
	$XUnitExe = (Find-PackagePath $packagesPath "xunit.runner.console") + "\Tools\xunit.console.exe"
}

FormatTaskName "`r`n`r`n----------------- Executing {0} Task ---------------"

task default -depends Test

task Init -description "Initialises the build by removing previous artifacts and creating output directories" `
			-depends Clean `
			-requiredVariables outputDirectory, temporaryOutputDirectory {
	
	Assert -conditionToCheck ("Debug", "Release" -contains $buildConfiguration) `
			-failureMessage "Invalid build configuration '$buildConfiguration'. Values must be 'Debug' or 'Release'."

	Assert -conditionToCheck ("x86", "x64", "Any CPU" -contains $buildPlatform) `
			-failureMessage "Invalid build platform '$buildPlatform'. Values must be 'x86', 'x64' or 'Any CPU'."
	# Check that all tools are available
	Write-Host "Checking that all required tools are available"

	Assert (Test-Path $NUnitExe) "NUnit Console could not be found"
	Assert (Test-Path $xUnitExe) "XUnit Console could not be found"

	# Remove previous build results
	if(Test-Path $outputDirectory){
		Write-Host "Removing output Directory located at $outputDirectory"
		Remove-Item $outputDirectory -Force -Recurse
	}

	Write-Host "Creating output directory located at $outputDirectory"
	New-Item $outputDirectory -ItemType Directory | Out-Null

	Write-Host "Creating temporary directory located at $temporaryOutputDirectory"
	New-Item $temporaryOutputDirectory -ItemType Directory | Out-Null
}

task Clean -description "Clean the build output"{
	Write-Host $cleanMessage
}

task Compile -depends Init `
	-description "Compile the solution"`
	-requiredVariables solutionFile,buildConfiguration,buildPlatform,temporaryOutputDirectory {
	Write-Host "Building Solution $solutionFile"
	# We use Exec to capture the exit code of MSBuild. This will make the task fails if the exit code is not 0 and will make the build fail
	exec {
		msbuild $solutionFile "/p:Configuration=$buildConfiguration;Platform=$buildPlatform;OutDir=$temporaryOutputDirectory"
	}
}

task Test -depends Compile, TestNUnit, TestXUnit, TestMSTest -description "Runs the unit test"{
	Write-Host $testMessage
}

task TestNUnit `
	-depends Compile `
	-description "Run Nunit tests" `
	-precondition {return Test-Path $publishedNUnitTestsDirectory} `
{
	$testAssemblies = Prepare-Tests -testRunnerName "NUnit" `
									-publishedTestsDirectory $publishedNUnitTestsDirectory `
									-testResultsDirectory $NUnitTestResultsDirectory

	Exec {
		&$NUnitExe $testAssemblies --result $NUnitTestResultsDirectory\NUnit.xml --noheader
	}
	
}

task TestXUnit `
	-depends Compile `
	-description "Run XUnit tests" `
	-precondition {return Test-Path $publishedxUnitTestsDirectory} ` {
	$testAssemblies = Prepare-Tests -testRunnerName "XUnit" `
									-publishedTestsDirectory $publishedXUnitTestsDirectory `
									-testResultsDirectory $XUnitTestResultsDirectory
	Exec{
		&$XUnitExe $testAssemblies -xml $XunitTestResultsDirectory\xUnit.xml -nologo -noshadow
	}
}

task TestMSTest `
	-depends Compile `
	-description "Run MSTest tests" {


}