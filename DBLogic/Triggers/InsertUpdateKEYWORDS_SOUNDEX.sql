	/******************************************************************************************************************/
	/*** RFC4757 Create InsertUpdateKEYWORDS_SOUNDEX trigger									***/
	/******************************************************************************************************************/     
	if exists (select * from sysobjects where type='TR' and name = 'InsertUpdateKEYWORDS_SOUNDEX')
   		begin
    		 PRINT 'Refreshing trigger InsertUpdateKEYWORDS_SOUNDEX...'
    		 DROP TRIGGER InsertUpdateKEYWORDS_SOUNDEX
   		end
  	go

	create trigger InsertUpdateKEYWORDS_SOUNDEX on KEYWORDS for INSERT, UPDATE NOT FOR REPLICATION as
		begin
  		 
		 /* Update SOUNDEX column */
		 if update(KEYWORD)
			begin
				Update KEYWORDS
				Set [SOUNDEX] = dbo.fn_SoundsLike(KEYWORDS.KEYWORD)
				from inserted
				where KEYWORDS.KEYWORDNO = inserted.KEYWORDNO
			end
		end
	go


