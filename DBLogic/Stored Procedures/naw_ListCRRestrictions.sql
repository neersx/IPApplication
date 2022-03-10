-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListCRRestrictions  
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListCRRestrictions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListCRRestrictions.'
	Drop procedure [dbo].[naw_ListCRRestrictions  ]
	Print '**** Creating Stored Procedure dbo.naw_ListCRRestrictions...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_ListCRRestrictions  
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	naw_ListCRRestrictions  
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Lists supplier restrictions.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07-Sep-2004	TM	RFC1158	1	Procedure created
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
	Select  R.CRRESTRICTIONID		as 'RestrictionKey',
		"+dbo.fn_SqlTranslatedColumn('CRRESTRICTION','CRRESTRICTIONDESC',null,'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'RestrictionDescription'
	from CRRESTRICTION R
	order by 'RestrictionDescription'"
		
	exec @nErrorCode = sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.naw_ListCRRestrictions to public
GO
