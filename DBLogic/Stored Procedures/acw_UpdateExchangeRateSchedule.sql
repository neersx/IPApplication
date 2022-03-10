-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_UpdateExchangeRateSchedule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_UpdateExchangeRateSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_UpdateExchangeRateSchedule.'
	Drop procedure [dbo].[acw_UpdateExchangeRateSchedule]
End
Print '**** Creating Stored Procedure dbo.acw_UpdateExchangeRateSchedule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_UpdateExchangeRateSchedule
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,			
	@pbCalledFromCentura		bit		= 0,
	@pnExchangeScheduleID       int,			-- Mandatory
	@psExchangeCode				nvarchar(10),	-- Mandatory
	@psDescription				nvarchar(50),	-- Mandatory
	@pdLogDate					datetime
)
as
-- PROCEDURE:	acw_UpdateExchangeRateSchedule
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to insert or update Exchange Rate Schedule
-- MODIFICATIONS :
-- Date			Who		Number	Version		Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 22 Jun 2010  DV		RFC7350		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)
Declare @message_string VARCHAR(255)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin
	If exists (Select 1 from EXCHRATESCHEDULE 
			   where EXCHSCHEDULECODE = @psExchangeCode and EXCHSCHEDULEID != @pnExchangeScheduleID)
	Begin	
		SET @message_string = 'Cannot insert duplicate EXCHSCHEDULECODE.'  
		RAISERROR(@message_string, 16, 1)
		Set @nErrorCode = @@Error
	End
End
If @nErrorCode = 0
Begin
	If exists (Select 1 from EXCHRATESCHEDULE 
			   where EXCHSCHEDULEID = @pnExchangeScheduleID and (LOGDATETIMESTAMP = @pdLogDate or @pdLogDate is null))
	Begin		
		Set @sSQLString = "
				Update  EXCHRATESCHEDULE 
				Set DESCRIPTION = @psDescription,EXCHSCHEDULECODE = @psExchangeCode
				where EXCHSCHEDULEID = @pnExchangeScheduleID
				and (LOGDATETIMESTAMP = @pdLogDate
				or @pdLogDate is null)"
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@psExchangeCode		nvarchar(10),
					@pnExchangeScheduleID	int,
					@psDescription			nvarchar(50),
					@pdLogDate		datetime',					
					@psExchangeCode	 		= @psExchangeCode,
					@pnExchangeScheduleID   = @pnExchangeScheduleID,
					@psDescription	 		= @psDescription,
					@pdLogDate     = @pdLogDate	
	End
	Else	
	Begin		  
		SET @message_string = 'Concurrency violation: The Update command affected 0 records.'  
		RAISERROR(@message_string, 16, 1)
	End
	
End

Return @nErrorCode
go

Grant exec on dbo.acw_UpdateExchangeRateSchedule to Public
go