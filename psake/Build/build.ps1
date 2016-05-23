cls

# '[p]sake is the same as 'psake' but $Error is not polluted if the module is not loaded
Remove-Module [p]sake

# find psake's path
$psakeModule = (Get-ChildItem ('..\Packages\psake*\tools\psake.psm1')).FullName | Sort-Object $_ | select -Last 1

# Import the module
Import-Module $psakeModule

Invoke-psake -buildFile .\default.ps1 -taskList Test
