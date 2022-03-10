xcopy "InprotechKaizen.Database\bin\Release" "Build\Content\Database" /I /R /Y /E
xcopy "Inprotech.Server\bin\Release" "Build\Content\Inprotech.Server" /I /R /Y /E
xcopy "Inprotech.IntegrationServer\bin\Release" "Build\Content\Inprotech.IntegrationServer" /I /R /Y /E
xcopy "Inprotech.Setup.Actions\bin\Release\Inprotech.Setup.Actions.dll" "Build\Content" /I /R /Y
xcopy "Inprotech.Setup\bin\Release" "Build" /I /R /Y /E
xcopy "Inprotech.Setup.IpPlatformTester\bin\release" "Build\Utility\ConnectivityTest" /I /R /Y /E

del /S /Q /F "Build\*.xml"
del /S /Q /F "Build\*.pdb"

if not exist "Build\Content\Database\_PublishedWebsites" goto end
rmdir "Build\Build\Content\_PublishedWebsites" /S /Q
:end

rmdir "Build\Package" /S /Q