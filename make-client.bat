rem @echo off

REM client make file. If this file exists it is called by team city to build
REM the client applications

REM any parameters are passed to the client build scripts 
REM "%1" == "true" to clean bower caches (passed by team city from build param)
REM "%2" == "true" to include e2e test pages (passed by team city from build param)
REM "%3" == "true" to gzip ng and condor build files (passed by team city from build param)

REM build condor client dist
pushd "%~dp0\condor"
echo ##teamcity[blockOpened name='making condor']
call make.bat %*
IF NOT %ERRORLEVEL% EQU 0 (
	echo ##teamcity[message text='making condor failed' errorDetails='%ERRORLEVEL%' status='ERROR']
	echo ##teamcity[blockClosed name='making condor']
	exit /b %ERRORLEVEL%
)
echo ##teamcity[blockClosed name='making condor']
popd

REM deploy condor to client
pushd "%~dp0\condor"
echo ##teamcity[blockOpened name='copying condor']
call gulp deploy --path="..\Build\Content\Inprotech.Server\client"
IF NOT %ERRORLEVEL% EQU 0 (
	echo ##teamcity[message text='copying condor failed' errorDetails='%ERRORLEVEL%' status='ERROR']
	echo ##teamcity[blockClosed name='copying condor']
	exit /b %ERRORLEVEL%
)
echo ##teamcity[blockClosed name='copying condor']
popd