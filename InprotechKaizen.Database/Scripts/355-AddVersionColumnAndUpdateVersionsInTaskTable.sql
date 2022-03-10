/****************************************************************************/
/************* DR-77379 Add column TASK.VERSIONID ***************************/
/****************************************************************************/

If NOT exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'TASK' AND COLUMN_NAME = 'VERSIONID')
    BEGIN
	PRINT '**** DR-77379 Adding column TASK.VERSIONID'
	ALTER TABLE TASK ADD VERSIONID int NULL
	PRINT '**** DR-77379 Column TASK.VERSIONID added'
END
ELSE
    BEGIN
	PRINT '**** DR-77379 Column TASK.VERSIONID exists already'
END
GO

IF dbo.fn_IsAuditSchemaConsistent('TASK') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'TASK'
END
GO


/****************************************************************************/
/************* DR-77379 Insert RELEASEVERSION data ***************************/
/*****************************************************************************/

--1) Inprotech Apps 6.0
IF NOT EXISTS(SELECT 1 FROM RELEASEVERSIONS where VERSIONNAME = 'Inprotech Apps 6.0')
BEGIN
	INSERT INTO RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 6.0', '20181109', 600000)
	PRINT 'Release Inprotech Apps 6.0 added successfully.'
END
ELSE BEGIN 
	PRINT 'Release Inprotech Apps 6.0 is already exists.'
END

--2) Inprotech Apps 6.2
IF NOT EXISTS(SELECT 1 FROM RELEASEVERSIONS where VERSIONNAME = 'Inprotech Apps 6.2')
BEGIN
	INSERT INTO RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 6.2', '20190201', 620000)
	PRINT 'Release Inprotech Apps 6.2 added successfully.'
END
ELSE BEGIN 
	PRINT 'Release Inprotech Apps 6.2 is already exists.'
END

--3) Inprotech Apps 6.3
IF NOT EXISTS(SELECT 1 FROM RELEASEVERSIONS where VERSIONNAME = 'Inprotech Apps 6.3')
BEGIN
	INSERT INTO RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 6.3', '20190315', 630000)
	PRINT 'Release Inprotech Apps 6.3 added successfully.'
END
ELSE BEGIN 
	PRINT 'Release Inprotech Apps 6.3 is already exists.'
END

--4) Inprotech Apps 7.5
IF NOT EXISTS(SELECT 1 FROM RELEASEVERSIONS where VERSIONNAME = 'Inprotech Apps 7.5')
BEGIN
	INSERT INTO RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 7.5', '20200619', 750000)
	PRINT 'Release Inprotech Apps 7.5 added successfully.'
END
ELSE BEGIN 
	PRINT 'Release Inprotech Apps 7.5 is already exists.'
END

--5) Inprotech Apps 7.9
IF NOT EXISTS(SELECT 1 FROM RELEASEVERSIONS where VERSIONNAME = 'Inprotech Apps 7.9')
BEGIN
	INSERT INTO RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 7.9', '20211217', 840000)
	PRINT 'Release Inprotech Apps 7.9 added successfully.'
END
ELSE BEGIN 
	PRINT 'Release Inprotech Apps 7.9 is already exists.'
END

--6) Inprotech Apps 7.12
IF NOT EXISTS(SELECT 1 FROM RELEASEVERSIONS where VERSIONNAME = 'Inprotech Apps 7.12')
BEGIN
	INSERT INTO RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 7.12', '20210409', 7120000)
	PRINT 'Release Inprotech Apps 7.12 added successfully.'
END
ELSE BEGIN 
	PRINT 'Release Inprotech Apps 7.12 is already exists.'
END

--7) Inprotech Apps 8.2
IF NOT EXISTS(SELECT 1 FROM RELEASEVERSIONS where VERSIONNAME = 'Inprotech Apps 8.2')
BEGIN
	INSERT INTO RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 8.2', '20210409', 820000)
	PRINT 'Release Inprotech Apps 8.2 added successfully.'
END
ELSE BEGIN 
	PRINT 'Release Inprotech Apps 8.2 is already exists.'
END

--8) Inprotech Apps 8.4
IF NOT EXISTS(SELECT 1 FROM RELEASEVERSIONS where VERSIONNAME = 'Inprotech Apps 8.4')
BEGIN
	INSERT INTO RELEASEVERSIONS(VERSIONNAME, RELEASEDATE, SEQUENCE)
				values(N'Inprotech Apps 8.4', '20211217', 840000)
	PRINT 'Release Inprotech Apps 8.4 added successfully.'
