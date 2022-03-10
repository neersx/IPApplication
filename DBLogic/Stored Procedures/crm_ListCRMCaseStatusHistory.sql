-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_ListCRMCaseStatusHistory									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_ListCRMCaseStatusHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_ListCRMCaseStatusHistory.'
	Drop procedure [dbo].[crm_ListCRMCaseStatusHistory]
End
Print '**** Creating Stored Procedure dbo.crm_ListCRMCaseStatusHistory...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.crm_ListCRMCaseStatusHistory
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int 		-- Mandatory
)
as
-- PROCEDURE:	crm_ListCRMCaseStatusHistory
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the CRMCaseStatusHistory business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 20 Jun 2008	AT	RFC5748	1	Procedure created
-- 04 Sep 2008	AT	RFC5726	2	Added monetary values to history
-- 04 Nov 2015	KR	R53910	3	Adjust formatted names logic (DR-15543)

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Select cast(C.STATUSID as nvarchar(50))	as 'RowKey',
		C.CASEID		as 'CaseKey',
		C.CRMCASESTATUS		as 'CRMCaseStatusKey',
		T.DESCRIPTION		as 'CRMCaseStatusDescription',
		C.LOGDATETIMESTAMP	as 'ModifiedDate',
		C.POTENTIALVALUELOCAL	as 'PotentialValueLocal',
		C.ACTUALCOSTLOCAL	as 'ActualCostLocal',
		C.BUDGETAMOUNT		as 'BudgetAmount',
		UI.NAMENO		as 'EmployeeKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, NULL) as 'Employee'
	from CRMCASESTATUSHISTORY C
	join TABLECODES T ON (C.CRMCASESTATUS = T.TABLECODE)
	LEFT JOIN USERIDENTITY UI ON (UI.IDENTITYID = C.LOGIDENTITYID)
	LEFT JOIN NAME N ON (N.NAMENO = UI.NAMENO)
	where C.CASEID = @pnCaseKey
	order by C.LOGDATETIMESTAMP DESC"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCaseKey		int',
			@pnCaseKey	 = @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.crm_ListCRMCaseStatusHistory to public
GO