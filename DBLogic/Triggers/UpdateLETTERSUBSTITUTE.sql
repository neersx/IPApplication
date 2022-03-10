if exists (select * from sysobjects where type='TR' and name = 'UpdateLETTERSUBSTITUTE')
begin
	PRINT 'Refreshing trigger UpdateLETTERSUBSTITUTE...'
	DROP TRIGGER UpdateLETTERSUBSTITUTE
end
go

CREATE TRIGGER UpdateLETTERSUBSTITUTE on LETTERSUBSTITUTE for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateLETTERSUBSTITUTE  
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
   		 @insLETTERNO smallint, 
   		 @insSEQUENCE smallint,
   		 @errno   int,
   		 @errmsg  varchar(255)

	 /* LETTER changed to LETTERSUBSTITUTE ON CHILD UPDATE RESTRICT */
	 if update(ALTERNATELETTER)
	 	begin
		 select @nullcnt = 0
		 select @validcnt = count(*)
		 from inserted,LETTER
		 where inserted.ALTERNATELETTER = LETTER.LETTERNO
		 select @nullcnt = count(*) from inserted where inserted.ALTERNATELETTER is null
		 if @validcnt + @nullcnt != @numrows
			begin
			 select @errno  = 30007,
     			 @errmsg = 'Error %d Cannot UPDATE LETTERSUBSTITUTE because LETTER does not exist.'
			 goto error
			end
		end

	 return
	 error:
	 --raiserror @errno @errmsg
	 Raiserror  ( @errmsg, 16,1, @errno)	 
	 rollback transaction
end
go

