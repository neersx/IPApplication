if exists (select * from sysobjects where type='TR' and name = 'UpdateCOUNTRYGROUPGROUP')
begin
	PRINT 'Dropping trigger UpdateCOUNTRYGROUP...'
	DROP TRIGGER UpdateCOUNTRYGROUPGROUP
end
go
   
if exists (select * from sysobjects where type='TR' and name = 'UpdateCOUNTRYGROUP')
begin
	PRINT 'Refreshing trigger UpdateCOUNTRYGROUP...'
	DROP TRIGGER UpdateCOUNTRYGROUP
end
go

CREATE TRIGGER UpdateCOUNTRYGROUP on COUNTRYGROUP for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateCOUNTRYGROUP  
-- VERSION:	5
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	MF	17490	2	Ignore if trigger is being fired as a result of the audit details being updated
-- 30 Mar 2009	MF	17546	3	Correct error in name of trigger and remove incorrect version.
-- 15 Jul 2009	MF	17869	4	Get @rowcount as first thing in trigger to avoid it getting reset
-- 28 Sep 2012 DL	12795	5	Correct syntax error for SQL Server 2012

declare @numrows int

set @numrows = @@rowcount

If NOT UPDATE(LOGDATETIMESTAMP)
begin
	 declare @nullcnt int,
   		 @validcnt int,
   		 @insTREATYCODE nvarchar(3), 
   		 @insMEMBERCOUNTRY nvarchar(3),
   		 @errno   int,
   		 @errmsg  varchar(255)

	 /* COUNTRY has members COUNTRYGROUP ON CHILD UPDATE RESTRICT */
	 if update(TREATYCODE)
	 	begin
		 select @nullcnt = 0
		 select @validcnt = count(*)
		 from inserted,COUNTRY
		 where inserted.TREATYCODE = COUNTRY.COUNTRYCODE
		 if @validcnt + @nullcnt != @numrows
		 	begin
			 select @errno  = 30007,
     			 @errmsg = 'Error %d Cannot UPDATE COUNTRYGROUP because COUNTRY does not exist.'
			 goto error
			end
		end

	 /* COUNTRY is part of COUNTRYGROUP ON CHILD UPDATE RESTRICT */
	 if update(MEMBERCOUNTRY)
	 	begin
		 select @nullcnt = 0
		 select @validcnt = count(*)
		 from 	inserted,COUNTRY
		 where 	inserted.MEMBERCOUNTRY = COUNTRY.COUNTRYCODE
		 if @validcnt + @nullcnt != @numrows
			begin
			 select @errno  = 30007,
     			 @errmsg = 'Error %d Cannot UPDATE COUNTRYGROUP because COUNTRY does not exist.'
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
