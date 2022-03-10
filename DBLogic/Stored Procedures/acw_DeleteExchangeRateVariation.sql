-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_DeleteExchangeRateVariation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_DeleteExchangeRateVariation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_DeleteExchangeRateVariation.'
	Drop procedure [dbo].[acw_DeleteExchangeRateVariation]
End
Print '**** Creating Stored Procedure dbo.acw_DeleteExchangeRateVariation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_DeleteExchangeRateVariation
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,			
	@pbCalledFromCentura		bit		= 0,
	@pnExchVariationID			int,	-- Mandatory
	@pdtLastUpdatedDate			datetime = null
)
as
-- PROCEDURE:	acw_DeleteExchangeRateVariation
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to delete Exchange Rate Variation
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
	If not exists (Select 1 from EXCHRATEVARIATION 
			   where EXCHVARIATIONID = @pnExchVariationID and LOGDATETIMESTAMP = @pdtLastUpdatedDate)
	Begin
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Concurrency violation: The Delete command affected 0 records.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin
		Set @sDeleteString = "DELETE FROM EXCHRATEVARIATION 
							Where EXCHVARIATIONID = @pnExchVariationID 
							and LOGDATETIMESTAMP = @pdtLastUpdatedDate"

		exec @nErrorCode=sp_executesql @sDeleteString,
				   N'@pnExchVariationID		int,
					@pdtLastUpdatedDate		datetime',
					@pnExchVariationID	 	= @pnExchVariationID,
					@pdtLastUpdatedDate	 	= @pdtLastUpdatedDate
	End			
END
Return @nErrorCode
go

Grant exec on dbo.acw_DeleteExchangeRateVariation to Public
go