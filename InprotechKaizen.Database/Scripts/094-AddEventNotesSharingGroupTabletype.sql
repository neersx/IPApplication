/**********************************************************************************************************/
/*** RFC64418 Insert Note Sharing Group Table Type -515							***/
/**********************************************************************************************************/
If not exists (select 1 from TABLETYPE WHERE TABLETYPE = -515)
Begin
	PRINT '**** RFC64418 Adding Report Table Type'
	INSERT INTO TABLETYPE(TABLETYPE,TABLENAME,MODIFIABLE,ACTIVITYFLAG,DATABASETABLE)
	VALUES(-515,'Note Sharing Group',1,0,'TABLECODES')
	PRINT '**** RFC64418 Data successfully added to TABLETYPE table.'
	PRINT ''
End
Else
Begin
	PRINT '**** RFC64418 Insert Report Table Type already exists'
	PRINT ''
End
go


--  Need to lock number to prevent users from modifying the allocated number.

/**********************************************************************************************************/
/*** RFC64418 Insert Protect Codes TABLETYPE -515							***/
/**********************************************************************************************************/
If NOT exists (select 1 from PROTECTCODES where TABLETYPE = -515)
Begin
	PRINT '**** RFC64418 TABLETYPE = -515  protect codes'
	insert into PROTECTCODES(PROTECTKEY,TABLETYPE)
	select MAX(PROTECTKEY) + 1, -515
	from PROTECTCODES
	PRINT '**** RFC64418 Data successfully added to PROTECTCODES table.'
	PRINT ''
End
Else
	PRINT '**** RFC64418 PROTECTCODES.TABLETYPE = -515 already exists'
	PRINT ''
go