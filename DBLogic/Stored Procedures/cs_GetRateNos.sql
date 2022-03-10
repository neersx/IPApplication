-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetRateNos
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GetRateNos]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GetRateNos.'
	Drop procedure [dbo].[cs_GetRateNos]
End
Print '**** Creating Stored Procedure dbo.cs_GetRateNos...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.cs_GetRateNos
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(5)	= null, -- the language in which output is to be expressed
	@pnCaseKey			int,
	@pnChargeTypeNo			int,
	@pnRatesTempTable		nvarchar(30),
	@pbCalledFromCentura		bit = 0
)
as
-- PROCEDURE:	cs_GetRateNos
-- VERSION:		2
-- SCOPE:		WorkBenches
-- DESCRIPTION:	Fills a Temp Table with applicable Rate numbers.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 Nov 2007	AT		RFC5776	1		Procedure created
-- 19 Sep 2013	KR		DR-920	2		Return RATETYPE.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	if (@pbCalledFromCentura = 0)
	Begin
		Set @sSQLString = "
			insert into " + @pnRatesTempTable + "(RATENO, RATETYPE)"+CHAR(10)
	End

	Set @sSQLString = @sSQLString + "
		select CR.RATENO, R.RATETYPE
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
			THEN dbo.fn_StandingInstruction( @pnCaseKey , INSTRUCTIONTYPE)
			ELSE null
			END as INSTRUCTIONCODE
			from CHARGERATES CR) AS CR on (CR.CHARGETYPENO = @pnChargeTypeNo)
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
		where C.CASEID = @pnCaseKey
			and (CR.CASETYPE = C.CASETYPE OR CR.CASETYPE     is null)
			and (CR.PROPERTYTYPE= C.PROPERTYTYPE OR CR.PROPERTYTYPE is null)
			and (CR.COUNTRYCODE = C.COUNTRYCODE OR CR.COUNTRYCODE  is null)
			and (CR.CASECATEGORY= C.CASECATEGORY OR CR.CASECATEGORY is null)
			and (CR.SUBTYPE = C.SUBTYPE OR CR.SUBTYPE      is null)
			and (CR.FLAGNUMBER  = F.FLAGNUMBER OR CR.FLAGNUMBER   is null)"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnChargeTypeNo	int,
				@pnCaseKey	int',
				@pnChargeTypeNo	= @pnChargeTypeNo,
				@pnCaseKey	= @pnCaseKey

End


Set @nErrorCode = @@ERROR

Return @nErrorCode
GO

Grant execute on dbo.cs_GetRateNos to public
GO
