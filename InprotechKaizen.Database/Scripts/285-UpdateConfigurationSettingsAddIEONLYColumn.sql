
/**********************************************************************************************************/
/*** DR-66244 IE Required message is unnecessary for Hybrid-X    ***/

/**********************************************************************************************************/
PRINT '**** DR-66244 IE Required message is unnecessary for Hybrid-X '
If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CONFIGURATIONITEM' AND COLUMN_NAME = 'IEONLY')
BEGIN
	PRINT '**** ADD COLUMN IEONLY '
    ALTER TABLE [dbo].[CONFIGURATIONITEM]
        ADD IEONLY Bit NOT NULL 
    DEFAULT (0)
WITH VALUES
END
GO

UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 148 and TITLE = 'Bill Formats'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 154 and TITLE = 'Currencies'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 156 and TITLE = 'Bill Format Profiles'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 157 and TITLE = 'Bill Map Profiles'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 180 and TITLE = 'Questions'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 158 and TITLE = 'Sanity Check Rules - Cases'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 190 and TITLE = 'Tax Codes'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 156 and TITLE = 'Bill Case Columns'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 207 and TITLE = 'Sanity Check Rules - Names'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 204 and TITLE = 'WIP Types'		
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 155 and TITLE = 'Exchange Rate Schedule'	
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 206 and TITLE = 'Keywords'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 208 and TITLE = 'Office File Locations'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 181 and TITLE = 'Offices'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 131 and TITLE = 'Protected Rules - Checklists'
UPDATE [dbo].[CONFIGURATIONITEM] SET IEONLY = 1 WHERE TASKID = 130 and TITLE = 'Rules - Checklists'
GO