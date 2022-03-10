	/******************************************************************************************************************/
	/*** 10047 Create InsertSYSNONYMS trigger									***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'InsertSYSNONYMS')
   		begin
    		 PRINT 'Refreshing trigger InsertSYSNONYMS...'
    		 DROP TRIGGER InsertSYSNONYMS
   		end
  	go

	create trigger InsertSYSNONYMS on SYNONYMS for INSERT NOT FOR REPLICATION as
		begin
  		 declare @numrows int,
           		 @nullcnt int,
           		 @validcnt int,
           		 @errno   int,
           		 @errmsg  varchar(255)
  		 select  @numrows = @@rowcount

  		 /* KEYWORDS is synonym of SYNONYMS ON CHILD INSERT RESTRICT */
  		 if update(KEYWORDNO)
  			begin
    			 select @nullcnt = 0
    			 select @validcnt = count(*)
      			 from inserted,KEYWORDS
        		 where inserted.KEYWORDNO = KEYWORDS.KEYWORDNO
    			 if @validcnt + @nullcnt != @numrows
    				begin
      				 select @errno  = 30002,
             			 @errmsg = 'Error %d Cannot INSERT SYNONYMS because KEYWORDS does not exist.'
      				 goto error
    				end
  			end

  		 /* KEYWORDS has synonyms SYNONYMS ON CHILD INSERT RESTRICT */
  		 if update(KWSYNONYM)
  			begin
    			 select @nullcnt = 0
    			 select @validcnt = count(*)
      			 from inserted,KEYWORDS
        		 where inserted.KWSYNONYM = KEYWORDS.KEYWORDNO
    			 if @validcnt + @nullcnt != @numrows	
    				begin
      				 select @errno  = 30002,
             			 @errmsg = 'Error % Cannot INSERT SYNONYMS because KEYWORDS does not exist.'
      				 goto error
    				end
  			end

  		 return
		 error:
    		 Raiserror  (@errmsg, 16,1, @errno)
    		 rollback transaction
		end
	go


