-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_UpdateExchangeRateVariation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_UpdateExchangeRateVariation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_UpdateExchangeRateVariation.'
	Drop procedure [dbo].[acw_UpdateExchangeRateVariation]
End
Print '**** Creating Stored Procedure dbo.acw_UpdateExchangeRateVariation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_UpdateExchangeRateVariation
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture				nvarchar(10) 	= null,			
	@pbCalledFromCentura		        bit		= 0,
	@pnExchVariationID			int		= null,
	@pnExchScheduleID			int		= null,				
	@psCurrencyCode				nvarchar(3)	= null,		
	@psCaseTypeCode				nvarchar(1)	= null,		
	@psCaseCategoryCode			nvarchar(2)	= null,		
	@psPropertyTypeCode			nvarchar(1)	= null,		
	@psCountryCode				nvarchar(3)	= null,		
	@psSubTypeCode				nvarchar(2)	= null,		
	@pdBuyFactor				decimal(11,4)   = null,	
	@pdSellFactor				decimal(11,4)   = null,	
	@pdBuyRate				decimal(11,4)   = null,	
	@pdSellRate				decimal(11,4)   = null,	
	@pdtDateEffective			datetime,
	@psNotes				nvarchar(254)   = null,
	@pdtLastUpdatedDate			datetime        = null
)
as
-- PROCEDURE:	acw_UpdateExchangeRateVariation
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

Declare @sSQLString	nvarchar(1000)
Declare @message_string VARCHAR(255)  

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin
	If exists (Select 1 from EXCHRATEVARIATION 
			   where (EXCHSCHEDULEID = @pnExchScheduleID or (@pnExchScheduleID is null and EXCHSCHEDULEID is null))
					and (CURRENCYCODE = @psCurrencyCode or (@psCurrencyCode is null and CURRENCYCODE is null))
					and	(CASETYPE = @psCaseTypeCode or (@psCaseTypeCode is null and CASETYPE is null))
					and (CASECATEGORY = @psCaseCategoryCode or (@psCaseCategoryCode is null and CASECATEGORY is null))
					and	(PROPERTYTYPE = @psPropertyTypeCode or (@psPropertyTypeCode is null and PROPERTYTYPE is null))
					and	(COUNTRYCODE = @psCountryCode or (@psCountryCode is null and COUNTRYCODE is null))
					and	(CASESUBTYPE = @psSubTypeCode or (@psSubTypeCode is null and CASESUBTYPE is null))
					and EXCHVARIATIONID != @pnExchVariationID)
	Begin
		SET @message_string = 'Cannot insert duplicate EXCHRATEVARIATION.'  
		RAISERROR(@message_string, 16, 1)
		Set @nErrorCode = @@Error
	End
End
If @nErrorCode = 0
Begin
	If not exists (Select 1 from EXCHRATEVARIATION 
			   where EXCHVARIATIONID = @pnExchVariationID and LOGDATETIMESTAMP = @pdtLastUpdatedDate)
	Begin		
		
		SET @message_string = 'Concurrency violation: The Update command affected 0 records.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin	
		Set @sSQLString = "
				Update  EXCHRATEVARIATION 
				Set EXCHSCHEDULEID = @pnExchScheduleID,			
					CURRENCYCODE = @psCurrencyCode,		
					CASETYPE = @psCaseTypeCode	,		
					CASECATEGORY = @psCaseCategoryCode,		
					PROPERTYTYPE = @psPropertyTypeCode,		
					COUNTRYCODE = @psCountryCode,		
					CASESUBTYPE = @psSubTypeCode,		
					EFFECTIVEDATE = @pdtDateEffective,
					NOTES = @psNotes,
					BUYFACTOR = @pdBuyFactor,
					SELLFACTOR = @pdSellFactor,
					BUYRATE = @pdBuyRate,
					SELLRATE = @pdSellRate
					where EXCHVARIATIONID = @pnExchVariationID
					and LOGDATETIMESTAMP = @pdtLastUpdatedDate"		
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnExchVariationID		        int,
					@pnExchScheduleID			int,
					@psCurrencyCode				nvarchar(3),		
					@psCaseTypeCode				nvarchar(1),		
					@psCaseCategoryCode			nvarchar(2),		
					@psPropertyTypeCode			nvarchar(1),		
					@psCountryCode				nvarchar(3),		
					@psSubTypeCode				nvarchar(2),		
					@pdBuyFactor				decimal(11,4),	
					@pdSellFactor				decimal(11,4),	
					@pdBuyRate				decimal(11,4),	
					@pdSellRate				decimal(11,4),	
					@pdtDateEffective			datetime,
					@psNotes				nvarchar(254),
					@pdtLastUpdatedDate			datetime',		
					@pnExchVariationID                      = @pnExchVariationID,			
					@pnExchScheduleID			= @pnExchScheduleID,
					@psCurrencyCode				= @psCurrencyCode,		
					@psCaseTypeCode				= @psCaseTypeCode,		
					@psCaseCategoryCode			= @psCaseCategoryCode,		
					@psPropertyTypeCode			= @psPropertyTypeCode,		
					@psCountryCode				= @psCountryCode,		
					@psSubTypeCode				= @psSubTypeCode,		
					@pdBuyFactor				= @pdBuyFactor,	
					@pdSellFactor				= @pdSellFactor,	
					@pdBuyRate				= @pdBuyRate,	
					@pdSellRate				= @pdSellRate,	
					@pdtDateEffective			= @pdtDateEffective,
					@psNotes				= @psNotes,
					@pdtLastUpdatedDate			= @pdtLastUpdatedDate		
	End

End

Return @nErrorCode
go

Grant exec on dbo.acw_UpdateExchangeRateVariation to Public
go