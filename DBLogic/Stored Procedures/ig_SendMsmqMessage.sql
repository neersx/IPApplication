-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ig_SendMsmqMessage
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ig_SendMsmqMessage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ig_SendMsmqMessage.'
	Drop procedure [dbo].[ig_SendMsmqMessage]
End
Print '**** Creating Stored Procedure dbo.ig_SendMsmqMessage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ig_SendMsmqMessage
(
	@psMessageLabel 	nvarchar(255),		-- Mandatory
   	@pnMessageType 		int,			-- Mandatory
   	@psMessageBody 		nvarchar(1000)		-- Mandatory
)
as
-- PROCEDURE:	ig_SendMsmqMessage
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 May 2005	TM	RFC2588	1	Procedure created
-- 31 Aug 2005	TM	RFC2952	2	Remove 'select' statements.
-- 02 Sep 2005 	TM	RFC2952	3	RaiseError should use WITH LOG so they get added to the system log.
-- 05 Sep 2005  TM	RFC2952	4	Correct the error checking.
-- 09 Sep 2005	JEK	RFC3005 5	Errors raised with severity 16 are being reported to WorkBenches,
--					even though @@ERROR is being reset.  Reduce severity to a Warning.
-- 15 Sep 2005	JEK	RFC3074	6	Improve error information.
-- 28 May 2013	DL	10030	7	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @nMsmqQueue 	int

Declare @sSource 	nvarchar(53)
Declare @sDescription 	nvarchar(200)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin	 
	-- Create the SQLMSMQ Object.
	execute @nErrorCode = ipu_OACreate 'CPASS.Messaging.SqlMSMQ', @nMsmqQueue OUT, 1

	If @nErrorCode <> 0 
	Begin	
		execute ipu_OAGetErrorInfo @nMsmqQueue, @sSource OUT, @sDescription OUT, NULL, NULL
		RAISERROR('CPA Inpro Integration ig_SendMsmqMessage: Unable to create CPASS.Messaging.SqlMSMQ. Error received: %s.  Please check that the CPASS.Messaging.SqlMSMQ component has been installed.', 10, 1, @sDescription) WITH LOG 
		
		-- Destroy the SQLMSMQ object.
		execute  ipu_OADestroy @nMsmqQueue 
	End
	Else
	If @nErrorCode = 0
	Begin	 
		-- Send the message using the Send method
		execute @nErrorCode = ipu_OAMethod @nMsmqQueue, 'SendMessage', NULL,  @psMessageLabel, @pnMessageType, @psMessageBody
	
		If @nErrorCode <> 0 
		Begin	
			execute ipu_OAGetErrorInfo @nMsmqQueue, @sSource OUT, @sDescription OUT, NULL, NULL
			RAISERROR('CPA Inpro Integration ig_SendMsmqMessage: Unable to send ''%s'' message to CPASS.Messaging.SqlMSMQ. Error received: %s.', 10, 1, @psMessageLabel, @sDescription) WITH LOG 
				
			-- Destroy the SQLMSMQ object.
			execute ipu_OADestroy @nMsmqQueue 
		End
		 
		-- Destroy the SQLMSMQ object.
		execute ipu_OADestroy @nMsmqQueue 
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ig_SendMsmqMessage to public
GO
