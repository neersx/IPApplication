declare @nRowCount int

EXEC dbo.ua_ListTask @pnUserIdentityId = 5,
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
			    <Column ID="TaskKey" PublishName="TaskKey" SortOrder="2" SortDirection="A" />
			    <Column ID="TaskName" PublishName="Name" />
			    <Column ID="Description " PublishName="Description " SortOrder="1" SortDirection="A"/>
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
<ua_ListTask>
	<FilterCriteria>
	    <TaskKey Operator="1">1</TaskKey>	
		<Name Operator="4">maiNtain</Name>	
		<PickListSearch>maintain r</PickListSearch>
	</FilterCriteria>
</ua_ListTask>'

print @nRowCount



 










