if exists (select * from sysobjects where type='TR' and name = 'UpdateMARGIN')
begin
	PRINT 'Refreshing trigger UpdateMARGIN...'
	DROP TRIGGER UpdateMARGIN
end
go

CREATE TRIGGER UpdateMARGIN on MARGIN for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateMARGIN  
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
   		 @insMARGINNO int,
   		 @errno   int,
   		 @errmsg  varchar(255)

	 /* NAME R/170 MARGIN ON CHILD UPDATE RESTRICT */
	 if update(DEBTOR)
	 	begin
		 select @nullcnt = 0
		 select @validcnt = count(*)
		 from inserted,NAME
		 where inserted.DEBTOR = NAME.NAMENO
		 select @nullcnt = count(*) from inserted where inserted.DEBTOR is null
		 if @validcnt + @nullcnt != @numrows
		 	begin
			 select @errno  = 30007,
     			 @errmsg = 'Error %d Cannot UPDATE MARGIN because NAME does not exist.'
			 goto error
			end
		end

	 /* COUNTRY R/35 MARGIN ON CHILD UPDATE RESTRICT */
	 if update(DEBTORCOUNTRY)
	 	begin
		 select @nullcnt = 0
		 select @validcnt = count(*)
		 from 	inserted,COUNTRY
		 where	inserted.DEBTORCOUNTRY = COUNTRY.COUNTRYCODE
		 select @nullcnt = count(*) from inserted where inserted.DEBTORCOUNTRY is null
		 if @validcnt + @nullcnt != @numrows
			begin
		 	 select @errno  = 30007,
     			 @errmsg = 'Error %d Cannot UPDATE MARGIN because COUNTRY does not exist.'
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

