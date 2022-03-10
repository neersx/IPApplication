if exists (select * from sysobjects where type='TR' and name = 'UpdateKEYWORDS')
begin
	PRINT 'Refreshing trigger UpdateKEYWORDS...'
	DROP TRIGGER UpdateKEYWORDS
end
go

CREATE TRIGGER UpdateKEYWORDS on KEYWORDS for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateKEYWORDS  
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
   		 @insKEYWORDNO int,
   		 @errno   int,
   		 @errmsg  varchar(255)

	 /* KEYWORDS is synonym of SYNONYMS ON PARENT UPDATE RESTRICT */
	 if update(KEYWORDNO)
	 	begin
		 if exists (select * from deleted,SYNONYMS
			    where SYNONYMS.KEYWORDNO = deleted.KEYWORDNO)
			begin
			 select @errno  = 30005,
     			 @errmsg = 'Error %d Cannot UPDATE KEYWORDS because SYNONYMS exists.'
			 goto error
			end
		end

	 /* KEYWORDS has synonyms SYNONYMS ON PARENT UPDATE RESTRICT */
	 if update(KEYWORDNO)
	 	begin
		 if exists (select * from deleted,SYNONYMS
			    where SYNONYMS.KWSYNONYM = deleted.KEYWORDNO)
			begin
      			 select @errno  = 30005,
     			 @errmsg = 'Error %d Cannot UPDATE KEYWORDS because SYNONYMS exists.'
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


