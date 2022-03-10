	/**********************************************************************************************************/
	/*** RFC37376 Group USPTO Private PAIR and USPTO TSDR configuration items							    ***/
	/**********************************************************************************************************/
	IF exists (select * from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CONFIGURATIONITEM' AND COLUMN_NAME = 'GROUPID')
	Begin
		declare @bExists bit
		Set @bExists = 0
		exec sp_executesql N'select @bExists = 1 FROM CONFIGURATIONITEM WHERE TASKID = 216 and GROUPID IS NULL', N'@bExists bit output', @bExists = @bExists output
		IF (@bExists = 1)
		Begin
			PRINT '**** RFC37376 Updating CONFIGURATIONITEM for Schedule USPTO Private PAIR Data Download'
			EXEC sp_executesql N'UPDATE CONFIGURATIONITEM 
				SET GROUPID = 1,
				TITLE = ''Schedule USPTO Private PAIR Data Download''
				WHERE TASKID = 216'
			PRINT '**** RFC37376 Data successfully updated on CONFIGURATIONITEM table.'
			PRINT ''
		End
		Else
		Begin
			PRINT '**** RFC37376 CONFIGURATIONITEM Schedule USPTO Private PAIR Data Download already up to date.'
			PRINT ''
		End
	End
	go