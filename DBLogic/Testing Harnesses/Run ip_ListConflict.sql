declare @nRowCount 	int
declare @nCaseRowCount	int
declare @sSearchTerms	nvarchar(4000)
declare	@sNameFields	nvarchar(4000)
declare @sCaseFields	nvarchar(4000)

exec ip_ListConflict
	@pnRowCount = @nRowCount output,
	@pnCaseRowCount = @nCaseRowCount output,
	@psSearchTerms=@sSearchTerms output,
	@psNameFields=@sNameFields output,
	@psCaseFields=@sCaseFields output,
	@pnUserIdentityId = -1,
	@psCulture=null,
	@pnQueryContextKey = 250,
@ptXMLNameOutputRequests=
'<?xml version="1.0"?>
<OutputRequests>
<Column ID="NameKey" PublishName="Name Key" ProcedureName="ip_ListConflict" DisplaySequence="1" DataFormatId="9101" ColumnHiddenFlag="0" ColumnId="-2701"></Column>
<Column ID="RecordType" PublishName="Record Type" ProcedureName="ip_ListConflict" DisplaySequence="2" DataFormatId="9101" ColumnHiddenFlag="0" ColumnId="-2700"></Column>
<Column ID="IsAssociatedNameDescription" PublishName="Associated Name Flag" ProcedureName="ip_ListConflict" DisplaySequence="3" DataFormatId="9100" ColumnHiddenFlag="0" ColumnId="-2702"></Column>
</OutputRequests>',
@ptXMLCaseOutputRequests=
'<?xml version="1.0"?>
<OutputRequests>
<Column ID="CaseKey" PublishName="Case Key" DisplaySequence="1" DataFormatId="9101" ColumnHiddenFlag="1" ColumnId="-146"></Column>
<Column ID="CaseReference" PublishName="Case Ref." DisplaySequence="1" DataFormatId="9100" SortDirection="A" SortOrder="1" ColumnId="-77"></Column>
<Column ID="CurrentOfficialNumber" PublishName="Official No." DisplaySequence="2" DataFormatId="9100" ColumnId="-3"></Column>
<Column ID="ShortTitle" PublishName="Title" DisplaySequence="3" DataFormatId="9100" ColumnId="-15"></Column>
<Column ID="StatusDescription" PublishName="Case Status" DisplaySequence="4" DataFormatId="9100" ColumnId="-14"></Column>
<Column ID="CaseTypeDescription" PublishName="Case Type" DisplaySequence="5" DataFormatId="9100" ColumnId="-6"></Column>
<Column ID="CountryName" PublishName="Country" DisplaySequence="6" DataFormatId="9100" ColumnId="-7"></Column>
<Column ID="PropertyTypeDescription" PublishName="Property Type" DisplaySequence="7" DataFormatId="9100" ColumnId="-8"></Column>
<Column ID="LocalClasses" PublishName="Local Classes" DisplaySequence="8" DataFormatId="9100" ColumnId="-69"></Column>
<Column ID="DisplayName" Qualifier="A" PublishName="Agent" DisplaySequence="9" DataFormatId="9100" ColumnTitle="Agent" ColumnId="-92"></Column>
</OutputRequests>',
@ptXMLFilterFields=
'<ip_ListConflict>
	<FilterFields>
		<NameFields>
			<FieldKey>-1</FieldKey>
			<FieldKey>-2</FieldKey>
			<FieldKey>-5</FieldKey>
			<FieldKey>-6</FieldKey>
			<FieldKey>-7</FieldKey>
			<FieldKey>-8</FieldKey>
		</NameFields>
		<CaseFields>
			<FieldKey>-3</FieldKey>
			<FieldKey>-4</FieldKey>
			<FieldKey>-9</FieldKey>
			<FieldKey>-11</FieldKey>
			<FieldKey>-12</FieldKey>
		</CaseFields>
	</FilterFields>
</ip_ListConflict>',
@ptXMLFilterCriteria=
'<ip_ListConflict>
	<FilterCriteria>
		<SearchTerm>
			<TermGroup>
				<Term BooleanOperator="" Operator="4">Brimstone</Term>
				<Term BooleanOperator="OR" Operator="0">Butler</Term>
				<Term BooleanOperator="OR" Operator="0">Fisher</Term>
			</TermGroup>
		</SearchTerm>
		<Results>
			<ShowMatchingName>1</ShowMatchingName>
			<AssociatedNames Operator="0">
				<RelationshipGroup>
					<RelationshipKey>REL</RelationshipKey>
				</RelationshipGroup>
			</AssociatedNames>
			<ShowMatchingCase>0</ShowMatchingCase>
			<ShowCasesForName>1</ShowCasesForName>
		</Results>
	</FilterCriteria>
</ip_ListConflict>',
@pbSingleResultSet=0,
@pbCalledFromCentura=0,
@pnCallingLevel=0,
@pbPrintSQL=0

select 	@nRowCount, @nCaseRowCount
select	@sSearchTerms
select	@sNameFields
select	@sCaseFields