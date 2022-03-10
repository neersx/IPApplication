-----------------------------------------------------------------------------------------------------------------------------
-- Creation of apps_GetRateNos
-----------------------------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[apps_GetRateNos]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
BEGIN
	PRINT '**** Drop Stored Procedure dbo.apps_GetRateNos.'
	DROP PROCEDURE [dbo].apps_GetRateNos
END
PRINT '**** Creating Stored Procedure dbo.apps_GetRateNos...'
PRINT ''
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.apps_GetRateNos
(
	@pnCaseId			int,
	@pnChargeTypeId		int
)
AS
-- PROCEDURE:	apps_GetRateNos
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Stored procedure that will perform a best fit select and return applicable Rate numbers.

-- MODIFICATIONS :
-- Date			Who		Change		Version	Description
-- -----------	-------	-------		-------	----------------------------------------------- 
-- 01 Sep 2020	vql		DR-63580	1		Procedure created

SET NOCOUNT ON

select CR.RATENO as RateId, R.RATETYPE as RateTypeId
from CASES C
join ( Select CHARGETYPENO, RATENO, SEQUENCENO, CASETYPE, PROPERTYTYPE,
	COUNTRYCODE, CASECATEGORY, SUBTYPE, INSTRUCTIONTYPE, FLAGNUMBER,
	(	CASE WHEN(CR.CASETYPE    is null) THEN '0' ELSE '1' END+
		CASE WHEN(CR.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
		CASE WHEN(CR.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
		CASE WHEN(CR.CASECATEGORY is null) THEN '0' ELSE '1' END+
		CASE WHEN(CR.SUBTYPE      is null) THEN '0' ELSE '1' END+
		CASE WHEN(CR.FLAGNUMBER   is null) THEN '0' ELSE '1' END) AS SCORE,
	CASE WHEN(INSTRUCTIONTYPE is not null) 
	THEN dbo.fn_StandingInstruction( @pnCaseId, INSTRUCTIONTYPE)
	ELSE null
	END as INSTRUCTIONCODE
	from CHARGERATES CR) AS CR on (CR.CHARGETYPENO = @pnChargeTypeId)
left join RATES R on (R.RATENO = CR.RATENO)
left JOIN (select CHARGETYPENO, max(	CASE WHEN(CR1.CASETYPE     is null) THEN '0' ELSE '1' END+
			CASE WHEN(CR1.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
			CASE WHEN(CR1.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
			CASE WHEN(CR1.CASECATEGORY is null) THEN '0' ELSE '1' END+
			CASE WHEN(CR1.SUBTYPE      is null) THEN '0' ELSE '1' END+
			CASE WHEN(CR1.FLAGNUMBER   is null) THEN '0' ELSE '1' END) AS SCORE
	from CHARGERATES AS CR1
	GROUP BY CR1.CHARGETYPENO) AS CR1 ON CR1.SCORE = CR.SCORE AND CR1.CHARGETYPENO = CR.CHARGETYPENO
left join INSTRUCTIONFLAG F  on (F.INSTRUCTIONCODE=CR.INSTRUCTIONCODE)
where C.CASEID = @pnCaseId
	and (CR.CASETYPE = C.CASETYPE OR CR.CASETYPE     is null)
	and (CR.PROPERTYTYPE= C.PROPERTYTYPE OR CR.PROPERTYTYPE is null)
	and (CR.COUNTRYCODE = C.COUNTRYCODE OR CR.COUNTRYCODE  is null)
	and (CR.CASECATEGORY= C.CASECATEGORY OR CR.CASECATEGORY is null)
	and (CR.SUBTYPE = C.SUBTYPE OR CR.SUBTYPE      is null)
	and (CR.FLAGNUMBER  = F.FLAGNUMBER OR CR.FLAGNUMBER   is null)

GRANT EXECUTE ON dbo.apps_GetRateNos TO PUBLIC