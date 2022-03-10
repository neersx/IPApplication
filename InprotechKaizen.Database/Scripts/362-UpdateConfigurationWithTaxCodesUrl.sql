/**********************************************************************************************************/
/***      DR-61320 Tax codes configuration item to launch the apps version							***/
/**********************************************************************************************************/
	
 IF NOT EXISTS (select 1 from CONFIGURATIONITEM where TASKID =190 and IEONLY=0 and URL='/apps/#/configuration/taxcodes')
 BEGIN
    PRINT '**** DR-61320 Set APPs URL for task 190 - Maintain Tax Codes ****'
	
	UPDATE CONFIGURATIONITEM set 
	URL = '/apps/#/configuration/taxcodes',
	IEONLY=0
	WHERE TASKID = 190
	PRINT '**** DR-61320 Maintain Tax Codes APPs URL set for task 190 ****'
END
	
GO

IF NOT EXISTS (SELECT 1 FROM CONFIGURATIONITEMCOMPONENTS WHERE CONFIGITEMID = 50)
 BEGIN
    PRINT '**** DR-61320 Map component for Tax Codes ****'

	INSERT CONFIGURATIONITEMCOMPONENTS(CONFIGITEMID, COMPONENTID)
	SELECT CI.CONFIGITEMID, C.COMPONENTID
	FROM CONFIGURATIONITEM CI 
	left join COMPONENTS C on C.COMPONENTNAME = 'Billing'
	WHERE CI.CONFIGITEMID = 50

	PRINT '**** DR-61320 Component mapped for Tax Codes ****'
END
GO