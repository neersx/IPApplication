-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dsb_ListAccountingPeriods 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dsb_ListAccountingPeriods]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dsb_ListAccountingPeriods.'
	Drop procedure [dbo].[dsb_ListAccountingPeriods]
End
Print '**** Creating Stored Procedure dbo.dsb_ListAccountingPeriods...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.dsb_ListAccountingPeriods 
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	dsb_ListAccountingPeriods 
-- VERSION:	1
-- SCOPE:	Dashboard
-- DESCRIPTION:	Lists Employess for accounting purposes.
-- COPYRIGHT:Copyright 1993 - 2009 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28-Oct-2009	SF	RFC8564	1	Return additional information

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin	
	Select  P.PERIODID			as PeriodKey,
			P.LABEL				as PeriodLabel,
			P.STARTDATE			as StartDate,
			P.ENDDATE			as EndDate
	from PERIOD P
	order by P.STARTDATE desc

	Set @nErrorCode = @@Error
End


Return @nErrorCode
GO

Grant execute on dbo.dsb_ListAccountingPeriods to public
GO


