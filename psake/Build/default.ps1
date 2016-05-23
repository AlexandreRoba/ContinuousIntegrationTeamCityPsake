properties{
	$cleanMessage = "Executed Clean!"
	$compileMessage = "Executed Compile !"
	$testMessage = "Executed unit tests!"
}

task default -depends Test

task Clean -description "Clean the build output"{
	Write-Host $cleanMessage
}

task Compile -depends Clean -description "Compile the all solution"{
	Write-Host $compileMessage
}

task Test -depends Compile, Clean -description "Runs the unit test"{
	Write-Host $testMessage
}