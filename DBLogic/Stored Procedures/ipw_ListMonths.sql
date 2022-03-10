-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListMonths									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListMonths]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListMonths.'
	Drop procedure [dbo].[ipw_ListMonths]
End
Print '**** Creating Stored Procedure dbo.ipw_ListMonths...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_ListMonths
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0
)
as
-- PROCEDURE:	ipw_ListMonths
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists the months retrieved from TABLECODES table (TABLETYPE = 89) sorted by 
--		USERCODE column converted to numeric values, i.e. in calendar order.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 29 May 2006	IB	RFC3678	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode=0
Begin
	Set @sSQLString = "
		Select	
			T.USERCODE 	as MonthKey,
			" + 
		dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura) + 
				      " as MonthDescription
		from	TABLECODES T
		where	T.TABLETYPE = 89
		order by cast(T.USERCODE as tinyint)"

	Exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListMonths to public
GO

