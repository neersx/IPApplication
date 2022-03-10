@echo off

echo ------------------------------------------------------------------------
echo Compiling InprotechKaizen Solution
echo ------------------------------------------------------------------------
set msbuild="C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\MSBuild\Current\Bin\MSBuild.exe"
if not exist %msbuild% (
    set msbuild="C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
)
if not exist %msbuild% (
    set msbuild="C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\MSBuild\15.0\Bin\MSBuild.exe"
)
if not exist %msbuild% (
    set msbuild="C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\MSBuild\15.0\Bin\MSBuild.exe"
)
if not exist %msbuild% (
    set msbuild="C:\Program Files (x86)\Microsoft Visual Studio\2019\Preview\MSBuild\Current\Bin\MSBuild.exe"
)

echo Build using %msbuild%


call %msbuild% InprotechKaizen.sln /t:Rebuild /verbosity:m /noconlog 
if errorlevel 1 goto CompileError

echo ------------------------------------------------------------------------
echo Executing .Net Unit Test Cases
echo ------------------------------------------------------------------------
%homePath%\.nuget\packages\xunit.runner.console\2.4.1\tools\net472\xunit.console Inprotech.Tests\bin\debug\Inprotech.Tests.dll -nologo

echo ------------------------------------------------------------------------
echo Executing Unit Tests from Condor Folder
echo ------------------------------------------------------------------------
cd condor
call gulp  test  --silent --quickrun
cd..
goto TestsRunDone

:CompileError
echo ------------------------------------------------------------------------
echo COMPILATION ERROR - TESTS ARE NOT EXECUTED
echo ------------------------------------------------------------------------
goto end

:TestsRunDone
echo ------------------------------------------------------------------------
echo All Tests executed . Check the results above.
echo ------------------------------------------------------------------------

:end
exit /b

@echo on



