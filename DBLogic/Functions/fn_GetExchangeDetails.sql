-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetExchangeDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetExchangeDetails]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
begin
	print '**** Drop function dbo.fn_GetExchangeDetails.'
	drop function dbo.fn_GetExchangeDetails
end
print '**** Creating function dbo.fn_GetExchangeDetails...'
print ''
go

set QUOTED_IDENTIFIER off
go
CREATE FUNCTION [dbo].[fn_GetExchangeDetails]
(
	-- All exchange rates relate to local currency;
	-- i.e. LocalAmount * ExchangeRate = ForeignAmount
	@pnUserIdentityId		INT,		-- Mandatory
	@pbCalledFROMCentura		BIT,
	@psCurrencyCode			NVARCHAR(5),	-- The currency the information is required for
	@pdtTransactionDate		datetime,	-- Required for historical exchange rates.
	@pbUseHistoricalRates		BIT,		-- Indicates historical exchange rate to be used or not
	@pnCaseID			INT,		-- CaseID used to obtain the correct exchange rate variation
	@pnNameNo			INT,		-- NameNo used to obtain the correct exchange rate variation
	@pbIsSupplier			BIT,		-- Determines whether to get exchange rate variation FROM CREDITOR/IPNAME when NameNo is supplied
	@psCaseType			NCHAR(1),	-- SQA12361 User entered CaseType
	@psCountryCode			NVARCHAR(3),	-- SQA12361 User entered Country
	@psPropertyType			NCHAR(1),	-- SQA12361 User entered Property Type
	@psCaseCategory			NVARCHAR(2),	-- SQA12361 User entered Category
	@psSubType			NVARCHAR(2),	-- SQA12361 User entered Sub Type
	@pnExchScheduleId		INT				-- SQA12361 User entered Exchange Rate Schedule
)
RETURNS @tbFXDetails TABLE
(
	BankRate			DECIMAL(11,4),
	BuyRate				DECIMAL(11,4),
	SellRate			DECIMAL(11,4),
	DecimalPlaces		TINYINT,
	RoundBilledValues	SMALLINT
)
AS
-- PROCEDURE:	fn_GetExchangeDetails
-- VERSION:	10
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Obtain information necessary for calculations in a foreign currency

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Jun 2005	JEK	RFC2629	1	Procedure created 
-- 14 Jun 2006	KR	11702	2	added call to fn_pat_ac_GetExchangeVariation and 
--			12108		added code to determine historical exchange rate based on wipcategory
-- 23 Jun 2006	KR	12108	3	added code to obtain Debtor IF applicable when not provided.
-- 27 Jun 2006	KR	12108	4	Added description to the parameters and fixed a few problems realted to supplier.
-- 06 Jul 2006	MF	12361	5	Allow user entered parameter to be used.
-- 12 Dec 2006	KR	13982	6	Added new parameter @pnRoundBilledValues
-- 18 Jan 2007	CR	12400	7	Updated call to fn_pat_ac_GetExchangeVariation to not include @pnDecimalPlaces.
--					Also removed some redundant repeated code. 
-- 05 Jul 2013	vql	R13629	8	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 31 Aug 2017	MS	R71887	9	Used fn_GetExchangeVariation function instead of fn_ac_part_GetExchangeVariation
-- 14 Nov 2018  AV  75198/DR-45358	10   Date conversion errors when creating cases and opening names in Chinese DB
 
