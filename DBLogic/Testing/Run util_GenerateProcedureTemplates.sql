set QUOTED_IDENTIFIER OFF

--	1. Apply procedure util_GenerateProcedureTemplates to the database.
--	2. Set your query analyser output to text.
--	3. Set the value of @ptXMLSPRules to your prepared XML rules.
--	4. Run.
--	5. Copy output into new window and tidy up formatting as necessary.
--	6. Save as stored procedures.

exec util_GenerateProcedureTemplates
@pnUserIdentityId = 5,
@ptXMLSPRules=
'<?xml version="1.0" ?> 
<StoredProcedureRules>
	<DatabaseTable>
		<TableName></TableName>
		<InternalName></InternalName>
		<Prefix></Prefix>
	</DatabaseTable>
	<DatabaseColumns>
		<DatabaseColumn>
			<ColumnName></ColumnName>
			<PropertyName></PropertyName>
		</DatabaseColumn>		
	</DatabaseColumns>
	<FetchCriteria>
		<DatabaseColumns>
			<ColumnName></ColumnName>
		</DatabaseColumns>
	</FetchCriteria>
</StoredProcedureRules>'



