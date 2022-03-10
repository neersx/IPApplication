-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_GetAgedWipTotals
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_GetAgedWipTotals]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_GetAgedWipTotals.'
	Drop procedure [dbo].[ts_GetAgedWipTotals]
End
Print '**** Creating Stored Procedure dbo.ts_GetAgedWipTotals...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ts_GetAgedWipTotals
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int
)
as
-- PROCEDURE:	ts_GetAgedWipTotals
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Programmer comments here

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 JUL 2011	SF	10045	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)

Declare	@nAge0				smallint
Declare	@nAge1				smallint
Declare	@nAge2				smallint
Declare @dtBaseDate 			datetime -- the end date of the current period

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Determine the ageing periods to be used for the aged balance calculations
If @nErrorCode=0
Begin
	exec @nErrorCode = dbo.ac_GetAgeingBrackets @pdtBaseDate	  = @dtBaseDate		OUTPUT,
						@pnBracket0Days   = @nAge0		OUTPUT,
						@pnBracket1Days   = @nAge1 		OUTPUT,
						@pnBracket2Days   = @nAge2		OUTPUT,
						@pnUserIdentityId = @pnUserIdentityId,
						@psCulture	  = @psCulture
End


If @nErrorCode = 0
Begin
	Set @sSQLString =  	
	"Select
		WIP.CASEID 				as 'CaseKey',
		WIP.ENTITYNO 				as 'EntityKey',
		WIP.EntityName				as 'EntityName',
		SUM(ISNULL(WIP.Bracket0Total,0))	as 'Bracket0Total',
		SUM(ISNULL(WIP.Bracket1Total,0))	as 'Bracket1Total',
		SUM(ISNULL(WIP.Bracket2Total,0))	as 'Bracket2Total',
		SUM(ISNULL(WIP.Bracket3Total,0))	as 'Bracket3Total',
		SUM(ISNULL(WIP.Total,0))		as 'Total'
	FROM  (SELECT W.CASEID   AS CASEID,
		      W.ENTITYNO AS ENTITYNO,
		      N.NAME     AS EntityName,
		      CASE
			WHEN( datediff(day, W.TRANSDATE, @dtBaseDate) < @nAge0 ) THEN W.BALANCE
			ELSE 0
		      END        AS Bracket0Total,
		      CASE
			WHEN( datediff(day, W.TRANSDATE, @dtBaseDate) BETWEEN @nAge0 AND @nAge1 - 1 ) THEN W.BALANCE
			ELSE 0
		      END        AS Bracket1Total,
		      CASE
			WHEN( datediff(day, W.TRANSDATE, @dtBaseDate) BETWEEN @nAge1 AND @nAge2 - 1 ) THEN W.BALANCE
			ELSE 0
		      END        AS Bracket2Total,
		      CASE
			WHEN( datediff(day, W.TRANSDATE, @dtBaseDate) >= @nAge2 ) THEN W.BALANCE
			ELSE 0
		      END        AS Bracket3Total,
		      W.BALANCE  AS Total
	       FROM   WORKINPROGRESS W
		      JOIN NAME N
			ON ( N.NAMENO = W.ENTITYNO )
	       WHERE  W.CASEID = @pnCaseKey
		      AND W.STATUS <> 0
		      AND W.TRANSDATE <= getdate()) WIP
	GROUP  BY WIP.CASEID,
		  WIP.ENTITYNO,
		  WIP.EntityName
	ORDER  BY 'EntityName',
		  'EntityKey'" 

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey   	int,
					  @dtBaseDate		datetime,
					  @nAge0		smallint,
					  @nAge1		smallint,
					  @nAge2		smallint',
					  @pnCaseKey	= @pnCaseKey, 
					  @dtBaseDate			= @dtBaseDate,
					  @nAge0			= @nAge0,
					  @nAge1			= @nAge1,
					  @nAge2			= @nAge2

End

Return @nErrorCode
GO

Grant execute on dbo.ts_GetAgedWipTotals to public
GO
