	
	/*** DR-72547 Add data SITECONTROL.CONTROLID = Due Date Event Threshold for Task Planner ***/
	IF NOT exists(SELECT 1 FROM SITECONTROL WHERE CONTROLID = N'Due Date Event Threshold for Task Planner')
	BEGIN
		PRINT '**** DR-72547 Add data SITECONTROL.CONTROLID = Due Date Event Threshold for Task Planner ****'
		 
		IF exists(select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME ='SITECONTROLCOMPONENTS')
		BEGIN
			-----------------------------------
			-- Ensure Release Version exists --
			-----------------------------------
			IF not exists(select 1 from RELEASEVERSIONS where VERSIONNAME='Inprotech Apps 8')
				insert into RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 8', '20210702', 800000)
			-----------------------------
			-- Ensure Component exists --
			-----------------------------
			IF not exists(select 1 from COMPONENTS where COMPONENTNAME='Task Planner')
				insert into COMPONENTS(COMPONENTNAME,INTERNALNAME)
				values ('Task Planner', 'Task Planner')
			---------------------------
			-- Load the Site Control --
			---------------------------
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLINTEGER, VERSIONID, INITIALVALUE, COMMENTS, NOTES)
			select N'Due Date Event Threshold for Task Planner',
			       N'I',
			       100000,
			       VERSIONID,
			       N'100000',
			       N'A performance tuning setting for Task Planner to vary how the underlying SQL is constructed for reporting Due Dates and Reminders. If the number of rows in the Events table exceeds the integer value here, then temporary tables will be created internally
 prior to final query. We have found that on some databases with extremely large numbers of Events the temporary table method creates a performance boost, whereas on other databases it can create an overhead that slows the query down.',
			       N'A typical Inprotech database will have less than 100,000 Events defined, so we have used that as our default setting for Task Planner. If you change this number to be lower than the number of Events defined in the database, the queries returning Due Dates and/or Reminders will load some data into temporary tables before then running the final query to return what needs to be reported.'
			FROM RELEASEVERSIONS
			WHERE VERSIONNAME='Inprotech Apps 8'
			-------------------------------------
			-- Link Site Control to Components --
			-------------------------------------
			INSERT into SITECONTROLCOMPONENTS(SITECONTROLID, COMPONENTID)
			Select S.ID, C.COMPONENTID
			FROM COMPONENTS C
			join SITECONTROL S on (S.CONTROLID='Due Date Event Threshold for Task Planner')
			where C.COMPONENTNAME in ('Task Planner')
		End
		Else Begin
			INSERT INTO SITECONTROL (CONTROLID, DATATYPE, COLINTEGER, COMMENTS, NOTES)
			VALUES (N'Due Date Event Threshold for Task Planner', N'I', 100000,
			       N'A performance tuning setting for Task Planner to vary how the underlying SQL is constructed for reporting Due Dates and Reminders. If the number of rows in the Events table exceeds the integer value here, then temporary tables will be created internally
 prior to final query. We have found that on some databases with extremely large numbers of Events the temporary table method creates a performance boost, whereas on other databases it can create an overhead that slows the query down.',
			       N'A typical Inprotech database will have less than 100,000 Events defined, so we have used that as our default setting for Task Planner. If you change this number to be lower than the number of Events defined in the database, the queries returning Due Dates and/or Reminders will load some data into temporary tables before then running the final query to return what needs to be reported.')
		End
		 
		PRINT '**** DR-72547 Data successfully added to SITECONTROL table ****'
		PRINT ''
	END
	ELSE BEGIN 
		PRINT '**** DR-72547 SITECONTROL.CONTROLID = "Due Date Event Threshold for Task Planner" already exists ****'
		PRINT ''
	END 
	GO

/*********** DR-72547  Copy sitecontrol 'Due Date Event Threshhold' value into sitecontrol 'Due Date Event Threshold for Task Planner' *************************************/
IF Exists (SELECT 1 FROM SITECONTROL 
					WHERE CONTROLID = 'Due Date Event Threshhold'
					AND COLINTEGER <> 100000 )
BEGIN
PRINT '***** UPDATING SITECONTROL ''Due Date Event Threshold for Task Planner'' ***** '
Declare @nExistingValue int
SELECT @nExistingValue = COLINTEGER  FROM SITECONTROL WHERE CONTROLID = 'Due Date Event Threshhold' 
UPDATE SITECONTROL 
SET COLINTEGER = @nExistingValue
 WHERE CONTROLID = 'Due Date Event Threshold for Task Planner'  
PRINT '***** UPDATED SITECONTROL ''Due Date Event Threshold for Task Planner'' ***** '
END