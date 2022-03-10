-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_CopyNameDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[naw_CopyNameDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.naw_CopyNameDetails.'
	drop procedure dbo.naw_CopyNameDetails
end
print '**** Creating procedure dbo.naw_CopyNameDetails...'
print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.naw_CopyNameDetails
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCopyNameKey 		nvarchar(20)	= null,
	@pnNameKey		nvarchar(20)	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	naw_CopyNameDetails
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Save the Name Entities if Name is Copied from another Name.

-- MODIFICATIONS :
-- Date		Who	Number	        Version	Change
-- ------------	-------	------	        -------	----------------------------------------------- 
-- 03 Aug 2010  ASH	RFC3832	        1	Procedure created
-- 25 Sep 2013  MS      DR913           2       Remove @ptOldText parameter from naw_Correspondence 
-- 22 Jan 2019  MS      DR-45664        3       Do not copy case instructions when copying name

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	                        nvarchar(4000)
Declare @tText	                                nvarchar(max)
Declare @sPurchaseOrderNo			nvarchar(80)	
Declare	@sTaxCode				nvarchar(3)	
Declare	@sStateTaxCode				nvarchar(3)	
Declare	@sStateCode				nvarchar(20)	
Declare	@nCreditLimit				decimal(12,2)	
Declare	@nDebtorRestrictionKey			smallint
Declare	@nDebitCopies				int		
Declare	@bHasMultiCaseBills			bit		
Declare	@bHasMultiCaseBillsPerOwner		bit		
Declare	@bHasSameAddressAndAttention		bit		
Declare	@sTaxNumber				nvarchar(30)	
Declare	@sBillCurrencyCode			nvarchar(3)	
Declare	@nBillingFrequencyCode			int	
Declare	@nReceivableTermsDays			int		
Declare	@bIsLocalClient			        bit	
Declare	@nDebtorTypeCode			int		
Declare	@nUseDebtorTypeCode			int	
Declare	@nExchangeRateScheduleKey		int	
Declare	@nStatementAttentionKey		        int	
Declare	@sStatementAttention			nvarchar(254)	
Declare	@nStatementNameKey			int	
Declare	@nBillingCap				decimal(12,2)
Declare	@nBillingCapPeriod			int		
Declare	@nBillingCapPeriodType			nvarchar(1)
Declare	@dBillingCapStartDate			datetime	
Declare	@bBillingCapResetFlag			bit		
Declare	@nBillFormatProfileKey			int		
Declare	@bSeparateMarginFlag			bit	
Declare	@nBillMapProfileKey			int		
Declare @nConsolidation			        tinyint
Declare @sLookupCulture		                nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0
Set     @tText          = null
Set     @nConsolidation  = 0

-- Populating Notes result set
If @nErrorCode = 0
Begin
        Set @sSQLString = "INSERT INTO NAMETEXT (NAMENO, TEXTTYPE, TEXT) 
	                SELECT @pnNameKey, TEXTTYPE, TEXT 
	                FROM NAMETEXT WHERE NAMENO =@pnCopyNameKey" 

        exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCopyNameKey 	nvarchar(20),
					  @pnNameKey		nvarchar(20)',
					  @pnCopyNameKey	= @pnCopyNameKey,
					  @pnNameKey 	        = @pnNameKey

End

If @nErrorCode = 0 and exists(Select 1 From IPNAME Where NAMENO = @pnCopyNameKey and CORRESPONDENCE is not null )
Begin
        Set @sSQLString= "Select @tText= CORRESPONDENCE From IPNAME Where NAMENO=@pnCopyNameKey"
        exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCopyNameKey 	nvarchar(20),
					  @tText               nvarchar(max) OUTPUT',
					  @pnCopyNameKey	= @pnCopyNameKey,
					  @tText		= @tText OUTPUT

End

If @nErrorCode = 0 and (@tText is not null)
Begin
        Exec @nErrorCode = dbo.naw_UpdateCorrespondenceInstructions 
				@pnUserIdentityId = @pnUserIdentityId,
				@psCulture = @psCulture,
				@pnNameKey = @pnNameKey,
				@psTextTypeKey = -1,
				@ptText =@tText
End

---- Populating Attribute result set
If @nErrorCode = 0
Begin	
	Set @sSQLString = "INSERT INTO TABLEATTRIBUTES (PARENTTABLE, GENERICKEY, TABLECODE,TABLETYPE) 
	                SELECT PARENTTABLE,@pnNameKey, TABLECODE, TABLETYPE
		        FROM TABLEATTRIBUTES WHERE GENERICKEY =@pnCopyNameKey" 

        exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCopyNameKey 	nvarchar(20),
					  @pnNameKey		nvarchar(20)',
					  @pnCopyNameKey	= @pnCopyNameKey,
					  @pnNameKey 	        = @pnNameKey
End

---- Inserting Standing Instruction result set
If @nErrorCode = 0
Begin	
	Set @sSQLString = 
                "INSERT INTO NAMEINSTRUCTIONS (NAMENO, INTERNALSEQUENCE, RESTRICTEDTONAME, INSTRUCTIONCODE, CASEID, COUNTRYCODE, PROPERTYTYPE, 
                        PERIOD1AMT, PERIOD1TYPE, PERIOD2AMT, PERIOD2TYPE, PERIOD3AMT, PERIOD3TYPE, ADJUSTMENT, ADJUSTDAY, ADJUSTSTARTMONTH, 
                        ADJUSTDAYOFWEEK, ADJUSTTODATE, LOGUSERID, LOGIDENTITYID, LOGTRANSACTIONNO, LOGDATETIMESTAMP, LOGAPPLICATION, LOGOFFICEID, STANDINGINSTRTEXT)
		 SELECT @pnNameKey,INTERNALSEQUENCE, RESTRICTEDTONAME, INSTRUCTIONCODE, CASEID, COUNTRYCODE, PROPERTYTYPE, PERIOD1AMT, PERIOD1TYPE, 
		        PERIOD2AMT, PERIOD2TYPE, PERIOD3AMT, PERIOD3TYPE, ADJUSTMENT, ADJUSTDAY, ADJUSTSTARTMONTH, 
		        ADJUSTDAYOFWEEK, ADJUSTTODATE, LOGUSERID, LOGIDENTITYID, LOGTRANSACTIONNO, LOGDATETIMESTAMP, LOGAPPLICATION, LOGOFFICEID, STANDINGINSTRTEXT
		 FROM NAMEINSTRUCTIONS WHERE NAMENO =@pnCopyNameKey and CASEID is null" 

        exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCopyNameKey 	nvarchar(20),
					  @pnNameKey		nvarchar(20)',
					  @pnCopyNameKey	= @pnCopyNameKey,
					  @pnNameKey 	        = @pnNameKey
