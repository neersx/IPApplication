-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListEventCategories
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListEventCategories]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListEventCategories.'
	Drop procedure [dbo].[ipw_ListEventCategories]
	Print '**** Creating Stored Procedure dbo.ipw_ListEventCategories...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipw_ListEventCategories
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListEventCategories
-- VERSION:	4
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of event categories.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 26 Jul 2004  TM	RFC1323	1	Procedure created
-- 26 Jul 2004	TM	RFC1323	2	Correct the Description.
-- 15 Sep 2004	JEK	RFC886	3	Implement translation.
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
	Select 	C.CATEGORYID	as 'CategoryKey',
		"+dbo.fn_SqlTranslatedColumn('EVENTCATEGORY','CATEGORYNAME',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'CategoryName'
	from 	EVENTCATEGORY C
	order by 2"	

	exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount
End




Return @nErrorCode
GO

Grant execute on dbo.ipw_ListEventCategories to public
GO
