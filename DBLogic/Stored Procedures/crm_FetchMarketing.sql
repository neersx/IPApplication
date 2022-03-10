-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_FetchMarketing									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_FetchMarketing]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_FetchMarketing.'
	Drop procedure [dbo].[crm_FetchMarketing]
End
Print '**** Creating Stored Procedure dbo.crm_FetchMarketing...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_FetchMarketing
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int -- Mandatory
)
as
-- PROCEDURE:	crm_FetchMarketing
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the Marketing business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 22 Aug 2008	AT	RFC5712	1	Procedure created.
-- 03 Oct 2008	AT	RFC7118	2	Added Staff/Contacts Attended.
-- 24 Oct 2011	ASH	R11460  3	Cast integer columns as nvarchar(11) data type.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0

Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)


If @nErrorCode = 0
Begin
	Set @sSQLString = "Select

	CAST(M.CASEID as nvarchar(11))		as RowKey,
	M.CASEID		as CaseKey,
	M.ACTUALCOSTLOCAL	as ActualCostLocal,
	M.ACTUALCOST		as ActualCost,
	M.ACTUALCOSTCURRENCY	as ActualCostCurrency,
	"+dbo.fn_SqlTranslatedColumn('CURRENCY','DESCRIPTION',null,'C',
					@sLookupCulture,@pbCalledFromCentura)+
	"					as ActualCostCurrencyDescription,
	M.EXPECTEDRESPONSES	as ExpectedResponses,
	ES.EVENTDATE		as StartDate,
	isnull(EA.EVENTDUEDATE,EA.EVENTDATE) as ActualDate,
	M.STAFFATTENDED		as StaffAttended,
	M.CONTACTSATTENDED 	as ContactsAttended
	from MARKETING M
	left join CASEEVENT ES on (ES.CASEID = M.CASEID
				and ES.EVENTNO = -12210)
	left join CASEEVENT EA on (EA.CASEID = M.CASEID
				and EA.EVENTNO = -12211)
	LEFT JOIN CURRENCY C ON (C.CURRENCY = M.ACTUALCOSTCURRENCY)
	where
	M.CASEID = @pnCaseKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnCaseKey		int',
			@pnCaseKey	 = @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.crm_FetchMarketing to public
GO