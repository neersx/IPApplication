if not exists (select * from QUERYFILTER where PROCEDURENAME = 'ipw_TaskPlanner' and FILTERID = -28)
begin

	-- Disable the insert audit trigger if exists and is an instead of trigger and not disabled.
	declare @bTriggerHasDisabled bit
	If exists(SELECT * FROM sys.objects WHERE name = 'tI_QUERYFILTER_Audit' and type = 'TR' 
		and OBJECTPROPERTY (object_id, 'ExecIsInsteadOfTrigger') = 1
		and  OBJECTPROPERTY ( object_id, 'ExecIsTriggerDisabled') = 0)
	Begin	
		alter table QUERYFILTER disable trigger tI_QUERYFILTER_Audit 
		set @bTriggerHasDisabled = 1
	End	         	 

    set identity_insert QUERYFILTER on
	
	declare @xmlFilter nvarchar(max)
	set @xmlFilter = '		
<Search>
   <Filtering>
      <ipw_TaskPlanner>
         <FilterCriteria>
            <Include>
               <IsReminders>1</IsReminders>
               <IsDueDates>1</IsDueDates>
			   <IsAdHocDates>1</IsAdHocDates>
            </Include>
            <BelongsTo>
               <MemberOfGroupKey Operator="0" IsCurrentUser="1" />
               <ActingAs IsReminderRecipient="1" IsResponsibleStaff="1">                  
               </ActingAs>
            </BelongsTo>
            <Dates UseDueDate="1" UseReminderDate="1">
               <PeriodRange Operator="7">
                  <Type>W</Type>
                  <From>-4</From>
                  <To>2</To>
               </PeriodRange>
            </Dates>            
         </FilterCriteria>
      </ipw_TaskPlanner>
   </Filtering>
</Search>'

	insert QUERYFILTER(FILTERID, PROCEDURENAME, XMLFILTERCRITERIA)
	values (-28, 'ipw_TaskPlanner', @xmlFilter) 

	set identity_insert QUERYFILTER off

	-- Enable the trigger
	if exists(SELECT * FROM sys.objects WHERE name = 'tI_QUERYFILTER_Audit' and type = 'TR') and @bTriggerHasDisabled = 1
	begin
		alter table QUERYFILTER enable trigger tI_QUERYFILTER_Audit 	
	end
end
go

if not exists (select * from QUERY where QUERYID = -28)
begin

-- Disable the insert audit trigger if exists and is an instead of trigger and not disabled.
	declare @bTriggerHasDisabled bit
	If exists(SELECT * FROM sys.objects WHERE name = 'tI_QUERYPRESENTATION_Audit' and type = 'TR' 
		and OBJECTPROPERTY (object_id, 'ExecIsInsteadOfTrigger') = 1
		and  OBJECTPROPERTY ( object_id, 'ExecIsTriggerDisabled') = 0)
	Begin	
		alter table QUERYFILTER disable trigger tI_QUERYFILTER_Audit 
		set @bTriggerHasDisabled = 1
	End	         	 
	
	declare @nNewPresentationId int
	select @nNewPresentationId = Min(PRESENTATIONID) - 1 from QUERYPRESENTATION

	set identity_insert QUERYPRESENTATION on

	insert into QUERYPRESENTATION (PRESENTATIONID, CONTEXTID) 
			values (@nNewPresentationId, 970)
			
	set identity_insert QUERYPRESENTATION off

	-- Enable the trigger
	if exists(SELECT * FROM sys.objects WHERE name = 'tI_QUERYPRESENTATION_Audit' and type = 'TR') and @bTriggerHasDisabled = 1
	begin
		alter table QUERYFILTER enable trigger tI_QUERYFILTER_Audit 	
	end

	set identity_insert QUERY on

	insert QUERY (QUERYID, CONTEXTID, IDENTITYID, QUERYNAME, DESCRIPTION, FILTERID,PRESENTATIONID)
	values (-28, 970, null, 'My Team''s Tasks', 'Reminders, Due Dates and Ad Hocs for the next two weeks where anyone in my team is the Reminder Recipient, a staff member on the case, or has Due Date Responsibility.', -28, @nNewPresentationId)

	set identity_insert QUERY off

