if exists (select * from sysobjects where type='TR' and name = 'UpdateNARRATIVESUBSTITUT')
begin
	PRINT 'Refreshing trigger UpdateNARRATIVESUBSTITUT...'
	DROP TRIGGER UpdateNARRATIVESUBSTITUT
end
go

CREATE TRIGGER UpdateNARRATIVESUBSTITUT on NARRATIVESUBSTITUT for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateNARRATIVESUBSTITUT  
-- VERSION:	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	MF	17490	2	Ignore if trigger is being fired as a result of the audit details being updated
-- 15 Jul 2009	MF	17869	3	Get @rowcount as first thing in trigger to avoid it getting reset
-- 28 Sep 2012 DL	12795	4	Correct syntax error for SQL Server 2012

declare @numrows int

set @numrows = @@rowcount

If NOT UPDATE(LOGDATETIMESTAMP)
begin
	 declare @nullcnt int,
   		 @validcnt int,
   		 @insNARRATIVENO smallint, 
   		 @insSEQUENCE smallint,
   		 @errno   int,
   		 @errmsg  varchar(255)

	 /* NARRATIVE changed to NARRATIVESUBSTITUT ON CHILD UPDATE RESTRICT */
	 if update(ALTERNATENARRATIVE)
		begin
		 select @nullcnt = 0
		 select @validcnt = count(*)
		 from 	inserted,NARRATIVE
		 where  inserted.ALTERNATENARRATIVE = NARRATIVE.NARRATIVENO
		 select @nullcnt = count(*) from inserted where inserted.ALTERNATENARRATIVE is null
		 if @validcnt + @nullcnt != @numrows
			begin
			 select @errno  = 30007,
     			 @errmsg = 'Error %d Cannot UPDATE NARRATIVESUBSTITUT because NARRATIVE does not exist.'
			 goto error
			end
		end

	 return
	 error:
	-- raiserror @errno @errmsg
	Raiserror  ( @errmsg, 16,1, @errno)
	 rollback transaction
end
go

