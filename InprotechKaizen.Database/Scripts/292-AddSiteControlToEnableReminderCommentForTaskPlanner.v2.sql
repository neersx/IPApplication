
	/******************************************************************************************/
	/*** DR-66865 Add data SITECONTROL.CONTROLID = Reminder Comments Enabled in Task Planner ***/
	/******************************************************************************************/     
	IF NOT exists(SELECT 1 FROM SITECONTROL WHERE CONTROLID = N'Reminder Comments Enabled in Task Planner')
	BEGIN
		PRINT '**** DR-66865 Add data SITECONTROL.CONTROLID = Reminder Comments Enabled in Task Planner ****'
		 
		IF exists(select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME ='SITECONTROLCOMPONENTS')
		BEGIN
			-----------------------------------
			-- Ensure Release Version exists --
			-----------------------------------
			IF not exists(select 1 from RELEASEVERSIONS where VERSIONNAME='Inprotech Apps 7.10')
				insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 7.10', '20201207', 7100000)
			-----------------------------
			-- Ensure Component exists --
			-----------------------------
			IF not exists(select 1 from COMPONENTS where COMPONENTNAME='Task Planner')
				insert into COMPONENTS(COMPONENTNAME,INTERNALNAME)
				values ('Task Planner', 'Task Planner')
			---------------------------
			-- Load the Site Control --
			---------------------------
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLBOOLEAN, VERSIONID, INITIALVALUE, COMMENTS, NOTES)
			select N'Reminder Comments Enabled in Task Planner',
			       N'B',
			       1,
			       VERSIONID,
			       N'True',
			       N'If set to True, users will have the ability to view and maintain Reminder Comments from Task Planner. If set to False, Reminder Comments will be unavailable.',
			       N'If this Site Control is set to True, users will have the ability to view and maintain Reminder Comments from Task Planner. If it is set to False, Reminder Comments will be unavailable for the firm.'
			FROM RELEASEVERSIONS
			WHERE VERSIONNAME='Inprotech Apps 7.10'
			-------------------------------------
			-- Link Site Control to Components --
			-------------------------------------
			INSERT into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
			Select S.ID, C.COMPONENTID
			FROM COMPONENTS C
			join SITECONTROL S on (S.CONTROLID='Reminder Comments Enabled in Task Planner')
			where C.COMPONENTNAME in ('Task Planner')
		End
		Else Begin
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLBOOLEAN, COMMENTS, NOTES)
			VALUES (N'Reminder Comments Enabled in Task Planner', N'B', 1,
			       N'If set to True, users will have the ability to view and maintain Reminder Comments from Task Planner. If set to False, Reminder Comments will be unavailable.',
			       N'If this Site Control is set to True, users will have the ability to view and maintain Reminder Comments from Task Planner. If it is set to False, Reminder Comments will be unavailable for the firm.')
		End
		 
		PRINT '**** DR-66865 Data successfully added to SITECONTROL table ****'
		PRINT ''
	END
	ELSE BEGIN 
		PRINT '**** DR-66865 SITECONTROL.CONTROLID = "Reminder Comments Enabled in Task Planner" already exists ****'
		PRINT ''
	END 