end 
go


UPDATE QUERY SET QueryName = 'My Team''s Tasks' WHERE QueryId = -28
go

declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -28
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'CaseReference'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = @nPresentationId)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID = ' + cast(@nPresentationId as nvarchar)
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 1, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID ' + cast(@nPresentationId as nvarchar) +' already exists'
         	PRINT ''
    	go

declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -28
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'ReminderFor'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = @nPresentationId)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID = ' + cast(@nPresentationId as nvarchar)
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 2, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID ' + cast(@nPresentationId as nvarchar) +' already exists'
         	PRINT ''
    	go

declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -28
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'ReminderDate'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = @nPresentationId)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID = ' + cast(@nPresentationId as nvarchar)
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 3, 2, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID ' + cast(@nPresentationId as nvarchar) +' already exists'
         	PRINT ''
    	go

declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -28
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'DueDate'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = @nPresentationId)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID = ' + cast(@nPresentationId as nvarchar)
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 4, 1, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID ' + cast(@nPresentationId as nvarchar) +' already exists'
         	PRINT ''
    	go

declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -28
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'ReminderMessage'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = @nPresentationId)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID = ' + cast(@nPresentationId as nvarchar)
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 5, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID ' + cast(@nPresentationId as nvarchar) +' already exists'
         	PRINT ''
    	go


declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -28
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'IsAdHoc'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = @nPresentationId)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID = ' + cast(@nPresentationId as nvarchar)
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 6, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID ' + cast(@nPresentationId as nvarchar) +' already exists'
         	PRINT ''
    	go

declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -28
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'Instructor'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = @nPresentationId)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID = ' + cast(@nPresentationId as nvarchar)
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 7, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID ' + cast(@nPresentationId as nvarchar) +' already exists'
         	PRINT ''
    	go

declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -28
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'EventDescription'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = @nPresentationId)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID = ' + cast(@nPresentationId as nvarchar)
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 8, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID ' + cast(@nPresentationId as nvarchar) +' already exists'
         	PRINT ''
    	go

declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -28
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'CountryName'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = @nPresentationId)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID = ' + cast(@nPresentationId as nvarchar)
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 9, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID ' + cast(@nPresentationId as nvarchar) +' already exists'
         	PRINT ''
    	go

declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -28
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'PropertyTypeDescription'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = @nPresentationId)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID = ' + cast(@nPresentationId as nvarchar)
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 10, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID ' + cast(@nPresentationId as nvarchar) +' already exists'
         	PRINT ''
    	go

declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -28
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'StaffMember'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = @nPresentationId)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID = ' + cast(@nPresentationId as nvarchar)
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 11, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID ' + cast(@nPresentationId as nvarchar) +' already exists'
         	PRINT ''
    	go

declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -28
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'Signatory'
AND DI.PROCEDURENAME = N'ipw_TaskPlanner'
	If NOT exists(	SELECT * FROM QUERYCONTENT WHERE COLUMNID = cast(@nColumnId as nvarchar) AND PRESENTATIONID = @nPresentationId)
        	BEGIN
         	 PRINT '**** DR-62615 Adding data QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID = ' + cast(@nPresentationId as nvarchar)
		 INSERT INTO QUERYCONTENT (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 12, NULL, NULL, 970
		 FROM (select 1 as txt) TMP
		 left join QUERYPRESENTATION P on (P.CONTEXTID = 970)
		 where ISNULL(P.ISDEFAULT, 0) = 0
		 or ISNULL(P.ISPROTECT, 0) = 0
        	 PRINT '**** DR-62615 Data successfully added to QUERYCONTENT table.'
		 PRINT ''
         	END
    	ELSE
         	PRINT '**** DR-62615 QUERYCONTENT for COLUMNID = ' + cast(@nColumnId as nvarchar) + ' AND PRESENTATIONID ' + cast(@nPresentationId as nvarchar) +' already exists'
         	PRINT ''
    	go


