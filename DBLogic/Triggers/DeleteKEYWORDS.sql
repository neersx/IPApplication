	/******************************************************************************************************************/
	/*** 10047 Create DeleteKEYWORDS trigger									***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'DeleteKEYWORDS')
		begin
	    	 PRINT 'Refreshing trigger DeleteKEYWORDS...'
	    	 DROP TRIGGER DeleteKEYWORDS
	   	end
	go
	
	create trigger DeleteKEYWORDS on KEYWORDS for DELETE NOT FOR REPLICATION as
		begin

    		 /* KEYWORDS is synonym of SYNONYMS ON PARENT DELETE CASCADE */
    		 delete	SYNONYMS
      		 from 	SYNONYMS,deleted
      		 where  SYNONYMS.KEYWORDNO = deleted.KEYWORDNO

    		 /* KEYWORDS has synonyms SYNONYMS ON PARENT DELETE CASCADE */
    		 delete SYNONYMS
      		 from 	SYNONYMS,deleted
      		 where  SYNONYMS.KWSYNONYM = deleted.KEYWORDNO

		end
	go
