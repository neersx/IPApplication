update SITECONTROL
set 
	NOTES = 'Specifies the event to be updated when Inprotech data is updated via Case Data Comparison. ',
	COMMENTS = 'Event to be updated each time data is imported from a data source via the Case Data Comparison feature. To be used for triggering any additional workflow or as an identifier in a report.' 
where CONTROLID = 'Case Comparison Event'
	
