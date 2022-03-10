/**********************************************************************************************************/	
/*** RFC70793 Add column NAMETYPE.PRIORITYORDER													        ***/  
/**********************************************************************************************************/
If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'NAMETYPE' AND COLUMN_NAME = 'PRIORITYORDER')
	BEGIN		
		PRINT '**** R69625 Adding column NAMETYPE.PRIORITYORDER' 
		ALTER TABLE NAMETYPE ADD PRIORITYORDER smallint NOT NULL DEFAULT 0		 
		PRINT '**** R69625 Column NAMETYPE.PRIORITYORDER added' 
 	END
ELSE
	BEGIN
		PRINT '**** R69625 Column NAMETYPE.PRIORITYORDER exists already' 
	END
GO

 IF dbo.fn_IsAuditSchemaConsistent('NAMETYPE') = 0
 BEGIN
	exec ipu_UtilGenerateAuditTriggers 'NAMETYPE';
 END
GO


/**********************************************************************************************************/	
/*** RFC69625 Set values in newly added column NAMETYPE.PRIORITYORDER									***/ 
/**********************************************************************************************************/
If not exists (Select * from NAMETYPE where PRIORITYORDER > 0)
        BEGIN
                PRINT '**** R69625 Setting values in column NAMETYPE.PRIORITYORDER' 
                ;WITH NT
                     AS (SELECT PRIORITYORDER,
                                ROW_NUMBER() OVER 
	                                (Order by CASE	NAMETYPE 
		                                WHEN	'I'	THEN 0		/* Instructor */
		                                WHEN 	'A'	THEN 1		/* Agent */
		                                WHEN 	'O'	THEN 2		/* Owner */
		                                WHEN	'EMP'	THEN 3		/* Responsible Staff */
		                                WHEN	'SIG'	THEN 4		/* Signotory */
		                                ELSE 5				/* others, order by description and sequence */
	                                 END,
	                                 DESCRIPTION) -1 as NameTypeOrder
                         FROM   NAMETYPE)
                UPDATE NT
                SET    PRIORITYORDER = NameTypeOrder 

                PRINT '**** R69625  Setting values in column NAMETYPE.PRIORITYORDER is completed' 
        END
ELSE
        BEGIN
                PRINT '**** R69625  Values in column NAMETYPE.PRIORITYORDER is alredy initialized' 
        END
GO