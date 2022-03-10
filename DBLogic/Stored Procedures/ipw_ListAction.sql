-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListAction
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListAction]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListAction.'
	Drop procedure [dbo].[ipw_ListAction]
	Print '**** Creating Stored Procedure dbo.ipw_ListAction...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipw_ListAction
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListAction
-- VERSION:	5
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Actions.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 08 Jul 2004  TM	RFC1230	1	Procedure created
-- 09 Jul 2004	TM	RFC1230	2	Change Action column to ActionName.
-- 15 Sep 2004	JEK	RFC886	3	Implement translation.
-- 15 May 2005	JEK	RFC2508	4	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 15 Aug 2011	SF	RFC9317	5	Return ActionType

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
	Select 	A.ACTION 		as ActionKey,
		"+dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'A',@sLookupCulture,@pbCalledFromCentura)
				+ " as ActionName,
		A.ACTIONTYPEFLAG	as ActionTypeFlag				
	from 	ACTIONS A
	order by 2"	

	exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount
End




Return @nErrorCode
GO

Grant execute on dbo.ipw_ListAction to public
GO
