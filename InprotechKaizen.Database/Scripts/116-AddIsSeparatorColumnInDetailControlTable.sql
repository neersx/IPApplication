/**********************************************************************************************************/	
/*** RFC69625 Add column DETAILCONTROL.IsSeparator													***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'DETAILCONTROL' AND COLUMN_NAME = 'ISSEPARATOR')
	BEGIN		
		PRINT '**** R69625 Adding column DETAILCONTROL.IsSeparator' 
		ALTER TABLE DETAILCONTROL ADD ISSEPARATOR bit NOT NULL default 0		 
		PRINT '**** R69625 Column DETAILCONTROL.IsSeparator added' 
 	END
ELSE
	BEGIN
		PRINT '**** R69625 Column DETAILCONTROL.IsSeparator exists already' 
	END
GO
 IF dbo.fn_IsAuditSchemaConsistent('DETAILCONTROL') = 0
 BEGIN
	exec ipu_UtilGenerateAuditTriggers 'DETAILCONTROL'
 END
GO


/**********************************************************************************************************/	
/*** RFC69625 Set values in newly added column DETAILCONTROL.IsSeparator													***/      
/**                                                                                                      **/
/**********************************************************************************************************/

PRINT '**** R69625 Setting values in column DETAILCONTROL.IsSeparator where no other details are added apart from Description and description is nonalphanumeric only' 

UPDATE Entries
SET Entries.ISSEPARATOR = 1 
FROM DETAILCONTROL Entries
LEFT JOIN DETAILDATES dates ON Entries.CRITERIANO = dates.CRITERIANO AND Entries.ENTRYNUMBER = dates.ENTRYNUMBER
LEFT JOIN DETAILLETTERS letters ON Entries.CRITERIANO = letters.CRITERIANO AND Entries.ENTRYNUMBER = letters.ENTRYNUMBER
LEFT JOIN GROUPCONTROL groups ON Entries.CRITERIANO = groups.CRITERIANO AND Entries.ENTRYNUMBER = groups.ENTRYNUMBER
LEFT JOIN USERCONTROL users ON Entries.CRITERIANO = users.CRITERIANO AND Entries.ENTRYNUMBER = users.ENTRYNUMBER
LEFT JOIN WINDOWCONTROL wc ON Entries.CRITERIANO = wc.CRITERIANO AND Entries.ENTRYNUMBER = wc.ENTRYNUMBER
LEFT JOIN TOPICCONTROL tc ON wc.WINDOWCONTROLNO = tc.WINDOWCONTROLNO 
WHERE COALESCE(TAKEOVERFLAG, STATUSCODE,RENEWALSTATUS, FILELOCATION, ATLEAST1FLAG, ENTRYCODE, CHARGEGENERATION, DISPLAYEVENTNO, HIDEEVENTNO, DIMEVENTNO, SHOWTABS, SHOWMENUS, SHOWTOOLBAR, USERINSTRUCTION_TID) is null and
NUMBERTYPE IS NULL AND USERINSTRUCTION IS NULL AND POLICINGIMMEDIATE = 0 AND
dates.CRITERIANO IS NULL AND letters.CRITERIANO IS NULL AND groups.CRITERIANO IS NULL AND users.CRITERIANO IS NULL AND tc.TOPICCONTROLNO IS NULL
AND dbo.fn_StripNonAlphaNumerics(ENTRIES.ENTRYDESC) LIKE '' 

PRINT '**** R69625  Setting values in column DETAILCONTROL.IsSeparator is completed' 

GO