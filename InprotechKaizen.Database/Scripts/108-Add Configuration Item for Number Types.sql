/**********************************************************************************************************/
/*** RFC60735 Maintain Number Types - ConfigurationItem						                            ***/
/**********************************************************************************************************/

If not exists (SELECT * FROM CONFIGURATIONITEM WHERE TASKID=241)
Begin
    PRINT '**** RFC60735 Inserting CONFIGURATIONITEM WHERE TASKID=241 and TITLE = "Maintain Number Types"'
	INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) 
	VALUES(241,'Maintain Number Types','Create, update or delete Number Types.','/apps/#/configuration/general/numbertypes')		
	PRINT '**** RFC60735 Data successfully inserted in CONFIGURATIONITEM table.'
	PRINT ''			
End
Else
Begin
	PRINT '**** RFC60735 CONFIGURATIONITEM WHERE TASKID=241 already exists'
	PRINT ''
End
go