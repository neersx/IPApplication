declare @nRowCount int

EXEC dbo.ipw_ListAdHocTemplate @pnUserIdentityId = 6,
@pnRowCount = @nRowCount output,
@pnQueryContextKey = 280,
@ptXMLOutputRequests = N'<OutputRequests>
			    <Column ID="AdHocTemplateCode" PublishName="AdHocTemplateCode" SortOrder="2" SortDirection="A" />
			    <Column ID="TemplateMessage" PublishName="TemplateMessage" />
			    <Column ID="IsElectronicReminder" PublishName="IsElectronicReminder" SortOrder="1" SortDirection="A"/>
			    <Column ID="EmailSubject" PublishName="EmailSubject" SortOrder="3" SortDirection="A" />
			  </OutputRequests>',
@ptXMLFilterCriteria = N'<?xml version="1.0"?>
			<ipw_ListAdHocTemplate>
				<FilterCriteria>
					<AdHocTemplateCode Operator=""></AdHocTemplateCode>
					<PickListSearch></PickListSearch>
					<TemplateMessage Operator=""></TemplateMessage>
				</FilterCriteria>
			</ipw_ListAdHocTemplate>'


print @nRowCount



 





