-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetExchangeVariation
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[fn_GetExchangeVariation]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
begin
	print '**** Drop function dbo.fn_GetExchangeVariation.'
	drop function dbo.fn_GetExchangeVariation
end
print '**** Creating function dbo.fn_GetExchangeVariation...'
print ''
go

set QUOTED_IDENTIFIER off
go

CREATE FUNCTION [dbo].[fn_GetExchangeVariation]
(
	@pnUserIdentityId		INT,		-- Mandatory
	@pbCalledFromCentura	BIT,
	@psCurrencyCode			NVARCHAR(5),-- The currency the information is required for
	@pdtTransactionDate		DATETIME,	-- Transaction date used to get the correct exchange rate variation
	@pnCaseID				INT,		-- CaseID used to obtain the correct exchange rate variation
	@pnNameNo				INT,		-- NameNo used to obtain the correct exchange rate variation
	@pbIsSupplier			BIT,		-- Determines whether to get exchange rate variation FROM CREDITOR/IPNAME when NameNo is supplied
	@psCaseType				NCHAR(1),	-- SQA12361 User entered CaseType
	@psCountryCode			NVARCHAR(3),-- SQA12361 User entered Country
	@psPropertyType			NCHAR(1),	-- SQA12361 User entered Property Type
	@psCaseCategory			NVARCHAR(2),-- SQA12361 User entered Category
	@psSubType				NVARCHAR(2),-- SQA12361 User entered Sub Type
	@pnExchScheduleId		INT			-- SQA12361 User entered Exchange Rate Schedule
)
RETURNS @tbFXRates TABLE
(
	BankRate	DECIMAL(11,4),
	BuyRate		DECIMAL(11,4),
	SellRate	DECIMAL(11,4)
)
AS
-- PROCEDURE:	fn_GetExchangeVariation
-- VERSION:	10
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Wrapper stored procedure for ac_GetExchangeDetails to be used in Centura classes

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13 Jun 2006	KR	12108	1	Procedure created
-- 27 Jun 2006	KR	12108	2	Added description to the parameters
-- 07 Jul 2006	MF	12361	3	Allow the Exchange Rate Schedule Id to be optionally passed as a parameter
-- 20 Jul 2006	KR	13054	4	Adjusted the formula for Buy Rate to use multiplication.
-- 21 Jul 2006 	KR	13096	5	Get the bank rate FROM EXCHANGERATEHIST
-- 31 Aug 2006	MF	12361	6	Revisit to correct upper case problem and integration merge issue
-- 01 Sep 2006	MF	12361	7	Revisit
-- 18 Jan 2007	CR	12400	8 	Removed unnecessary @pnDecimalPlaces parameter.
-- 05 Jul 2013	vql	R13629	9	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 14 Nov 2018  AV  75198/DR-45358	10   Date conversion errors when creating cases and opening names in Chinese DB