BEGIN
	DECLARE @nErrorCode		INT
	DECLARE @nBankRate		DECIMAL(11,4)
	DECLARE @nBuyRate		DECIMAL(11,4)
	DECLARE @nSellRate		DECIMAL(11,4)
	DECLARE @nDecimalPlaces		TINYINT
	DECLARE @nRoundBilledValues	SMALLINT

	-- Initialise variables
	SET @nErrorCode = 0

	IF @nErrorCode = 0

	BEGIN
		
		IF (@nErrorCode=0)

		BEGIN
			SELECT	@nBankRate	= BankRate,
				@nBuyRate	= BuyRate,
				@nSellRate	= SellRate
				FROM dbo.fn_GetExchangeVariation(
							@pnUserIdentityId,
							@pbCalledFROMCentura,
							@psCurrencyCode,
							@pdtTransactionDate,
							@pnCaseID,
							@pnNameNo,
							@pbIsSupplier,
							@psCaseType,
							@psCountryCode,
							@psPropertyType,
							@psCaseCategory,
							@psSubType,
							@pnExchScheduleId
						)
		END

		IF ( @nBuyRate IS NOT NULL AND @nSellRate IS NOT NULL )
		BEGIN
			SELECT	@nDecimalPlaces = ISNULL(DECIMALPLACES,2),
				@nRoundBilledValues = ROUNDBILLEDVALUES
			FROM	CURRENCY C
			WHERE	C.CURRENCY = @psCurrencyCode
		END
		
		Else BEGIN		

			IF @pbUseHistoricalRates = 1
			BEGIN
				IF (@nBuyRate IS NULL) 
				BEGIN
					SELECT	@nDecimalPlaces = ISNULL(DECIMALPLACES,2),
						@nBankRate = H.BANKRATE,
						@nBuyRate = H.BUYRATE,
						@nRoundBilledValues = ROUNDBILLEDVALUES
						FROM	CURRENCY C
							LEFT JOIN EXCHANGERATEHIST H
								ON (H.CURRENCY = C.CURRENCY
								AND H.DATEEFFECTIVE = 
											(
												SELECT MAX(H1.DATEEFFECTIVE)
													FROM 	EXCHANGERATEHIST H1
													WHERE	H1.CURRENCY = H.CURRENCY
													AND		H1.DATEEFFECTIVE <= CONVERT(NVARCHAR, ISNULL(@pdtTransactionDate, GETDATE()),112))
											)
						WHERE	C.CURRENCY = @psCurrencyCode
				END
				IF (@nSellRate IS NULL) 
				BEGIN
					SELECT	@nDecimalPlaces = ISNULL(DECIMALPLACES,2),
						@nBankRate = H.BANKRATE,
						@nSellRate = H.SELLRATE,
						@nRoundBilledValues = ROUNDBILLEDVALUES
						FROM	CURRENCY C
						LEFT JOIN EXCHANGERATEHIST H	on (H.CURRENCY = C.CURRENCY
										and H.DATEEFFECTIVE = 
											(
												SELECT MAX(H1.DATEEFFECTIVE)
													FROM 	EXCHANGERATEHIST H1
													WHERE	H1.CURRENCY = H.CURRENCY
														AND	H1.DATEEFFECTIVE <= CONVERT(NVARCHAR,ISNULL(@pdtTransactionDate, GETDATE()),112))
											)
						WHERE	C.CURRENCY = @psCurrencyCode
				END
		
			
			END
		
			Else BEGIN
				IF (@nBuyRate IS NULL) 
				BEGIN
					SELECT	@nDecimalPlaces = ISNULL(C.DECIMALPLACES,2),
						@nBankRate = C.BANKRATE,
						@nBuyRate = C.BUYRATE,
						@nRoundBilledValues = ROUNDBILLEDVALUES
						FROM	CURRENCY C
						WHERE	C.CURRENCY = @psCurrencyCode
				END
				IF (@nSellRate IS NULL)
				BEGIN
					SELECT	@nDecimalPlaces = ISNULL(C.DECIMALPLACES,2),
						@nBankRate = C.BANKRATE,
						@nSellRate = C.SELLRATE
						FROM	CURRENCY C
						WHERE	C.CURRENCY = @psCurrencyCode
				END
		
			END
		END
	END
	-- Centura has not implemented decimal places yet
	IF @pbCalledFROMCentura = 1
	BEGIN
		SET @nDecimalPlaces = 2

	END

	INSERT INTO @tbFXDetails (BankRate, BuyRate, SellRate, DecimalPlaces, RoundBilledValues)
		VALUES (@nBankRate, @nBuyRate, @nSellRate, @nDecimalPlaces, @nRoundBilledValues)

	RETURN
END

GO

grant REFERENCES, SELECT on dbo.fn_GetExchangeDetails to public
GO
