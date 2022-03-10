-----------------------------------------------------------------------------------------------------------------------------
-- Enable Service Broker (RFC-39102)
-----------------------------------------------------------------------------------------------------------------------------
SET QUOTED_IDENTIFIER OFF
GO

DECLARE @sSQL nvarchar(max)

BEGIN TRY
	-- This option activates Service Broker message delivery, preserving the existing Service Broker identifier for the database.
	SET @sSQL = 'ALTER DATABASE ' + db_name() + ' SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE '
	PRINT @sSQL
	EXEC sp_executesql @sSQL
END TRY
BEGIN CATCH
	-- This option activates Service Broker message delivery and creates a new Service Broker identifier for the database. This option ends all existing conversations in the database.
	-- This option is used when restoring to a database that already has an existing service broker.
	SET @sSQL = 'ALTER DATABASE ' + db_name() + ' SET NEW_BROKER WITH ROLLBACK IMMEDIATE '
	PRINT @sSQL
	EXEC sp_executesql @sSQL
END CATCH

GO
PRINT N'Setting-up service broker';
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Work items service
-- This service receives new work that needs to be done.
-- Service broker polling to the service queue and carry out the work when a message is received.
-----------------------------------------------------------------------------------------------------------------------------

-- Create AsyncCommandQueue message type
IF  NOT EXISTS (SELECT * FROM sys.service_message_types WHERE name = N'http://schemas.inprotech.cpaglobal.com/messages/AsyncCommandQueue/enqueue')
	CREATE MESSAGE TYPE 
		[http://schemas.inprotech.cpaglobal.com/messages/AsyncCommandQueue/enqueue] 
	VALIDATION = NONE
GO


-- Create AsyncCommandQueue contract
IF  NOT EXISTS (SELECT * FROM sys.service_contracts WHERE name = N'http://schemas.inprotech.cpaglobal.com/contracts/AsyncCommandQueue')
	CREATE CONTRACT 
		[http://schemas.inprotech.cpaglobal.com/contracts/AsyncCommandQueue]
		([http://schemas.inprotech.cpaglobal.com/messages/AsyncCommandQueue/enqueue]
			SENT BY INITIATOR)
GO


-- Create AsyncCommandQueue queue 
IF  NOT EXISTS (SELECT * FROM sys.service_queues WHERE name = N'AsyncCommandQueue')
	CREATE QUEUE AsyncCommandQueue
GO


-- Create AsyncCommandQueue service
IF  EXISTS (SELECT * FROM sys.services WHERE name = N'http://schemas.inprotech.cpaglobal.com/services/AsyncCommandQueue')
	DROP SERVICE [http://schemas.inprotech.cpaglobal.com/services/AsyncCommandQueue]
GO
print '**** Creating WORKITEM SERVICE'
print ''
go

CREATE SERVICE
       [http://schemas.inprotech.cpaglobal.com/services/AsyncCommandQueue]
       ON QUEUE AsyncCommandQueue
       ([http://schemas.inprotech.cpaglobal.com/contracts/AsyncCommandQueue]);
GO



-----------------------------------------------------------------------------------------------------------------------------
-- Client service
-- Sender used for all one way communications
-----------------------------------------------------------------------------------------------------------------------------
print '**** Creating CLIENT SERVICE'
print ''


-- Create client constract
IF  NOT EXISTS (SELECT * FROM sys.service_contracts WHERE name = N'http://schemas.inprotech.cpaglobal.com/contracts/client')
	CREATE CONTRACT
		[http://schemas.inprotech.cpaglobal.com/contracts/client]
		([DEFAULT] SENT BY ANY)
GO


-- Create client queue
IF  NOT EXISTS (SELECT * FROM sys.service_queues WHERE name = N'Client')
	CREATE QUEUE Client;
GO	


-- Create client service
IF  EXISTS (SELECT * FROM sys.services WHERE name = N'http://schemas.inprotech.cpaglobal.com/services/client')
	DROP SERVICE [http://schemas.inprotech.cpaglobal.com/services/client]
GO

CREATE SERVICE
       [http://schemas.inprotech.cpaglobal.com/services/client]
       ON QUEUE Client
       ([http://schemas.inprotech.cpaglobal.com/contracts/client]);
GO


-----------------------------------------------------------------------------------------------------------------------------
-- Creation of QUEUE dbo.AsyncCommandQueue
-- When a message is arrived in the queue, the stored proc ipu_AsyncCommand is called to process the message.
-----------------------------------------------------------------------------------------------------------------------------
if exists (SELECT * FROM sys.service_queues WHERE name = N'AsyncCommandQueue')
begin
	print '**** Alter QUEUE dbo.AsyncCommandQueue.'
	ALTER QUEUE AsyncCommandQueue WITH 
			STATUS = ON,
			ACTIVATION	
			(
				STATUS = ON,
				PROCEDURE_NAME = dbo.ipu_AsyncCommand,
				MAX_QUEUE_READERS = 32767,
				EXECUTE AS SELF
			);
end
else
begin 
	print '**** Creating QUEUE dbo.AsyncCommandQueue....'
	CREATE QUEUE AsyncCommandQueue WITH 
			STATUS = ON,
			ACTIVATION	
			(
				STATUS = ON,
				PROCEDURE_NAME = dbo.ipu_AsyncCommand,
				MAX_QUEUE_READERS = 32767,
				EXECUTE AS SELF
			);
end
print ''
go






