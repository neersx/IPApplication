-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ipw_ListResources
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListResources]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListResources.'
	Drop procedure [dbo].[ipw_ListResources]
	Print '**** Creating Stored Procedure dbo.ipw_ListResources...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipw_ListResources
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey  		int		= null,		
	@pbCalledFromCentura	bit		= 0,
	@pnResourceTypeKey	smallint	= null
)
AS
-- PROCEDURE:	ipw_ListResources
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of resources.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 Oct 2005  TM	RFC3144	1	Procedure created
-- 18 May 2006  SW	RFC3492	2	Add a new optional parameter @pnResourceTypeKey to filter on RESOURCE.TYPE if @pnResourceTypeKey not null.
-- 23 Jun 2006	SW	RFC4034	3	Only return row when RESOURCENO >= 0

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(500)
Declare @sWhere		nvarchar(500)
Declare @sLookupCulture	nvarchar(10)

set 	@sLookupCulture  = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0
Set 	@sWhere		 = "where R.RESOURCENO >= 0 " + char(10)

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
		Select  R.RESOURCENO as ResourceKey,
			"+dbo.fn_SqlTranslatedColumn('RESOURCE','DESCRIPTION',null,'R',@sLookupCulture,@pbCalledFromCentura)+" as ResourceDescription
		from	RESOURCE R
	"

	If @pnNameKey is not null
	Begin
		Set @sSQLString = @sSQLString +	char(10) 
			+ "join  EMPLOYEE E		on (E.RESOURCENO = R.RESOURCENO)" + char(10)
		Set @sWhere = @sWhere + "and E.EMPLOYEENO = @pnNameKey" + char(10)
	End

	If @pnResourceTypeKey is not null
	Begin
		Set @sWhere = @sWhere + "and R.TYPE = @pnResourceTypeKey" + char(10)
	End

	-- Add where clause then order by
 	Set @sSQLString = @sSQLString + @sWhere + "order by ResourceDescription"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnNameKey		int,
					  @pnResourceTypeKey	smallint',
					  @pnNameKey		= @pnNameKey,
					  @pnResourceTypeKey 	= @pnResourceTypeKey
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListResources to public
GO
