	
	/*** DR-72645 Add data SITECONTROL.CONTROLID = Email Task Planner Subject ***/
	IF NOT exists(SELECT 1 FROM SITECONTROL WHERE CONTROLID = N'Email Task Planner Subject')
	BEGIN
		PRINT '**** DR-72645 Add data SITECONTROL.CONTROLID = Email Task Planner Subject ****'
		 
		IF exists(select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME ='SITECONTROLCOMPONENTS')
		BEGIN
			-----------------------------------
			-- Ensure Release Version exists --
			-----------------------------------
			IF not exists(select 1 from RELEASEVERSIONS where VERSIONNAME='Inprotech Apps 8.1')
				insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 8.1', '20210813', 810000)
			-----------------------------
			-- Ensure Component exists --
			-----------------------------
			IF not exists(select 1 from COMPONENTS where COMPONENTNAME='Task Planner')
				insert into COMPONENTS(COMPONENTNAME,INTERNALNAME)
				values ('Task Planner', 'Task Planner')
			---------------------------
			-- Load the Site Control --
			---------------------------
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, VERSIONID, INITIALVALUE, COMMENTS, NOTES)
			select N'Email Task Planner Subject',
			       N'C',
			       N'EMAIL_TASKPLANNER_SUBJECT',
			       VERSIONID,
			       N'EMAIL_TASKPLANNER_SUBJECT',
			       N'The name of the Data Item to be used for creating the subject line of an email sent from Task Planner.',
				   N'The name of the Data Item to be used for creating the subject line of an email sent for a Reminder, Due Date or Ad Hoc Date from Task Planner.'
			FROM RELEASEVERSIONS
			WHERE VERSIONNAME='Inprotech Apps 8.1'
			-------------------------------------
			-- Link Site Control to Components --
			-------------------------------------
			INSERT into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
			Select S.ID, C.COMPONENTID
			FROM COMPONENTS C
			join SITECONTROL S on (S.CONTROLID='Email Task Planner Subject')
			where C.COMPONENTNAME in ('Task Planner')
		End
		Else Begin
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, COMMENTS, NOTES)
			VALUES (N'Email Task Planner Subject', N'C', N'EMAIL_TASKPLANNER_SUBJECT',
			       N'The name of the Data Item to be used for creating the subject line of an email sent from Task Planner.',
				   N'The name of the Data Item to be used for creating the subject line of an email sent for a Reminder, Due Date or Ad Hoc Date from Task Planner.'
				   )
		End
		 
		PRINT '**** DR-72645 Data successfully added to SITECONTROL table ****'
		PRINT ''
	END
	ELSE BEGIN 
		PRINT '**** DR-72645 SITECONTROL.CONTROLID = "Email Task Planner Subject" already exists ****'
		PRINT ''
	END 
	GO

		
	/*** DR-72645 Add data SITECONTROL.CONTROLID = Email Task Planner Body ***/
	IF NOT exists(SELECT 1 FROM SITECONTROL WHERE CONTROLID = N'Email Task Planner Body')
	BEGIN
		PRINT '**** DR-72645 Add data SITECONTROL.CONTROLID = Email Task Planner Body ****'
		 
		IF exists(select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME ='SITECONTROLCOMPONENTS')
		BEGIN
			-----------------------------------
			-- Ensure Release Version exists --
			-----------------------------------
			IF not exists(select 1 from RELEASEVERSIONS where VERSIONNAME='Inprotech Apps 8.1')
				insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 8.1', '20210813', 810000)
			-----------------------------
			-- Ensure Component exists --
			-----------------------------
			IF not exists(select 1 from COMPONENTS where COMPONENTNAME='Task Planner')
				insert into COMPONENTS(COMPONENTNAME,INTERNALNAME)
				values ('Task Planner', 'Task Planner')
			---------------------------
			-- Load the Site Control --
			---------------------------
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, VERSIONID, INITIALVALUE, COMMENTS, NOTES)
			select N'Email Task Planner Body',
			       N'C',
			       N'EMAIL_TASKPLANNER_BODY',
			       VERSIONID,
			       N'EMAIL_TASKPLANNER_BODY',
			       N'The name of the Data Item to be used for creating the body of an email sent from Task Planner.',
				   N'The name of the Data Item to be used for creating the body of an email sent for a Reminder, Due Date or Ad Hoc Date from Task Planner.'
			FROM RELEASEVERSIONS
			WHERE VERSIONNAME='Inprotech Apps 8.1'
			-------------------------------------
			-- Link Site Control to Components --
			-------------------------------------
			INSERT into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
			Select S.ID, C.COMPONENTID
			FROM COMPONENTS C
			join SITECONTROL S on (S.CONTROLID='Email Task Planner Body')
			where C.COMPONENTNAME in ('Task Planner')
		End
		Else Begin
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLCHARACTER, COMMENTS, NOTES)
			VALUES (N'Email Task Planner Body', N'C', N'EMAIL_TASKPLANNER_BODY',
			       N'The name of the Data Item to be used for creating the body of an email sent from Task Planner.',
				   N'The name of the Data Item to be used for creating the body of an email sent for a Reminder, Due Date or Ad Hoc Date from Task Planner.'
				   )
		End
		 
		PRINT '**** DR-72645 Data successfully added to SITECONTROL table ****'
		PRINT ''
	END
	ELSE BEGIN 
		PRINT '**** DR-72645 SITECONTROL.CONTROLID = "Email Task Planner Body" already exists ****'
		PRINT ''
	END 
	GO

