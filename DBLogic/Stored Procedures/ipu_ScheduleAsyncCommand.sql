-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_ScheduleAsyncCommand
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipu_ScheduleAsyncCommand]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipu_ScheduleAsyncCommand.'
	Drop procedure [dbo].[ipu_ScheduleAsyncCommand]
end
print '**** Creating Stored Procedure dbo.ipu_ScheduleAsyncCommand...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

CREATE PROCEDURE dbo.ipu_ScheduleAsyncCommand
	@psCommand nvarchar(max)
AS
-- PROCEDURE :	ipu_ScheduleAsyncCommand
-- VERSION :	2
-- DESCRIPTION:	Send a command to the service broker queue.
--		This is the entry point to initiate a request to the service broker for processing the request asynchronously.
--		e.g. @psCommand = "dbo.ipu_Policing null,null,null,1,'',5,null,1,963,null" 
-- COPYRIGHT:	Copyright 1993 - 2014 CPA Global
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14/10/2014	DL		R39102	1		Procedure created
-- 25/10/2016	DL		R69571	2		Background processing not working with ilog audit trigger enabled on the ASYNCCOMMAND table

DECLARE @DialogHandle UNIQUEIDENTIFIER
BEGIN
	DECLARE @lastCommandId int	
	BEGIN TRAN
	insert into dbo.ASYNCCOMMAND( COMMAND, USERID ) values (@psCommand, CURRENT_USER)
	SET @lastCommandId = SCOPE_IDENTITY()
	
	BEGIN DIALOG @DialogHandle
			FROM SERVICE
			 [http://schemas.inprotech.cpaglobal.com/services/client]
			TO SERVICE
			 N'http://schemas.inprotech.cpaglobal.com/services/AsyncCommandQueue'
			ON CONTRACT
			 [http://schemas.inprotech.cpaglobal.com/contracts/AsyncCommandQueue]
			WITH
				ENCRYPTION = OFF;

		-- Send the command id to the service broker queue
		SEND ON CONVERSATION @DialogHandle
			MESSAGE TYPE 
			[http://schemas.inprotech.cpaglobal.com/messages/AsyncCommandQueue/enqueue]
			(@lastCommandId);
	    
		END CONVERSATION @DialogHandle
		
		
	COMMIT TRAN
END
GO

grant execute on dbo.ipu_ScheduleAsyncCommand to public
go
