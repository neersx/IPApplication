	
	/******************************************************************************************/
	/*** DR-53818 Add data SITECONTROL.CONTROLID =   ***/
	/******************************************************************************************/     
	If NOT exists(SELECT * FROM SITECONTROL WHERE CONTROLID = N'Policing Continuously Polling Time')
	BEGIN
		If exists(select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME ='SITECONTROLCOMPONENTS')
		Begin
			-----------------------------------
			-- Ensure Release Version exists --
			-----------------------------------
			If not exists(select 1 from RELEASEVERSIONS where VERSIONNAME='Inprotech Apps 7.0')
				insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 7.0', '20191122', 700000)
			---------------------------
			-- Load the Site Control --
			---------------------------
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLINTEGER, VERSIONID, INITIALVALUE, COMMENTS, NOTES)
			select N'Policing Continuously Polling Time',
			       N'I',
			       5,
			       VERSIONID,
			       '5',
			       N'This is only applicable when continuous policing is started in Policing Dashboard.' + char(10) + char(13) +
			       N'Specify the polling delay using seconds. This value determines how often the continuous policing process will check the policing queue, to process the requests.' + char(10) + char(13) +
			       N'The default value is 5 seconds. Any number between 1 and 3600 can be used.',
				   N'Continuous policing will not process requests that are on hold. If Policing Immediately is turned on, it is recommended that the delay specified in the site control is increased, as there will be less requests that require background processing.'
			from RELEASEVERSIONS R
			where VERSIONNAME='Inprotech Apps 7.0'
			-------------------------------------
			-- Link Site Control to Components --
			-------------------------------------
			Insert into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
			Select S.ID, C.COMPONENTID
			from COMPONENTS C
			join SITECONTROL S on (S.CONTROLID='Policing Continuously Polling Time')
			where C.COMPONENTNAME in ('Case', 'Name', 'Policing', 'IP Matter Management')
			
		End
		 
		PRINT '**** DR-53818 Data successfully added to SITECONTROL table ****'
		PRINT ''
	END
	ELSE BEGIN 
		PRINT '**** DR-53818 SITECONTROL.CONTROLID = "Policing Continuously Polling Time" already exists ****'
		PRINT ''
	END 
	go