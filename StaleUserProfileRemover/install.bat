mkdir c:\programdata\StaleUserProfileRemover
Xcopy /E /I /Y . c:\programdata\StaleUserProfileRemover

powershell -executionpolicy bypass -file .\StaleUserTask.ps1
