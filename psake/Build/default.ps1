properties{
	$cleanMessage = "Executed Clean!"
	$compileMessage = "Executed Compile !"
	$testMessage = "Executed unit tests!"

	$solutionDirectory = (Get-Item $solutionFile).DirectoryName
	$outputDirectory = "$solutionDirectory\.build"
	$temporaryOutputDirectory = "$outputDirectory\temp"
}

task default -depends Test

task Init -description "Initialises the build by removing previous artifacts and creating output directories" `
			-requiredVariables outputDirectory, temporaryOutputDirectory {
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

task Compile -depends Init -description "Compile the all solution"{
	Write-Host $compileMessage
}

task Test -depends Compile, Clean -description "Runs the unit test"{
	Write-Host $testMessage
}