BEGIN
	DECLARE @nErrorCode		 	INT
	DECLARE @nExchScheduleID 	INT
	DECLARE @nExchVariationID	INT
	DECLARE @sExchVariationID	NVARCHAR(11)
	DECLARE @nBuyFactor			DECIMAL(11,4)
	DECLARE @nSellFactor		DECIMAL(11,4)
	DECLARE @nBankRate			DECIMAL(11,4)
	DECLARE @nBuyRate			DECIMAL(11,4)
	DECLARE @nSellRate			DECIMAL(11,4)

	-- Initialise variables
	SET @nErrorCode = 0

	IF @pnExchScheduleId IS NOT NULL
	BEGIN
		SET @nExchScheduleID=@pnExchScheduleId
	END
	ELSE BEGIN
		IF @pnNameNo IS NOT NULL AND (@pbIsSupplier = 1) 
		BEGIN
			SELECT @nExchScheduleID = EXCHSCHEDULEID 
				FROM CREDITOR
				WHERE  NAMENO = @pnNameNo
		END
		ELSE IF @pnNameNo IS NOT NULL
		BEGIN
			SELECT @nExchScheduleID = EXCHSCHEDULEID 
				FROM IPNAME
				WHERE  NAMENO = @pnNameNo
		END
	END

	IF @nErrorCode = 0
	BEGIN
		SELECT @sExchVariationID = SUBSTRING ( MAX(
				CASE WHEN E.CURRENCYCODE    IS NULL THEN '0' ELSE '1' END +
				CASE WHEN E.EXCHSCHEDULEID  IS NULL THEN '0' ELSE '1' END +
				CASE WHEN E.CASETYPE	    IS NULL THEN '0' ELSE '1' END +
				CASE WHEN E.PROPERTYTYPE    IS NULL THEN '0' ELSE '1' END +
				CASE WHEN E.COUNTRYCODE     IS NULL THEN '0' ELSE '1' END +
				CASE WHEN E.CASECATEGORY    IS NULL THEN '0' ELSE '1' END +
				CASE WHEN E.CASESUBTYPE	    IS NULL THEN '0' ELSE '1' END +
				CONVERT(char(11),E.EXCHVARIATIONID)),8,11)
			FROM  EXCHRATEVARIATION E
				LEFT JOIN CASES C
					ON (C.CASEID = @pnCaseID)
			WHERE (E.CURRENCYCODE	= @psCurrencyCode	OR E.CURRENCYCODE	IS NULL)
			AND   (E.EXCHSCHEDULEID	= @nExchScheduleID	OR E.EXCHSCHEDULEID	IS NULL)
			AND ( E.CASETYPE		= ISNULL(C.CASETYPE,    @psCaseType)	OR E.CASETYPE		IS NULL) 
			AND ( E.PROPERTYTYPE	= ISNULL(C.PROPERTYTYPE,@psPropertyType)OR E.PROPERTYTYPE	IS NULL) 
			AND ( E.COUNTRYCODE		= ISNULL(C.COUNTRYCODE, @psCountryCode)	OR E.COUNTRYCODE	IS NULL)  
			AND ( E.CASECATEGORY	= ISNULL(C.CASECATEGORY,@psCaseCategory)OR E.CASECATEGORY	IS NULL) 
			AND ( E.CASESUBTYPE		= ISNULL(C.SUBTYPE,     @psSubType)	OR E.CASESUBTYPE	IS NULL)
			AND E.EFFECTIVEDATE		= (SELECT MAX(E1.EFFECTIVEDATE)
									FROM 	EXCHRATEVARIATION E1
									WHERE 	E1.EXCHVARIATIONID = E.EXCHVARIATIONID
									AND	E1.EFFECTIVEDATE <=  CONVERT(NVARCHAR,ISNULL(@pdtTransactionDate, GETDATE()), 112))

		IF ( @nErrorCode=0 ) AND (@sExchVariationID IS NOT NULL)
		BEGIN
			SET @nExchVariationID = CONVERT(int,@sExchVariationID)

			SELECT	@nBuyRate = BUYRATE, 
					@nSellRate = SELLRATE, 
					@nBuyFactor = BUYFACTOR, 
					@nSellFactor= SELLFACTOR
				FROM EXCHRATEVARIATION
				WHERE EXCHVARIATIONID = @nExchVariationID

			IF (@nErrorCode=0) AND (@nBuyRate IS NULL OR @nSellRate IS NULL)
			BEGIN
				SELECT @nBankRate = E.BANKRATE 
					FROM EXCHANGERATEHIST E
					WHERE E.CURRENCY = @psCurrencyCode
						AND E.DATEEFFECTIVE = (SELECT MAX(E1.DATEEFFECTIVE)
													FROM 	EXCHANGERATEHIST E1
													WHERE 	E1.CURRENCY = E.CURRENCY
														AND	E1.DATEEFFECTIVE <= CONVERT(NVARCHAR,ISNULL(@pdtTransactionDate, GETDATE()), 112))
			END
			
			IF (@nErrorCode=0) AND (@nBuyFactor IS NOT NULL)
				SET @nBuyRate = @nBankRate*@nBuyFactor
			IF (@nErrorCode=0) AND (@nSellFactor IS NOT NULL)
				SET @nSellRate = @nBankRate*@nSellFactor
		END
	END

	INSERT INTO @tbFXRates (BankRate, BuyRate, SellRate)
		VALUES (@nBankRate, @nBuyRate, @nSellRate)

	RETURN
END

GO

grant REFERENCES, SELECT on dbo.fn_GetExchangeVariation to public
GO
