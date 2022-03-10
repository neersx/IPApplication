    /**********************************************************************************************************/
    /*** RFC61751 Configuration item for Maintain Name Relationship Codes				    			    ***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 237)
    BEGIN
        PRINT '**** RFC61751 Adding data CONFIGURATIONITEM.TASKID = 237'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) VALUES(
	    237,
	    N'Maintain Name Relationship Codes',
	    N'Create, update or delete name relationships in the system.','/apps/configuration/names/namerelation/#/')
        PRINT '**** RFC61751 Data successfully added to CONFIGURATIONITEM table.'
        PRINT ''
    END
    ELSE
         PRINT '**** RFC61751 CONFIGURATIONITEM.TASKID = 237 already exists'
         PRINT ''
    go

	/**********************************************************************************************************/
    /*** RFC61751 Configuration item for Maintain Name Alias Types				    						***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 238)
    BEGIN
        PRINT '**** RFC61751 Adding data CONFIGURATIONITEM.TASKID = 238'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) VALUES(
	    238,
	    N'Maintain Name Alias Types',
	    N'Create, update or delete name alias types in the system.', '/apps/configuration/names/aliastype/#/')
        PRINT '**** RFC61751 Data successfully added to CONFIGURATIONITEM table.'
        PRINT ''
    END
    ELSE
         PRINT '**** RFC61751 CONFIGURATIONITEM.TASKID = 238 already exists'
         PRINT ''
    go

	/**********************************************************************************************************/
    /*** RFC61751 Configuration item for Maintain Locality				    								***/
    /**********************************************************************************************************/
    IF NOT EXISTS (SELECT * FROM CONFIGURATIONITEM WHERE TASKID = 234)
    BEGIN
        PRINT '**** RFC61751 Adding data CONFIGURATIONITEM.TASKID = 234'
	    INSERT INTO CONFIGURATIONITEM(TASKID, TITLE, DESCRIPTION, URL) VALUES(
	    234,
	    N'Maintain Locality',
	    N'Create, update or delete localities in the system.', '/apps/configuration/names/locality/#/')
        PRINT '**** RFC61751 Data successfully added to CONFIGURATIONITEM table.'
        PRINT ''
    END
    ELSE
         PRINT '**** RFC61751 CONFIGURATIONITEM.TASKID = 234 already exists'
         PRINT ''
    go