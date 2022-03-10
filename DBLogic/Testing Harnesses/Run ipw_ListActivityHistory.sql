declare @nRowCount int

EXEC dbo.ipw_ListActivityHistory @pnUserIdentityId = 5,
@psCulture = 'PT',
@pnRowCount = @nRowCount output,
@ptXMLOutputRequests = N'<OutputRequests>
			    <Column ID="CaseReference" PublishName="CaseReference" SortOrder="1" SortDirection="A" />
			    <Column ID="WhenRequested" PublishName="WhenRequested" />
			    <Column ID="SqlUser" PublishName="SqlUser" />
			    <Column ID="WorkBenchUser" PublishName="WorkBenchUser" />
			    <Column ID="ProgramName" PublishName="ProgramName" />
			    <Column ID="EventDescription" PublishName="EventDescription" />
			    <Column ID="StatusDescription" PublishName="StatusDescription" />
			    <Column ID="LetterName" PublishName="LetterName" />	
			    <Column ID="RateName" PublishName="RateName" />	
			    <Column ID="WhenOccurred" PublishName="WhenOccurred" />	
			    <Column ID="SystemMessage" PublishName="SystemMessage" />	
			  </OutputRequests>',
@ptXMLFilterCriteria = N'<ipw_ListActivityHistory>
				<FilterCriteria>
					<CaseKey Operator="0">-487</CaseKey>
					<!-- Multiple flags are ORed -->
					<RestrictionFlags>						
						<IsStatus>1</IsStatus>
					</RestrictionFlags>
				</FilterCriteria>
			</ipw_ListActivityHistory>'

print @nRowCount

/*
<IsLetter>1</IsLetter>
<IsCharge>1</IsCharge>
*/



 





