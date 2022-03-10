
	/******************************************************************************************/
	/*** DR-48752 Add data SITECONTROL.CONTROLID = Password Used History   		***/
	/******************************************************************************************/     
	If NOT exists(SELECT * FROM SITECONTROL WHERE CONTROLID = N'Password Used History')
	BEGIN
		PRINT '**** DR-48752 Add data SITECONTROL.CONTROLID = Password Used History ****'
		 
		If exists(select 1 from INFORMATION_SCHEMA.TABLES 
			  where TABLE_NAME ='SITECONTROLCOMPONENTS')
		Begin
			-----------------------------------
			-- Ensure Release Version exists --
			-----------------------------------
			If not exists(select 1 from RELEASEVERSIONS where VERSIONNAME='Inprotech Apps 7.1')
				insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 7.1', '20200103', 710000)
			-----------------------------
			-- Ensure Component exists --
			-----------------------------
			If not exists(select 1 from COMPONENTS where COMPONENTNAME='Security')
				insert into COMPONENTS(COMPONENTNAME,INTERNALNAME)
				values ('Security', 'Security')
			---------------------------
			-- Load the Site Control --
			---------------------------
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLINTEGER, VERSIONID, INITIALVALUE, COMMENTS, NOTES)
			select N'Password Used History',
			       N'I',
			       5,
			       VERSIONID,
			       5,
			       N'Specify the number of recently used passwords that cannot be reused while changing the sign in password for Inprotech.',
			       N'If set to zero (0), the last used password security does not apply and a recently used password can be used.'
			from RELEASEVERSIONS
			where VERSIONNAME='Inprotech Apps 7.1'
			-------------------------------------
			-- Link Site Control to Components --
			-------------------------------------
			Insert into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
			Select S.ID, C.COMPONENTID
			from COMPONENTS C
			join SITECONTROL S on (S.CONTROLID='Password Used History')
			where C.COMPONENTNAME in ('Security')
		End
		Else Begin
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLINTEGER, COMMENTS, NOTES)
			VALUES (N'Password Used History', N'I', 5, 
                        N'Specify the number of recently used passwords that cannot be reused while changing the sign in password for Inprotech.',
                        N'If set to zero (0), the last used password security does not apply and a recently used password can be used.')
		End
		 
		PRINT '**** DR-48752 Data successfully added to SITECONTROL table (DR-38850) ****'
		PRINT ''
	END
	ELSE BEGIN 
		PRINT '**** DR-48752 SITECONTROL.CONTROLID = "Password Used History" already exists (DR-38850) ****'
		PRINT ''
	END 
