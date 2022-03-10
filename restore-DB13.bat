echo
echo ---------------------------------------------------------
echo ----- GET DB13 database for E2E       -------------------
echo ---------------------------------------------------------

robocopy "\\aus-inpsqlvd009\public_current_build\DATABASE BACKUP" C:\Assets\e2e IPDEV_13_E2E.bak /xo

del C:\Assets\e2e\IPDEV.bak

ren C:\Assets\e2e\IPDEV_13_E2E.bak IPDEV.bak

echo
echo ---------------------------------------------------------
echo ----- Delete and Restore E2E Database -------------------
echo ---------------------------------------------------------
osql -E -d master -i .\Inprotech.Tests.Integration\Scripts\DropRestoreDevIpdev_E2E.sql

echo
echo ---------------------------------------------------------
echo ----- Call UpgradeE2E -------------------
echo ---------------------------------------------------------

call upgradeE2E.bat
