-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListEventRule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListEventRule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListEventRule.'
	Drop procedure [dbo].[ipw_ListEventRule]
End
Print '**** Creating Stored Procedure dbo.ipw_ListEventRule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListEventRule
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCriteriaKey		int		-- Mandatory
)
as
-- PROCEDURE:	ipw_ListEventRule
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List event control for a given criteria key

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
	Select	EC.CRITERIANO as CriterionKey,
		EC.EVENTNO as EventKey,
		"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)
				+ " as EventDescription,
		E.EVENTCODE as EventCode,
		EC.IMPORTANCELEVEL as ImportanceLevelKey,
		"+dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)
				+ " as ImportanceLevelDescription,
		EC.NUMCYCLESALLOWED as MaxCycle,
		EC.DISPLAYSEQUENCE as DisplaySequence,	
		Cast(isnull(EC.INHERITED,0) as bit) as IsInherited,
		EC.PARENTCRITERIANO as ParentCriterionKey,	
		EC.PARENTEVENTNO as ParentEventKey
	from EVENTCONTROL EC
	join [EVENTS] E on (E.EVENTNO = EC.EVENTNO)
	left join IMPORTANCE I on (EC.IMPORTANCELEVEL = I.IMPORTANCELEVEL)
	where EC.CRITERIANO = @pnCriteriaKey
	order by EC.DISPLAYSEQUENCE"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCriteriaKey	int',
				   	  @pnCriteriaKey	= @pnCriteriaKey
	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListEventRule to public
GO
