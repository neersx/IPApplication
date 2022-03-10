@echo off
if not exist build goto start
del /S /Q /F Build\*.*
rmdir Build /S /Q

:start

call "C:\Program Files (x86)\Microsoft Visual Studio\2017\BuildTools\MSBuild\15.0\Bin\msbuild" InprotechKaizen.sln /t:Rebuild /verbosity:m /noconlog /p:Configuration=Release;DeployOnBuild=true;DeployTarget=Package;_PackageTempDir=..\Build\Content\Apps\;PackageLocation=..\Build\Package\content\iis\iwa.zip

pushd condor
pushd batchEventUpdate
call npm install
popd

call npm install
call gulp build --includeBatchEvent
call gulp deploy --vsrelease
popd

call "Package.bat"
