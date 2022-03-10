	/******************************************************************************************************************/
	/*** 10717 Create tD_PROFILENAME trigger									***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'tD_PROFILENAME')
   		begin
    		 PRINT 'Refreshing trigger tD_PROFILENAME...'
    		 DROP TRIGGER tD_PROFILENAME
   		end
	go

	create trigger tD_PROFILENAME on COPYPROFILE for DELETE NOT FOR REPLICATION AS 
		begin
		 declare @errno int,
			@errmsg  varchar(255)
	
		 if exists (
			select	C.PROFILENAME 
			from 	DELETED D
			join	CRITERIA C on ( D.PROFILENAME = C.PROFILENAME )
			where	not exists ( 
					select	PROFILENAME 
					from 	COPYPROFILE 
					where	PROFILENAME = D.PROFILENAME
					)
			)
		 begin
			select @errno  = 30005,
			@errmsg = 'Error %d This profile is referenced by the CRITERIA table and cannot be deleted.'
			goto error
		 end

		 return
		 error:
		 Raiserror  (@errmsg, 16,1, @errno)
		 rollback transaction
		end
		go

