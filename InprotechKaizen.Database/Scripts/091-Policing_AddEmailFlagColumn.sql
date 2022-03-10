/*** RFC43118 Add column to POLICING                                                   ***/       

       If NOT exists (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'POLICING' AND COLUMN_NAME = 'EMAILFLAG')
             BEGIN  
             PRINT '**** RFC43118 Adding columns POLICING.EMAILFLAG.'   
                    ALTER TABLE POLICING ADD EMAILFLAG   bit NULL default(1)                          
                     
              PRINT '**** RFC43118 POLICING.EMAILFLAG column has been added.'
            END
             PRINT '**** RFC43118 POLICING.EMAILFLAG already exist'
             PRINT ''
       GO
       IF dbo.fn_IsAuditSchemaConsistent('POLICING') = 0
       BEGIN
       exec ipu_UtilGenerateAuditTriggers 'POLICING'
       END
	   GO
