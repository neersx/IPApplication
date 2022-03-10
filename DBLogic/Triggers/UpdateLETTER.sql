
if exists (select * from sysobjects where type='TR' and name = 'UpdateLETTER')
begin
	PRINT 'Refreshing trigger UpdateLETTER...'
	DROP TRIGGER UpdateLETTER
end
go

CREATE TRIGGER UpdateLETTER on LETTER for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateLETTER  
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
   		 @errno   int,
   		 @errmsg  varchar(255)

	 /* LETTER changed to LETTERSUBSTITUTE ON PARENT UPDATE RESTRICT */
	 if update(LETTERNO)
	 	begin
	 	 if exists (select * from deleted,LETTERSUBSTITUTE
			    where LETTERSUBSTITUTE.ALTERNATELETTER = deleted.LETTERNO)
			begin
			 select @errno  = 30005,
     			 @errmsg = 'Error %d Cannot UPDATE LETTER because LETTERSUBSTITUTE exists.'
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

