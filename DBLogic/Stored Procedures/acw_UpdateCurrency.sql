-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_UpdateCurrency
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_UpdateCurrency]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_UpdateCurrency.'
	Drop procedure [dbo].[acw_UpdateCurrency]
End
Print '**** Creating Stored Procedure dbo.acw_UpdateCurrency...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_UpdateCurrency
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,			
	@pbCalledFromCentura		        bit		= 0,
	@psCurrencyCode				nvarchar(3),	-- Mandatory
	@psDescription				nvarchar(40),
	@pdBankRate				decimal(11,4)   = null,	
	@pdBuyFactor				decimal(11,4)   = null,	
	@pdSellFactor				decimal(11,4)   = null,	
	@pdBuyRate				decimal(11,4)   = null,	
	@pdSellRate				decimal(11,4)   = null,
	@pnRoundedValues			smallint        = null,	
	@pdtDateChanged				datetime,
	@pdtLastUpdatedDate			datetime        = null
)
as
-- PROCEDURE:	acw_UpdateCurrency
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to insert or update Currency
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 22 Jun 2010  DV	RFC7350	1	Procedure created
-- 20 Oct 2015  MS      R53933  2       Changed parameters size from decimal(8,4) to decimal(11,4)

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin
	If not exists (Select 1 from CURRENCY 
			   where CURRENCY = @psCurrencyCode and (LOGDATETIMESTAMP = @pdtLastUpdatedDate or @pdtLastUpdatedDate is null))
	Begin		
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Concurrency violation: The Update command affected 0 records.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin	
		Set @sSQLString = "
				Update  CURRENCY 
				Set DESCRIPTION = @psDescription,
				BUYFACTOR = @pdBuyFactor,
				SELLFACTOR = @pdSellFactor,
				BUYRATE = @pdBuyRate,
				SELLRATE = @pdSellRate,
				BANKRATE = @pdBankRate,
				DATECHANGED = @pdtDateChanged,
				ROUNDBILLEDVALUES = @pnRoundedValues
				where CURRENCY = @psCurrencyCode
				and (LOGDATETIMESTAMP = @pdtLastUpdatedDate
				or @pdtLastUpdatedDate is null)"		
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@psCurrencyCode		nvarchar(10),
					@psDescription			nvarchar(50),
					@pdBuyFactor			decimal(11,4), 
					@pdSellFactor			decimal(11,4),
					@pdBuyRate			decimal(11,4), 
					@pdBankRate			decimal(11,4),
					@pdSellRate			decimal(11,4), 
					@pnRoundedValues		smallint,
					@pdtDateChanged			datetime,
					@pdtLastUpdatedDate		datetime',					
					@psCurrencyCode	 		= @psCurrencyCode,
					@psDescription	 		= @psDescription,
					@pdBuyFactor	 		= @pdBuyFactor,
					@pdSellFactor	 		= @pdSellFactor,
					@pdBuyRate	 		= @pdBuyRate,
					@pdBankRate			= @pdBankRate,
					@pdSellRate	 		= @pdSellRate,
					@pnRoundedValues		= @pnRoundedValues,
					@pdtDateChanged	 		= @pdtDateChanged,
					@pdtLastUpdatedDate             = @pdtLastUpdatedDate
		if	(@nErrorCode = 0)
		Begin
			If not exists (Select 1 from EXCHANGERATEHIST 
			   where CURRENCY = @psCurrencyCode and DATEEFFECTIVE = @pdtDateChanged)
			Begin	
				Set @sSQLString = "
							Insert into EXCHANGERATEHIST 
								(CURRENCY, BANKRATE, BUYFACTOR, SELLFACTOR,
									BUYRATE, SELLRATE, DATEEFFECTIVE)
							values 
								(@psCurrencyCode,@pdBankRate, @pdBuyFactor, 
								@pdSellFactor,@pdBuyRate, @pdSellRate, @pdtDateChanged)"
			End
			Else
			Begin
				Set @sSQLString = "
							UPDATE EXCHANGERATEHIST 
								Set BANKRATE = @pdBankRate, 
									BUYFACTOR = @pdBuyFactor, 
									SELLFACTOR = @pdSellFactor,
									BUYRATE = @pdBuyRate, 
									SELLRATE = @pdSellRate
									WHERE CURRENCY = @psCurrencyCode and
									DATEEFFECTIVE = @pdtDateChanged"
			End
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@psCurrencyCode		nvarchar(10),
							@pdBuyFactor			decimal(11,4), 
							@pdSellFactor			decimal(11,4),
							@pdBuyRate			decimal(11,4), 
							@pdBankRate			decimal(11,4),
							@pdSellRate			decimal(11,4), 
							@pdtDateChanged			datetime',					
							@psCurrencyCode	 		= @psCurrencyCode,
							@pdBuyFactor	 		= @pdBuyFactor,
							@pdSellFactor	 		= @pdSellFactor,
							@pdBuyRate	 		= @pdBuyRate,
							@pdBankRate			= @pdBankRate,
							@pdSellRate	 		= @pdSellRate,
							@pdtDateChanged	 		= @pdtDateChanged
		End
	End

End

Return @nErrorCode
go

Grant exec on dbo.acw_UpdateCurrency to Public
go