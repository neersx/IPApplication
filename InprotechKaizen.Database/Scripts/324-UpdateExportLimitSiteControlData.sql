	/******************************************************************************************/
	/*** DR-63988 Update data SITECONTROL.CONTROLID = Export Limit ***/
	/******************************************************************************************/     
	IF EXISTS(SELECT 1 FROM SITECONTROL WHERE CONTROLID = N'Export Limit')
	BEGIN
		PRINT '**** DR-63988 Update data SITECONTROL.CONTROLID = Export Limit ****'
		 
			UPDATE SITECONTROL SET 
			COMMENTS = N'The maximum number of rows that can be exported from search results. If not provided, no limit is enforced (not recommended).',
			NOTES = N'This Site Control allows you to set the maximum number of rows that can be exported from search results. This can reduce the time it takes to export reports in the available formats. A message will be displayed if you try to export a report which consists of more rows than the maximum set in this Site Control. If you proceed, the report will be truncated to the export limit. The recommended maximum setting is 1000 rows.'
			WHERE CONTROLID = N'Export Limit'
		 
		PRINT '**** DR-63988 Data successfully updated to SITECONTROL table for Export Limit****'
	END