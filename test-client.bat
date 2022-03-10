@echo off

REM client test file. If this file exists it is called by team city to run
REM the tests for the client applications

REM any parameters are passed to the client build scripts 
REM "%1" == "true" to clean bower caches (passed by team city from build param)

REM test condor client
pushd "%~dp0\condor"
echo ##teamcity[blockOpened name='testing condor']
call test.bat %*
IF NOT %ERRORLEVEL% EQU 0 (
	echo ##teamcity[message text='testing condor failed' errorDetails='%ERRORLEVEL%' status='ERROR']
	echo ##teamcity[blockClosed name='testing condor']
	exit /b %ERRORLEVEL%
)
echo ##teamcity[blockClosed name='testing condor']
popd