	/**********************************************************************************************************/
	/*** 11085 Create tD_PERIOD trigger									***/
	/**********************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'tD_PERIOD')
		begin
	    	 PRINT 'Refreshing trigger tD_PERIOD...'
	    	 DROP TRIGGER tD_PERIOD
	   	end
	else
		print 'Creating trigger tD_PERIOD'
		PRINT ''
	go

	Create trigger tD_PERIOD on PERIOD AFTER DELETE NOT FOR REPLICATION as
		Begin
		 Declare @pnPeriodId 	int
		 Select  @pnPeriodId = deleted.PERIODID from deleted

		 If  exists (select * from PERIOD where PERIODID > @pnPeriodId) 
		 and exists (select * from PERIOD where PERIODID < @pnPeriodId)
		 	Begin
			 RAISERROR  ( 'You cannot delete the period.', 12,1)
			 Rollback
			End
		End
	GO