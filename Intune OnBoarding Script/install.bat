mkdir c:\programdata\IntuneExpeditedOnBoardingTask
Xcopy /E /I /Y . c:\programdata\IntuneExpeditedOnBoardingTask

powershell -executionpolicy bypass -file .\install-scheduledtask.ps1