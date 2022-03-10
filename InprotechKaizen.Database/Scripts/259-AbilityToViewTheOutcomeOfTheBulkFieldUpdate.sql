/**********************************************************************************************************/
/*** DR-51223 Ability to view the outcome of the bulk field update - Query Data Item							***/
/**********************************************************************************************************/

If NOT exists(SELECT *
FROM QUERYDATAITEM
WHERE PROCEDUREITEMID = N'ProfitCentreCodeUpdated' AND PROCEDURENAME = N'csw_ListCase')
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYDATAITEM.PROCEDUREITEMID = ProfitCentreCodeUpdated'
    INSERT INTO QUERYDATAITEM
        (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION,
        DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
    select N'ProfitCentreCodeUpdated', NULL, N'A', 0, 0, N'Indicates that the Profit Centre against the Case has been updated via Bulk Field Updates.', isnull(max(DATAITEMID),0)+1, 9106, NULL, N'csw_ListCase', NULL, NULL
    from QUERYDATAITEM
    PRINT '**** DR-51223 Data successfully added to QUERYDATAITEM table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYDATAITEM.PROCEDUREITEMID = ProfitCentreCodeUpdated already exists'
PRINT ''
    	GO
If NOT exists(SELECT *
FROM QUERYDATAITEM
WHERE PROCEDUREITEMID = N'PurchaseOrderNoUpdated' AND PROCEDURENAME = N'csw_ListCase')
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYDATAITEM.PROCEDUREITEMID = PurchaseOrderNoUpdated'
    INSERT INTO QUERYDATAITEM
        (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION,
        DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
    select N'PurchaseOrderNoUpdated', NULL, N'A', 0, 0, N'Indicates that the Purchase Order against the Case has been updated via Bulk Field Updates.', isnull(max(DATAITEMID),0)+1, 9106, NULL, N'csw_ListCase', NULL, NULL
    from QUERYDATAITEM
    PRINT '**** DR-51223 Data successfully added to QUERYDATAITEM table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYDATAITEM.PROCEDUREITEMID = PurchaseOrderNoUpdated already exists'
PRINT ''
    	GO
If NOT exists(SELECT *
FROM QUERYDATAITEM
WHERE PROCEDUREITEMID = N'EntitySizeUpdated' AND PROCEDURENAME = N'csw_ListCase')
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYDATAITEM.PROCEDUREITEMID = EntitySizeUpdated'
    INSERT INTO QUERYDATAITEM
        (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION,
        DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
    select N'EntitySizeUpdated', NULL, N'A', 0, 0, N'Indicates that the Entity Size against the Case has been updated via Bulk Field Updates.', isnull(max(DATAITEMID),0)+1, 9106, NULL, N'csw_ListCase', NULL, NULL
    from QUERYDATAITEM
    PRINT '**** DR-51223 Data successfully added to QUERYDATAITEM table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYDATAITEM.PROCEDUREITEMID = EntitySizeUpdated already exists'
PRINT ''
    	GO
If NOT exists(SELECT *
FROM QUERYDATAITEM
WHERE PROCEDUREITEMID = N'TypeOfMarkUpdated' AND PROCEDURENAME = N'csw_ListCase')
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYDATAITEM.PROCEDUREITEMID = TypeOfMarkUpdated'
    INSERT INTO QUERYDATAITEM
        (PROCEDUREITEMID, QUALIFIERTYPE, SORTDIRECTION, ISMULTIRESULT, ISAGGREGATE, DESCRIPTION,
        DATAITEMID, DATAFORMATID, FORMATITEMID, PROCEDURENAME, DECIMALPLACES, FILTERNODENAME)
    select N'TypeOfMarkUpdated', NULL, N'A', 0, 0, N'Indicates that the Type of Mark against the Case has been updated via Bulk Field Updates.', isnull(max(DATAITEMID),0)+1, 9106, NULL, N'csw_ListCase', NULL, NULL
    from QUERYDATAITEM
    PRINT '**** DR-51223 Data successfully added to QUERYDATAITEM table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYDATAITEM.PROCEDUREITEMID = TypeOfMarkUpdated already exists'
PRINT ''
    	GO


/**********************************************************************************************************/
/*** DR-51223 Ability to view the outcome of the bulk field update - Query Column							***/
/**********************************************************************************************************/

SET IDENTITY_INSERT QUERYCOLUMN ON
	GO

If NOT exists(	SELECT *
FROM QUERYCOLUMN
WHERE COLUMNID = -9700)
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYCOLUMN for COLUMNID = -9700'
    INSERT INTO QUERYCOLUMN
        (COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
    SELECT -9700, N'Has Updated Profit Centre', N'Indicates that the Profit Centre against the Case has been updated via Bulk Field Updates.', NULL, DI.DATAITEMID
    FROM QUERYDATAITEM DI
    WHERE DI.PROCEDUREITEMID = N'ProfitCentreCodeUpdated'
        AND DI.PROCEDURENAME = N'csw_ListCase'
    PRINT '**** DR-51223 Data successfully added to QUERYCOLUMN table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYCOLUMN for COLUMNID = -9700 already exists'
PRINT ''
    	GO
If NOT exists(	SELECT *
FROM QUERYCOLUMN
WHERE COLUMNID = -9701)
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYCOLUMN for COLUMNID = -9701'
    INSERT INTO QUERYCOLUMN
        (COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
    SELECT -9701, N'Has Updated Purchase Order', N'Indicates that the Purchase Order against the Case has been updated via Bulk Field Updates.', NULL, DI.DATAITEMID
    FROM QUERYDATAITEM DI
    WHERE DI.PROCEDUREITEMID = N'PurchaseOrderNoUpdated'
        AND DI.PROCEDURENAME = N'csw_ListCase'
    PRINT '**** DR-51223 Data successfully added to QUERYCOLUMN table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYCOLUMN for COLUMNID = -9701 already exists'
PRINT ''
    	GO
If NOT exists(	SELECT *
FROM QUERYCOLUMN
WHERE COLUMNID = -9702)
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYCOLUMN for COLUMNID = -9702'
    INSERT INTO QUERYCOLUMN
        (COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
    SELECT -9702, N'Has Updated Entity Size', N'Indicates that the Entity Size against the Case has been updated via Bulk Field Updates.', NULL, DI.DATAITEMID
    FROM QUERYDATAITEM DI
    WHERE DI.PROCEDUREITEMID = N'EntitySizeUpdated'
        AND DI.PROCEDURENAME = N'csw_ListCase'
    PRINT '**** DR-51223 Data successfully added to QUERYCOLUMN table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYCOLUMN for COLUMNID = -9702 already exists'
PRINT ''
    	GO
If NOT exists(	SELECT *
FROM QUERYCOLUMN
WHERE COLUMNID = -9703)
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYCOLUMN for COLUMNID = -9703'
    INSERT INTO QUERYCOLUMN
        (COLUMNID, COLUMNLABEL, DESCRIPTION, QUALIFIER, DATAITEMID)
    SELECT -9703, N'Has Updated Type of Mark', N'Indicates that the Type of Mark against the Case has been updated via Bulk Field Updates.', NULL, DI.DATAITEMID
    FROM QUERYDATAITEM DI
    WHERE DI.PROCEDUREITEMID = N'TypeOfMarkUpdated'
        AND DI.PROCEDURENAME = N'csw_ListCase'
    PRINT '**** DR-51223 Data successfully added to QUERYCOLUMN table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYCOLUMN for COLUMNID = -9703 already exists'
PRINT ''
    	GO


-------------------------------------------
SET IDENTITY_INSERT QUERYCOLUMN OFF
	GO


/**********************************************************************************************************/
/*** DR-51223 Ability to view the outcome of the bulk field update - Query Context Column						***/
/**********************************************************************************************************/


If NOT exists(	SELECT *
FROM QUERYCONTEXTCOLUMN
WHERE COLUMNID = -9700 and CONTEXTID = 2)
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYCONTEXTCOLUMN for COLUMNID = -9700 and CONTEXTID = 2'
    INSERT INTO QUERYCONTEXTCOLUMN
        (CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
    VALUES
        (2, -9700, NULL, NULL, 0, 1)
    PRINT '**** DR-51223 Data successfully added to QUERYCONTEXTCOLUMN table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYCONTEXTCOLUMN for COLUMNID = -9700 and CONTEXTID = 2 already exists'
PRINT ''
    	GO
If NOT exists(	SELECT *
FROM QUERYCONTEXTCOLUMN
WHERE COLUMNID = -9701 and CONTEXTID = 2)
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYCONTEXTCOLUMN for COLUMNID = -9701 and CONTEXTID = 2'
    INSERT INTO QUERYCONTEXTCOLUMN
        (CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
    VALUES
        (2, -9701, NULL, NULL, 0, 1)
    PRINT '**** DR-51223 Data successfully added to QUERYCONTEXTCOLUMN table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYCONTEXTCOLUMN for COLUMNID = -9701 and CONTEXTID = 2 already exists'
PRINT ''
    	GO
If NOT exists(	SELECT *
FROM QUERYCONTEXTCOLUMN
WHERE COLUMNID = -9702 and CONTEXTID = 2)
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYCONTEXTCOLUMN for COLUMNID = -9702 and CONTEXTID = 2'
    INSERT INTO QUERYCONTEXTCOLUMN
        (CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
    VALUES
        (2, -9702, NULL, NULL, 0, 1)
    PRINT '**** DR-51223 Data successfully added to QUERYCONTEXTCOLUMN table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYCONTEXTCOLUMN for COLUMNID = -9702 and CONTEXTID = 2 already exists'
PRINT ''
    	GO
If NOT exists(	SELECT *
FROM QUERYCONTEXTCOLUMN
WHERE COLUMNID = -9703 and CONTEXTID = 2)
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYCONTEXTCOLUMN for COLUMNID = -9703 and CONTEXTID = 2'
    INSERT INTO QUERYCONTEXTCOLUMN
        (CONTEXTID, COLUMNID, USAGE, GROUPID, ISMANDATORY, ISSORTONLY)
    VALUES
        (2, -9703, NULL, NULL, 0, 1)
    PRINT '**** DR-51223 Data successfully added to QUERYCONTEXTCOLUMN table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYCONTEXTCOLUMN for COLUMNID = -9703 and CONTEXTID = 2 already exists'
PRINT ''
    	GO


/**********************************************************************************************************/
/*** DR-51223 Ability to view the outcome of the bulk field update - Query Content						***/
/**********************************************************************************************************/

If NOT exists(	SELECT *
FROM QUERYCONTENT
WHERE COLUMNID = -9700 AND PRESENTATIONID = -26)
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYCONTENT for COLUMNID = -9700 AND PRESENTATIONID = -26'
    INSERT INTO QUERYCONTENT
        (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
    SELECT DISTINCT -26, -9700, 9, 1, N'A', 2
    FROM (select 1 as txt) TMP
        left join QUERYPRESENTATION P on (P.CONTEXTID = 2)
    where ISNULL(P.ISDEFAULT, 0) = 0
        or ISNULL(P.ISPROTECT, 0) = 0
    PRINT '**** DR-51223 Data successfully added to QUERYCONTENT table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYCONTENT for COLUMNID = -9700 AND PRESENTATIONID -26 already exists'
PRINT ''
    	GO
If NOT exists(	SELECT *
FROM QUERYCONTENT
WHERE COLUMNID = -9701 AND PRESENTATIONID = -26)
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYCONTENT for COLUMNID = -9701 AND PRESENTATIONID = -26'
    INSERT INTO QUERYCONTENT
        (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
    SELECT DISTINCT -26, -9701, 10, 1, N'A', 2
    FROM (select 1 as txt) TMP
        left join QUERYPRESENTATION P on (P.CONTEXTID = 2)
    where ISNULL(P.ISDEFAULT, 0) = 0
        or ISNULL(P.ISPROTECT, 0) = 0
    PRINT '**** DR-51223 Data successfully added to QUERYCONTENT table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYCONTENT for COLUMNID = -9701 AND PRESENTATIONID -26 already exists'
PRINT ''
    	GO
If NOT exists(	SELECT *
FROM QUERYCONTENT
WHERE COLUMNID = -9702 AND PRESENTATIONID = -26)
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYCONTENT for COLUMNID = -9702 AND PRESENTATIONID = -26'
    INSERT INTO QUERYCONTENT
        (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
    SELECT DISTINCT -26, -9702, 11, 1, N'A', 2
    FROM (select 1 as txt) TMP
        left join QUERYPRESENTATION P on (P.CONTEXTID = 2)
    where ISNULL(P.ISDEFAULT, 0) = 0
        or ISNULL(P.ISPROTECT, 0) = 0
    PRINT '**** DR-51223 Data successfully added to QUERYCONTENT table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYCONTENT for COLUMNID = -9702 AND PRESENTATIONID -26 already exists'
PRINT ''
    	GO
If NOT exists(	SELECT *
FROM QUERYCONTENT
WHERE COLUMNID = -9703 AND PRESENTATIONID = -26)
        	BEGIN
    PRINT '**** DR-51223 Adding data QUERYCONTENT for COLUMNID = -9703 AND PRESENTATIONID = -26'
    INSERT INTO QUERYCONTENT
        (PRESENTATIONID, COLUMNID, DISPLAYSEQUENCE, SORTORDER, SORTDIRECTION, CONTEXTID)
    SELECT DISTINCT -26, -9703, 12, 1, N'A', 2
    FROM (select 1 as txt) TMP
        left join QUERYPRESENTATION P on (P.CONTEXTID = 2)
    where ISNULL(P.ISDEFAULT, 0) = 0
        or ISNULL(P.ISPROTECT, 0) = 0
    PRINT '**** DR-51223 Data successfully added to QUERYCONTENT table.'
    PRINT ''
END
    	ELSE
         	PRINT '**** DR-51223 QUERYCONTENT for COLUMNID = -9703 AND PRESENTATIONID -26 already exists'
PRINT ''
    	GO
