declare @nRowCount int

exec naw_ListName
@pnUserIdentityId = 5,
@pnRowCount = @nRowCount output,
@pnQueryContextKey = 10,
@ptXMLOutputRequests=
'<OutputRequests>
    <Column ID="DisplayName" PublishName="Name" SortOrder="1" SortDirection="A" />
    <Column ID="Text" PublishName="Extended Name" Qualifier="N" />
    <Column ID="NameKey" SortOrder="2" SortDirection="A" />
</OutputRequests>',
@ptXMLFilterCriteria=N'
<?xml version="1.0" ?> 
<naw_ListName>
	<FilterCriteriaGroup>		
		<FilterCriteria BooleanOperator="">	
			<NameCode Operator="0">001234</NameCode> 
			<AddedNamesGroup>
				<NameKey>1</NameKey>
				<NameKey>2</NameKey>
			</AddedNamesGroup>
			<SelectedNamesGroup Operator="1"> <!-- Operator=0 include Names; Operator=1 exclude Names -->
				<NameKey>1</NameKey>
			</SelectedNamesGroup>
		</FilterCriteria>	
		<FilterCriteria BooleanOperator="or">	
			<NameCode Operator="2">ACME</NameCode> 
		</FilterCriteria>		    
	</FilterCriteriaGroup>	   
</naw_ListName>',
@pnCallingLevel	= null,	
@pbPrintSQL=0

print @nRowCount

/*
N'<?xml version="1.0" ?> 
  <naw_ListName>
   <FilterCriteriaGroup>
    <FilterCriteria BooleanOperator="">
	<AddedNamesGroup>
		<NameKey></NameKey> <!-- Names manually added to the result set -->
	</AddedNamesGroup>
	<SelectedNamesGroup Operator=""> <!-- Operator=0 include Names; Operator=1 exclude Names -->
		<NameKey></NameKey> <!-- Names that have been ticked for inclusion or exclusion depending on Operator-->
	</SelectedNamesGroup>
	<AnySearch /> 
	<NameKey /> 
	<PickListSearch />

	<EntityFlags>
		<IsOrganisation></IsOrganisation>
		<IsIndividual></IsIndividual>
		<IsStaff>1</IsStaff>
	</EntityFlags>

	<IsClient></IsClient> 
	<IsSupplier>0</IsSupplier> 
	<IsCurrent>1</IsCurrent>  
	<IsCeased>1</IsCeased>

	<SearchKey Operator="0" UseSearchKey1="" UseSearchKey2="" UseSoundsLike="1">BRIMSTONE HOLDING</SearchKey> 

	<Name Operator="1" UseSoundsLike="1" >BRIm</Name> 
	
	<NameCode Operator="0">tren</NameCode> 
	
	<FirstName Operator="0" >aNN</FirstName>  

	<LastChanged Operator="7">
		<DateFrom>1995-04-17 17:42:04.110</DateFrom>
		<DateTo>2003-04-17 17:42:04.110</DateTo>
	</LastChanged>

	<Remarks Operator="8">wS</Remarks>

	<Address>
		<CountryKey Operator="0">AU</CountryKey>
		<StateKey Operator="0">NSW</StateKey>
		<City Operator="0">Sydney</City>
		<Street1 Operator="2">23rd</Street1>
		<PostCode Operator = ""></PostCode>
	</Address>

	<NameGroupKey Operator="0">-499</NameGroupKey>
	<NameTypeKey Operator=""></NameTypeKey>
	<SuitableForNameTypeKey>O</SuitableForNameTypeKey> 
	<AirportKey Operator=""></AirportKey>
	<NameCategoryKey Operator="6">7</NameCategoryKey>
	<BadDebtorKey Operator="8">1</BadDebtorKey>
	<FilesInKey Operator="6">GB</FilesInKey>

	<NameText Operator="6">
		<TypeKey>N</TypeKey>
		<Text>1.  Ensure that their Order Letter No.</Text>
	</NameText>

	<InstructionKey Operator="8">40</InstructionKey>
	<ParentNameKey Operator="6">42</ParentNameKey>

	<AssociatedName Operator="0" IsReverseRelationship="1">
		<RelationshipKey>EMP</RelationshipKey>
		<NameKeys>42</NameKeys>
	</AssociatedName>

	<MainPhone>
		<Number Operator="5">2411 3061 </Number>
		<AreaCode Operator="0">3</AreaCode>
	</MainPhone>

	<AttributeGroup BooleanOr="1">	
		<Attribute Operator="0">
		<TypeKey>26</TypeKey>		
		<AttributeKey>2601</AttributeKey>
		</Attribute>

		<Attribute Operator="1">
		<TypeKey>25</TypeKey>		
		<AttributeKey>2602</AttributeKey>
		</Attribute>

		<Attribute Operator="1">
		<TypeKey>27</TypeKey>		
		<AttributeKey>2607</AttributeKey>
		</Attribute>
		</AttributeGroup>


	<NameAlias Operator="2">
		<TypeKey>AA</TypeKey>
		<Alias>t</Alias>
	</NameAlias>

	<TypeKey /> 
	<Alias /> 
	</NameAlias>
	<QuickIndex Operator="1">-1</QuickIndex>	
	<BillingCurrency Operator="0">USD</BillingCurrency>
	<TaxRateKey Operator="5">0</TaxRateKey>
	<DebtorTypeKey Operator="5">10266</DebtorTypeKey>
	<PurchaseOrderNo Operator="6">0</PurchaseOrderNo>

	<ReceivableTerms Operator="8">
		<FromDays>1</FromDays>
		<ToDays>6</ToDays>
	</ReceivableTerms>

	<BillingFrequency Operator="7">5</BillingFrequency>	 
	<IsLocalClient Operator="1">0</IsLocalClient>	

    </FilterCriteria>
   </FilterCriteriaGroup>
  </naw_ListName>'
*/