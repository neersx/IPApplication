set conf=debug

if [%1]==[] goto execute

set conf=%1

echo conf

:execute
"InprotechKaizen.Database\bin\%conf%\InprotechKaizen.Database.exe" -m "InprotechIntegration" -c "Data Source=.;Initial Catalog=IPDEVIntegration;Integrated Security=True"