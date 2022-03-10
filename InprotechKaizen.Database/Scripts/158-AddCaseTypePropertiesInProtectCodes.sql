         /*** R72142 Add CASETYPE 'A' in PROTECTCODES table         ***/      

	 If NOT EXISTS (SELECT 1 FROM PROTECTCODES WHERE CASETYPE = 'A')
	 BEGIN   

                DECLARE @ProtectKey smallint

                Select @ProtectKey = MAX(PROTECTKEY) + 1 from PROTECTCODES 
		PRINT '**** R72142 Adding CASETYPE A in PROTECTCODES table'           
		INSERT INTO PROTECTCODES(PROTECTKEY, CASETYPE) values (@ProtectKey,'A')		 
		PRINT '**** R72142 A has been added in PROTECTCODES.CASETYPE.'
	 END
	 ELSE   
		PRINT '**** R72142 PROTECTCODES.CASETYPE A already exists'
		PRINT ''
	 GO