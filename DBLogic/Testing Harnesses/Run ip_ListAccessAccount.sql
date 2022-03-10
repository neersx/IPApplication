declare @nRowCount int

exec ip_ListAccessAccount
@pnUserIdentityId = 5,
@pnRowCount = @nRowCount output,
@pnQueryContextKey = 60,
@ptXMLOutputRequests=
'<OutputRequests>
    <Column ID="AccountKey" PublishName="Key" />
    <Column ID="NameCode" PublishName="NameCode" />	
    <Column ID="AccountName" PublishName="Account" SortOrder="1" SortDirection="A" />
    <Column ID="NameKey" PublishName="NameKey" />
    <Column ID="DisplayName" PublishName="Name"/>
</OutputRequests>',
@ptXMLFilterCriteria=
'<ip_ListAccessAccount>
	<FilterCriteria>
		<AccountName Operator="2">B</AccountName>
	</FilterCriteria>
</ip_ListAccessAccount>'

print @nRowCount