declare @nRowCount int

exec csw_ListCase
@pnUserIdentityId = 5,
@pnRowCount = @nRowCount output,
@pnQueryContextKey = 2,
@ptXMLOutputRequests=
'<OutputRequests>
    <Column ID="CaseReference" PublishName="Reference" SortOrder="1" SortDirection="A" />
    <Column ID="DisplayName" Qualifier="I" PublishName="Instructor"/>
    <Column ID="CaseKey" SortOrder="2" SortDirection="A" />
</OutputRequests>',
@ptXMLFilterCriteria=
'<csw_ListCase>
	<FilterCriteriaGroup>
		<FilterCriteria >
			<CaseReference Operator="2">1234</CaseReference>
		</FilterCriteria>
	</FilterCriteriaGroup>
</csw_ListCase>',
@pbCalledFromCentura=0,
@pnCallingLevel=3

print @nRowCount