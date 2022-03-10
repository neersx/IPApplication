declare @nRowCount int

EXEC dbo.ua_ListPortal @pnUserIdentityId = 5,
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
			    <Column ID="PortalKey" PublishName="PortalKey" SortOrder="2" SortDirection="A" />
			    <Column ID="Name" PublishName="Name" />
			    <Column ID="Description " PublishName="Description " SortOrder="1" SortDirection="A"/>
			    <Column ID="IsExternal" PublishName="IsExternal" SortOrder="3" SortDirection="A" />
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
<ua_ListPortal>
	<FilterCriteria>
	    <SelectedRoles>
			<!-- RoleKeys may repeat as long as each occurrence has a different RoleKey -->
			<RoleKey>-1</RoleKey>
			<RoleKey>-2</RoleKey>
			<RoleKey>-3</RoleKey>
			<RoleKey>-4</RoleKey>
			<RoleKey>-5</RoleKey>
			<RoleKey>-10</RoleKey>
		</SelectedRoles>
		<PickListSearch>cLIE</PickListSearch>
		<PortalKey Operator="1">-5</PortalKey>	
		<Name Operator=""></Name>
		<Description Operator="4">To Do</Description>
		<IsExternal>1</IsExternal>			
	</FilterCriteria>
</ua_ListPortal>'

print @nRowCount



 










