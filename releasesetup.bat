set TargetDir=Inprotech.Setup\bin\release
if exist %TargetDir%\content rmdir /S /Q %TargetDir%\content
mkdir %TargetDir%\content


xcopy Inprotech.Setup.Actions\bin\release\Inprotech.Setup.Actions.dll %TargetDir%\content

xcopy InprotechKaizen.Database\bin\release %TargetDir%\content\database /I /R /Y /E
xcopy Inprotech.Server\bin\release %TargetDir%\content\inprotech.server /I /R /Y /E
xcopy Inprotech.IntegrationServer\bin\release %TargetDir%\content\inprotech.integrationserver /I /R /Y /E
