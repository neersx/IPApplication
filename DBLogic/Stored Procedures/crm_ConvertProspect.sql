-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_ConvertProspect									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_ConvertProspect]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_ConvertProspect.'
	Drop procedure [dbo].[crm_ConvertProspect]
End
Print '**** Creating Stored Procedure dbo.crm_ConvertProspect...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.crm_ConvertProspect
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnProspectKey          int             -- Mandatory
)
as
-- PROCEDURE:	crm_ConvertProspect
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Convert the Prospect by defaulting associated names.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 23 Mar 2009	AT	RFC7244	1	Procedure created.


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)
Declare @sNameTypeKeys          nvarchar(508)

-- Initialise variables
Set @nErrorCode = 0

Select @sNameTypeKeys = COLCHARACTER from SITECONTROL where CONTROLID = 'CRM Convert Client Name Types'

-- Set Name Type Classification of client
If @nErrorCode = 0 and @sNameTypeKeys is not null
Begin
        exec @nErrorCode = dbo.naw_ToggleNameTypes	@pnUserIdentityId	= @pnUserIdentityId,	
						        @psCulture		= @psCulture,	
						        @pbCalledFromCentura    = @pbCalledFromCentura,
						        @psNameKeys             = @pnProspectKey,
						        @psNameTypeKeys         = @sNameTypeKeys,
						        @pbIsAllowed	        = 1
End

-- Make the name a client by toggling the Used as Client flag.
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		update NAME SET USEDASFLAG = USEDASFLAG | 4
		WHERE NAMENO = @pnProspectKey"

        exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnProspectKey	int',
					  @pnProspectKey	= @pnProspectKey
End

-- Deselect Name Type Classification for inactive Prospect
If @nErrorCode = 0
Begin
        Set @sSQLString = "
        Update NTC
        set NTC.ALLOW = 0
	from NAMETYPECLASSIFICATION NTC
        where NTC.NAMETYPE = N'~PR'
	and NTC.NAMENO = @pnProspectKey"
        
        exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnProspectKey	int',
					  @pnProspectKey	= @pnProspectKey
End

-- Deselect Name Type Classification for inactive Leads
If @nErrorCode = 0
Begin
        Set @sSQLString = "
        Update NTC
        set NTC.ALLOW = 0
	from NAMETYPECLASSIFICATION NTC 
	-- Leads against the prospect
	join ASSOCIATEDNAME AN1 on (AN1.RELATEDNAME = NTC.NAMENO
				and AN1.RELATIONSHIP IN ('LEA', 'EMP')
				and AN1.NAMENO = @pnProspectKey)
	left join -- other prospects against the Lead.
	(select AN2.RELATEDNAME, AN2.NAMENO FROM
		ASSOCIATEDNAME AN2 
		join NAMETYPECLASSIFICATION PNTC on (PNTC.NAMENO = AN2.NAMENO and PNTC.NAMETYPE = '~PR' and PNTC.ALLOW = 1)
		join NAME PN on (PN.NAMENO = AN2.NAMENO)
		where isnull(PN.USEDASFLAG, 0) & 4 = 0
		and AN2.RELATIONSHIP IN ('LEA', 'EMP')
		and AN2.NAMENO != @pnProspectKey) as OP on (OP.RELATEDNAME = NTC.NAMENO)
        where NTC.NAMETYPE = '~LD'
	and OP.RELATEDNAME is null"

        exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnProspectKey	int',
					  @pnProspectKey	= @pnProspectKey        
End

Return @nErrorCode
GO

Grant execute on dbo.crm_ConvertProspect to public
GO