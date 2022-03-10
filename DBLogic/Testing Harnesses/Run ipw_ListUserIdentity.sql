declare @nRowCount int

EXEC dbo.ipw_ListUserIdentity @pnUserIdentityId = 5,
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
			    <Column ID="IdentityKey" PublishName="IdentityKey" SortOrder="2" SortDirection="A" />
			    <Column ID="LoginID" PublishName="LoginID" />
			    <Column ID="IdentityNameKey" PublishName="IdentityNameKey" SortOrder="1" SortDirection="A"/>
			    <Column ID="DisplayName" PublishName="DisplayName" SortOrder="3" SortDirection="A" />
			    <Column ID="NameCode" PublishName="NameCode" />
			    <Column ID="DisplayEmail" PublishName="DisplayEmail" SortOrder="4" SortDirection="D"/>
			    <Column ID="IsInternalUser" PublishName="IsInternalUser" />
			    <Column ID="IsExternalUser" PublishName="IsExternalUser" />
			    <Column ID="IsAdministrator" PublishName="IsAdministrator" />
			    <Column ID="AccessAccountKey" PublishName="AccessAccountKey" />
			    <Column ID="AccessAccountName" PublishName="AccessAccountName" />			    
			    <Column ID="IsIncompleteWorkBench" PublishName="IsIncompleteWorkBench" />
			    <Column ID="IsIncompleteInprostart" PublishName="IsIncompleteInprostart" />		           
			    <Column ID="PortalKey" PublishName="PortalKey" />		
			    <Column ID="PortalName" PublishName="PortalName" />		           
			    <Column ID="PortalDescription" PublishName="PortalDescription" />	
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
<ipw_ListUserIdentity>
	<FilterCriteria>
		<IdentityKey Operator="0">110</IdentityKey>
		<LoginID Operator="0"></LoginID>
		<NameKey Operator="0">-487</NameKey>
		<IsExternalUser>0</IsExternalUser>
		<IsAdministrator>0</IsAdministrator>
		<EmailAddress Operator="5"></EmailAddress>
		<AccessAccountKey Operator="0">-1</AccessAccountKey>
		<RoleKey Operator="0"></RoleKey>			
		<IsIncompleteWorkBench></IsIncompleteWorkBench>
		<IsIncompleteInprostart></IsIncompleteInprostart>	
		<PortalKey Operator="0">-3</PortalKey>		
	</FilterCriteria>
</ipw_ListUserIdentity>'

print @nRowCount