End

---- Inserting Billing Instruction result set
If @nErrorCode = 0
Begin
Set @sSQLString= "Select @sTaxCode                     = TAXCODE,				
			@sPurchaseOrderNo	        = PURCHASEORDERNO,				
			@sStateTaxCode	                = STATETAXCODE,
			@bIsLocalClient			= LOCALCLIENTFLAG,
			@sStateCode	                = SERVPERFORMEDIN,
			@nDebtorRestrictionKey	        = BADDEBTOR,
			@sBillCurrencyCode	        = CURRENCY,
			@nDebitCopies		        = DEBITCOPIES,
			@nDebtorTypeCode	        = DEBTORTYPE,
			@nUseDebtorTypeCode	        = USEDEBTORTYPE,
			@pnConsolidation		= CONSOLIDATION ,
			@nCreditLimit			= CREDITLIMIT,
			@nBillingFrequencyCode		= BILLINGFREQUENCY,
			@nReceivableTermsDays		= TRADINGTERMS,
			@nExchangeRateScheduleKey	= EXCHSCHEDULEID,
			@nBillingCap			= BILLINGCAP,
			@nBillingCapPeriod		= BILLINGCAPPERIOD,
			@nBillingCapPeriodType		= BILLINGCAPPERIODTYPE,
			@dBillingCapStartDate		= BILLINGCAPSTARTDATE,
			@bBillingCapResetFlag	        = BILLINGCAPRESETFLAG,
			@nBillFormatProfileKey		= BILLFORMATID,
			@nBillMapProfileKey	        = BILLMAPPROFILEID,
			@bSeparateMarginFlag           = SEPARATEMARGINFLAG	 
			From IPNAME 
			Where NAMENO=@pnCopyNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCopyNameKey 	                        nvarchar(20),
						@sTaxCode				nvarchar(3) OUTPUT,
						@sStateTaxCode				nvarchar(3) OUTPUT,
						@sStateCode				nvarchar(20) OUTPUT,
						@nDebtorRestrictionKey			smallint OUTPUT,
						@sBillCurrencyCode			nvarchar(3) OUTPUT,
						@nDebitCopies				smallint OUTPUT,
						@pnConsolidation			tinyint OUTPUT,
						@nDebtorTypeCode			int OUTPUT,
						@nUseDebtorTypeCode			int OUTPUT,
						@sPurchaseOrderNo			nvarchar(80) OUTPUT,
						@bIsLocalClient			        bit OUTPUT,
						@nReceivableTermsDays			int OUTPUT,
						@nBillingFrequencyCode			int OUTPUT,
						@nCreditLimit				decimal(12,2) OUTPUT,
						@nExchangeRateScheduleKey		int OUTPUT,
						@nBillingCap				decimal(12,2) OUTPUT,
						@nBillingCapPeriod			int OUTPUT,
						@nBillingCapPeriodType			nvarchar(1) OUTPUT,
						@dBillingCapStartDate			datetime OUTPUT,
						@bBillingCapResetFlag			bit OUTPUT,
						@nBillFormatProfileKey			int OUTPUT,
						@nBillMapProfileKey			int OUTPUT,
						@bSeparateMarginFlag			bit OUTPUT',
					        @pnCopyNameKey		                = @pnCopyNameKey ,
						@sTaxCode	 			= @sTaxCode OUTPUT,
						@sStateTaxCode	 			= @sStateTaxCode OUTPUT,
						@sStateCode				= @sStateCode OUTPUT,
						@nDebtorRestrictionKey	 		= @nDebtorRestrictionKey OUTPUT,
						@sBillCurrencyCode	 		= @sBillCurrencyCode OUTPUT,
						@nDebitCopies	 			= @nDebitCopies OUTPUT,
						@pnConsolidation 			= @nConsolidation OUTPUT,
						@nDebtorTypeCode	 		= @nDebtorTypeCode OUTPUT,
						@nUseDebtorTypeCode	 		= @nUseDebtorTypeCode OUTPUT,
						@sPurchaseOrderNo	 		= @sPurchaseOrderNo,
						@bIsLocalClient	 		        = @bIsLocalClient OUTPUT,
						@nReceivableTermsDays	 		= @nReceivableTermsDays OUTPUT,
						@nBillingFrequencyCode	 		= @nBillingFrequencyCode OUTPUT,
						@nCreditLimit	 			= @nCreditLimit OUTPUT,
						@nExchangeRateScheduleKey		= @nExchangeRateScheduleKey OUTPUT,
						@nBillingCap				= @nBillingCap OUTPUT,
						@nBillingCapPeriod			= @nBillingCapPeriod OUTPUT,
						@nBillingCapPeriodType			= @nBillingCapPeriodType OUTPUT,
						@dBillingCapStartDate			= @dBillingCapStartDate OUTPUT,
						@bBillingCapResetFlag			= @bBillingCapResetFlag OUTPUT,
						@nBillFormatProfileKey			= @nBillFormatProfileKey OUTPUT,
						@nBillMapProfileKey			= @nBillMapProfileKey OUTPUT,
						@bSeparateMarginFlag			= @bSeparateMarginFlag OUTPUT

