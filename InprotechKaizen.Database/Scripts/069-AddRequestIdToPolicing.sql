-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Identity column for Policing table
-----------------------------------------------------------------------------------------------------------------------------

/*** R60335 Add Index POLICING.XIE2POLICING***/      

if exists (select * from sysindexes where name = 'XIE2POLICING')
begin
	 PRINT 'Dropping index POLICING.XIE2POLICING ...'
	 DROP INDEX XIE2POLICING ON POLICING
end
go

PRINT 'Adding index POLICING.XIE2POLICING ...'
			
CREATE NONCLUSTERED INDEX XIE2POLICING ON POLICING
( 
	SYSGENERATEDFLAG      ASC,
	ONHOLDFLAG            ASC,
	DATEENTERED           ASC
)
INCLUDE( POLICINGSEQNO,CASEID,LOGDATETIMESTAMP )
go

/*** R52333 Add column POLICING.REQUESTID          ***/

If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'POLICING' AND COLUMN_NAME = 'REQUESTID')
 BEGIN
	PRINT '**** R52333 Adding column POLICING.REQUESTID.'
	ALTER TABLE POLICING add  REQUESTID int NOT NULL IDENTITY ( 1,1 ) NOT FOR REPLICATION	
	PRINT '**** R52333 POLICING.REQUESTID column has been added.'
 END
 ELSE
	PRINT '**** R52333 POLICING.REQUESTID already exists'
	PRINT ''
 GO
 IF dbo.fn_IsAuditSchemaConsistent('POLICING') = 0
 BEGIN
	EXEC ipu_UtilGenerateAuditTriggers 'POLICING'
 END
 GO