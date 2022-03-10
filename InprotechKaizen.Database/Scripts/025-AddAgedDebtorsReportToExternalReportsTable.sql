	/******************************************************************************************************************/
	/*** RFC25328 Add Aged Debtors Report in ExternalReports table for providing the link in Financial Reports	***/
	/******************************************************************************************************************/
	If NOT exists (select * from EXTERNALREPORTS where TASKID = 217 and TITLE = 'Aged Debtors Report' )
	BEGIN
		PRINT '**** RFC25328 Adding data EXTERNALREPORTS.TASKID = 217'
		Insert into EXTERNALREPORTS(TASKID, TITLE, DESCRIPTION, PATH)
		values (217, 'Aged Debtors Report', 'This report contains aged debtors information for a specific debtor, entity, or debtor category up to a given period, which can be further broken down and analysed using your preferred tool.', 
		'AgedDebtorsReport.xls')
		PRINT '**** RFC25328 Data successfully added to EXTERNALREPORTS table.'
		PRINT ''
	END
	ELSE
		 PRINT '**** RFC25328 EXTERNALREPORTS.TASKID = 217 already exists'
		 PRINT ''
	go