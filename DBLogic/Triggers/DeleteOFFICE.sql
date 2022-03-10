	/******************************************************************************************************************/
	/*** 13910 Create DeleteOFFICE trigger (The Trigger name has been update for RFC7795)		***/
	/******************************************************************************************************************/     
	
	if exists (select * from sysobjects where type='TR' and name = 'DeleteOFFICE')
   		begin
    		 PRINT 'Refreshing trigger DeleteOFFICE...'
    		 DROP TRIGGER DeleteOFFICE
   		end
  	go
	  	
	CREATE TRIGGER DeleteOFFICE ON OFFICE for DELETE NOT FOR REPLICATION AS 
	BEGIN
		SET NOCOUNT ON;

		Declare @errno   int
		Declare @errmsg  varchar(255)
		
		If exists (	Select 1
				from DELETED D
				join TABLEATTRIBUTES TA on (TA.TABLETYPE = 44 and TA.TABLECODE = D.OFFICEID and TA.PARENTTABLE = 'NAME')
		)
		BEGIN
			select @errno  = 30005,
			@errmsg = 'Error %d Cannot DELETE OFFICE because DESCRIPTION exists.'
			goto error
		END
		

		return
		error:
		Raiserror  (@errmsg, 16,1, @errno)
		rollback transaction
		
	END
	GO
