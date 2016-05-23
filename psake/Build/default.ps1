properties{
	$cleanMessage = "Executed Clean!"
	$testMessage = "Executed unit tests!"

	$solutionDirectory = (Get-Item $solutionFile).DirectoryName
	$outputDirectory = "$solutionDirectory\.build"
	$temporaryOutputDirectory = "$outputDirectory\temp"

	$buildConfiguration = "Release"
	$buildPlatform = "Any CPU"
}

FormatTaskName "`r`n`r`n---------- Executing {0} Task -------"

task default -depends Test

task Init -description "Initialises the build by removing previous artifacts and creating output directories" `
			-requiredVariables outputDirectory, temporaryOutputDirectory {
	
	Assert -conditionToCheck ("Debug", "Release" -contains $buildConfiguration) `
			-failureMessage "Invalid build configuration '$buildConfiguration'. Values must be 'Debug' or 'Release'."

	Assert -conditionToCheck ("x86", "x64", "Any CPU" -contains $buildPlatform) `
			-failureMessage "Invalid build platform '$buildPlatform'. Values must be 'x86', 'x64' or 'Any CPU'."

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
	exec {
		msbuild $solutionFile "/p:Configuration=$buildConfiguration;Platform=$buildPlatform;OutDir=$temporaryOutputDirectory"
	}
}

task Test -depends Compile, Clean -description "Runs the unit test"{
	Write-Host $testMessage
}