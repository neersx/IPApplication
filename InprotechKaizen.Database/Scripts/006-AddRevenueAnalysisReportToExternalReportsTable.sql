If NOT exists (select * from EXTERNALREPORTS where TASKID = 210 and TITLE = 'Revenue Analysis Report' )
BEGIN
	Insert into EXTERNALREPORTS(TASKID, TITLE, DESCRIPTION, PATH)
	values (210, 'Revenue Analysis Report', 'This report contains revenue information for a specific period and debtor, which can be further broken down and analysed using your preferred tool.', 
	'RevenueAnalysisReport.xls')
END
go