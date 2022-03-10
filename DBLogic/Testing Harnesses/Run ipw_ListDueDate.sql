Declare @nRowCount int

EXEC dbo.ipw_ListDueDate @pnRowCount = @nRowCount output,
			 @pnUserIdentityId = 5, 
			 @pnQueryContextKey = 160, 
			 @ptXMLOutputRequests = NULL, 
			 @pbPrintSQL = 1,	
			 @ptXMLFilterCriteria = 
N'<ipw_ListDueDate>
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
<!--	All other attributes have bit values (i.e. 0, 1 or null) unless
		explicitly documented.  If null, 0 will be assumed.
-->
	<FilterCriteria>
		<!-- Set flags to 0/1 as required. -->
		<SearchType>
			<IsEvent>1</IsEvent>
			<IsAdHoc>1</IsAdHoc>
			<HasCase>1</HasCase>
			<IsGeneral>1</IsGeneral>
		</SearchType>
		<BelongsTo>
			<!-- IsCurrentUser: use the name key of the current user. -->
			<NameKey Operator="" IsCurrentUser=""></NameKey>
			<!-- MemberOfGroupKey return due dates for all the names belonging to
			     the supplied GroupKey.
				 IsCurrentUser: use the group key of the current user. -->
			<MemberOfGroupKey Operator="" IsCurrentUser=""></MemberOfGroupKey>
			<!-- IsRecipient indicates whether a reminder or Ad Hoc Date is addressed to the user. -->
			<ActingAs IsRecipient="">
				<!-- Multiple occurrences of NameTypeKey may be specified -->
				<NameTypeKey></NameTypeKey>							
			</ActingAs>
		</BelongsTo>
		<!-- Use either DateRange or Period, not both. -->
		<Dates UseDueDate="" UseReminderDate="">
			<DateRange Operator="">
				<From></From>
				<To></To>
			</DateRange>
			<PeriodRange Operator="">
				<!-- Type: D-Days,W–Weeks,M–Months,Y-Years -->
				<Type></Type>
				<!-- From, To: Use negative numbers for past periods -->
				<From></From>
				<To></To>
			</PeriodRange>
		</Dates>
		<Actions IsRenewalsOnly="" IsNonRenewalsOnly="" IncludeClosed="">
			<ActionKey Operator=""></ActionKey>
		</Actions>
		<ImportanceLevel Operator="">
			<From></From>
			<To></To>
		</ImportanceLevel>
		<EventKey Operator=""></EventKey>
		<!-- Any filter criteria that can be used for the case search. -->
		<csw_ListCase>
			<FilterCriteriaGroup>
				<FilterCriteria BooleanOperator="">
					<AddedCasesGroup>
						<CaseKey></CaseKey>	<!-- Cases manually added to the result set -->
					</AddedCasesGroup>
					<SelectedCasesGroup Operator=""> <!-- Operator=0 include Cases; Operator=1 exclude cases -->
						<CaseKey></CaseKey>	<!-- Cases that have been ticked for inclusion or exclusion depending on Operator-->
					</SelectedCasesGroup>
					<AnySearch></AnySearch>		<!-- Quick search on a variety of criteria
												If provided, all other filter criteria is ignored -->
					<CaseKey></CaseKey>
					<PickListSearch></PickListSearch>
					<!-- IsWithinFileCover=1: Also select any case where CaseReference is 
					defined as the FileCover -->
					<CaseReference Operator="4" IsWithinFileCover="">2</CaseReference>
					<!-- UseCurrent=1: Search the current official number => NumberType is ignored. -->
					<!-- UseRelatedCase=1: Search related cases => NumberType is ignored. -->
					<!-- UseNumericSearch=1: Ignore non-numeric characters. -->
					<OfficialNumber Operator="1" UseCurrent="" UseRelatedCase="">
						<TypeKey></TypeKey>
						<Number UseNumericSearch="">123</Number>
					</OfficialNumber>					
				</FilterCriteria>
			</FilterCriteriaGroup>	
		</csw_ListCase>
	</FilterCriteria>
</ipw_ListDueDate>'

print @nRowCount



				 
	