End
If @nErrorCode = 0 and exists(Select 1 From IPNAME Where NAMENO =@pnNameKey)
Begin
        Set @sSQLString = 
                        "UPDATE IPNAME 
	                set 	TAXCODE			= @sTaxCode,				
				PURCHASEORDERNO		= @sPurchaseOrderNo,				
				STATETAXCODE		= @sStateTaxCode,
				LOCALCLIENTFLAG		= @bIsLocalClient,
				SERVPERFORMEDIN		= @sStateCode,
				BADDEBTOR		= @nDebtorRestrictionKey,
				CURRENCY		= @sBillCurrencyCode,
				DEBITCOPIES		= @nDebitCopies,
				DEBTORTYPE		= @nDebtorTypeCode,
				USEDEBTORTYPE		= @nUseDebtorTypeCode,
				CONSOLIDATION		= @pnConsolidation,
				CREDITLIMIT		= @nCreditLimit,
				BILLINGFREQUENCY	= @nBillingFrequencyCode,
				TRADINGTERMS		= @nReceivableTermsDays,
				EXCHSCHEDULEID		= @nExchangeRateScheduleKey,
				BILLINGCAP		= @nBillingCap,
				BILLINGCAPPERIOD	= @nBillingCapPeriod,
				BILLINGCAPPERIODTYPE	= @nBillingCapPeriodType,
				BILLINGCAPSTARTDATE	= @dBillingCapStartDate,
				BILLINGCAPRESETFLAG	= @bBillingCapResetFlag,
				BILLFORMATID		= @nBillFormatProfileKey,
				BILLMAPPROFILEID	= @nBillMapProfileKey,
				SEPARATEMARGINFLAG	= @bSeparateMarginFlag
			where NAMENO = @pnNameKey " 
				
        exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnNameKey				nvarchar(20),
			@sTaxCode				nvarchar(3),
			@sStateTaxCode				nvarchar(3),
			@sStateCode				nvarchar(20),
			@nDebtorRestrictionKey			smallint,
			@sBillCurrencyCode			nvarchar(3),
			@nDebitCopies				smallint,
			@pnConsolidation			tinyint,
			@nDebtorTypeCode			int,
			@nUseDebtorTypeCode			int,
			@sPurchaseOrderNo			nvarchar(80),
			@bIsLocalClient			        bit,
			@nReceivableTermsDays			int,
			@nBillingFrequencyCode			int,
			@nCreditLimit				decimal(12,2),
			@nExchangeRateScheduleKey		int,
			@nBillingCap				decimal(12,2),
			@nBillingCapPeriod			int,
			@nBillingCapPeriodType			nvarchar(1),
			@dBillingCapStartDate			datetime,
			@bBillingCapResetFlag			bit,
			@nBillFormatProfileKey			int,
			@nBillMapProfileKey			int,
			@bSeparateMarginFlag			bit',
			@pnNameKey	 			= @pnNameKey,
			@sTaxCode	 			= @sTaxCode,
			@sStateTaxCode	 			= @sStateTaxCode,
			@sStateCode				= @sStateCode,
			@nDebtorRestrictionKey	 		= @nDebtorRestrictionKey,
			@sBillCurrencyCode	 		= @sBillCurrencyCode,
			@nDebitCopies	 			= @nDebitCopies,
			@pnConsolidation 			= @nConsolidation,
			@nDebtorTypeCode	 		= @nDebtorTypeCode,
			@nUseDebtorTypeCode	 		= @nUseDebtorTypeCode,
			@sPurchaseOrderNo	 		= @sPurchaseOrderNo,
			@bIsLocalClient	 		        = @bIsLocalClient,
			@nReceivableTermsDays	 		= @nReceivableTermsDays,
			@nBillingFrequencyCode	 		= @nBillingFrequencyCode,
			@nCreditLimit	 			= @nCreditLimit,
			@nExchangeRateScheduleKey		= @nExchangeRateScheduleKey,
			@nBillingCap				= @nBillingCap,
			@nBillingCapPeriod			= @nBillingCapPeriod,
			@nBillingCapPeriodType			= @nBillingCapPeriodType,
			@dBillingCapStartDate			= @dBillingCapStartDate,
			@bBillingCapResetFlag			= @bBillingCapResetFlag,
			@nBillFormatProfileKey			= @nBillFormatProfileKey,
			@nBillMapProfileKey			= @nBillMapProfileKey,
			@bSeparateMarginFlag			= @bSeparateMarginFlag
End

Return @nErrorCode
GO

Grant execute on dbo.naw_CopyNameDetails  to public
GO





