/*** DR-79354 Add data SITECONTROL.CONTROLID = DB Release Revision ***/
	IF NOT exists(SELECT 1 FROM SITECONTROL WHERE CONTROLID = N'DB Release Revision')
	BEGIN
		PRINT '**** DR-79354 Add data SITECONTROL.CONTROLID = DB Release Revision ****'
		 
		IF exists(select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME ='SITECONTROLCOMPONENTS')
		BEGIN
			-----------------------------------
			-- Ensure Release Version exists --
			-----------------------------------
			IF not exists(select 1 from RELEASEVERSIONS where VERSIONNAME='Inprotech Apps 8.6')
				insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 8.6', '20220318', 860000)
			-----------------------------
			-- Ensure Component exists --
			-----------------------------
			IF not exists(select 1 from COMPONENTS where COMPONENTNAME='Inprotech')
				insert into COMPONENTS(COMPONENTNAME,INTERNALNAME)
				values ('Inprotech', 'Inprotech')
			---------------------------
			-- Load the Site Control --
			---------------------------
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, VERSIONID, INITIALVALUE, COMMENTS, NOTES)
			select N'DB Release Revision',
			       N'C',
			       null,
			       VERSIONID,
			       null,
			       N'This is an indicator of the Inprotech Retrofit version installed and is updated with every Retrofit installation for the major release.',
				   N'This is an indicator of the Inprotech Retrofit version installed and is updated with every Retrofit installation for the major release.'
			FROM RELEASEVERSIONS
			WHERE VERSIONNAME='Inprotech Apps 8.6'
			-------------------------------------
			-- Link Site Control to Components --
			-------------------------------------
			INSERT into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
			Select S.ID, C.COMPONENTID
			FROM COMPONENTS C
			join SITECONTROL S on (S.CONTROLID='DB Release Revision')
			where C.COMPONENTNAME in ('Inprotech')
		End
		Else Begin
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, COMMENTS, NOTES)
			VALUES (N'DB Release Revision', N'C', null,
			       N'This is an indicator of the Inprotech Retrofit version installed and is updated with every Retrofit installation for the major release.',
				   N'This is an indicator of the Inprotech Retrofit version installed and is updated with every Retrofit installation for the major release.'
				   )
		End
		 
		PRINT '**** DR-79354 Data successfully added to SITECONTROL table ****'
		PRINT ''
	END
	ELSE BEGIN 
		PRINT '**** DR-79354 SITECONTROL.CONTROLID = "DB Release Revision" already exists ****'
		PRINT ''
	END 
	GO