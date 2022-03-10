set conf=debug

if [%1]==[] goto execute

set conf=%1

echo conf

:execute
"InprotechKaizen.Database\bin\%conf%\InprotechKaizen.Database.exe" -f -m "Inprotech" -c "Data Source=.;Initial Catalog=IPDEV;Integrated Security=True"