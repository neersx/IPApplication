declare @nRowCount int

EXEC dbo.ipw_ListKeyWord @pnUserIdentityId = 26,
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
			    <Column ID="KeyWordKey" PublishName="KeyWordKey" SortOrder="2" SortDirection="A" />
			    <Column ID="KeyWord" PublishName="KeyWord" />
			    <Column ID="IsStopWord" PublishName="IsStopWord" SortOrder="1" SortDirection="A"/>
			   </OutputRequests>',
@ptXMLFilterCriteria = N'<ipw_ListKeyWord>
				<FilterCriteria>
					<CaseKey Operator="0">-487</CaseKey>
				    <KeyWordKey Operator="0">-477</KeyWordKey>	
					<PickListSearch>SHOE</PickListSearch>	
					<KeyWord Operator="2">s</KeyWord>
					<IsStopWord>0</IsStopWord>	
				</FilterCriteria>
			</ipw_ListKeyWord>'


print @nRowCount



 





