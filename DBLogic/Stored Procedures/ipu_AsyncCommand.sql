-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipu_AsyncCommand
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipu_AsyncCommand]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipu_AsyncCommand.'
	Drop procedure [dbo].[ipu_AsyncCommand]
end
print '**** Creating Stored Procedure dbo.ipu_AsyncCommand...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

CREATE PROCEDURE dbo.ipu_AsyncCommand
WITH EXECUTE AS OWNER
AS
-- PROCEDURE :	ipu_AsyncCommand
-- VERSION :	4
-- DESCRIPTION:	This stored proc is called by the service broker when a message is received in the queue 'AsyncCommandQueue'.
--		It extracts the command from the queue and executes it asynchronously.
--		e.g. @psCommand = "dbo.ipu_Policing null,null,null,1,'',5,null,1,963,null" 
-- COPYRIGHT:	Copyright 1993 - 2014 CPA Global
-- MODIFICATIONS :
-- Date		Who	Change	  Version	Description
-- -----------	-------	------	  -------	----------------------------------------------- 
-- 15/10/2014	DL	R39102	  1	        Procedure created
-- 08/11/2018	DL	DR-43949  2	        Transaction error arised from background processing does not get recorded in ASYNCCOMMAND.STATUS column.
-- 18/06/2019	DL	DR-49441  3	        Provide more information in the Error Log Message of the Policing Dashboard
-- 06/09/2019   MS      DR-20211  4             Set ContextInfo for LogIdentityID       
        
BEGIN		
	DECLARE @handle UNIQUEIDENTIFIER
	DECLARE @sCommand NVARCHAR (max)
	DECLARE @nRowCount INT
	DECLARE @nCommandId INT
	DECLARE @nErrorCode INT
	DECLARE @sRequestUserId NVARCHAR(30)
	DECLARE @sErrorMessage NVARCHAR(MAX)
        DECLARE @nIdentityId INT
	DECLARE @messages TABLE(		
		handle UNIQUEIDENTIFIER,     
		command int)   
	
	WAITFOR
	(RECEIVE TOP(1) conversation_handle, message_body
	FROM AsyncCommandQueue
	INTO @messages), 
	TIMEOUT 0;	
	

	IF @@ROWCOUNT <> 0 			
	BEGIN	
		-- Get the command id in the queue
		SELECT @nCommandId = command, @handle = handle FROM @messages		
		END CONVERSATION @handle;
		
		-- get the actual command from the ASYNCCOMMAND table for the given command id
		-- e.g. "dbo.ipu_Policing null,null,null,1,'',5,null,1,963,null" 
		select @sCommand = COMMAND,
		@sRequestUserId = USERID,
                @nIdentityId = LOGIDENTITYID
		from ASYNCCOMMAND 
		where COMMANDID = @nCommandId		
		
		Begin Try	
                        If @nIdentityId is not null
                        Begin
                                exec ip_SetContextInfo @nIdentityId
                        End
                        
			exec @nErrorCode = sp_executesql @sCommand
		End Try	
		
		Begin Catch
			-- log the error against the command
			set @nErrorCode = ERROR_NUMBER()
			set @sErrorMessage = isnull(CAST(ERROR_NUMBER() AS VARCHAR(20)),0) + ' - ' + isnull(ERROR_MESSAGE(), '')

			-- DR-49441 Add ERROR_LINE() & ERROR_PROCEDURE() to error message
			If isnull(PATINDEX('%Error Proc:%', @sErrorMessage), 0) = 0
				and ERROR_PROCEDURE() IS NOT NULL
			Begin 
				set @sErrorMessage = @sErrorMessage  + 
				'; Error Proc: ' + isnull(ERROR_PROCEDURE(), '') +
				'; Error line number: ' +  isnull(CAST(ERROR_LINE() AS VARCHAR(20)),0) 
			End

			-- Rollback uncommittable transaction to allow error to be logged in the ASYNCCOMMAND table.
			If XACT_STATE()<>0
				Rollback Transaction

			UPDATE ASYNCCOMMAND set STATUS = @sErrorMessage + ' CURRENT USER: ' + CURRENT_USER where COMMANDID = @nCommandId
		END CATCH

		-- remove the command if executed successfully
		If @nErrorCode = 0
			DELETE ASYNCCOMMAND where COMMANDID = @nCommandId

	END	
END
GO
grant execute on dbo.ipu_AsyncCommand   to public
go
