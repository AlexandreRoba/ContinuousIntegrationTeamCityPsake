Include ".\helpers.ps1"

properties{
	$cleanMessage = "Executed Clean!"
	$testMessage = "Executed unit tests!"

	$solutionDirectory = (Get-Item $solutionFile).DirectoryName 
	$outputDirectory = "$solutionDirectory\.build"
	$temporaryOutputDirectory = "$outputDirectory\temp"

	$publishedNUnitTestsDirectory = "$temporaryOutputDirectory\_PublishedNUnitTests"
	$publishedXUnitTestsDirectory = "$temporaryOutputDirectory\_PublishedXUnitTests"
	$publishedMSTestTestsDirectory = "$temporaryOutputDirectory\_PublishedMSTestTests"

	$testResultsDirectory = "$outputDirectory\TestResults"
	$NUnitTestResultsDirectory = "$testResultsdirectory\NUnit"
	$XUnitTestResultsDirectory = "$testResultsdirectory\XUnit"
	$MSTestTestResultsDirectory = "$testResultsdirectory\MSTest"

	$testCoverageDirectory = "$outputDirectory\TestCoverage"
	$testCoverageReportPath = "$testCoverageDirectory\OpenCover.xml"
	$testCoverageFilter = "+[*]* -[xunit.*]* -[*.NUnitTests]* -[*.Tests]* -[*.xunitTests]*"
	$testCoverageExcludeByAttribute = "System.Diagnostics.CodeAnalysis.ExcludeFromCoverageAttribute"
	$testCoverageExcludeByFile = "*\*Designer.cs;*\*.g.cs;*\*.g.i.cs"


	$buildConfiguration = "Release"
	$buildPlatform = "Any CPU"

	$packagesPath = "$solutionDirectory\packages"
	$NUnitExe = (Find-PackagePath $packagesPath "NUnit.ConsoleRunner") + "\Tools\nunit3-console.exe"
	$XUnitExe = (Find-PackagePath $packagesPath "xunit.runner.console") + "\Tools\xunit.console.exe"
	$MSTestExe = (Get-ChildItem ("C:\Program Files (x86)\Microsoft Visual Studio 12.0\Common7\IDE\CommonExtensions\Microsoft\TestWindow\vstest.console.exe")).FullName | Sort-Object $_ | select -last 1
	$OpenCoverExe = (Find-PackagePath $packagesPath "OpenCover") + "\Tools\OpenCover.Console.exe"
	$ReportGeneratorExe = (Find-PackagePath $packagesPath "ReportGenerator") + "\Tools\ReportGenerator.exe"
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
	Assert (Test-Path $MSTestExe) "MSTest Console could not be found"
	Assert (Test-Path $OpenCoverExe) "OpenCover Console Could not be found"
	Assert (Test-Path $ReportGeneratorExe) "Report Generator could not be found"

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
	if (Test-Path $testCoverageReportPath)
	{
		#Generate HTML test coverage report
		Write-Host "`r`nGenerating HTML test Coverage report"
		Exec { &$reportGeneratorExe $testCoverageReportPath $testCoverageDirectory }

		Write-Host "Parsing OpenCover results"
		# Load the coverage report as XML
		$coverage = [xml](Get-Content -Path $testCoverageReportPath)
		$coverageSummary = $coverage.CoverageSession.Summary

		# We force the formating of the numbers to be in US culture otherwise we will get comma instead of points.
		$UsCulture = New-Object System.Globalization.CultureInfo("us-EN")
		# Write class coverage
		Write-Host "##teamcity[buildStatisticValue key='CodeCoverageAbsCCovered' value='$($coverageSummary.visitedClasses)']"
		Write-Host "##teamcity[buildStatisticValue key='CodeCoverageAbsCTotal' value='$($coverageSummary.numClasses)']"
		$codeCoverageC = (($coverageSummary.visitedClasses / $coverageSummary.numClasses)*100)
		Write-Host ([string]::Format($UsCulture,"##teamcity[buildStatisticValue key='CodeCoverageC' value='{0:0.##}']",$codeCoverageC))
		
		# Write method coverage
		Write-Host "##teamcity[buildStatisticValue key='CodeCoverageAbsMCovered' value='$($coverageSummary.visitedMethods)']"
		Write-Host "##teamcity[buildStatisticValue key='CodeCoverageAbsMTotal' value='$($coverageSummary.numMethods)']"
		$codeCoverageM = (($coverageSummary.visitedMethods / $coverageSummary.numMethods)*100)
		Write-Host ([string]::Format($UsCulture,"##teamcity[buildStatisticValue key='CodeCoverageM' value='{0:0.##}']",$codeCoverageM))
	
		# Write branch coverage
		Write-Host "##teamcity[buildStatisticValue key='CodeCoverageAbsBCovered' value='$($coverageSummary.visitedBranchPoints)']"
		Write-Host "##teamcity[buildStatisticValue key='CodeCoverageAbsBTotal' value='$($coverageSummary.numBranchPoints)']"
		Write-Host "##teamcity[buildStatisticValue key='CodeCoverageM' value='$($coverageSummary.branchCoverage)']"
	
		# Write statement coverage
		Write-Host "##teamcity[buildStatisticValue key='CodeCoverageAbsSCovered' value='$($coverageSummary.visitedSequencePoints)']"
		Write-Host "##teamcity[buildStatisticValue key='CodeCoverageAbsSTotal' value='$($coverageSummary.numSequencePoints)']"
		Write-Host "##teamcity[buildStatisticValue key='CodeCoverageS' value='$($coverageSummary.sequenceCoverage)']"
	
	
	}
	else
	{
		Write-Host "No Coverage file found at : $testCoverageReportPath"
	}
}

