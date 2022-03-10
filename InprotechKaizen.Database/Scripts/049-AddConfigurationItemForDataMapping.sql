/**********************************************************************************************************/
    /*** RFC45627 Configuration item for Data Mapping for each data Source      			    ***/
/**********************************************************************************************************/
IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 239 and GENERICPARAM = N'EPO' )
    BEGIN
        PRINT '**** RFC45627 Adding data CONFIGURATIONITEM.TASKID = 239 and CONFIGURATIONITEM.GENERICPARAM = EPO'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL, GENERICPARAM) VALUES(
	    239,
	    N'Configure Data Mapping for European Patent Office',
	    N'Create, update or delete data mappings for European Patent Office.',  N'/apps/configuration/ede/datamapping/#/Epo', N'EPO');
	    PRINT '**** RFC45627 Data successfully added to CONFIGURATIONITEM table.'
	END
	ELSE
	BEGIN
         PRINT '**** RFC45627 CONFIGURATIONITEM.TASKID = 239 and CONFIGURATIONITEM.GENERICPARAM = EPO already exists'
         PRINT ''
	END
go

IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 239 and GENERICPARAM = N'USPTO.PP' )
    BEGIN
		PRINT '**** RFC45627 Adding data CONFIGURATIONITEM.TASKID = 239 and CONFIGURATIONITEM.GENERICPARAM = USPTO.PrivatePAIR'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL, GENERICPARAM) VALUES(
	    239,
	    N'Configure Data Mapping for USPTO Private PAIR',
	    N'Create, update or delete data mappings for USPTO Private PAIR.', N'/apps/configuration/ede/datamapping/#/UsptoPrivatePair', N'USPTO.PP' )
	    PRINT '**** RFC45627 Data successfully added to CONFIGURATIONITEM table.'
	END
	ELSE
	BEGIN
         PRINT '**** RFC45627 CONFIGURATIONITEM.TASKID = 239 and CONFIGURATIONITEM.GENERICPARAM = USPTO.PP already exists'
         PRINT ''
	END
go

IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 239 and GENERICPARAM = N'USPTO.TSDR' )
    BEGIN	
		PRINT '**** RFC45627 Adding data CONFIGURATIONITEM.TASKID = 239 and CONFIGURATIONITEM.GENERICPARAM = USPTO.TSDR'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL, GENERICPARAM) VALUES(
	    239,
	    N'Configure Data Mapping for USPTO TSDR',
	    N'Create, update or delete data mappings for USPTO TSDR.', N'/apps/configuration/ede/datamapping/#/UsptoTsdr', N'USPTO.TSDR')
        PRINT '**** RFC45627 Data successfully added to CONFIGURATIONITEM table.'
        PRINT ''
    END
    ELSE
	BEGIN
         PRINT '**** RFC45627 CONFIGURATIONITEM.TASKID = 239 and CONFIGURATIONITEM.GENERICPARAM = USPTO.TSDR already exists'
         PRINT ''
	END
go