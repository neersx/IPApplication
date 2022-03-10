-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_FetchOpportunity									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_FetchOpportunity]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_FetchOpportunity.'
	Drop procedure [dbo].[crm_FetchOpportunity]
End
Print '**** Creating Stored Procedure dbo.crm_FetchOpportunity...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.crm_FetchOpportunity
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int 		-- Mandatory
)
as
-- PROCEDURE:	crm_FetchOpportunity
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Opportunity business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 17 Jun 2008	AT	RFC5748	1	Procedure created
-- 20 Aug 2008	AT	RFC6894	2	Added Potential value Local
-- 24 Oct 2011	ASH	R11460  3	Cast integer columns as nvarchar(11) data type.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sLookupCulture	nvarchar(10)
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
	CAST(O.CASEID as nvarchar(11))	as RowKey,
	O.CASEID			as CaseKey,
	O.POTENTIALVALUELOCAL		as PotentialValueLocal,
	O.POTENTIALVALUE		as PotentialValue,
	O.SOURCE			as Source,
	O.EXPCLOSEDATE			as ExpCloseDate,
	"+dbo.fn_SqlTranslatedColumn('OPPORTUNITY','REMARKS',null,'O',
					@sLookupCulture,@pbCalledFromCentura)+
	" as Remarks,
	O.POTENTIALWIN			as PotentialWin,
	"+dbo.fn_SqlTranslatedColumn('OPPORTUNITY','NEXTSTEP',null,'O',
					@sLookupCulture,@pbCalledFromCentura)+
	" as NextStep,
	O.STAGE				as Stage,
	O.POTENTIALVALCURRENCY		as PotentialValCurrency,
	O.NUMBEROFSTAFF			as NumberOfStaff,
	"+dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'C',
					@sLookupCulture,@pbCalledFromCentura)+
	"					as PotentialValCurrencyDesc
	from OPPORTUNITY O
	LEFT JOIN CURRENCY C ON (C.CURRENCY = O.POTENTIALVALCURRENCY)
	where 
	O.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnCaseKey		int',
			@pnCaseKey	 = @pnCaseKey

End

Return @nErrorCode
GO

Grant execute on dbo.crm_FetchOpportunity to public
GO