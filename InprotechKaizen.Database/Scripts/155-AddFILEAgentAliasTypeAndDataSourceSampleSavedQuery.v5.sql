/***************************************************************************/
/************************** FILE Agent name alias **************************/
/***************************************************************************/
if not exists (select * from ALIASTYPE where ALIASTYPE = '_F')
begin
	print '**** DR-33343 Inserting ALIASTYPE WHERE ALIASTYPE = "_F"'
	
	insert ALIASTYPE (ALIASTYPE, ALIASDESCRIPTION, MUSTBEUNIQUE)
	values ('_F', 'FILE Agent Id', 0)

	print '**** DR-33343 Data successfully inserted in ALIASTYPE table.'

    print ''
end
else
begin
    print '**** DR-33343 ALIASTYPE WHERE ALIASTYPE = "_F" already exists'
    print ''
end 
go

/***************************************************************************/
/************************** FILE Data Souce ********************************/
/***************************************************************************/
if not exists (select * from EXTERNALSYSTEM where SYSTEMID = -6 and SYSTEMCODE = 'FILE')
begin	
	insert EXTERNALSYSTEM (SYSTEMID, SYSTEMNAME, SYSTEMCODE, DATAEXTRACTID)
	values (-6, 'FILE', 'FILE', null)
end
go

if not exists (select * from DATAEXTRACTMODULE where SYSTEMID = -6 and DATAEXTRACTID = 6)
begin
	insert DATAEXTRACTMODULE (DATAEXTRACTID, SYSTEMID, EXTRACTNAME)
	values (6, -6, 'FILE')
end
go

if not exists (select * from DATASOURCE where DATASOURCEID = -6 and SYSTEMID = -6 and DATASOURCECODE = 'FILE')
begin
    set identity_insert DATASOURCE on

	insert DATASOURCE (DATASOURCEID, SYSTEMID, ISPROTECTED, DATASOURCECODE)
	values (-6, -6, 1, 'FILE')

	set identity_insert DATASOURCE off
end
go

/***************************************************************************/
/***************** FILE Data Mapping Scenario - EVENT **********************/
/***************************************************************************/
if not exists (select * 
				from MAPSCENARIO MS
				where MS.STRUCTUREID = 5 and MS.SYSTEMID = -6 and MS.SCHEMEID = -3)
begin
	insert MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	values (-6, 5, -3, 1)
end
go

/***************************************************************************/
/***************** FILE Data Mapping Scenario - Document EVENT *************/
/***************************************************************************/
if not exists (select * 
				from MAPSCENARIO MS
				where MS.STRUCTUREID = 14 and MS.SYSTEMID = -6 and MS.SCHEMEID = -3)
begin
	insert MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	values (-6, 14, -3, 1)
end
go

/***************************************************************************/
/***************** FILE Data Mapping Scenario - Number Type ****************/
/***************************************************************************/
if not exists (select * 
				from MAPSCENARIO MS
				where MS.STRUCTUREID = 1 and MS.SYSTEMID = -6 and MS.SCHEMEID = -3)
begin
	insert MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	values (-6, 1, -3, 0)
end
go

/***************************************************************************/
/***************** FILE Data Mapping Scenario - Country ********************/
/***************************************************************************/
if not exists (select * 
				from MAPSCENARIO MS
				where MS.STRUCTUREID = 4 and MS.SYSTEMID = -6 and MS.SCHEMEID = -2)
begin
	insert MAPSCENARIO (SYSTEMID, STRUCTUREID, SCHEMEID, IGNOREUNMAPPED)
	values (-6, 4, -2, 0)
end
go

/***************************************************************************/
/************ FILE Extract/Comparision Eligibility - Patents ***************/
/***************************************************************************/
if	exists (select * from PROPERTYTYPE where PROPERTYTYPE = 'P')
begin
	IF NOT exists (select * 
				from CRITERIA
				where CASETYPE = 'A' and PROPERTYTYPE = 'P' and DATAEXTRACTID = 6)
	begin
		declare @next int
		select @next = max(CRITERIANO)+1
		from CRITERIA 

		insert CRITERIA (PURPOSECODE, CASETYPE, PROPERTYTYPE, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, DATAEXTRACTID, CRITERIANO)
		values ('D', 'A', 'P', 0, 1, 'The IP Platform - FILE App for Patents', 6, @next)
	
		update	LASTINTERNALCODE 
		set		INTERNALSEQUENCE = @next
		where TABLENAME = 'CRITERIA'
	END
	ELSE
    BEGIN
		UPDATE CRITERIA SET CASECATEGORY = NULL 
		WHERE PURPOSECODE = 'D'
		AND CASETYPE = 'A'
		AND PROPERTYTYPE = 'P'
		AND USERDEFINEDRULE = 0
		AND RULEINUSE = 1
		AND DATAEXTRACTID = 6
	END
end
GO

/***************************************************************************/
/************ FILE Extract/Comparision Eligibility - TradeMarks ***************/
/***************************************************************************/
if	exists (select * from PROPERTYTYPE where PROPERTYTYPE = 'T')
begin
	IF NOT exists (select * 
				from CRITERIA
				where CASETYPE = 'A' and PROPERTYTYPE = 'T' and DATAEXTRACTID = 6)
	begin
		declare @next int
		select @next = max(CRITERIANO)+1
		from CRITERIA 

		insert CRITERIA (PURPOSECODE, CASETYPE, PROPERTYTYPE, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, DATAEXTRACTID, CRITERIANO)
		values ('D', 'A', 'T', 0, 1, 'The IP Platform - FILE App for TradeMarks', 6, @next)
	
		update	LASTINTERNALCODE 
		set		INTERNALSEQUENCE = @next
		where TABLENAME = 'CRITERIA'
	END
