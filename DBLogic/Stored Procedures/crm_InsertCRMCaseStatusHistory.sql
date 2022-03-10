-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_InsertCRMCaseStatusHistory									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_InsertCRMCaseStatusHistory]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_InsertCRMCaseStatusHistory.'
	Drop procedure [dbo].[crm_InsertCRMCaseStatusHistory]
End
Print '**** Creating Stored Procedure dbo.crm_InsertCRMCaseStatusHistory...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.crm_InsertCRMCaseStatusHistory
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,		-- Mandatory.
	@pnCRMCaseStatusKey	int		-- Mandatory
)
as
-- PROCEDURE:	crm_InsertCRMCaseStatusHistory
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert CRMCaseStatusHistory.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 20 Jun 2008	AT	RFC5748	1	Procedure created
-- 04 Sep 2008	AT	RFC5726	2	Store Monetary values also.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sInsertString 		nvarchar(4000)
Declare @sValuesString		nvarchar(4000)
Declare @sComma			nchar(1)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sInsertString = "Insert into CRMCASESTATUSHISTORY
				(CASEID, CRMCASESTATUS, POTENTIALVALUELOCAL, ACTUALCOSTLOCAL, BUDGETAMOUNT)
				select @pnCaseKey, @pnCRMCaseStatusKey, O.POTENTIALVALUELOCAL, M.ACTUALCOSTLOCAL, C.BUDGETAMOUNT
				from CASES C
				left join OPPORTUNITY O on (O.CASEID = C.CASEID)
				left join MARKETING M on (M.CASEID = C.CASEID)
				where C.CASEID = @pnCaseKey"		

	exec @nErrorCode=sp_executesql @sInsertString,
			      	N'@pnCaseKey		int,
				@pnCRMCaseStatusKey	int',
				@pnCaseKey	 	= @pnCaseKey,
				@pnCRMCaseStatusKey	= @pnCRMCaseStatusKey
End

Return @nErrorCode
GO

Grant execute on dbo.crm_InsertCRMCaseStatusHistory to public
GO