-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_DeleteExchangeRateSchedule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_DeleteExchangeRateSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_DeleteExchangeRateSchedule.'
	Drop procedure [dbo].[acw_DeleteExchangeRateSchedule]
End
Print '**** Creating Stored Procedure dbo.acw_DeleteExchangeRateSchedule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_DeleteExchangeRateSchedule
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,			
	@pbCalledFromCentura		bit		= 0,
	@pnExchSchdID				int,	-- Mandatory
	@pdtLastUpdatedDate			datetime -- Mandatory
)
as
-- PROCEDURE:	acw_DeleteExchangeRateSchedule
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to delete Exchange Rate Schedule
-- MODIFICATIONS :
-- Date			Who		Number	Version		Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 22 Jun 2010  DV		RFC7350		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sDeleteString	nvarchar(500)

Set	@nErrorCode      = 0

Set @nErrorCode = 0
If @nErrorCode = 0
BEGIN
	If not exists (Select 1 from EXCHRATESCHEDULE 
			   where EXCHSCHEDULEID = @pnExchSchdID and (LOGDATETIMESTAMP = @pdtLastUpdatedDate or @pdtLastUpdatedDate is null))
	Begin
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Concurrency violation: The Delete command affected 0 records.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin
		Set @sDeleteString = "DELETE FROM EXCHRATESCHEDULE 
							Where EXCHSCHEDULEID = @pnExchSchdID 
							and (LOGDATETIMESTAMP = @pdtLastUpdatedDate
							or @pdtLastUpdatedDate is null)"

		exec @nErrorCode=sp_executesql @sDeleteString,
				   N'@pnExchSchdID		int,
					@pdtLastUpdatedDate		datetime',
					@pnExchSchdID	 		= @pnExchSchdID,
					@pdtLastUpdatedDate	 	= @pdtLastUpdatedDate	
	End		
END
Return @nErrorCode
go

Grant exec on dbo.acw_DeleteExchangeRateSchedule to Public
go