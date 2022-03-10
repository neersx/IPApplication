/*** DR-65822 Alter column QUERYFILTER.XMLFILTERCRITERIA     ***/
If exists (SELECT *
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'QUERYFILTER' AND COLUMN_NAME = 'XMLFILTERCRITERIA' and UPPER(DATA_TYPE) = 'NTEXT')
Begin
    ALTER TABLE QUERYFILTER DISABLE TRIGGER ALL
    PRINT '*** DR-65822 Altering COLUMN QUERYFILTER.XMLFILTERCRITERIA     ***'
    ALTER TABLE QUERYFILTER ALTER COLUMN XMLFILTERCRITERIA nvarchar(max) NOT NULL
    PRINT '*** DR-65822 QUERYFILTER.XMLFILTERCRITERIA column has been altered    ***' 

    -- Move data (<4000 bytes) from LOB onto the table to improve performance
    UPDATE QUERYFILTER SET XMLFILTERCRITERIA = XMLFILTERCRITERIA
        WHERE XMLFILTERCRITERIA IS NOT NULL
    PRINT '' 

    ALTER TABLE QUERYFILTER ENABLE TRIGGER ALL 

End
Else
Begin
    PRINT '*** DR-65822 QUERYFILTER.XMLFILTERCRITERIA already converted to nvarchar(max)     ***'
End
GO

-- Regenerate audit trigger on OPENITEM table
IF dbo.fn_IsAuditSchemaConsistent('QUERYFILTER') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'QUERYFILTER'
END
GO