-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListRestrictions
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListRestrictions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListRestrictions.'
	Drop procedure [dbo].[naw_ListRestrictions]
	Print '**** Creating Stored Procedure dbo.naw_ListRestrictions...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListRestrictions
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	naw_ListRestrictions
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns columns RestrictionKey and RestrictionDescription from the DebtorStatus database table 
--		(BadDebtor, DebtorStatus).

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19-Dec-2003	TM	RFC611	1	Procedure created
-- 15 Sep 2004	JEK	RFC886	2	Implement translation.
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
	Select 	D.BADDEBTOR 	as 'RestrictionKey', 
		"+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'D',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'RestrictionDescription'
	from DEBTORSTATUS D
	order by RestrictionDescription"
	
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.naw_ListRestrictions to public
GO
