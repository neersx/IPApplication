﻿/*** DR-68353 Add column EXCHANGEREQUESTQUEUE.MAILBOX          ***/      

If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EXCHANGEREQUESTQUEUE' AND COLUMN_NAME = 'MAILBOX')
BEGIN   
    PRINT '**** DR-68353 Adding column EXCHANGEREQUESTQUEUE.MAILBOX.'           
    
    ALTER TABLE EXCHANGEREQUESTQUEUE add MAILBOX nvarchar(254)  NULL 		
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.MAILBOX column has been added.'
END
ELSE   
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.MAILBOX already exists'
PRINT ''
GO

If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EXCHANGEREQUESTQUEUE' AND COLUMN_NAME = 'RECIPIENTS')
BEGIN   
    PRINT '**** DR-68353 Adding column EXCHANGEREQUESTQUEUE.RECIPIENTS.'           
    
    ALTER TABLE EXCHANGEREQUESTQUEUE add RECIPIENTS nvarchar(max)  NULL 		
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.RECIPIENTS column has been added.'
END
ELSE   
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.RECIPIENTS already exists'
PRINT ''
GO

If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EXCHANGEREQUESTQUEUE' AND COLUMN_NAME = 'CCRECIPIENTS')
BEGIN   
    PRINT '**** DR-68353 Adding column EXCHANGEREQUESTQUEUE.CCRECIPIENTS.'           
    
    ALTER TABLE EXCHANGEREQUESTQUEUE add CCRECIPIENTS nvarchar(max)  NULL 		
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.CCRECIPIENTS column has been added.'
END
ELSE   
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.CCRECIPIENTS already exists'
PRINT ''
GO

If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EXCHANGEREQUESTQUEUE' AND COLUMN_NAME = 'BCCRECIPIENTS')
BEGIN   
    PRINT '**** DR-68353 Adding column EXCHANGEREQUESTQUEUE.BCCRECIPIENTS.'           
    
    ALTER TABLE EXCHANGEREQUESTQUEUE add BCCRECIPIENTS nvarchar(max)  NULL 		
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.BCCRECIPIENTS column has been added.'
END
ELSE   
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.BCCRECIPIENTS already exists'
PRINT ''
GO

If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EXCHANGEREQUESTQUEUE' AND COLUMN_NAME = 'SUBJECT')
BEGIN   
    PRINT '**** DR-68353 Adding column EXCHANGEREQUESTQUEUE.SUBJECT.'           
    
    ALTER TABLE EXCHANGEREQUESTQUEUE add [SUBJECT] nvarchar(max)  NULL 		
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.SUBJECT column has been added.'
END
ELSE   
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.SUBJECT already exists'
PRINT ''
GO

If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EXCHANGEREQUESTQUEUE' AND COLUMN_NAME = 'BODY')
BEGIN   
    PRINT '**** DR-68353 Adding column EXCHANGEREQUESTQUEUE.BODY.'           
    
    ALTER TABLE EXCHANGEREQUESTQUEUE add BODY nvarchar(max)  NULL 		
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.BODY column has been added.'
END
ELSE   
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.BODY already exists'
PRINT ''
GO

If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EXCHANGEREQUESTQUEUE' AND COLUMN_NAME = 'ISBODYHTML')
BEGIN   
    PRINT '**** DR-68353 Adding column EXCHANGEREQUESTQUEUE.ISBODYHTML.'           
    
    ALTER TABLE EXCHANGEREQUESTQUEUE add ISBODYHTML bit not null DEFAULT 0 		
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.ISBODYHTML column has been added.'
END
ELSE   
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.ISBODYHTML already exists'
PRINT ''
GO

If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'EXCHANGEREQUESTQUEUE' AND COLUMN_NAME = 'ATTACHMENTS')
BEGIN   
    PRINT '**** DR-68353 Adding column EXCHANGEREQUESTQUEUE.ATTACHMENTS.'           
    
    ALTER TABLE EXCHANGEREQUESTQUEUE add ATTACHMENTS nvarchar(max)
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.ATTACHMENTS column has been added.'
END
ELSE   
    PRINT '**** DR-68353 EXCHANGEREQUESTQUEUE.ATTACHMENTS already exists'
PRINT ''
GO

IF dbo.fn_IsAuditSchemaConsistent('EXCHANGEREQUESTQUEUE') = 0
BEGIN
   EXEC ipu_UtilGenerateAuditTriggers 'EXCHANGEREQUESTQUEUE'
END
GO