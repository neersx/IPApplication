-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_InsertExchangeRateSchedule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_InsertExchangeRateSchedule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_InsertExchangeRateSchedule.'
	Drop procedure [dbo].[acw_InsertExchangeRateSchedule]
End
Print '**** Creating Stored Procedure dbo.acw_InsertExchangeRateSchedule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_InsertExchangeRateSchedule
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,			
	@pbCalledFromCentura		bit		= 0,
	@psExchangeCode				nvarchar(10),	-- Mandatory
	@psDescription				nvarchar(50)	-- Mandatory
)
as
-- PROCEDURE:	acw_InsertExchangeRateSchedule
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

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin
	If exists (Select 1 from EXCHRATESCHEDULE 
			   where EXCHSCHEDULECODE = @psExchangeCode)
	Begin	
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Cannot insert duplicate EXCHSCHEDULECODE.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin
		Set @sSQLString = "
				Insert into EXCHRATESCHEDULE 
					(EXCHSCHEDULECODE,
					DESCRIPTION)
				values 
					(@psExchangeCode,
					@psDescription)"
		exec @nErrorCode = sp_executesql @sSQLString,
				   N'@psExchangeCode		nvarchar(10),
					@psDescription			nvarchar(50)',
					@psExchangeCode	 		= @psExchangeCode,
					@psDescription	 		= @psDescription	
	End
End

Return @nErrorCode
go

Grant exec on dbo.acw_InsertExchangeRateSchedule to Public
go