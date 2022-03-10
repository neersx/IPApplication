@echo off

rem   echo ##teamcity[blockOpened name='condor npm install']
rem   
rem   rem IF NOT DEFINED VCTargetsPath SET VCTargetsPath=C:\Program Files (x86)\MSBuild\Microsoft.Cpp\v4.0\V120
rem   rem call npm cache clean
rem   rem call npm install --force
rem   
rem   IF NOT %ERRORLEVEL% EQU 0 (
rem   	echo ##teamcity[message text='condor npm install failed' errorDetails='%ERRORLEVEL%' status='ERROR']
rem   	echo ##teamcity[blockClosed name='condor npm install']
rem   	exit /b %ERRORLEVEL%
rem   )

echo ##teamcity[blockOpened name='condor npm install']
pushd "%~dp0\client\batchEventUpdate"
call npm install
popd
echo call npm install
call npm install

IF NOT %ERRORLEVEL% EQU 0 (
	IF %ERRORLEVEL% == -4048 (
		call cd .
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

echo ##teamcity[blockOpened name='Kendo License Install']
call npx kendo-ui-license activate
echo ##teamcity[blockClosed name='Kendo License Install']

echo ##teamcity[blockOpened name='condor gulp dist']
call gulp build --includeE2e="%2" --includeBatchEvent --gzCompress="%3"
IF NOT %ERRORLEVEL% EQU 0 (
	echo ##teamcity[message text='condor gulp dist failed' errorDetails='%ERRORLEVEL%' status='ERROR']
	echo ##teamcity[blockClosed name='condor gulp dist']
	exit /b %ERRORLEVEL%
)
echo ##teamcity[blockClosed name='condor gulp dist']
