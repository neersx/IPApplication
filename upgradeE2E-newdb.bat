@echo off
set conf=debug

if [%1]==[] goto execute

set conf=%1
echo %conf%

:execute


if exist "C:\Program Files\7-Zip\7z.exe" (
    echo ---------------------------------------------------------
    echo ----- Copying IPDEV.zip to C:\Assets\e2e if newer -------
    echo ---------------------------------------------------------

    robocopy "\\aus-inpsqlvd009\public_current_build\DATABASE BACKUP" C:\Assets\e2e IPDEV.zip /xo
    
    echo ---------------------------------------------------------
    echo ----- Unzipping IPDEV.bak C:\Assets\e2e         -------
    echo ---------------------------------------------------------

    "C:\Program Files\7-Zip\7z.exe" e C:\Assets\e2e\IPDEV.zip -oC:\Assets\e2e -aoa
    if ERRORLEVEL 1 (
        echo. Unable to unzip the IPDEV.zip
        exit /b 1
    )
) else (
    echo ---------------------------------------------------------
    echo ----- Copying IPDEV.bak to C:\Assets\e2e if newer -------
    echo ---------------------------------------------------------

    robocopy "\\aus-inpsqlvd009\public_current_build\DATABASE BACKUP" C:\Assets\e2e IPDEV.bak /xo
)

echo
echo ---------------------------------------------------------
echo ----- Delete and Restore E2E Database -------------------
echo ---------------------------------------------------------
osql -E -d master -i .\Inprotech.Tests.Integration\Scripts\DropRestoreDevIpdev_E2E.sql

echo
echo ---------------------------------------------------------
echo ----- Ensure last ref no up-to-date ---------------------
echo ---------------------------------------------------------

osql -E -d IPDEV -i Inprotech.Tests.Integration\Scripts\lastrefno.sql

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


echo ---------------------------------------------------------
echo ----- Run scripts ---------------------------------------
echo ---------------------------------------------------------
echo

call "InprotechKaizen.Database\bin\%conf%\InprotechKaizen.Database.exe" -m "Inprotech" -c "Data Source=.;Initial Catalog=IPDEV_E2E;Integrated Security=True"
call "InprotechKaizen.Database\bin\%conf%\InprotechKaizen.Database.exe" -m "InprotechIntegration" -c "Data Source=.;Initial Catalog=IPDEV_E2EIntegration;Integrated Security=True"

echo
echo ------------------------------------------------
echo ----- Grant access to Internal user role -------
echo ------------------------------------------------

echo
echo Add all applicable tasks to the 'All Internal' role
osql -E -d IPDEV_E2E -i post-dev-upgrade.sql

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