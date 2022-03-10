-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListEntryRule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListEntryRule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListEntryRule.'
	Drop procedure [dbo].[ipw_ListEntryRule]
End
Print '**** Creating Stored Procedure dbo.ipw_ListEntryRule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListEntryRule
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCriteriaKey		int		-- Mandatory
)
as
-- PROCEDURE:	ipw_ListEntryRule
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List entries for a given criteria key

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Aug 2011	SF	R9317	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select	DC.CRITERIANO as CriterionKey,
		DC.ENTRYNUMBER as EntryKey,
		"+dbo.fn_SqlTranslatedColumn('DETAILCONTROL','ENTRYDESC',null,'DC',@sLookupCulture,@pbCalledFromCentura)
				+ " as EntryDescription,
		DC.DISPLAYSEQUENCE as DisplaySequence,	
		Cast(isnull(DC.INHERITED,0) as bit) as IsInherited,
		DC.PARENTCRITERIANO as ParentCriterionKey,	
		DC.PARENTENTRYNUMBER as ParentEntryKey
	from DETAILCONTROL DC
	where DC.CRITERIANO = @pnCriteriaKey
	order by DC.DISPLAYSEQUENCE"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCriteriaKey	int',
				   	  @pnCriteriaKey	= @pnCriteriaKey
	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListEntryRule to public
GO
