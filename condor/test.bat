@echo off

rem echo ##teamcity[blockOpened name='condor npm install']
rem call npm install
rem IF NOT %ERRORLEVEL% EQU 0 (
rem 	echo ##teamcity[message text='condor install failed' errorDetails='%ERRORLEVEL%' status='ERROR']
rem 	echo ##teamcity[blockClosed name='condor npm install']
rem 	exit /b %ERRORLEVEL%
rem )
rem echo ##teamcity[blockClosed name='condor npm install']

echo ##teamcity[blockOpened name='condor npm install']
echo call npm i
call npm i

IF NOT %ERRORLEVEL% EQU 0 (
	IF %ERRORLEVEL% == -4048 (
		call cd .
		echo %ERRORLEVEL%
		echo Error occurred during install
		echo Force re-installing packages
		call npm install --force
	)
	IF NOT %ERRORLEVEL% EQU 0 (
		echo ##teamcity[message text='condor npm install failed' errorDetails='%ERRORLEVEL%' status='ERROR']
		echo ##teamcity[blockClosed name='condor npm install']
		exit /b %ERRORLEVEL%
	)
)
echo ##teamcity[blockClosed name='condor npm install']

IF "%1" == "coverage" (
	echo ##teamcity[blockOpened name='condor gulp test --teamcity --coverage']
	call npx gulp test --teamcity --coverage
) ELSE (
	echo ##teamcity[blockOpened name='condor gulp test --teamcity']
	call npx gulp test --teamcity --jestworkers=%2
)

IF NOT %ERRORLEVEL% EQU 0 (
	echo ##teamcity[message text='condor gulp test failed' errorDetails='%ERRORLEVEL%' status='ERROR']
	echo ##teamcity[blockClosed name='condor gulp test']
	exit /b %ERRORLEVEL%
)
echo ##teamcity[blockClosed name='condor gulp test']