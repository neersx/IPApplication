declare @nRowCount int

EXEC dbo.mk_ListContactActivity @pnUserIdentityId = 5,
@psCulture = 'PT-BR',
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
				<Column ID="ActivityCategory" PublishName="ActivityCategory" SortOrder="2" SortDirection="A" />			    
				<Column ID="ActivityDate" PublishName="ActivityDate" SortOrder="1" SortDirection="D" />		
				<Column ID="ActivityKey" PublishName="ActivityKey" />
				<Column ID="ActivityType" PublishName="ActivityType" />		
				<Column ID="AttachmentCount" PublishName="AttachmentCount" />	
				<Column ID="CallerKey" PublishName="CallerKey" />						
				<Column ID="CallerName" PublishName="CallerName" />	
				<Column ID="CallerNameCode" PublishName="CallerNameCode" />	
				<Column ID="CaseKey" PublishName="CaseKey" />	
				<Column ID="CaseReference" PublishName="CaseReference" />	
				<Column ID="ContactKey" PublishName="ContactKey" />	
				<Column ID="ContactName" PublishName="ContactName" />	
				<Column ID="ContactNameCode" PublishName="ContactNameCode" />	
				<Column ID="FirstAttachmentFilePath" PublishName="FirstAttachmentFilePath" />	
				<Column ID="IsIncomingCall" PublishName="IsIncomingCall" />	
				<Column ID="IsIncomplete" PublishName="IsIncomplete" />	
				<Column ID="IsOutgoingCall" PublishName="IsOutgoingCall" />	
				<Column ID="Notes" PublishName="Notes" />	
				<Column ID="Reference" PublishName="Reference" />
				<Column ID="ReferredToKey" PublishName="ReferredToKey" />	
				<Column ID="ReferredToName" PublishName="ReferredToName" />
				<Column ID="ReferredToNameCode" PublishName="ReferredToNameCode" />		
				<Column ID="RegardingNameKey" PublishName="RegardingNameKey" />	
				<Column ID="RegardingName" PublishName="RegardingName" />
				<Column ID="RegardingNameCode" PublishName="RegardingNameCode" />	
				<Column ID="StaffKey" PublishName="StaffKey" />	
				<Column ID="StaffName" PublishName="StaffName" />
				<Column ID="StaffNameCode" PublishName="StaffNameCode" />	
				<Column ID="Summary" PublishName="Summary" />
				<Column ID="AttachmentName" PublishName="AttachmentName" />	
				<Column ID="AttachmentType" PublishName="AttachmentType" />				
				<Column ID="AttachmentDescription" PublishName="AttachmentDescription" />
				<Column ID="FilePath" PublishName="FilePath" />		
				<Column ID="IsPublic" PublishName="IsPublic" />				
				<Column ID="Language" PublishName="Language" />
				<Column ID="PageCount" PublishName="PageCount" />		
			  </OutputRequests>',
@ptXMLFilterCriteria = N'<!--	Operator attributes may have the following values
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
<mk_ListContactActivity>
	<FilterCriteria>
	    <ActivityKey Operator="5"></ActivityKey>
		<!-- Activities are returned where either the
				contact person or name match. -->
		<ContactParty>
			<!-- Search for rows involving contact with a particular person:
					IsContact = 1 - where the person was recorded as the Contact
					IsName = 1 - where the person was recorded as the related Name
					Setting both IsContact and IsName will return rows where the person
					was recorded as either Contact or related Name. -->
			<ContactPersonKey Operator="" IsContact="" IsName=""></ContactPersonKey>
			<!-- Search for rows involving contact with a particular related Name. -->
			<ContactNameKey Operator=""></ContactNameKey>
		</ContactParty>
		<StaffKey Operator=""></StaffKey>
		<CallerKey Operator=""></CallerKey>
		<CaseKey Operator=""></CaseKey>
		<ReferredToKey Operator=""></ReferredToKey>
		<Reference Operator=""></Reference>
		<CategoryKey Operator=""></CategoryKey>
		<TypeKey Operator=""></TypeKey>
		<!-- Use either DateRange or Period, not both. -->
		<ActivityDate>
			<DateRange Operator="">
				<From></From>
				<To></To>
			</DateRange>
			<PeriodRange Operator="">
				<!-- Type: D-Days,W–Weeks,M–Months,Y-Years -->
				<Type></Type>
				<!-- From, To: Always refers to past periods - use positive numbers -->
				<From></From>
				<To></To>
			</PeriodRange>
		</ActivityDate>
		<!-- Search for the Word in the Summary, the Notes, or either. -->
		<Word Operator="" UseSummary="" UseNotes=""></Word>
		<!-- CallDirection flags are ORed together -->
		<CallDirection>
			<IsIncoming>1</IsIncoming>
			<IsOutgoing>1</IsOutgoing>
		</CallDirection>
		<!-- CallStatus flags are ORed together -->
		<CallStatus>
			<IsContacted>1</IsContacted>
			<IsLeftMessage>1</IsLeftMessage>
			<IsNoAnswer>1</IsNoAnswer>
			<IsBusy>1</IsBusy>
		</CallStatus>
		<!-- ActivityStatus flags are ORed together -->
		<ActivityStatus>
			<IsComplete>1</IsComplete>
			<IsIncomplete>1</IsIncomplete>
		</ActivityStatus>
		<!-- Show the top x rows -->
		<TopRowCount></TopRowCount>
	</FilterCriteria>
</mk_ListContactActivity>'

print @nRowCount


