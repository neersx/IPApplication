/**********************************************************************************************************/
/*** DR-63493 Instructor Column for Task Planner														***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'Instructor' AND PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYDATAITEM.PROCEDUREITEMID = Instructor'
	INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
		DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
	select N'Instructor', NULL, N'A', 0, 0, N'The name providing instructions for the case.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
	from QUERYDATAITEM 
	PRINT '**** DR-63493 Data successfully added to QUERYDATAITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYDATAITEM.PROCEDUREITEMID = Instructor already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN ON
go

Declare @nColumnId int 
Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
				JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
				WHERE DI.PROCEDUREITEMID = N'Instructor'
				AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar)
	INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
	SELECT cast(@nColumnId as nvarchar), N'Instructor', N'The name providing instructions for the case.', NULL, DI.DATAITEMID
	FROM QUERYDATAITEM DI
	WHERE DI.PROCEDUREITEMID = N'Instructor'
	AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) + ' already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN OFF
go

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'Instructor'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
If NOT exists(SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970'
	INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
	VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
	PRINT '**** DR-63493 Data successfully added to QUERYCONTEXTCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970 already exists'
	PRINT ''
go

If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9711)
BEGIN
	PRINT '**** DR-63493 Adding data IMPLIEDDATAID = 9711'
	INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
	SELECT 9711, DATAITEMID, N'NameDetails', N'Link to name details from Instructor.', 970
	FROM QUERYDATAITEM
	WHERE PROCEDUREITEMID = N'Instructor'
	AND PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYIMPLIEDDATA table.'
PRINT ''
END
ELSE
	PRINT '**** DR-63493 IMPLIEDDATAID = 9711 already exists'
	PRINT ''
go

If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9711 AND SEQUENCENO = 1)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9711 AND SEQUENCENO = 1'
	INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
	VALUES (9711, 1, N'InstructorKey', 0, N'InstructorKey', N'ipw_TaskPlanner')
	PRINT '**** DR-63493 Data successfully added to QUERYIMPLIEDITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYIMPLIEDITEM IMPLIEDDATAID = 9711 AND SEQUENCENO = 1 already exists'
	PRINT ''
go

If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9711 AND SEQUENCENO = 2)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9711 AND SEQUENCENO = 2'
	INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
	VALUES (9711, 2, N'Instructor', 0, NULL, N'ipw_TaskPlanner')
	PRINT '**** DR-63493 Data successfully added to QUERYIMPLIEDITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYIMPLIEDITEM IMPLIEDDATAID = 9706 AND SEQUENCENO = 2 already exists'
	PRINT ''
go


/**********************************************************************************************************/
/*** DR-63493 Owners Column for Task Planner														    ***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'Owners' AND PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYDATAITEM.PROCEDUREITEMID = Owners'
	INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
		DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
	select N'Owners', NULL, N'A', 0, 0, N'The full list of Owners associated with the case, separated by semi-colons.', isnull(max(DATAITEMID),0)+1, 9107, NULL, N'ipw_TaskPlanner', NULL, NULL
	from QUERYDATAITEM 
	PRINT '**** DR-63493 Data successfully added to QUERYDATAITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYDATAITEM.PROCEDUREITEMID = Owners already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN ON
go

Declare @nColumnId int 
Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
				JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
				WHERE DI.PROCEDUREITEMID = N'Owners'
				AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar)
	INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
	SELECT cast(@nColumnId as nvarchar), N'Owners', N'The full list of Owners associated with the case, separated by semi-colons.', NULL, DI.DATAITEMID
	FROM QUERYDATAITEM DI
	WHERE DI.PROCEDUREITEMID = N'Owners'
	AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) + ' already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN OFF
go

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'Owners'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
If NOT exists(SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970'
	INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
	VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
	PRINT '**** DR-63493 Data successfully added to QUERYCONTEXTCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970 already exists'
	PRINT ''
go

/**********************************************************************************************************/
/*** DR-63493 Official No. Column for Task Planner														***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'CurrentOfficialNumber' AND PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYDATAITEM.PROCEDUREITEMID = CurrentOfficialNumber'
	INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
		DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
	select N'CurrentOfficialNumber', NULL, N'A', 0, 0, N'The current official number for the case.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
	from QUERYDATAITEM 
	PRINT '**** DR-63493 Data successfully added to QUERYDATAITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYDATAITEM.PROCEDUREITEMID = CurrentOfficialNumber already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN ON
go

Declare @nColumnId int 
Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
				JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
				WHERE DI.PROCEDUREITEMID = N'CurrentOfficialNumber'
				AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar)
	INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
	SELECT cast(@nColumnId as nvarchar), N'Official No.', N'The current official number for the case.', NULL, DI.DATAITEMID
	FROM QUERYDATAITEM DI
	WHERE DI.PROCEDUREITEMID = N'CurrentOfficialNumber'
	AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) + ' already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN OFF
go

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'CurrentOfficialNumber'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
If NOT exists(SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970'
	INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
	VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
	PRINT '**** DR-63493 Data successfully added to QUERYCONTEXTCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970 already exists'
	PRINT ''
go

If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9713)
BEGIN
	PRINT '**** DR-63493 Adding data IMPLIEDDATAID = 9713'
	INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
	SELECT 9713, DATAITEMID, N'CaseDetails', N'Link to case details from official number.', 970
	FROM QUERYDATAITEM
	WHERE PROCEDUREITEMID = N'CurrentOfficialNumber'
	AND PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYIMPLIEDDATA table.'
PRINT ''
END
ELSE
	PRINT '**** DR-63493 IMPLIEDDATAID = 9713 already exists'
	PRINT ''
go

If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9713 AND SEQUENCENO = 1)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9713 AND SEQUENCENO = 1'
	INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
	VALUES (9713, 1, N'CaseKey', 0, N'CaseKey', N'ipw_TaskPlanner')
	PRINT '**** DR-63493 Data successfully added to QUERYIMPLIEDITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYIMPLIEDITEM IMPLIEDDATAID = 9713 AND SEQUENCENO = 1 already exists'
	PRINT ''
go

If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9713 AND SEQUENCENO = 2)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9713 AND SEQUENCENO = 2'
	INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
	VALUES (9713, 2, N'CurrentOfficialNumber', 0, NULL, N'ipw_TaskPlanner')
	PRINT '**** DR-63493 Data successfully added to QUERYIMPLIEDITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYIMPLIEDITEM IMPLIEDDATAID = 9713 AND SEQUENCENO = 2 already exists'
	PRINT ''
go

/**********************************************************************************************************/
/*** DR-63493 Jurisdiction Code Column for Task Planner													***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'CountryCode' AND PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYDATAITEM.PROCEDUREITEMID = CountryCode'
	INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
		DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
	select N'CountryCode', NULL, N'A', 0, 0, N'The code for the jurisdiction.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
	from QUERYDATAITEM 
	PRINT '**** DR-63493 Data successfully added to QUERYDATAITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYDATAITEM.PROCEDUREITEMID = CountryCode already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN ON
go

Declare @nColumnId int 
Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
				JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
				WHERE DI.PROCEDUREITEMID = N'CountryCode'
				AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar)
	INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
	SELECT cast(@nColumnId as nvarchar), N'Jurisdiction Code', N'The code for the jurisdiction.', NULL, DI.DATAITEMID
	FROM QUERYDATAITEM DI
	WHERE DI.PROCEDUREITEMID = N'CountryCode'
	AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) + ' already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN OFF
go

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'CountryCode'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
If NOT exists(SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970'
	INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
	VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
	PRINT '**** DR-63493 Data successfully added to QUERYCONTEXTCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970 already exists'
	PRINT ''
go

/**********************************************************************************************************/
/*** DR-63493 Importance Column for Task Planner	    												***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'ImportanceDescription' AND PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYDATAITEM.PROCEDUREITEMID = ImportanceDescription'
	INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
		DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
	select N'ImportanceDescription', NULL, N'A', 0, 0, N'A description of the importance of the due date.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
	from QUERYDATAITEM 
	PRINT '**** DR-63493 Data successfully added to QUERYDATAITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYDATAITEM.PROCEDUREITEMID = ImportanceDescription already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN ON
go

Declare @nColumnId int 
Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
				JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
				WHERE DI.PROCEDUREITEMID = N'ImportanceDescription'
				AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar)
	INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
	SELECT cast(@nColumnId as nvarchar), N'Importance', N'A description of the importance of the due date.', NULL, DI.DATAITEMID
	FROM QUERYDATAITEM DI
	WHERE DI.PROCEDUREITEMID = N'ImportanceDescription'
	AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) + ' already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN OFF
go

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'ImportanceDescription'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
If NOT exists(SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970'
	INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
	VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
	PRINT '**** DR-63493 Data successfully added to QUERYCONTEXTCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970 already exists'
	PRINT ''
go

/**********************************************************************************************************/
/*** DR-63493 Event No. Column for Task Planner	          												***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'EventNumber' AND PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYDATAITEM.PROCEDUREITEMID = EventNumber'
	INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
		DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
	select N'EventNumber', NULL, N'A', 0, 0, N'The internal number of the event.', isnull(max(DATAITEMID),0)+1, 9101, NULL, N'ipw_TaskPlanner', NULL, NULL
	from QUERYDATAITEM 
	PRINT '**** DR-63493 Data successfully added to QUERYDATAITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYDATAITEM.PROCEDUREITEMID = EventNumber already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN ON
go

Declare @nColumnId int 
Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
				JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
				WHERE DI.PROCEDUREITEMID = N'EventNumber'
				AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar)
	INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
	SELECT cast(@nColumnId as nvarchar), N'Event No.', N'The internal number of the event.', NULL, DI.DATAITEMID
	FROM QUERYDATAITEM DI
	WHERE DI.PROCEDUREITEMID = N'EventNumber'
	AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) + ' already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN OFF
go

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'EventNumber'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
If NOT exists(SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970'
	INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
	VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
	PRINT '**** DR-63493 Data successfully added to QUERYCONTEXTCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970 already exists'
	PRINT ''
go

/**********************************************************************************************************/
/*** DR-63493 Case Status Column for Task Planner           											***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'StatusDescription' AND PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYDATAITEM.PROCEDUREITEMID = StatusDescription'
	INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
		DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
	select N'StatusDescription', NULL, N'A', 0, 0, N'The status of the case. See also Renewal Status.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
	from QUERYDATAITEM 
	PRINT '**** DR-63493 Data successfully added to QUERYDATAITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYDATAITEM.PROCEDUREITEMID = StatusDescription already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN ON
go

Declare @nColumnId int 
Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
				JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
				WHERE DI.PROCEDUREITEMID = N'StatusDescription'
				AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar)
	INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
	SELECT cast(@nColumnId as nvarchar), N'Case Status', N'The status of the case. See also Renewal Status.', NULL, DI.DATAITEMID
	FROM QUERYDATAITEM DI
	WHERE DI.PROCEDUREITEMID = N'StatusDescription'
	AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) + ' already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN OFF
go

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'StatusDescription'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
If NOT exists(SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970'
	INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
	VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
	PRINT '**** DR-63493 Data successfully added to QUERYCONTEXTCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970 already exists'
	PRINT ''
go

/**********************************************************************************************************/
/*** DR-63493 Event Category Column for Task Planner         											***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'EventCategory' AND PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYDATAITEM.PROCEDUREITEMID = EventCategory'
	INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
		DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
	select N'EventCategory', NULL, N'A', 0, 0, N'The category of event.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
	from QUERYDATAITEM 
	PRINT '**** DR-63493 Data successfully added to QUERYDATAITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYDATAITEM.PROCEDUREITEMID = EventCategory already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN ON
go

Declare @nColumnId int 
Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
				JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
				WHERE DI.PROCEDUREITEMID = N'EventCategory'
				AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar)
	INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
	SELECT cast(@nColumnId as nvarchar), N'Event Category', N'The category of event.', NULL, DI.DATAITEMID
	FROM QUERYDATAITEM DI
	WHERE DI.PROCEDUREITEMID = N'EventCategory'
	AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) + ' already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN OFF
go

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'EventCategory'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
If NOT exists(SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970'
	INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
	VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
	PRINT '**** DR-63493 Data successfully added to QUERYCONTEXTCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970 already exists'
	PRINT ''
go

/**********************************************************************************************************/
/*** DR-63493 Event Group Column for Task Planner          												***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'EventGroup' AND PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYDATAITEM.PROCEDUREITEMID = EventGroup'
	INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
		DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
	select N'EventGroup', NULL, N'A', 0, 0, N'The group events belong to.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
	from QUERYDATAITEM 
	PRINT '**** DR-63493 Data successfully added to QUERYDATAITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYDATAITEM.PROCEDUREITEMID = EventGroup already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN ON
go

Declare @nColumnId int 
Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
				JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
				WHERE DI.PROCEDUREITEMID = N'EventGroup'
				AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar)
	INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
	SELECT cast(@nColumnId as nvarchar), N'Event Group', N'The group events belong to.', NULL, DI.DATAITEMID
	FROM QUERYDATAITEM DI
	WHERE DI.PROCEDUREITEMID = N'EventGroup'
	AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) + ' already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN OFF
go

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'EventGroup'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
If NOT exists(SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970'
	INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
	VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
	PRINT '**** DR-63493 Data successfully added to QUERYCONTEXTCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970 already exists'
	PRINT ''
go

/**********************************************************************************************************/
/*** DR-63493 Event Category Icon Column for Task Planner          										***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'EventCategoryIcon' AND PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYDATAITEM.PROCEDUREITEMID = EventCategoryIcon'
	INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
		DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
	select N'EventCategoryIcon', NULL, N'A', 0, 0, N'The icon associated with the event category.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
	from QUERYDATAITEM 
	PRINT '**** DR-63493 Data successfully added to QUERYDATAITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYDATAITEM.PROCEDUREITEMID = EventCategoryIcon already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN ON
go

Declare @nColumnId int 
Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
				JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
				WHERE DI.PROCEDUREITEMID = N'EventCategoryIcon'
				AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar)
	INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
	SELECT cast(@nColumnId as nvarchar), N'Event Category Icon', N'The icon associated with the event category.', NULL, DI.DATAITEMID
	FROM QUERYDATAITEM DI
	WHERE DI.PROCEDUREITEMID = N'EventCategoryIcon'
	AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) + ' already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN OFF
go

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'EventCategoryIcon'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
If NOT exists(SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970'
	INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
	VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
	PRINT '**** DR-63493 Data successfully added to QUERYCONTEXTCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970 already exists'
	PRINT ''
go

If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9714)
BEGIN
	PRINT '**** DR-63493 Adding data IMPLIEDDATAID = 9714'
	INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
	SELECT 9714, DATAITEMID, N'EventCategoryIconKey', N'Show Event Category as an icon from a image key.', 970
	FROM QUERYDATAITEM
	WHERE PROCEDUREITEMID = N'EventCategoryIcon'
	AND PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYIMPLIEDDATA table.'
PRINT ''
END
ELSE
	PRINT '**** DR-63493 IMPLIEDDATAID = 9714 already exists'
	PRINT ''
go

If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9714 AND SEQUENCENO = 1)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9714 AND SEQUENCENO = 1'
	INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
	VALUES (9714, 1, N'EventCategoryIconKey', 0, null, N'ipw_TaskPlanner')
	PRINT '**** DR-63493 Data successfully added to QUERYIMPLIEDITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYIMPLIEDITEM IMPLIEDDATAID = 9714 AND SEQUENCENO = 1 already exists'
	PRINT ''
go


/**********************************************************************************************************/
/*** DR-63493 Type of Mark Column for Task Planner               										***/
/**********************************************************************************************************/
If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'TypeOfMarkDescription' AND PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYDATAITEM.PROCEDUREITEMID = TypeOfMarkDescription'
	INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
		DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
	select N'TypeOfMarkDescription', NULL, N'A', 0, 0, N'The type of trademark, e.g. Word Mark, Device Mark.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
	from QUERYDATAITEM 
	PRINT '**** DR-63493 Data successfully added to QUERYDATAITEM table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYDATAITEM.PROCEDUREITEMID = TypeOfMarkDescription already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN ON
go

Declare @nColumnId int 
Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
				JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
				WHERE DI.PROCEDUREITEMID = N'TypeOfMarkDescription'
				AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar)
	INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
	SELECT cast(@nColumnId as nvarchar), N'Type of Mark', N'The type of trademark, e.g. Word Mark, Device Mark.', NULL, DI.DATAITEMID
	FROM QUERYDATAITEM DI
	WHERE DI.PROCEDUREITEMID = N'TypeOfMarkDescription'
	AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	PRINT '**** DR-63493 Data successfully added to QUERYCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) + ' already exists'
	PRINT ''
go

SET IDENTITY_INSERT QUERYCOLUMN OFF
go

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'TypeOfMarkDescription'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
If NOT exists(SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
BEGIN
	PRINT '**** DR-63493 Adding data QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970'
	INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
	VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
	PRINT '**** DR-63493 Data successfully added to QUERYCONTEXTCOLUMN table.'
	PRINT ''
END
ELSE
	PRINT '**** DR-63493 QUERYCONTEXTCOLUMN for COLUMNID =' + cast(@nColumnId as nvarchar) +' and CONTEXTID = 970 already exists'
	PRINT ''
go




