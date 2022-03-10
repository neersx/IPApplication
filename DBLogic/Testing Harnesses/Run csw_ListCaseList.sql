declare @nRowCount int

EXEC dbo.csw_ListCaseList @pnUserIdentityId = 5,
@psCulture = null,
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
			    <Column ID="CaseListKey" PublishName="CaseListKey" SortOrder="2" SortDirection="A" />
			    <Column ID="ListName" PublishName="ListName" />
			    <Column ID="ListDescription" PublishName="ListDescription" SortOrder="1" SortDirection="A"/>			   
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
<csw_ListCaseList>
	<FilterCriteria>
	    <CaseListKey Operator=""></CaseListKey>	
		<PickListSearch></PickListSearch>	
		<ListName Operator=""></ListName>
		<ListDescription Operator=""></ListDescription>	
	</FilterCriteria>
</csw_ListCaseList>'

print @nRowCount



 





