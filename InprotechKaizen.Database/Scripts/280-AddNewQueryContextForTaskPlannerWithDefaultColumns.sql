    /*** DR-62615 Create a script for new Query Context for Task Planner - Query Context							***/
	
    If NOT exists(SELECT * FROM QUERYCONTEXT WHERE CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXT.CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXT (CONTEXTID, CONTEXTNAME, PROCEDURENAME, NOTES)
		 VALUES (970, N'TaskPlanner', 'ipw_TaskPlanner', N'Task Planner Notes')
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXT.CONTEXTID = 970 already exists'
         	PRINT ''
    	go

    /*** DR-62615 Create a script for new Query Context for Task Planner - Query Presentation						***/
	
    SET IDENTITY_INSERT QUERYPRESENTATION ON
	go

    If NOT exists(SELECT * FROM QUERYPRESENTATION WHERE PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYPRESENTATION.PRESENTATIONID = -970'
		 INSERT INTO QUERYPRESENTATION (PRESENTATIONID, CONTEXTID, IDENTITYID, ISDEFAULT, 
			REPORTTITLE, REPORTTEMPLATE, REPORTTOOL, EXPORTFORMAT, PRESENTATIONTYPE)
		 SELECT DISTINCT -970, 970, NULL, 1, NULL, NULL, NULL, NULL, NULL
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYPRESENTATION table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYPRESENTATION.PRESENTATIONID = -970 already exists'
         	PRINT ''
    	go

    SET IDENTITY_INSERT QUERYPRESENTATION OFF
	go
    
    /*** DR-62615 Create a script for new Query Context for Task Planner - Query Data Item							***/
	
    If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'CaseReference' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = CaseReference'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'CaseReference', NULL, N'A', 0, 0, N'The identifying code used for the case internally.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = CaseReference already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'ReminderDate' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = ReminderDate'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'ReminderDate', NULL, N'A', 0, 0, N'The date of the reminder.', isnull(max(DATAITEMID),0)+1, 9103, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = ReminderDate already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'DueDate' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = DueDate'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'DueDate', NULL, N'A', 0, 0, N'The date the item is due.', isnull(max(DATAITEMID),0)+1, 9103, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = DueDate already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'ReminderMessage' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = ReminderMessage'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'ReminderMessage', NULL, N'A', 0, 0, N'The reminder message.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = ReminderMessage already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'IsAdHoc' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = IsAdHoc'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'IsAdHoc', NULL, N'A', 0, 0, N'Indicates whether the due date originates from an Ad Hoc reminder.', isnull(max(DATAITEMID),0)+1, 9106, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = IsAdHoc already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'Owner' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = Owner'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'Owner', NULL, N'A', 0, 0, N'The name of the main Owner for the case.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = Owner already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'EventDescription' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = EventDescription'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'EventDescription', NULL, N'A', 0, 0, N'The description of the event.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = EventDescription already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'CountryName' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = CountryName'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'CountryName', NULL, N'A', 0, 0, N'The jurisdiction of the case.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = CountryName already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'CaseTypeDescription' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = CaseTypeDescription'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'CaseTypeDescription', NULL, N'A', 0, 0, N'The type of case; e.g. Properties, Searching.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = CaseTypeDescription already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'PropertyTypeDescription' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = PropertyTypeDescription'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'PropertyTypeDescription', NULL, N'A', 0, 0, N'The type of property; e.g. Patent, Trademark.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = PropertyTypeDescription already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'StaffMember' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = StaffMember'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'StaffMember', NULL, N'A', 0, 0, N'The Staff Member or Employee responsible for the case.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = StaffMember already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'Signatory' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = Signatory'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'Signatory', NULL, N'A', 0, 0, N'The Signatory or Partner responsible for the case.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = Signatory already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'NextReminderDate' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = NextReminderDate'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'NextReminderDate', NULL, N'A', 0, 0, N'The date of the next reminder for the event.', isnull(max(DATAITEMID),0)+1, 9103, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = NextReminderDate already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'ReminderFor' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = ReminderFor'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'ReminderFor', NULL, N'A', 0, 0, N'The name the Reminder was generated for.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = ReminderFor already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYDATAITEM WHERE PROCEDUREITEMID = N'DueDateResponsibility' AND PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYDATAITEM.PROCEDUREITEMID = DueDateResponsibility'
		 INSERT INTO QUERYDATAITEM (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION, 
					DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
		 select N'DueDateResponsibility', NULL, N'A', 0, 0, N'The name of the Staff Member who has responsibility for the due date.', isnull(max(DATAITEMID),0)+1, 9100, NULL, N'ipw_TaskPlanner', NULL, NULL
		 from QUERYDATAITEM 
        	 PRINT '**** DR-62615 Data successfully added to QUERYDATAITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYDATAITEM.PROCEDUREITEMID = DueDateResponsibility already exists'
         	PRINT ''
    	go

    /*** DR-62615 Create a script for new Query Context for Task Planner - Query Column							***/
	
    SET IDENTITY_INSERT QUERYCOLUMN ON
	go

Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'CaseReference'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Case Ref.', N'The identifying code used for the case internally.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'CaseReference'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'ReminderDate'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Reminder Date', N'The date of the reminder.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'ReminderDate'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'DueDate'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Due Date', N'The date the item is due.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'DueDate'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'ReminderMessage'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Message', N'The reminder message.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'ReminderMessage'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'IsAdHoc'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Ad Hoc', N'Indicates whether the due date originates from an Ad Hoc reminder.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'IsAdHoc'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'Owner'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Owner', N'The name of the main Owner for the case.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'Owner'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'EventDescription'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Event', N'The description of the event.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'EventDescription'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'CountryName'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Jurisdiction', N'The jurisdiction of the case.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'CountryName'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'CaseTypeDescription'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Case Type', N'The type of case; e.g. Properties, Searching.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'CaseTypeDescription'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'PropertyTypeDescription'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Property Type', N'The type of property; e.g. Patent, Trademark.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'PropertyTypeDescription'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'StaffMember'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Staff Member', N'The Staff Member or Employee responsible for the case.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'StaffMember'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'Signatory'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Signatory', N'The Signatory or Partner responsible for the case.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'Signatory'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'NextReminderDate'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Next Reminder', N'The date of the next reminder for the event.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'NextReminderDate'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'ReminderFor'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Reminder For', N'The name the Reminder was generated for.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'ReminderFor'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go
 Declare @nColumnId int 
 Select @nColumnId = min(COLUMNID)-1  from QUERYCOLUMN
 If NOT exists(	SELECT * FROM QUERYCOLUMN QC 
 JOIN QUERYDATAITEM DI ON (QC.DATAITEMID = DI.DATAITEMID) 
 WHERE DI.PROCEDUREITEMID = N'DueDateResponsibility'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner')
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar)'
		 INSERT INTO QUERYCOLUMN(COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
		 SELECT cast(@nColumnId as nvarchar), N'Due Date Resp.', N'The name of the Staff Member who has responsibility for the due date.', NULL, DI.DATAITEMID
		 FROM QUERYDATAITEM DI
		 WHERE DI.PROCEDUREITEMID = N'DueDateResponsibility'
		 AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) already exists'
         	PRINT ''
    	go

    SET IDENTITY_INSERT QUERYCOLUMN OFF
	go

   	/*** DR-62615 Create a script for new Query Context for Task Planner - Query Context Column						***/
	
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'CaseReference'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'ReminderDate'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'DueDate'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'ReminderMessage'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'IsAdHoc'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'Owner'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'EventDescription'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'CountryName'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'CaseTypeDescription'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'PropertyTypeDescription'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'StaffMember'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'Signatory'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'NextReminderDate'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'ReminderFor'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'DueDateResponsibility'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTEXTCOLUMN WHERE COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970'
		 INSERT INTO QUERYCONTEXTCOLUMN(CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
		 VALUES (970, cast(@nColumnId as nvarchar), NULL, NULL, 0, 0)
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTEXTCOLUMN table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTEXTCOLUMN for COLUMNID = cast(@nColumnId as nvarchar) and CONTEXTID = 970 already exists'
         	PRINT ''
    	go

    /*** DR-62615 Create a script for new Query Context for Task Planner - Query Content						***/
	
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'CaseReference'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 1, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'ReminderDate'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 2, 1, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'DueDate'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 3, 2, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'ReminderMessage'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 4, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'IsAdHoc'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 5, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go

Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'EventDescription'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 8, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'CountryName'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 9, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'CaseTypeDescription'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 10, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'PropertyTypeDescription'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 11, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'StaffMember'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 12, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'Signatory'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 13, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'NextReminderDate'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = -970'
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT -970, cast(@nColumnId as nvarchar), 14, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID -970 already exists'
         	PRINT ''
    	go

    /*** DR-62615 Create a script for new Query Context for Task Planner - Query Implied Data						***/

    If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9700)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data IMPLIEDDATAID = 9700'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9700, DATAITEMID, N'CaseDetails', N'Link to case details from case reference.', 970
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'CaseReference'
		 AND PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 IMPLIEDDATAID = 9700 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9701)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data IMPLIEDDATAID = 9701'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9701, DATAITEMID, N'NameDetails', N'Link to Name details from Owner.', 970
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'Owner'
		 AND PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 IMPLIEDDATAID = 9701 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9702)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data IMPLIEDDATAID = 9702'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9702, DATAITEMID, N'Reference', N'Reference to Event.', 970
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'EventDescription'
		 AND PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 IMPLIEDDATAID = 9702 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9703)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data IMPLIEDDATAID = 9703'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9703, DATAITEMID, N'Reference', N'Reference to Jurisdiction.', 970
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'CountryName'
		 AND PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 IMPLIEDDATAID = 9703 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9704)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data IMPLIEDDATAID = 9704'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9704, DATAITEMID, N'Reference', N'Reference to CaseType.', 970
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'CaseTypeDescription'
		 AND PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 IMPLIEDDATAID = 9704 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9705)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data IMPLIEDDATAID = 9705'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9705, DATAITEMID, N'Reference', N'Reference to PropertyType.', 970
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'PropertyTypeDescription'
		 AND PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 IMPLIEDDATAID = 9705 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9706)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data IMPLIEDDATAID = 9706'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9706, DATAITEMID, N'NameDetails', N'Link to Name details from Staff Member.', 970
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'StaffMember'
		 AND PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 IMPLIEDDATAID = 9706 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9707)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data IMPLIEDDATAID = 9707'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9707, DATAITEMID, N'NameDetails', N'Link to Name details from Signatory.', 970
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'Signatory'
		 AND PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 IMPLIEDDATAID = 9707 already exists'
         	PRINT ''
    	go
        If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9708)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data IMPLIEDDATAID = 9708'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9708, DATAITEMID, N'NameDetails', N'Link to Name name the Reminder was generated for.', 970
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'ReminderFor'
		 AND PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 IMPLIEDDATAID = 9708 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDDATA WHERE IMPLIEDDATAID = 9709)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data IMPLIEDDATAID = 9709'
		 INSERT INTO QUERYIMPLIEDDATA(IMPLIEDDATAID, DATAITEMID, TYPE, NOTES, CONTEXTID)
		 SELECT 9709, DATAITEMID, N'NameDetails', N'Link to name of the Staff Member who has responsibility for the due date.', 970
		 FROM QUERYDATAITEM
		 WHERE PROCEDUREITEMID = N'DueDateResponsibility'
		 AND PROCEDURENAME = N'ipw_TaskPlanner'
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDDATA table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 IMPLIEDDATAID = 9709 already exists'
         	PRINT ''
    	go

    /*** DR-62615 Create a script for new Query Context for Task Planner - Query Implied Item						***/
	
    If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9700 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9700 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9700, 1, N'CaseKey', 0, N'CaseKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9700 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9700 AND SEQUENCENO = 2)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9700 AND SEQUENCENO = 2'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9700, 2, N'CaseReference', 0, NULL, N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9700 AND SEQUENCENO = 2 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9701 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9701 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9701, 1, N'OwnerKey', 0, N'OwnerKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9701 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9701 AND SEQUENCENO = 2)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9701 AND SEQUENCENO = 2'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9701, 2, N'Owner', 0, NULL, N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9701 AND SEQUENCENO = 2 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9702 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9702 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9702, 1, N'EventKey', 0, N'EventKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9702 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9702 AND SEQUENCENO = 2)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9702 AND SEQUENCENO = 2'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9702, 2, N'EventDescription', 0, NULL, N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9702 AND SEQUENCENO = 2 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9703 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9703 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9703, 1, N'CountryKey', 0, N'CountryKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9703 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9703 AND SEQUENCENO = 2)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9703 AND SEQUENCENO = 2'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9703, 2, N'CountryName', 0, NULL, N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9703 AND SEQUENCENO = 2 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9704 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9704 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9704, 1, N'CaseTypeKey', 0, N'CaseTypeKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9704 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9704 AND SEQUENCENO = 2)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9704 AND SEQUENCENO = 2'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9704, 2, N'CaseTypeDescription', 0, NULL, N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9704 AND SEQUENCENO = 2 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9705 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9705 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9705, 1, N'PropertyTypeKey', 0, N'PropertyTypeKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9705 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9705 AND SEQUENCENO = 2)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9705 AND SEQUENCENO = 2'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9705, 2, N'PropertyTypeDescription', 0, NULL, N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9705 AND SEQUENCENO = 2 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9706 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9706 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9706, 1, N'StaffMemberKey', 0, N'StaffMemberKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9706 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9706 AND SEQUENCENO = 2)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9706 AND SEQUENCENO = 2'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9706, 2, N'StaffMember', 0, NULL, N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9706 AND SEQUENCENO = 2 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9707 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9707 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9707, 1, N'SignatoryKey', 0, N'SignatoryKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9707 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9707 AND SEQUENCENO = 2)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9707 AND SEQUENCENO = 2'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9707, 2, N'Signatory', 0, NULL, N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9707 AND SEQUENCENO = 2 already exists'
         	PRINT ''
    	go
        If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9708 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9708 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9708, 1, N'ReminderForNameKey', 0, N'ReminderForNameKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9708 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9708 AND SEQUENCENO = 2)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9708 AND SEQUENCENO = 2'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9708, 2, N'ReminderFor', 0, NULL, N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9708 AND SEQUENCENO = 2 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9709 AND SEQUENCENO = 1)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9709 AND SEQUENCENO = 1'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9709, 1, N'DueDateResponsibilityNameKey', 0, N'DueDateResponsibilityNameKey', N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9709 AND SEQUENCENO = 1 already exists'
         	PRINT ''
    	go
	If NOT exists(SELECT * FROM QUERYIMPLIEDITEM WHERE IMPLIEDDATAID = 9709 AND SEQUENCENO = 2)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYIMPLIEDITEM for IMPLIEDDATAID = 9709 AND SEQUENCENO = 2'
		 INSERT INTO QUERYIMPLIEDITEM(IMPLIEDDATAID, SEQUENCENO, PROCEDUREITEMID, USESQUALIFIER, USAGE, PROCEDURENAME)
		 VALUES (9709, 2, N'DueDateResponsibility', 0, NULL, N'ipw_TaskPlanner')
        	 PRINT '**** DR-62615 Data successfully added to QUERYIMPLIEDITEM table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYIMPLIEDITEM IMPLIEDDATAID = 9709 AND SEQUENCENO = 2 already exists'
         	PRINT ''
    	go

