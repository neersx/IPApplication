declare @nRowCount int

EXEC dbo.ac_ListProfitCentre @pnUserIdentityId = 26,
@psCulture = 'ZH-CHS',
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
			    <Column ID="ProfitCentreCode" PublishName="ProfitCentreCode" SortOrder="2" SortDirection="A" />
			    <Column ID="EntityKey" PublishName="EntityKey" />
			    <Column ID="Entity" PublishName="Entity" SortOrder="1" SortDirection="A"/>
			    <Column ID="Description" PublishName="Description" SortOrder="3" SortDirection="A"/>
			   </OutputRequests>',
@ptXMLFilterCriteria = N'<ac_ListProfitCentre>
				<FilterCriteria>
				    <ProfitCentreCode Operator=""></ProfitCentreCode>	
					<PickListSearch></PickListSearch>	
					<EntityKey Operator=""></EntityKey>
					<Description Operator=""></Description>			
				</FilterCriteria>
			</ac_ListProfitCentre>'


print @nRowCount



 