task TestNUnit `
	-depends Compile `
	-description "Run Nunit tests" `
	-precondition {return Test-Path $publishedNUnitTestsDirectory} `
{
	$testAssemblies = Prepare-Tests -testRunnerName "NUnit" `
									-publishedTestsDirectory $publishedNUnitTestsDirectory `
									-testResultsDirectory $NUnitTestResultsDirectory `
									-testCoverageDirectory $testCoverageDirectory

	$targetArgs = "$testAssemblies --result `"`"$NUnitTestResultsDirectory\NUnit.xml`"`" --noheader"

	#Run openCover, which in turn will run NUnit
	Run-Tests -opencoverex $openCoverExe `
				-targetExe $NUnitExe `
				-targetArgs $targetArgs `
				-coveragePath $testCoverageReportPath `
				-filter $testCoverageFilter `
				-excludebyattribute:$testCoverageExcludeByAttribute `
				-excludebyfile:$testCoverageExcludeByFile
}

task TestXUnit `
	-depends Compile `
	-description "Run XUnit tests" `
	-precondition {return Test-Path $publishedxUnitTestsDirectory} ` {
	$testAssemblies = Prepare-Tests -testRunnerName "XUnit" `
									-publishedTestsDirectory $publishedXUnitTestsDirectory `
									-testResultsDirectory $XUnitTestResultsDirectory `
									-testCoverageDirectory $testCoverageDirectory
	$targetArgs = "$testAssemblies -xml `"`"$XunitTestResultsDirectory\xUnit.xml`"`" -nologo -noshadow"
	#Run openCover, which in turn will run xUnit
	Run-Tests -opencoverex $openCoverExe `
				-targetExe $xUnitExe `
				-targetArgs $targetArgs `
				-coveragePath $testCoverageReportPath `
				-filter $testCoverageFilter `
				-excludebyattribute:$testCoverageExcludeByAttribute `
				-excludebyfile:$testCoverageExcludeByFile
}

task TestMSTest `
	-depends Compile `
	-description "Run MSTest tests" `
	-precondition { return Test-Path $publishedMSTestTestsDirectory} {
		$testAssemblies = Prepare-Tests -testRunnerName "MSTest" `
									-publishedTestsDirectory $publishedMSTestTestsDirectory `
									-testResultsDirectory $MSTestTestResultsDirectory `
									-testCoverageDirectory $testCoverageDirectory

		#vsTest console does not have any option to change the output directory
		#so we need to change the working directory
		Push-Location $MSTestTestResultsDirectory
		Exec{ &$MSTestExe $testAssemblies /Logger:trx}
		$targetArgs = "$testAssemblies /Logger:trx"
		Run-Tests -opencoverex $openCoverExe `
				-targetExe $MsTestExe `
				-targetArgs $targetArgs `
				-coveragePath $testCoverageReportPath `
				-filter $testCoverageFilter `
				-excludebyattribute:$testCoverageExcludeByAttribute `
				-excludebyfile:$testCoverageExcludeByFile
		Pop-Location

		# move the .trx file back to $MSTestTestResultsDirectory
		Move-Item -Path $MSTestTestResultsDirectory\TestResults\*.trx -Destination $MSTestTestResultsDirectory\MSTest.trx -Force
		Remove-Item $MStestTestResultsDirectory\TestResults

}