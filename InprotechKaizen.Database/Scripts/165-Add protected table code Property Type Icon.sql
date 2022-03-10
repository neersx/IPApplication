	/*** RFC72426 New Image Status for Property Type Icons (DR-34859)			***/
    	
    	If NOT exists (select 1 from TABLECODES where TABLETYPE = 11 and TABLECODE = -42847002)
        	BEGIN
         	 PRINT '**** RFC72426 Adding data TABLECODES.TABLECODE = -42847002 ****'
		 INSERT INTO TABLECODES (TABLECODE, TABLETYPE, DESCRIPTION)
		 VALUES (-42847002, 11, N'Property Type Icon')
        	 PRINT '**** RFC72426 Data successfully added to TABLECODES table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** RFC72426 TABLECODES.TABLECODE = -42847002 already exists'
         	PRINT ''
    	go
    	
    	
	If NOT exists (select 1 from PROTECTCODES where TABLECODE = -42847002)
	Begin
		PRINT '**** RFC72426 TABLECODE = -42847002 protect codes'
		INSERT INTO PROTECTCODES(PROTECTKEY, TABLECODE) 
		SELECT  ISNULL(MAX(PROTECTKEY), 0) + 1, -42847002 FROM PROTECTCODES
		PRINT '**** RFC72426 Data successfully added to PROTECTCODES table.'
		PRINT ''
	End
	Else
		PRINT '**** RFC72426 PROTECTCODES.TABLECODE = -42847002 already exists'
		PRINT ''
	go