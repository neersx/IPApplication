@echo off
set conf=debug

if [%1]==[] goto execute

set conf=%1
echo %conf%

:execute

echo
echo ---------------------------------------------------------
echo ----- Build the Database Project ------------------------
echo ---------------------------------------------------------

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

call %msbuild% .\InprotechKaizen.Database\InprotechKaizen.Database.csproj /t:Rebuild /verbosity:m  /p:Configuration=%conf% /p:RunCodeAnalysis=false
if errorlevel 1 goto CompileError

echo
echo ---------------------------------------------------------
echo ----- Ensure last ref no up-to-date ---------------------
echo ---------------------------------------------------------

osql -E -d IPDEV -i Inprotech.Tests.Integration\Scripts\lastrefno.sql

echo ---------------------------------------------------------
echo ----- Run scripts ---------------------------------------
echo ---------------------------------------------------------
echo

call "InprotechKaizen.Database\bin\%conf%\InprotechKaizen.Database.exe" -m "Inprotech" -c "Data Source=.;Initial Catalog=IPDEV;Integrated Security=True"
call "InprotechKaizen.Database\bin\%conf%\InprotechKaizen.Database.exe" -m "InprotechIntegration" -c "Data Source=.;Initial Catalog=IPDEVIntegration;Integrated Security=True"

echo
echo ------------------------------------------------
echo ----- Grant access to Internal user role -------
echo ------------------------------------------------

echo
echo Add all applicable tasks to the 'All Internal' role
osql -E -d IPDEV -i post-dev-upgrade.sql

:end
exit /b

:CompileError
echo ------------------------------------------------------------------------
echo COMPILATION ERROR - Database project is not compiled
echo ------------------------------------------------------------------------
goto end

:end
exit /b

@echo on