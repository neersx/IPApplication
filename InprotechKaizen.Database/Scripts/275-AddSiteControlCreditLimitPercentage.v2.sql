
	/******************************************************************************************/
	/*** DR-59384 Add data SITECONTROL.CONTROLID = Credit Limit Warning Percentage   		***/
	/******************************************************************************************/     
	If NOT exists(SELECT * FROM SITECONTROL WHERE CONTROLID = N'Credit Limit Warning Percentage')
	BEGIN
		PRINT '**** DR-59384 Add data SITECONTROL.CONTROLID = Credit Limit Warning Percentage ****'
		 
		If exists(select 1 from INFORMATION_SCHEMA.TABLES 
			  where TABLE_NAME ='SITECONTROLCOMPONENTS')
		Begin
			-----------------------------------
			-- Ensure Release Version exists --
			-----------------------------------
			If not exists(select 1 from RELEASEVERSIONS where VERSIONNAME='Inprotech Apps 7.7')
				insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 7.7', '20200911', 770000)
			-----------------------------
			-- Ensure Component exists --
			-----------------------------
			If not exists(select 1 from COMPONENTS where COMPONENTNAME='Time Recording')
				insert into COMPONENTS(COMPONENTNAME,INTERNALNAME)
				values ('Time Recording', 'Time Recording')
			---------------------------
			-- Load the Site Control --
			---------------------------
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLINTEGER, VERSIONID, INITIALVALUE, COMMENTS, NOTES)
			select N'Credit Limit Warning Percentage',
			       N'I',
			       100,
			       VERSIONID,
			       null,
			       N'The percentage of a client''s credit limit that must be used for a warning to display in Time Recording (Apps). By default, the percentage used must be 100%. When set to zero no warning is displayed.',
			       N''
			from RELEASEVERSIONS
			where VERSIONNAME='Inprotech Apps 7.7'
			-------------------------------------
			-- Link Site Control to Components --
			-------------------------------------
			Insert into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
			Select S.ID, C.COMPONENTID
			from COMPONENTS C
			join SITECONTROL S on (S.CONTROLID='Credit Limit Warning Percentage')
			where C.COMPONENTNAME in ('Time Recording')
		End
		Else Begin
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLINTEGER, COMMENTS, NOTES)
			VALUES (N'Credit Limit Warning Percentage', N'I', 100, 
                        N'The percentage of a client''s credit limit that must be used for a warning to display in Time Recording (Apps). By default, the percentage used must be 100%. When set to zero no warning is displayed.',
                        N'')
		End
		 
		PRINT '**** DR-59384 Data successfully added to SITECONTROL table ****'
		PRINT ''
	END
	ELSE BEGIN 
		PRINT '**** DR-59384 SITECONTROL.CONTROLID = "Credit Limit Warning Percentage" already exists ****'
		PRINT ''
	END 
	If exists (select 1 from RELEASEVERSIONS where VERSIONNAME='Inprotech Apps 7.7' and SEQUENCE = '710000')
		   update RELEASEVERSIONS set SEQUENCE = '770000' where VERSIONNAME='Inprotech Apps 7.7'
	Go