/* **** DR-43001 Incorrect labels and descriptions on Configuration pages ****/

IF EXISTS(SELECT *
FROM CONFIGURATIONITEM
WHERE TASKID = 75 AND TITLE= 'Standing Instructions')
BEGIN
PRINT '*** DR-43001 Start - Update CONFIGURATIONITEM data***'
UPDATE CONFIGURATIONITEM SET TITLE= 'Instruction Definitions', DESCRIPTION='Define the Instructions that may be provided by your firm''s clients.' WHERE  TASKID = 75
AND TITLE= 'Standing Instructions'
PRINT '*** DR-43001 End - Updated CONFIGURATIONITEM successfully ***'
END
GO

IF EXISTS(SELECT *
FROM CONFIGURATIONITEM
WHERE TASKID = 244 AND TITLE= 'Standing Instruction Definitions')
BEGIN
PRINT '*** DR-43001 Start - Update CONFIGURATIONITEM data***'
UPDATE CONFIGURATIONITEM SET TITLE= 'Standing Instructions', DESCRIPTION='Create and modify Standing Instructions, including Instruction Types and Characteristics.' WHERE TASKID = 244
AND TITLE= 'Standing Instruction Definitions'
PRINT '*** DR-43001 End - Updated CONFIGURATIONITEM successfully ***'
END
GO

IF EXISTS(SELECT *
FROM CONFIGURATIONITEM
WHERE TASKID = 215)
BEGIN
PRINT '*** DR-43001 Start - Update CONFIGURATIONITEM data***'
UPDATE CONFIGURATIONITEM set TITLE = 'USPTO Private PAIR Practitioner Sponsorship', 
DESCRIPTION='Manage the Sponsored Accounts stored in Inprotech, which are used to automatically download case data from the USPTO Private Pair.' WHERE TASKID = 215
print '***** DR-43001 Updated TITLE, DESCRIPTION and URL to USPTO Private PAIR Practitioner Sponsorship.'
END 
GO
