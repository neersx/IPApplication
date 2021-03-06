IF EXISTS (SELECT name FROM master.dbo.sysdatabases WHERE name = 'IPDEV_E2E')
BEGIN
    DROP DATABASE [IPDEV_E2E]
END
GO

RESTORE DATABASE [IPDEV_E2E] 
FROM DISK='C:\Assets\e2e\IPDEV.bak' 
WITH REPLACE, MOVE 'IPDEMO' TO 'C:\Assets\E2E\IPDEV_E2E.mdf', MOVE 'IPDEMO_Log' TO 'C:\Assets\E2E\IPDEV_E2E.ldf'
GO