END

/***************************************************************************/
/*********************** FILE Sample Saved Query ***************************/
/***************************************************************************/
if not exists (select * from QUERYFILTER where PROCEDURENAME = 'csw_ListCase' and FILTERID = -30)
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
	
	insert QUERYFILTER(FILTERID, PROCEDURENAME, XMLFILTERCRITERIA)
	values (-30, 'csw_ListCase', '		
<csw_ListCase>
	<FilterCriteriaGroup>
		<FilterCriteria ID="1">
			<IsAdvancedFilter>false</IsAdvancedFilter>
            <CaseTypeKey Operator="0" IncludeCRMCases="0">A</CaseTypeKey>
            <PropertyTypeKeys Operator="0">
                <PropertyTypeKey>P</PropertyTypeKey>
            </PropertyTypeKeys>
			<CategoryKey Operator="0">K</CategoryKey>
			<StatusFlags CheckDeadCaseRestriction="1">
				<IsPending>1</IsPending><IsRegistered>1</IsRegistered><IsDead>0</IsDead>
			</StatusFlags>
		</FilterCriteria>
	</FilterCriteriaGroup>
</csw_ListCase>') 

	set identity_insert QUERYFILTER off

	-- Enable the trigger
	if exists(SELECT * FROM sys.objects WHERE name = 'tI_QUERYFILTER_Audit' and type = 'TR') and @bTriggerHasDisabled = 1
	begin
		alter table QUERYFILTER enable trigger tI_QUERYFILTER_Audit 	
	end
end
go

set identity_insert QUERY on
go

if not exists (select * from QUERY where QUERYID = -30)
begin

	insert QUERY (QUERYID, CONTEXTID, IDENTITYID, QUERYNAME, DESCRIPTION, FILTERID)
	values (-30, 2, null, 'FILE Integration - Sample', 'A sample query returning cases for use with FILE Integration. The system will use this query to determine the list of cases to query for status changes from FILE.', -30)

end 
go

set identity_insert QUERY off
GO


IF EXISTS(SELECT * FROM QUERYFILTER WHERE FILTERID = -30 AND dbo.fn_IsNTextEqual(XMLFILTERCRITERIA, N'		
<csw_ListCase>
	<FilterCriteriaGroup>
		<FilterCriteria ID="1">
			<IsAdvancedFilter>false</IsAdvancedFilter>
            <CaseTypeKey Operator="0" IncludeCRMCases="0">A</CaseTypeKey>
            <PropertyTypeKeys Operator="0">
                <PropertyTypeKey>P</PropertyTypeKey>
            </PropertyTypeKeys>
			<CategoryKey Operator="0">K</CategoryKey>
			<StatusFlags CheckDeadCaseRestriction="1">
				<IsPending>1</IsPending><IsRegistered>1</IsRegistered><IsDead>0</IsDead>
			</StatusFlags>
		</FilterCriteria>
	</FilterCriteriaGroup>
</csw_ListCase>') = 1)
BEGIN

	UPDATE QUERYFILTER
	SET XMLFILTERCRITERIA = N'		
<csw_ListCase>
	<FilterCriteriaGroup>
		<FilterCriteria ID="1">
			<IsAdvancedFilter>false</IsAdvancedFilter>
            <CaseTypeKey Operator="0" IncludeCRMCases="0">A</CaseTypeKey>
            <PropertyTypeKeys Operator="0">
                <PropertyTypeKey>P</PropertyTypeKey>
            </PropertyTypeKeys>
			<StatusFlags CheckDeadCaseRestriction="1">
				<IsPending>1</IsPending><IsRegistered>1</IsRegistered><IsDead>0</IsDead>
			</StatusFlags>
		</FilterCriteria>
	</FilterCriteriaGroup>
</csw_ListCase>' WHERE FILTERID = -30

END
go


IF EXISTS(SELECT * FROM QUERYFILTER WHERE FILTERID = -30 AND dbo.fn_IsNTextEqual(XMLFILTERCRITERIA, N'		
<csw_ListCase>
	<FilterCriteriaGroup>
		<FilterCriteria ID="1">
			<IsAdvancedFilter>false</IsAdvancedFilter>
            <CaseTypeKey Operator="0" IncludeCRMCases="0">A</CaseTypeKey>
            <PropertyTypeKeys Operator="0">
                <PropertyTypeKey>P</PropertyTypeKey>
            </PropertyTypeKeys>
			<StatusFlags CheckDeadCaseRestriction="1">
				<IsPending>1</IsPending><IsRegistered>1</IsRegistered><IsDead>0</IsDead>
			</StatusFlags>
		</FilterCriteria>
	</FilterCriteriaGroup>
</csw_ListCase>') = 1)
BEGIN

	UPDATE QUERYFILTER
	SET XMLFILTERCRITERIA = N'		
<csw_ListCase>
	<FilterCriteriaGroup>
		<FilterCriteria ID="1">
			<IsAdvancedFilter>false</IsAdvancedFilter>
            <CaseTypeKey Operator="0" IncludeCRMCases="0">A</CaseTypeKey>
            <PropertyTypeKeys Operator="0">
                <PropertyTypeKey>P</PropertyTypeKey>
				<PropertyTypeKey>T</PropertyTypeKey>
            </PropertyTypeKeys>
			<StatusFlags CheckDeadCaseRestriction="1">
				<IsPending>1</IsPending><IsRegistered>1</IsRegistered><IsDead>0</IsDead>
			</StatusFlags>
		</FilterCriteria>
	</FilterCriteriaGroup>
</csw_ListCase>' WHERE FILTERID = -30

END
go