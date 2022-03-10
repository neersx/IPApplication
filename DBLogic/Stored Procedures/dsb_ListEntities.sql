-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.dsb_ListEntities
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dsb_ListEntities]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dsb_ListEntities.'
	Drop procedure [dbo].[dsb_ListEntities]
End
Print '**** Creating Stored Procedure dbo.dsb_ListEntities...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.dsb_ListEntities
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbForPosting 		bit 		= 0
)
AS
-- PROCEDURE:	dsb_ListEntities
-- VERSION:	2
-- SCOPE:	Dashboard Prototype
-- DESCRIPTION:	Returns a list of Entities, based on ac_ListEntities.
-- COPYRIGHT:Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 30 Oct 2009	SF	RFC8564 1	Procedure created
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(4000)

Declare @bIsMainEntity	bit

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0
Set 	@bIsMainEntity	 = 0


-- Should the WIP be automatically created against the main Entity of the firm?
If @nErrorCode = 0
and @pbForPosting = 1
Begin	
	Set @sSQLString = "
	Select @bIsMainEntity = COLBOOLEAN
	from SITECONTROL 
	where CONTROLID = 'Automatic WIP Entity'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@bIsMainEntity	bit			output',
				   	  @bIsMainEntity	= @bIsMainEntity	output
End

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	N.NAMENO	as 'EntityKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'EntityName',
		N.NAMECODE		as 'EntityCode',
		CASE WHEN(E.DEFAULTENTITYNO is not null)
			THEN CASE WHEN(E.DEFAULTENTITYNO=N.NAMENO) THEN CAST(1 as bit) ELSE CAST(0 as bit) END
			ELSE CASE WHEN(SC.COLINTEGER=N.NAMENO)     THEN CAST(1 as bit) ELSE CAST(0 as bit) END
		END		as 'IsDefault'		
	from NAME N
	join SPECIALNAME SN      on (SN.NAMENO = N.NAMENO and SN.ENTITYFLAG = 1)
	join USERIDENTITY UI     on (UI.IDENTITYID = @pnUserIdentityId)
	left join SITECONTROL SC on (SC.CONTROLID = 'HOMENAMENO')
	left join EMPLOYEE E     on (E.EMPLOYEENO = UI.NAMENO)"+char(10)+
	CASE 	WHEN @pbForPosting = 1 and @bIsMainEntity = 1
		-- Return only the best default Entity
		THEN "where N.NAMENO = ISNULL(E.DEFAULTENTITYNO,SC.COLINTEGER)"
	END+char(10)+
	"order by 'EntityName'"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int',
		 			  @pnUserIdentityId	= @pnUserIdentityId
	
	Set @pnRowCount = @@Rowcount
End


Return @nErrorCode
GO

Grant execute on dbo.dsb_ListEntities to public
GO
