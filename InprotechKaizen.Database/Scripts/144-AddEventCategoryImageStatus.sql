    	/*** RFC71602 New Image Status for Event Category Images (DR-31534)			***/
    	
    	If NOT exists (select 1 from TABLECODES where TABLETYPE = 11 and TABLECODE = -42847001)
        	BEGIN
         	 PRINT '**** RFC71602 Adding data TABLECODES.TABLECODE = -42847001 ****'
		 INSERT INTO TABLECODES (TABLECODE, TABLETYPE, DESCRIPTION)
		 VALUES (-42847001, 11, N'Event Category Icon')
        	 PRINT '**** RFC71602 Data successfully added to TABLECODES table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC71602 TABLECODES.TABLECODE = -42847001 already exists'
         	PRINT ''
    	go


	If NOT exists (select 1 from PROTECTCODES where TABLECODE = -42847001)
	Begin
		PRINT '**** RFC71602 TABLECODE = -42847001 protect codes'
		INSERT INTO PROTECTCODES(PROTECTKEY, TABLECODE) 
		SELECT  ISNULL(MAX(PROTECTKEY), 0) + 1, -42847001 FROM PROTECTCODES
		PRINT '**** RFC71602 Data successfully added to PROTECTCODES table.'
		PRINT ''
	End
	Else
		PRINT '**** RFC71602 PROTECTCODES.TABLECODE = -42847001 already exists'
		PRINT ''
	go


	/*** RFC71602 Set image status for event category images that are not set (DR-31534)		***/
	If exists (select 1 from IMAGEDETAIL I
			join EVENTCATEGORY E on (E.ICONIMAGEID = I.IMAGEID)
			where I.IMAGESTATUS is null)
	Begin
		PRINT '**** RFC71602 updating IMAGEDETAIL.IMAGESTATUS'
			UPDATE I
			SET I.IMAGESTATUS = -42847001
			FROM IMAGEDETAIL I
			join EVENTCATEGORY E on (E.ICONIMAGEID = I.IMAGEID)
			where I.IMAGESTATUS is null
		PRINT '**** RFC71602 Data successfully updated to IMAGEDETAIL table.'
		PRINT ''
	End
	Else
		PRINT '**** RFC71602 Nothing to update on IMAGEDETAIL.IMAGESTATUS'
		PRINT ''
	go


	/*** RFC71602 Reset image status for event category images that are set but are not used in caseimage  (DR-31534)	***/
	If exists (select 1 from IMAGEDETAIL I
			join EVENTCATEGORY E on (E.ICONIMAGEID = I.IMAGEID)
			left join CASEIMAGE C on (C.IMAGEID = I.IMAGEID)
			where I.IMAGESTATUS is not null and C.IMAGEID is null 
			and I.IMAGESTATUS != -42847001)
	Begin
		PRINT '**** RFC71602 updating IMAGEDETAIL.IMAGESTATUS'
			UPDATE I
			SET I.IMAGESTATUS = -42847001
			from IMAGEDETAIL I
			join EVENTCATEGORY E on (E.ICONIMAGEID = I.IMAGEID)
			left join CASEIMAGE C on (C.IMAGEID = I.IMAGEID)
			where I.IMAGESTATUS is not null and C.IMAGEID is null
			and I.IMAGESTATUS != -42847001
		PRINT '**** RFC71602 Data successfully updated to IMAGEDETAIL table.'
		PRINT ''
	End
	Else
		PRINT '**** RFC71602 Nothing to update on IMAGEDETAIL.IMAGESTATUS'
		PRINT ''
	go


	/*** RFC71602 Make a copy of event category images that have been used in caseimage and set the new image status to Event Category Icon (DR-31534)	***/
	If exists (select 1 from IMAGEDETAIL I
			join EVENTCATEGORY E on (E.ICONIMAGEID = I.IMAGEID)
			join CASEIMAGE C on (C.IMAGEID = I.IMAGEID)
			where I.IMAGESTATUS is not null
			and I.IMAGESTATUS != -42847001)
	Begin Try 
		Begin Transaction
			Declare @nInternalCode int
			Declare @nImageId int
			Declare @tImages table (IMAGEID int)
			
			Insert into @tImages
			Select distinct I.IMAGEID
			from IMAGEDETAIL I
			join EVENTCATEGORY E on (E.ICONIMAGEID = I.IMAGEID)
			join CASEIMAGE C on (C.IMAGEID = I.IMAGEID)
			where I.IMAGESTATUS is not null
			and I.IMAGESTATUS != -42847001
			
			Select @nInternalCode = INTERNALSEQUENCE + 1 from LASTINTERNALCODE where TABLENAME = 'IMAGE'
			
			While exists (Select 1 IMAGEID from @tImages)
			Begin
				Print 'RFC71602 Copying event category images (DR-31534)'
				
				Select @nImageId = min(IMAGEID) from @tImages

				Insert into IMAGE (IMAGEID, IMAGEDATA)
				Select @nInternalCode, IMAGEDATA from IMAGE where IMAGEID = @nImageId
				
				Insert into IMAGEDETAIL (IMAGEID, IMAGESTATUS, SCANNEDFLAG, IMAGEDESC, FILELOCATION, CONTENTTYPE)
				Select @nInternalCode, -42847001, SCANNEDFLAG, IMAGEDESC, FILELOCATION, CONTENTTYPE from IMAGEDETAIL where IMAGEID = @nImageId
				
				Update EVENTCATEGORY
				set ICONIMAGEID = @nInternalCode
				where ICONIMAGEID = @nImageId
				
				Set @nInternalCode = @nInternalCode + 1
				
				Delete from @tImages where IMAGEID = @nImageId
			End	

			Update LASTINTERNALCODE set INTERNALSEQUENCE = @nInternalCode where TABLENAME = 'IMAGE'
		Commit Transaction
	End Try
	Begin Catch
		If @@trancount > 0
		Begin
			rollback
		End
		Print 'RFC71602 Insert into IMAGE and IMAGEDETAIL failed (DR-31534)'
	End Catch
	Else Print 'RFC71602 IMAGE and IMAGEDETAIL data already exists (DR-31534)'
	Go