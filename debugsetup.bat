set TargetDir=Inprotech.Setup\bin\debug
if exist %TargetDir%\content rmdir /S /Q %TargetDir%\content
mkdir %TargetDir%\content

xcopy Inprotech.Setup.Actions\bin\debug\Inprotech.Setup.Actions.dll %TargetDir%\content

xcopy InprotechKaizen.Database\bin\debug %TargetDir%\content\database /I /R /Y /E
xcopy Inprotech.Server\bin\debug %TargetDir%\content\inprotech.server /I /R /Y /E
xcopy Inprotech.IntegrationServer\bin\debug %TargetDir%\content\inprotech.integrationserver /I /R /Y /E
xcopy Inprotech.StorageService\bin\debug %TargetDir%\content\inprotech.storageservice /I /R /Y /E

mkdir %TargetDir%\Utility
mkdir %TargetDir%\Utility\ConnectivityTest
xcopy Inprotech.Setup.IpPlatformTester\bin\Debug %TargetDir%\Utility\ConnectivityTest /I /R /Y /E
xcopy Inprotech.Setup.IWSConfig\bin\Debug %TargetDir%\Utility\IWSConfig /I /R /Y /E

xcopy condor\client\cookieDeclaration.html %TargetDir%\content\client\ /Y

set TargetDir2=Inprotech.Setup.CommandLine\bin\debug
if exist %TargetDir2%\content rmdir /S /Q %TargetDir2%\content
mkdir %TargetDir2%\content

xcopy Inprotech.Setup.Actions\bin\debug\Inprotech.Setup.Actions.dll %TargetDir2%\content

xcopy InprotechKaizen.Database\bin\debug %TargetDir2%\content\database /I /R /Y /E
xcopy Inprotech.Server\bin\debug %TargetDir2%\content\inprotech.server /I /R /Y /E
xcopy Inprotech.IntegrationServer\bin\debug %TargetDir2%\content\inprotech.integrationserver /I /R /Y /E
xcopy Inprotech.StorageService\bin\debug %TargetDir%\content\inprotech.storageservice /I /R /Y /E

mkdir %TargetDir2%\Utility
mkdir %TargetDir2%\Utility\ConnectivityTest
xcopy Inprotech.Setup.IpPlatformTester\bin\Debug %TargetDir2%\Utility\ConnectivityTest /I /R /Y /E
xcopy Inprotech.Setup.IWSConfig\bin\Debug %TargetDir2%\Utility\IWSConfig /I /R /Y /E

xcopy condor\client\cookieDeclaration.html %TargetDir2%\content\client\ /Y