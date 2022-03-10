-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ac_ListProfitCentres 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ac_ListProfitCentres]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ac_ListProfitCentres.'
	Drop procedure [dbo].[ac_ListProfitCentres ]
End
Print '**** Creating Stored Procedure dbo.ac_ListProfitCentres...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ac_ListProfitCentres 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ac_ListProfitCentres 
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Lists Profit Centres.
-- COPYRIGHT:Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07-Sep-2004	TM	RFC1158	1	Procedure created
-- 13-Sep-2004	TM	RFC886	2	Implement Translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0


If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	select  P.PROFITCENTRECODE	as ProfitCentreKey,
	"+dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'P',@sLookupCulture,@pbCalledFromCentura)
				+ " as ProfitCentreDescription
	from PROFITCENTRE P 
	order  by ProfitCentreDescription"
		
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.ac_ListProfitCentres to public
GO
