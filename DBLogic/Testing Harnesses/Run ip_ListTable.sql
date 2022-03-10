declare @nRowCount int

EXEC dbo.ip_ListTable @pnUserIdentityId = 6,
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
    				<Column ID="Description" PublishName="Description" SortOrder="1" SortDirection="A" />
    				<Column ID="Code" PublishName="Code" />
   				<Column ID="Key" PublishName="Key" SortOrder="2" SortDirection="A"/>
			</OutputRequests>',
@ptXMLFilterCriteria = N'<ip_ListTable>
				<FilterCriteria>
					<TableTypeKey></TableTypeKey> 
					<Key></Key>
					<PickListSearch>Renewals Standard Discount</PickListSearch>
				        <Description Operator=""></Description>
					<Code Operator=""></Code>
				</FilterCriteria>
			</ip_ListTable>'

print @nRowCount





 





