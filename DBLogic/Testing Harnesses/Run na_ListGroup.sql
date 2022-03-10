declare @nRowCount int

EXEC dbo.na_ListGroup @pnUserIdentityId = 6,
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
    				<Column ID="GroupTitle" PublishName="Group" SortOrder="2" SortDirection="A" />
    				<Column ID=" GroupComments" PublishName="Comments" />
    				<Column ID="GroupKey" PublishName="GroupKey" SortOrder="1" SortDirection="A"/>
			</OutputRequests>',
@ptXMLFilterCriteria = N'<na_ListGroup>
				<FilterCriteria>						
				 	<GroupKey>0</GroupKey>
				</FilterCriteria>
			</na_ListGroup>'

print @nRowCount

/*



<GroupKey>0</GroupKey>
<PickListSearch>Brimstone</PickListSearch>
<GroupTitle Operator="0">Brimstone Group OF Companies</GroupTitle>
<GroupComments Operator="5">Companies</GroupComments>	
<IsStaffGroup>0</IsStaffGroup>		
*/



 