END
ELSE BEGIN 
	PRINT 'Release Inprotech Apps 8.4 is already exists.'
END



GO
/****************************************************************************/
/************* DR-77379 Update TASK.VERSIONID data ***************************/
/****************************************************************************/

--1) Configure USPTO Practitioner Sponsorship
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 6.2') and TASKID=215)

BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 6.2')
where TASKID = 215;
	PRINT 'Updated VERSIONID of Configure USPTO Practitioner Sponsorship'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Configure USPTO Practitioner Sponsorship'
END

-- 2) Consolidate Names
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 6.0')and TASKID=278)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 6.0')
where TASKID = 278;
	PRINT 'Updated VERSIONID of Consolidate Names'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Consolidate Names'
END

-- 3) Show Links for Inprotech Web
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 6.0') and TASKID=279) 
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 6.0')
where TASKID = 279;
	PRINT 'Updated VERSIONID of Show Links for Inprotech Web'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Show Links for Inprotech Web'
END

--4) Submit HMRC VAT Returns
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 6.3')and TASKID=280)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 6.3')
	where TASKID = 280;
	PRINT 'Updated VERSIONID of Submit HMRC VAT Returns'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Submit HMRC VAT Returns'
END

--5) Store HMRC Settings
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 6.3')and TASKID=281)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 6.3')
	where TASKID = 281;
	PRINT 'Updated VERSIONID of Store HMRC Settings'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Store HMRC Settings'
END

--6) Maintain Time in Time Recording
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 7.1')and TASKID=282)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 7.1')
	where TASKID = 282;
	PRINT 'Updated VERSIONID of Maintain Time in Time Recording'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Maintain Time in Time Recording'
END

--7) Configure Reporting Services Integration
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 7.5')and TASKID=283)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 7.5')
	where TASKID = 283;
	PRINT 'Updated VERSIONID of Configure Reporting Services Integration'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Configure Reporting Services Integration'
END

-- 8) Maintain Task Planner Search Columns 
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 7.10')and TASKID=284)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 7.10')
	where TASKID = 284;
	PRINT 'Updated VERSIONID of Maintain Task Planner Search Columns'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Maintain Task Planner Search Columns'
END

-- 9)Configure Attachments Service 
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 7.9')and TASKID=285)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 7.9')
	where TASKID = 285;
	PRINT 'Updated VERSIONID of Configure Attachments Service'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Configure Attachments Service'
END

--10) Task Planner Application
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 7.10')and TASKID=286)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 7.10')
	where TASKID = 286;
	PRINT 'Updated VERSIONID of Task Planner Application'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Task Planner Application'
END

--11) Replace Event Notes
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 7.12')and TASKID=287)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 7.12')
	where TASKID = 287;
	PRINT 'Updated VERSIONID of Replace Event Notes'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Replace Event Notes'
END


--12) Maintain Task Planner Search
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 8')and TASKID=288)
BEGIN 
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 8')
	where TASKID = 288;
	PRINT 'Updated VERSIONID of Maintain Task Planner Search'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Maintain Task Planner Search'
END

--13) Maintain Recordal Type
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 8.1')and TASKID=289)
BEGIN 
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 8.1')
	where TASKID = 289;
	PRINT 'Updated VERSIONID of Maintain Recordal Type'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Maintain Recordal Type'
END

--14) Maintain Prior Art Attachments
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 8.2')and TASKID=290)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 8.2')
	where TASKID = 290;
	PRINT 'Updated VERSIONID of Maintain Prior Art Attachments'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Maintain Prior Art Attachments'
END

--15) Maintain Task Planner
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 8.2')and TASKID=291)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 8.2')
	where TASKID = 291;
	PRINT 'Updated VERSIONID of Maintain Task Planner'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Maintain Task Planner'
END

--16) Disbursement Dissection
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 8.4')and TASKID=292)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 8.4')
	where TASKID = 292;
	PRINT 'Updated VERSIONID of Disbursement Dissection'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Disbursement Dissection'
END

--17) Change Due Date Responsibility
IF NOT EXISTS(SELECT 1 FROM TASK where VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 8.4')and TASKID=293)
BEGIN
	UPDATE TASK set VERSIONID = (select VERSIONID from RELEASEVERSIONS where VERSIONNAME = N'Inprotech Apps 8.4')
	where TASKID = 293;
	PRINT 'Updated VERSIONID of Change Due Date Responsibility'
END
ELSE BEGIN 
	PRINT 'VERSIONID is already available for Change Due Date Responsibility'
END

GO