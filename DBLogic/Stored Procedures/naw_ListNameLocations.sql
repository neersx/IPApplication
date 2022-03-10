-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListNameLocations									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListNameLocations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListNameLocations.'
	Drop procedure [dbo].[naw_ListNameLocations]
End
Print '**** Creating Stored Procedure dbo.naw_ListNameLocations...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListNameLocations
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int 		-- Mandatory
)
as
-- PROCEDURE:	naw_ListNameLocations
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the File Requests data.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 28 Jul 2011	MS	R100503	1	Procedure created            
-- 02 Nov 2015	vql	R53910	2	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
If @psCulture is not null
Begin
        Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
End 

If @nErrorCode = 0
Begin

        Set @sSQLString = "               
        Select  @pnNameKey as NameKey,
        dbo.fn_FormatNameUsingNameNo(@pnNameKey, 7101) as DisplayName"

        exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey		int',
			@pnNameKey		= @pnNameKey
End 

If @nErrorCode = 0
Begin
        Set @sSQLString = "Select
        NL.NAMENO		as NameKey,
        NL.FILELOCATION		as FileLocationKey,
	dbo.fn_GetTranslation(TC.[DESCRIPTION],null,TC.DESCRIPTION_TID,@sLookupCulture)
				as FileLocationDescription,
	NL.ISCURRENTLOCATION    as IsCurrent,
	NL.ISDEFAULTLOCATION    as IsDefault,
	NL.LOGDATETIMESTAMP     as LastModifiedDate
        FROM NAMELOCATION NL
	left join TABLECODES TC on (TC.TABLECODE = NL.FILELOCATION)
        WHERE NL.NAMENO = @pnNameKey
        order by FileLocationDescription"

        exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey		int,
			@sLookupCulture		nvarchar(10)',
			@pnNameKey		= @pnNameKey,
			@sLookupCulture		= @sLookupCulture
End


Return @nErrorCode
GO

Grant execute on dbo.naw_ListNameLocations to public
GO