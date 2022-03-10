if exists (select * from sysobjects where type='TR' and name = 'UpdateSYSNONYMS')
begin
	PRINT 'Refreshing trigger UpdateSYSNONYMS...'
	DROP TRIGGER UpdateSYSNONYMS
end
go

CREATE TRIGGER UpdateSYSNONYMS on SYNONYMS for UPDATE NOT FOR REPLICATION as
-- TRIGGER:	UpdateSYSNONYMS  
-- VERSION:	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	MF	17490	2	Ignore if trigger is being fired as a result of the audit details being updated
-- 15 Jul 2009	MF	17869	3	Get @rowcount as first thing in trigger to avoid it getting reset
-- 28 Sep 2012	vql	RFC7887	4	Fix raiserror syntax.
   
declare @numrows int

set @numrows = @@rowcount

If NOT UPDATE(LOGDATETIMESTAMP)
begin
	 declare @nullcnt int,
   		 @validcnt int,
   		 @insKEYWORDNO int, 
   		 @insKWSYNONYM int,
   		 @errno   int,
   		 @errmsg  varchar(255)

	 /* KEYWORDS is synonym of SYNONYMS ON CHILD UPDATE RESTRICT */
	 if update(KEYWORDNO)
		begin
		 select @nullcnt = 0
		 select @validcnt = count(*)
		 from 	inserted,KEYWORDS
		 where	inserted.KEYWORDNO = KEYWORDS.KEYWORDNO
		 if @validcnt + @nullcnt != @numrows
			begin
			 select @errno  = 30007,
     			 @errmsg = 'Error %d Cannot UPDATE SYNONYMS because KEYWORDS does not exist.'
			 goto error
			end
		end

	 /* KEYWORDS has synonyms SYNONYMS ON CHILD UPDATE RESTRICT */
	 if update(KWSYNONYM)
		begin
		 select @nullcnt = 0
		 select @validcnt = count(*)
	 	 from 	inserted,KEYWORDS
		 where  inserted.KWSYNONYM = KEYWORDS.KEYWORDNO
		 if @validcnt + @nullcnt != @numrows
			begin
			 select @errno  = 30007,
     			 @errmsg = 'Error %d Cannot UPDATE SYNONYMS because KEYWORDS does not exist.'
		 	 goto error
			end
		end
	 return
	 error:
	 Raiserror  (@errmsg, 16,1, @errno)
	 rollback transaction
end
go

