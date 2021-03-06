set QUOTED_IDENTIFIER OFF

--	1. Apply procedure ip_GenerateQueryRules to the database.
--	2. Set your query analyser output to text.
--	3. Set the value of @ptXMLQueryRules to your prepared XML rules.
--	4. Run.
--	5. Copy output into new window and tidy up formatting as necessary.
--	6. Save as script.

exec ip_GenerateQueryRules
@pnUserIdentityId = 5,
@ptXMLQueryRules=
"
<!-- Rules for the creation of scripting to populate Query* database tables.
	 For use with the ip_GenerateQueryRules stored procedure. -->
<QueryRules>
	<ChangeReference>RFCxxx</ChangeReference>
	<Comment>Description of script</Comment>
	<!-- The default ContextID to be used throughout the document, unless specified otherwise -->
	<ContextID></ContextID> <!-- Allocate a +ve ID in logical groups. -->
	<!-- The default stored procedure name to be used throughout the document, unless specified otherwise -->
	<StoredProcedure></StoredProcedure>
	<!-- Fill in if the stored procedure re-uses functionality from other search stored procedures -->
	<ProcedureUsed>
		<ProcedureName></ProcedureName>
		<UsesProcedureName></UsesProcedureName>
		<ExcludeFilterNode></ExcludeFilterNode>
	</ProcedureUsed>
	<!-- Fill in if a new QueryContext entry is required -->
	<Context>
		<ContextID></ContextID> 
		<Name></Name>
		<Notes></Notes>
		<StoredProcedure></StoredProcedure>
	</Context>
	<!-- Create a Name to group columns together on the presentation screen -->
	<ColumnGroup>
		<GroupID></GroupID> <!-- Allocate a -ve ID in logical groups. -->
		<ContextID></ContextID>
		<GroupName></GroupName>
		<DisplaySequence></DisplaySequence>
	</ColumnGroup>
	<!-- Fill in if a new default QueryPresentation is required -->
	<Presentation>
		<PresentationID></PresentationID> <!-- Allocate a -ve ID - usually ContextID*-1 -->
		<ContextID></ContextID>
		<ReportTitle></ReportTitle>
		<ReportTemplate></ReportTemplate>
		<ReportTool></ReportTool>
		<ExportFormat></ExportFormat>
		<PresentationType></PresentationType>
	</Presentation>
	<!-- The first QueryColumn.ColumnID value to be inserted.  Assign a -ve number in logical groups.  -->
	<FirstColumnID></FirstColumnID>
	<!-- Fill in the following for each new QueryDataItem and/or QueryColumn is required -->
	<DataItemColumn>
		<ProcedureName></ProcedureName>
		<ProcedureItemID></ProcedureItemID>
		<!-- If the ProcedureItemID is new in the stored procedure, you will need to create a data item for it. -->
		<CreateDataItem>
			<DataItemDescription></DataItemDescription>
			<QualifierType></QualifierType> <!-- 1 Case Text Type, 2 Name Type, 3 Attribute Type, 4 Event No,
											5 Number Type, 6 Image Type, 7 Case Relation, 8 Alias Type,
											9 Telecom Type, 10 Name Text Type, 11 Importance Level,
											12 Fee Type, 13 Free Format -->
			<SortDirection></SortDirection> <!-- Default sort direction: A Ascending, D Descending, Null no sorting -->
			<IsMultiResult></IsMultiResult> <!-- Defaults to 0 -->
			<IsAggregate></IsAggregate> <!-- Defaults to 0 -->
			<DataFormatID></DataFormatID> <!-- Defaults to 9100 string
										9100 String, 9101 Integer, 9102 Decimal, 9103 Date, 9104 Time,
										9105 Date/Time, 9106 Boolean, 9107 Text, 9108 Currency, 9109 Local Currency,
										9110 Image Key, 9112 Email, 9113 TelecomNumber -->
			<DecimalPlaces></DecimalPlaces>
			<FilterNodeName></FilterNodeName>
			<FormatItemID></FormatItemID> <!-- A companion ProcedureItemID necessary for formating; e.g. LocalCurrencyCode -->
		</CreateDataItem>
		<!-- If you want the item to be visible as a column for selection, you will need to create a column for it. -->
		<CreateColumn>
			<ColumnLabel></ColumnLabel>
			<Qualifier></Qualifier>
			<Description></Description> <!-- if not provided, the description of the data item is used. -->
			<!-- For each Column, there must be at least one context of use before it is selectable by users. -->
			<CreateContextColumn>
				<ContextID></ContextID>
				<GroupID></GroupID> <!-- A grouping that the column is displayed under.  See ColumnGroup above. -->
				<IsMandatory></IsMandatory> <!-- Defaults to 0 -->
				<IsSortOnly></IsSortOnly> <!-- Defaults to 0 -->
				<Usage></Usage> <!-- Ensures column is returned with a particular internal name for use by the calling software. -->
			</CreateContextColumn>
			<!-- Add the column to the default presentation. -->
			<CreatePresentationContent>
				<PresentationID></PresentationID> <!-- Defaults to Presentation/PresentationID above. -->
				<DisplaySequence></DisplaySequence>
				<SortOrder></SortOrder>
				<SortDirection></SortDirection>
				<ContextID></ContextID>
			</CreatePresentationContent>
		</CreateColumn>
		<!-- Create implied data used for WorkBenches presentation -->
		<CreateImpliedData>
			<ImpliedDataID></ImpliedDataID> <!-- Assign a +ve number in logical groups. -->
			<ContextID></ContextID>
			<Type></Type>
			<Notes></Notes>
			<ImpliedItem>
				<SequenceNo></SequenceNo>	<!-- Defaults to 1.  A number beginning at 1 for each item within the ImpliedDataID. -->
				<ProcedureName></ProcedureName>
				<ProcedureItemID></ProcedureItemID>
				<UsesQualifier></UsesQualifier> <!-- Defaults to 0. Does the implied item use the same qualifier as the ProcedureItemID? -->
				<Usage></Usage> <!-- Ensures column is returned with a particular internal name for use by the calling software. -->
			</ImpliedItem>
		</CreateImpliedData>
	</DataItemColumn>
	<!-- Add an existing column to a ColumnContext -->
	<AddColumnToContext>
		<ColumnID></ColumnID>
		<ContextID></ContextID>
		<GroupID></GroupID> <!-- A grouping that the column is displayed under.  See ColumnGroup above. -->
		<IsMandatory></IsMandatory> <!-- Defaults to 0 -->
		<IsSortOnly></IsSortOnly> <!-- Defaults to 0 -->
		<Usage></Usage> <!-- Ensures column is returned with a particular internal name for use by the calling software. -->
	</AddColumnToContext>
	<!-- Add an existing column to the default presentation. -->
	<AddColumnToPresentation>
		<ColumnID></ColumnID>
		<PresentationID></PresentationID> <!-- Defaults to Presentation/PresentationID above. -->
		<DisplaySequence></DisplaySequence>
		<SortOrder></SortOrder>
		<SortDirection></SortDirection>
		<ContextID></ContextID>
	</AddColumnToPresentation>
	<!-- Create implied data used for WorkBenches presentation at the Context level -->
	<AddImpliedDataToContext>
		<ImpliedDataID></ImpliedDataID> <!-- Assign a +ve number in logical groups. -->
		<ContextID></ContextID>
		<Type></Type>
		<Notes></Notes>
		<ImpliedItem>
			<SequenceNo></SequenceNo>	<!-- Defaults to 1.  A number beginning at 1 for each item within the ImpliedDataID. -->
			<ProcedureName></ProcedureName>
			<ProcedureItemID></ProcedureItemID>
			<Usage></Usage> <!-- Ensures column is returned with a particular internal name for use by the calling software. -->
		</ImpliedItem>
	</AddImpliedDataToContext>
</QueryRules>
"

