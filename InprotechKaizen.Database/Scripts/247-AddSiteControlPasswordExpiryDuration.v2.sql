
	/******************************************************************************************/
	/*** DR-48751 Add data SITECONTROL.CONTROLID = Password Expiry Duration   		***/
	/******************************************************************************************/     
	If NOT exists(SELECT * FROM SITECONTROL WHERE CONTROLID = N'Password Expiry Duration')
	BEGIN
		PRINT '**** DR-48751 Add data SITECONTROL.CONTROLID = Password Expiry Duration ****'
		 
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
			select N'Password Expiry Duration',
			       N'I',
			       null,
			       VERSIONID,
			       null,
			       N'Specify the number of days after which staff members must change their sign-in password. The system will display appropriate reminder messages starting a week before the calculated date.',
			       N'A negative number will be considered as null or 0, in which case the password will never expire. It is recommended that you enter a value greater than zero, otherwise passwords may become vulnerable.'
			from RELEASEVERSIONS
			where VERSIONNAME='Inprotech Apps 7.1'
			-------------------------------------
			-- Link Site Control to Components --
			-------------------------------------
			Insert into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
			Select S.ID, C.COMPONENTID
			from COMPONENTS C
			join SITECONTROL S on (S.CONTROLID='Password Expiry Duration')
			where C.COMPONENTNAME in ('Security')
		End
		Else Begin
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLINTEGER, COMMENTS, NOTES)
			VALUES (N'Password Expiry Duration', N'I', null, 
                        N'Specify the number of days after which staff members must change their sign-in password. The system will display appropriate reminder messages starting a week before the calculated date.',
                        N'A negative number will be considered as null or 0, in which case the password will never expire. It is recommended that you enter a value greater than zero, otherwise passwords may become vulnerable.')
		End
		 
		PRINT '**** DR-48751 Data successfully added to SITECONTROL table ****'
		PRINT ''
	END
	ELSE BEGIN 
		PRINT '**** DR-48751 SITECONTROL.CONTROLID = "Password Expiry Duration" already exists ****'
		PRINT ''
	END 

	/******************************************************************************************/
	/*** DR-48751 Add data SITECONTROL.CONTROLID = Password Expiry Duration   		***/
	/******************************************************************************************/     
	If exists(SELECT * FROM SITECONTROL WHERE CONTROLID = N'Enforce Password Policy') and 
        not exists(Select 1 from SITECONTROLCOMPONENTS SC 
                        join COMPONENTS C on SC.COMPONENTID = C.COMPONENTID
			join SITECONTROL S on (SC.SITECONTROLID = S.ID)
			where C.COMPONENTNAME in ('Security') and S.CONTROLID='Enforce Password Policy')
	BEGIN
		PRINT '**** DR-48751 Add data into SITECONTROLCOMPONENTS ****'
		 
		If exists(select 1 from INFORMATION_SCHEMA.TABLES 
			  where TABLE_NAME ='SITECONTROLCOMPONENTS')
		Begin
			-----------------------------
			-- Ensure Component exists --
			-----------------------------
			If not exists(select 1 from COMPONENTS where COMPONENTNAME='Security')
				insert into COMPONENTS(COMPONENTNAME,INTERNALNAME)
				values ('Security', 'Security')

                        DELETE FROM SITECONTROLCOMPONENTS  
                        where SITECONTROLID = (Select ID from SITECONTROL where CONTROLID='Enforce Password Policy')
                        and COMPONENTID in ( Select COMPONENTID from COMPONENTS where COMPONENTNAME in ('Case', 'IP Matter Management'))

                        Insert into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
			Select S.ID, C.COMPONENTID
			from COMPONENTS C
			join SITECONTROL S on (S.CONTROLID='Enforce Password Policy')
			where C.COMPONENTNAME in ('Security')
		End
                PRINT '**** DR-48751 Data successfully added to SITECONTROLCOMPONENTS table ****'
		PRINT ''
	END
	ELSE BEGIN 
		PRINT '**** DR-48751 Security component exists for Enforce Password Policy ****'
		PRINT ''
	END 
