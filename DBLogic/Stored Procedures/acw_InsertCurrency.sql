-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_InsertCurrency
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_InsertCurrency]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_InsertCurrency.'
	Drop procedure [dbo].[acw_InsertCurrency]
End
Print '**** Creating Stored Procedure dbo.acw_InsertCurrency...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_InsertCurrency
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,			
	@pbCalledFromCentura		        bit		= 0,
	@psCurrencyCode				nvarchar(3),	-- Mandatory
	@psDescription				nvarchar(40),
	@pdBuyFactor				decimal(11,4)   = null,	
	@pdSellFactor				decimal(11,4)   = null,
	@pdBankRate				decimal(11,4)	= null,	
	@pdBuyRate				decimal(11,4)   = null,	
	@pdSellRate				decimal(11,4)   = null,
	@pnRoundedValues			smallint        = null,	
	@pdtDateChanged				datetime
)
as
-- PROCEDURE:	acw_InsertCurrency
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
	If exists (Select 1 from CURRENCY 
			   where CURRENCY = @psCurrencyCode)
	Begin		
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Cannot insert duplicate CURRENCY.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin	
		Set @sSQLString = "
				Insert into CURRENCY 
					(CURRENCY, DESCRIPTION, BANKRATE, BUYFACTOR, SELLFACTOR,
						BUYRATE, SELLRATE, DATECHANGED, ROUNDBILLEDVALUES)
				values 
					(@psCurrencyCode,@psDescription,@pdBankRate, @pdBuyFactor, 
					@pdSellFactor,@pdBuyRate, @pdSellRate, @pdtDateChanged, 
					@pnRoundedValues)"
		

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@psCurrencyCode		nvarchar(10),
						@psDescription			nvarchar(50),
						@pdBankRate			decimal(11,4),
						@pdBuyFactor			decimal(11,4), 
						@pdSellFactor			decimal(11,4),
						@pdBuyRate			decimal(11,4), 
						@pdSellRate			decimal(11,4), 
						@pdtDateChanged			datetime,
						@pnRoundedValues		smallint',					
						@psCurrencyCode	 		= @psCurrencyCode,
						@psDescription	 		= @psDescription,
						@pdBankRate			= @pdBankRate,
						@pdBuyFactor	 		= @pdBuyFactor,
						@pdSellFactor	 		= @pdSellFactor,
						@pdBuyRate	 		= @pdBuyRate,
						@pdSellRate	 		= @pdSellRate,
						@pdtDateChanged	 		= @pdtDateChanged,
						@pnRoundedValues		= @pnRoundedValues	
		if(@nErrorCode =0)
		Begin
			Set @sSQLString = "
						Insert into EXCHANGERATEHIST 
							(CURRENCY, BANKRATE, BUYFACTOR, SELLFACTOR,
								BUYRATE, SELLRATE, DATEEFFECTIVE)
						values 
							(@psCurrencyCode,@pdBankRate, @pdBuyFactor, 
							@pdSellFactor,@pdBuyRate, @pdSellRate, @pdtDateChanged)"
			exec @nErrorCode=sp_executesql @sSQLString,
							N'@psCurrencyCode		nvarchar(10),
							@pdBankRate			decimal(11,4),
						        @pdBuyFactor			decimal(11,4), 
						        @pdSellFactor			decimal(11,4),
						        @pdBuyRate			decimal(11,4), 
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

Grant exec on dbo.acw_InsertCurrency to Public
go