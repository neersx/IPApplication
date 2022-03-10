	
	IF exists (select * from INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CONFIGURATIONITEM' AND COLUMN_NAME = 'GROUPID')
	Begin
		declare @bExists bit
		Set @bExists = 0
		exec sp_executesql N'select @bExists = 1 FROM CONFIGURATIONITEM WHERE TASKID = 232 and GROUPID IS NULL', N'@bExists bit output', @bExists = @bExists output
		IF (@bExists = 1)
		Begin
			PRINT '**** RFC42681 Updating CONFIGURATIONITEM for Schedule USPTO Private PAIR Data Download'
			EXEC sp_executesql N'UPDATE CONFIGURATIONITEM 
				SET GROUPID = 1,
				TITLE = ''Schedule EPO Data Download''
				WHERE TASKID = 232'
			PRINT '**** RFC42681 Data successfully updated on CONFIGURATIONITEM table.'
			PRINT ''
		End
		Else
		Begin
			PRINT '**** RFC42681 CONFIGURATIONITEM Schedule EPO Data Download already up to date.'
			PRINT ''
		End
	End
	go