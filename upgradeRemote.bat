@echo OFF

set /p server="Enter Server: " %=%
set /p database="Enter Database: " %=%
set /p login="Enter Login: %=%
set /p password="Enter Password: %=%

InprotechKaizen.Database\bin\debug\InprotechKaizen.Database.exe -m "Inprotech" -c "Data Source=%server%;Initial Catalog=%database%;uid=%login%;password=%password%"

@echo.
@echo.
@echo Complete.
@echo.