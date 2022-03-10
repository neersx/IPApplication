-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListAdjustmentTypes									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListAdjustmentTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListAdjustmentTypes.'
	Drop procedure [dbo].[ipw_ListAdjustmentTypes]
End
Print '**** Creating Stored Procedure dbo.ipw_ListAdjustmentTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_ListAdjustmentTypes
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pbForStandingInstructions	bit		= 0
)
as
-- PROCEDURE:	ipw_ListAdjustmentTypes
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists the relevant Adjustment types retrieved from ADJUSTMENT table.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 23 May 2006	IB	RFC3678	1	Procedure created
-- 01 Jun 2006	IB	RFC3678	2	Sorted the result set by description.
-- 02 Jun 2006	IB	RFC3910	3	Adjustment type should be translatable.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode=0
Begin
	If @pbForStandingInstructions = 1
	Begin
		Set @sSQLString = "
			Select	
				A.ADJUSTMENT 	as AdjustmentTypeKey,
				"+dbo.fn_SqlTranslatedColumn('ADJUSTMENT', 'ADJUSTMENTDESC', null, 'A', @sLookupCulture, @pbCalledFromCentura)+"
						as AdjustmentTypeDescription
			from	ADJUSTMENT A
			where	A.ADJUSTMENT != '~0'
			order by AdjustmentTypeDescription"
	End
	Else
	Begin
		Set @sSQLString = "
			Select	
				A.ADJUSTMENT 	as AdjustmentTypeKey,
				"+dbo.fn_SqlTranslatedColumn('ADJUSTMENT', 'ADJUSTMENTDESC', null, 'A', @sLookupCulture, @pbCalledFromCentura)+"
						as AdjustmentTypeDescription
			from	ADJUSTMENT A
			order by AdjustmentTypeDescription"
	End
	
	Exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListAdjustmentTypes to public
GO

