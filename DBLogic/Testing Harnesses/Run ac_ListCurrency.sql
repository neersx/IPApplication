declare @nRowCount int

EXEC dbo.ac_ListCurrency @pnUserIdentityId = 26,
@pnRowCount = @nRowCount output,
@psCulture = null,-- 'ZH-CHS',
@ptXMLOutputRequests = N'<OutputRequests>
			    <Column ID="CurrencyKey" PublishName="CurrencyKey" SortOrder="2" SortDirection="A" />
			    <Column ID="CurrencyCode" PublishName="CurrencyCode" />
			    <Column ID="CurrencyDescription" PublishName="CurrencyDescription" SortOrder="1" SortDirection="A"/>
			    <Column ID="DecimalPlaces" PublishName="DecimalPlaces"/>
			  </OutputRequests>',
@ptXMLFilterCriteria = N'<ac_ListCurrency>
				<FilterCriteria>
				    <CurrencyKey Operator=""></CurrencyKey>	
					<Description Operator=""></Description>
					<PickListSearch></PickListSearch>
				</FilterCriteria>
			</ac_ListCurrency>'

print @nRowCount



 





