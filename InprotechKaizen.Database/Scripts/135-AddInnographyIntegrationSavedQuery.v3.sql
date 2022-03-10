declare @xmlFilterWithoutMark nvarchar(max);
declare @xmlFilterWithMark nvarchar(max);

declare @available_property_types_without_mark nvarchar(500)
declare @available_property_types_with_mark nvarchar(500)

select @available_property_types_without_mark = coalesce(@available_property_types_without_mark, '') + ('<PropertyTypeKey>' + PROPERTYTYPE + '</PropertyTypeKey>')
from PROPERTYTYPE 
where PROPERTYTYPE in ('P', 'D', 'N', 'U', 'V')

select @available_property_types_with_mark = coalesce(@available_property_types_with_mark, '') + ('<PropertyTypeKey>' + PROPERTYTYPE + '</PropertyTypeKey>')
from PROPERTYTYPE 
where PROPERTYTYPE in ('P', 'D', 'N', 'U', 'V', 'T')
	
set @xmlFilterWithoutMark = '		
<csw_ListCase>
	<FilterCriteriaGroup>
		<FilterCriteria ID="1">
			<CaseTypeKey Operator="0" IncludeCRMCases="0">A</CaseTypeKey>
			<PropertyTypeKeys Operator="0">
				' + @available_property_types_without_mark + '
			</PropertyTypeKeys>
			<StatusFlags CheckDeadCaseRestriction="1">
				<IsPending>1</IsPending><IsRegistered>1</IsRegistered><IsDead>0</IsDead>
			</StatusFlags>
		</FilterCriteria>
	</FilterCriteriaGroup>
</csw_ListCase>'

	
set @xmlFilterWithMark = '		
<csw_ListCase>
	<FilterCriteriaGroup>
		<FilterCriteria ID="1">
			<CaseTypeKey Operator="0" IncludeCRMCases="0">A</CaseTypeKey>
			<PropertyTypeKeys Operator="0">
				' + @available_property_types_with_mark + '
			</PropertyTypeKeys>
			<StatusFlags CheckDeadCaseRestriction="1">
				<IsPending>1</IsPending><IsRegistered>1</IsRegistered><IsDead>0</IsDead>
			</StatusFlags>
		</FilterCriteria>
	</FilterCriteriaGroup>
</csw_ListCase>'

if not exists (select * from QUERYFILTER where PROCEDURENAME = 'csw_ListCase' and FILTERID = -25)
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
	values (-25, 'csw_ListCase', @xmlFilterWithMark)

	set identity_insert QUERYFILTER off

	-- Enable the trigger
	if exists(SELECT * FROM sys.objects WHERE name = 'tI_QUERYFILTER_Audit' and type = 'TR') and @bTriggerHasDisabled = 1
	begin
		alter table QUERYFILTER enable trigger tI_QUERYFILTER_Audit 	
	end
end
else if exists(select * from QUERYFILTER where PROCEDURENAME = 'csw_ListCase' and FILTERID = -25 and cast(XMLFILTERCRITERIA as nvarchar(max)) = @xmlFilterWithoutMark)
Begin
	PRINT 'Updating Filter Criteria to include Trademarks...'
	-- Disable the update audit trigger if exists and not disabled.
	declare @bUpdateTriggerHasDisabled bit
	If exists(SELECT * FROM sys.objects WHERE name = 'tU_QUERYFILTER_Audit' and type = 'TR'
		and OBJECTPROPERTY (object_id, 'ExecIsInsteadOfTrigger') = 1
		and  OBJECTPROPERTY ( object_id, 'ExecIsTriggerDisabled') = 0)
	Begin	
		alter table QUERYFILTER disable trigger tU_QUERYFILTER_Audit 
		set @bUpdateTriggerHasDisabled = 1
	End	

	UPDATE QUERYFILTER set XMLFILTERCRITERIA = @xmlFilterWithMark
	where FILTERID = -25;

	-- Enable the trigger
	if exists(SELECT * FROM sys.objects WHERE name = 'tU_QUERYFILTER_Audit' and type = 'TR') and @bUpdateTriggerHasDisabled = 1
	begin
		alter table QUERYFILTER enable trigger tU_QUERYFILTER_Audit 	
	end

	PRINT 'Update of Filter Criteria to include Trademarks successfull...'
End
go

set identity_insert QUERY on
go

if not exists (select * from QUERY where QUERYID = -25)
begin

	insert QUERY (QUERYID, CONTEXTID, IDENTITYID, QUERYNAME, DESCRIPTION, FILTERID)
	values (-25, 2, null, 'Innography Integration - Sample', 'A sample query returning cases for use with Innography Integration. The system will use this query to determine the list of cases eligible for integration.', -25)

end 
go

set identity_insert QUERY off
go

