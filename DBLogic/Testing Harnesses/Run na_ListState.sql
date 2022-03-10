declare @nRowCount int

EXEC dbo.na_ListState @pnUserIdentityId = 6,
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
    				<Column ID="StateName" PublishName="StateName" SortOrder="2" SortDirection="A" />
    				<Column ID="CountryName" PublishName="CountryName" />
    				<Column ID="CountryKey" PublishName="CountryKey" SortOrder="1" SortDirection="A"/>
			        <Column ID="StateKey" PublishName="StateKey" SortOrder="3" SortDirection="A"/>
			</OutputRequests>',
@ptXMLFilterCriteria = N'<na_ListState>
				<FilterCriteria>						
					<StateName Operator="4">c</StateName>
				</FilterCriteria>
			</na_ListState>'

print @nRowCount


/*

<StateKey Operator="2">NS</StateKey>		
<PickListSearch>Rj</PickListSearch>
<CountryKey Operator="4">a</CountryKey>

*/



 





