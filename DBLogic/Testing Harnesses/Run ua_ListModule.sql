declare @nRowCount int

EXEC dbo.ua_ListModule @pnUserIdentityId = 5,
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
			    <Column ID="ModuleKey" PublishName="ModuleKey" SortOrder="2" SortDirection="A" />
			    <Column ID="Title" PublishName="Title" />
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
<ua_ListModule>
	<FilterCriteria>
	    <ModuleKey Operator="1">-1</ModuleKey>	
		<Title Operator="4">S</Title>
		<IsExternal>1</IsExternal>			
		<IsInternal>0</IsInternal>
		<PickListSearch>w</PickListSearch>
	</FilterCriteria>
</ua_ListModule>'

print @nRowCount



 










