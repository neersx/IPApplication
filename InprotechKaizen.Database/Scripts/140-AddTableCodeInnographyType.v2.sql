------------------------------------------------------------------------------------------------------------------
--RFC70276 Table Type for Innography Type
------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS (SELECT * FROM TABLETYPE WHERE TABLETYPE = -516)
BEGIN
	PRINT '**** RFC70276 Adding data TABLETYPE.TABLETYPE = -516'
    INSERT INTO TABLETYPE (TABLETYPE, TABLENAME, MODIFIABLE, ACTIVITYFLAG, DATABASETABLE)
    VALUES (-516, N'Innography Type', 0, 0, N'TABLECODES')
	PRINT '**** RFC70276 Data successfully added to TABLETYPE table.'
    PRINT ''
END
ELSE
	PRINT '**** RFC70276 TABLETYPE.TABLETYPE = -516 already exists'
PRINT ''
GO

------------------------------------------------------------------------------------------------------------------
--RFC70276 SELECTIONTYPES for Country and Innography tabletype
------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS( SELECT * from SELECTIONTYPES WHERE PARENTTABLE = 'COUNTRY' AND TABLETYPE = -516)
BEGIN
    PRINT '**** RFC70276 Adding SELECTIONTYPES for country'
    INSERT INTO SELECTIONTYPES(PARENTTABLE, TABLETYPE, MINIMUMALLOWED, MAXIMUMALLOWED)
    VALUES('COUNTRY', -516 , 0, 1)
END
GO

------------------------------------------------------------------------------------------------------------------
--RFC70276, RFC73586 Table code for 'Innograpgy type' for Country EP
------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM TABLECODES WHERE TABLETYPE = -516 AND USERCODE = 'EPPAT' AND TABLECODE = -42847004)
BEGIN
    PRINT '**** RFC70276, RFC73586 Adding table code for country EP'
    INSERT INTO TABLECODES (TABLECODE, TABLETYPE, [DESCRIPTION], USERCODE)
    VALUES (-42847004, -516 , N'Jurisdiction for EPO','EPPAT')
END
GO

------------------------------------------------------------------------------------------------------------------
--RFC70276, RFC73586 Table code for 'Innograpgy type' for Country AP
------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM TABLECODES WHERE TABLETYPE = -516 AND USERCODE = 'ARIPO' AND TABLECODE = -42847005)
BEGIN
    PRINT '**** RFC70276, RFC73586 Adding table code for country AP'
    INSERT INTO TABLECODES (TABLECODE, TABLETYPE, [DESCRIPTION], USERCODE)
    VALUES (-42847005, -516 , N'Jurisdiction for ARIPO','ARIPO')
END
GO

------------------------------------------------------------------------------------------------------------------
--RFC70276, RFC73586 Table code for 'Innograpgy type' for Country EA
------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM TABLECODES WHERE TABLETYPE = -516 AND USERCODE = 'EAPO' AND TABLECODE = -42847006)
BEGIN
    PRINT '**** RFC70276, RFC73586 Adding table code for country EA'
    INSERT INTO TABLECODES (TABLECODE, TABLETYPE, [DESCRIPTION], USERCODE)
    VALUES (-42847006, -516 , N'Jurisdiction for EAPO','EAPO')
END
GO

------------------------------------------------------------------------------------------------------------------
--RFC70276, RFC73586 Table attributes for 'Innograpgy type' for Country EP
------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM TABLEATTRIBUTES WHERE TABLETYPE = -516 AND GENERICKEY = 'EP' AND PARENTTABLE = 'COUNTRY' AND TABLECODE = -42847004)
AND EXISTS(SELECT * FROM COUNTRY WHERE COUNTRYCODE = 'EP')
BEGIN
	PRINT '**** RFC70276, RFC73586 Adding table attribute for country EP'
    INSERT INTO TABLEATTRIBUTES(PARENTTABLE, GENERICKEY, TABLECODE, TABLETYPE)
    values( 'COUNTRY', 'EP' , -42847004, -516)
END
GO

------------------------------------------------------------------------------------------------------------------
--RFC70276, RFC73586 Table attributes for 'Innograpgy type' for Country AP
------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM TABLEATTRIBUTES WHERE TABLETYPE = -516 AND GENERICKEY = 'AP' AND PARENTTABLE = 'COUNTRY' AND TABLECODE = -42847005)
AND EXISTS(SELECT * FROM COUNTRY WHERE COUNTRYCODE = 'AP')
BEGIN
	PRINT '**** RFC70276, RFC73586 Adding table attribute for country AP'
    INSERT INTO TABLEATTRIBUTES(PARENTTABLE, GENERICKEY, TABLECODE, TABLETYPE)
    values( 'COUNTRY', 'AP' , -42847005, -516)
END
GO

------------------------------------------------------------------------------------------------------------------
--RFC70276, RFC73586 Table attributes for 'Innograpgy type' for Country EA
------------------------------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM TABLEATTRIBUTES WHERE TABLETYPE = -516 AND GENERICKEY = 'EA' AND PARENTTABLE = 'COUNTRY' AND TABLECODE = -42847006)
AND EXISTS(SELECT * FROM COUNTRY WHERE COUNTRYCODE = 'EA')
BEGIN
	PRINT '**** RFC70276, RFC73586 Adding table attribute for country EA'
    INSERT INTO TABLEATTRIBUTES(PARENTTABLE, GENERICKEY, TABLECODE, TABLETYPE)
    values( 'COUNTRY', 'EA' , -42847006, -516)
END
GO

------------------------------------------------------------------------------------------------------------------
--RFC73586 Remove table attributes that were incorrectly inserted
------------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM TABLEATTRIBUTES where TABLETYPE = -516 and PARENTTABLE = 'COUNTRY')
BEGIN
	PRINT '**** RFC73586 Remove incorrectly inserted table attributes if exists'
	
	delete from TABLEATTRIBUTES
	where PARENTTABLE = 'COUNTRY'
	and TABLETYPE = -516
	and GENERICKEY in ('EP', 'AP', 'EA')
	and TABLECODE > 0
END
GO

------------------------------------------------------------------------------------------------------------------
--RFC73586 Remove table codes that were incorrectly inserted
------------------------------------------------------------------------------------------------------------------
IF EXISTS(SELECT * FROM TABLECODES where TABLETYPE = -516)
BEGIN
	PRINT '**** RFC73586 Remove incorrectly inserted table codes if exists'
	
	delete from TABLECODES
	where TABLETYPE = -516
	and USERCODE in ('EPPAT', 'ARIPO', 'EAPO')
	and TABLECODE > 0
END
GO
