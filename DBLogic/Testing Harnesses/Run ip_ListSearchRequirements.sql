declare @sProcedureName nvarchar(50)

exec ip_ListSearchRequirements
@psProcedureName = @sProcedureName output,
@pnUserIdentityId = 5,
@psCulture=null,
@pnQueryContextKey = 2,
@pnQueryKey = null
--@ptXMLSelectedColumns =
--'<SelectedColumns>
--	<Column>
--		<ColumnKey>-77</ColumnKey>
--		<DisplaySequence>1</DisplaySequence>
--		<SortOrder>1</SortOrder>
--		<SortDirection>A</SortDirection>
--	</Column>
--	<Column>
--		<ColumnKey>-15</ColumnKey>
--		<DisplaySequence>2</DisplaySequence>
--	</Column>
--	<Column>
--		<ColumnKey>-39</ColumnKey>
--		<DisplaySequence>3</DisplaySequence>
--	</Column>
--</SelectedColumns>
--'

print @sProcedureName

