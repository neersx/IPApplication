if not exists (select * from QUERYFILTER where PROCEDURENAME = 'ipw_TaskPlanner' and FILTERID = -29)
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
			   <IsReminders>0</IsReminders>
               <IsDueDates>1</IsDueDates>
			   <IsAdHocDates>1</IsAdHocDates>			   
            </Include>
            <BelongsTo>
               <NameKey Operator="0" IsCurrentUser="1" />
               <ActingAs IsReminderRecipient="0" IsResponsibleStaff="1">
                  <NameTypeKey>SIG</NameTypeKey>
                  <NameTypeKey>EMP</NameTypeKey>
               </ActingAs>
            </BelongsTo>
            <Dates UseDueDate="1" UseReminderDate="1">
               <PeriodRange Operator="7">
                  <Type>W</Type>
                  	<From>-1</From>
					<To>4</To>
               </PeriodRange>
            </Dates>            
         </FilterCriteria>
      </ipw_TaskPlanner>
   </Filtering>
</Search>'

	insert QUERYFILTER(FILTERID, PROCEDURENAME, XMLFILTERCRITERIA)
	values (-29, 'ipw_TaskPlanner', @xmlFilter) 

	set identity_insert QUERYFILTER off

	-- Enable the trigger
	if exists(SELECT * FROM sys.objects WHERE name = 'tI_QUERYFILTER_Audit' and type = 'TR') and @bTriggerHasDisabled = 1
	begin
		alter table QUERYFILTER enable trigger tI_QUERYFILTER_Audit 	
	end
end
go

if not exists (select * from QUERY where QUERYID = -29)
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
	values (-29, 970, null, 'My Due Dates', 'Due Dates and Ad Hoc Dates for the next four weeks where I am the Staff Member or Signatory on a case or have Due Date Responsibility.', -29, @nNewPresentationId)

	set identity_insert QUERY off

end 
go


UPDATE QUERY SET QueryName = 'My Due Dates' WHERE QueryId = -29
go

declare @nPresentationId int
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -29
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
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 1, 2, NULL, 970
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
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -29
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
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 2, 1, NULL, 970
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
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -29
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
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 3, NULL, NULL, 970
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
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -29
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
		 SELECT DISTINCT @nPresentationId, cast(@nColumnId as nvarchar), 4, NULL, NULL, 970
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
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -29
Declare @nColumnId int 
Select @nColumnId = QC.ColumnID from 
QUERYCOLUMN QC 
join QUERYDATAITEM DI on QC.DATAITEMID = DI.DATAITEMID 
WHERE DI.PROCEDUREITEMID = N'DueDateResponsibility'
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
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -29
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
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -29
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
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -29
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
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -29
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
select @nPresentationId = PRESENTATIONID from QUERY where CONTEXTID = 970 and FILTERID = -29
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


