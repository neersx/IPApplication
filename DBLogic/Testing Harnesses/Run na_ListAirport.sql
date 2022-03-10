declare @nRowCount int

EXEC dbo.na_ListAirport @pnUserIdentityId = 6,
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
			    <Column ID="AirportKey" PublishName="AirportKey" SortOrder="2" SortDirection="A" />
			    <Column ID="AirportName" PublishName="AirportName" />
			    <Column ID="CountryKey" PublishName="CountryKey" SortOrder="1" SortDirection="A"/>
			    <Column ID="CountryName" PublishName="CountryName" SortOrder="3" SortDirection="A" />
			    <Column ID="StateName" PublishName="StateName" />
			    <Column ID="CityName" PublishName="CityName" SortOrder="4" SortDirection="D"/>
			  </OutputRequests>',
@ptXMLFilterCriteria = N'<na_ListAirport>
				<FilterCriteria>					
				<CityName Operator="1">Melbourne</CityName>
				</FilterCriteria>
			</na_ListAirport>'


/*

<AirportKey Operator="2">LON</AirportKey> 
<PickListSearch>CHr</PickListSearch>			
<AirportName Operator="3">area</AirportName>
<CountryKey Operator="4">gb</CountryKey>
<StateName Operator="1">New South Wales</StateName>		

*/

print @nRowCount



 





