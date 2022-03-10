declare @nRowCount int

EXEC dbo.ua_ListRole @pnUserIdentityId = 5,
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
    				<Column ID="RoleKey" PublishName="RoleKey" SortOrder="2" SortDirection="A" />
    				<Column ID="RoleName" PublishName="RoleName" />
    				<Column ID="Description" PublishName="Description" SortOrder="4" SortDirection="A"/>
				<Column ID="IsExternal" PublishName="IsExternal"/>								
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
<ua_ListRole>
	<FilterCriteria>
		<RoleKey Operator=""></RoleKey>
		<PickListSearch></PickListSearch>
		<RoleName Operator=""></RoleName>
		<Description Operator=""></Description>
		<IsExternal></IsExternal>
		<PermissionsGroup>
			<!-- Multiple Permissions elements may be provided. -->
			<Permissions Operator="0">
				<!-- ObjectTable: e.g. MODULE, DATATOPIC, TASK -->
				<ObjectTable>DATATOPIC</ObjectTable>
				<!-- Use either integer or string keys as suits the ObjectTable -->
				<ObjectIntegerKey></ObjectIntegerKey>
				<ObjectStringKey></ObjectStringKey>
				<!-- IsDenied=1 returns denied perissions
						otherwise returns granted permissions -->
				<Permission IsDenied="">
					<!-- The required flags should be set to 1 -->
					<CanSelect>1</CanSelect>
					<IsMandatory></IsMandatory>
					<CanInsert></CanInsert>
					<CanUpdate></CanUpdate>
					<CanDelete></CanDelete>
					<CanExecute></CanExecute>
				</Permission>
			</Permissions>
		</PermissionsGroup>
	</FilterCriteria>
</ua_ListRole>'

print @nRowCount



 





