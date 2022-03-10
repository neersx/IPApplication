declare @nRowCount int

EXEC dbo.ua_ListDataTopic @pnUserIdentityId = 5,
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
			    <Column ID="DataTopicKey" PublishName="DataTopicKey" SortOrder="2" SortDirection="A" />
			    <Column ID="Name" PublishName="Name" />
			    <Column ID="Description " PublishName="Description " SortOrder="1" SortDirection="A"/>
			    <Column ID="IsExternal" PublishName="IsExternal" SortOrder="3" SortDirection="A" />
			    <Column ID="IsInternal" PublishName="IsInternal" SortOrder="3" SortDirection="A" />				
			 </OutputRequests>',
@ptXMLFilterCriteria = N'<?xml version="1.0"?>
<!--	Operator attributes may have the following values
			0	Equal To
			1	Not Equal To
			2	Starts With
			3	Ends With
			4	Contains
			5	Is Not Null (exists)
			6	Is Null (not exists)
			7	Between
			8	Not Between
		Note: only appriate values are implemented for each element.
-->
<ua_ListDataTopic>
	<FilterCriteria>
	    <DataTopicKey Operator="1">100</DataTopicKey>	
		<Name Operator="4">b</Name>
		<IsExternal>1</IsExternal>			
		<IsInternal>1</IsInternal>
		<PickListSearch>b</PickListSearch>
	</FilterCriteria>
</ua_ListDataTopic>'

print @nRowCount



 










