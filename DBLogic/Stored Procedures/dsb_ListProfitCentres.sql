-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dsb_ListProfitCentres 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dsb_ListProfitCentres]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dsb_ListProfitCentres.'
	Drop procedure [dbo].[dsb_ListProfitCentres ]
End
Print '**** Creating Stored Procedure dbo.dsb_ListProfitCentres...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.dsb_ListProfitCentres 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	dsb_ListProfitCentres 
-- VERSION:	2
-- SCOPE:	Dashboard Prototype
-- DESCRIPTION:	Lists Profit Centres, based on ac_ListProfitCentres
-- COPYRIGHT:Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28-Oct-2009	SF	RFC8564	1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

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
				+ " as ProfitCentreDescription,
			P.ENTITYNO			as EntityKey,
			dbo.fn_FormatNameUsingNameNo(EN.NAMENO, null) as EntityName
	from PROFITCENTRE P 
	left join NAME EN on (EN.NAMENO = P.ENTITYNO)
	order  by ProfitCentreDescription"
		
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.dsb_ListProfitCentres to public
GO
