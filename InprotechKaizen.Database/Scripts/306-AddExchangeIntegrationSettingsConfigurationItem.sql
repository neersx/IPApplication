    /**********************************************************************************************************/
		/*** DR-68356 Update Exchange Integration Settings to new integration model    ***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 264)
	begin try
	begin transaction
		print '**** DR-68356 Adding data CONFIGURATIONITEM.TASKID = 264'
		insert into CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) values (
			264,
			N'Exchange Integration Settings', 
			N'Configure Exchange Integration and manage the Exchange Request queue.', 
			N'/apps/#/exchange-configuration')
        print '**** DR-68356 Data successfully added to CONFIGURATIONITEM table.'
        print ''

		insert CONFIGURATIONITEMCOMPONENTS (CONFIGITEMID, COMPONENTID)
			select CI.CONFIGITEMID, CO.COMPONENTID
				from CONFIGURATIONITEM CI
				join COMPONENTS CO on CO.COMPONENTNAME = 'Integration'
				where CI.TASKID = 264
		
		print '**** DR-68356 Data successfully added to CONFIGURATIONITEMCOMPONENTS table.'
        print ''
    commit transaction
	end try
	begin catch
		if @@trancount > 0
			rollback

		declare @ErrMsg nvarchar(4000), @ErrSeverity int
		select @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY()

		raiserror(@ErrMsg, @ErrSeverity, 1)
	end catch
	else
		print '**** DR-68356 CONFIGURATIONITEM.TASKID = 264 already exists'
	print ''
    go
