properties{
	$CleanMessage = "Executed Clean!"
	$CompileMessage = "Executed Compile !"
	$TestMessage = "Executed unit tests!"
}

task default -depends Test

task Clean -description "Clean the build output"{
	Write-Host $CleanMessage
}

task Compile -depends Clean -description "Compile the all solution"{
	Write-Host $CompileMessage
}

task Test -depends Compile, Clean -description "Runs the unit test"{
	Write-Host $TestMessage
}