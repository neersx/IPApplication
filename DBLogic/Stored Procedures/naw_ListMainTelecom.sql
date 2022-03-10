-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_ListMainTelecom									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_ListMainTelecom]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_ListMainTelecom.'
	Drop procedure [dbo].[naw_ListMainTelecom]
End
Print '**** Creating Stored Procedure dbo.naw_ListMainTelecom...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_ListMainTelecom
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey			int,
	@pnTelecomTypeKey		int
)
as
-- PROCEDURE:	naw_ListMainTelecom
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List Main Telecom for a Name and Telecom Type

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 19 Mar 2007	PG	RFC3646	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString ="
	Select  NT.NAMENO				as NameKey,	
		dbo.fn_FormatTelecom   (T.TELECOMTYPE,
					T.ISD,
					T.AREACODE,
					T.TELECOMNUMBER,
					T.EXTENSION) 	As TelecomNumber
		from [NAME] N
		join NAMETELECOM NT 		on (NT.NAMENO = N.NAMENO)
		join TELECOMMUNICATION T 	on (T.TELECODE = NT.TELECODE)
		where N.NAMENO = @pnNameKey and T.TELECOMTYPE=@pnTelecomTypeKey
		
			and ((T.TELECOMTYPE = 1901 and NT.TELECODE = N.MAINPHONE)
			or (T.TELECOMTYPE = 1902 and NT.TELECODE = N.FAX)
			or (T.TELECOMTYPE = 1903 and NT.TELECODE = N.MAINEMAIL))
			"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnNameKey		int,
					@pnTelecomTypeKey	int',
					@pnNameKey		= @pnNameKey,
					@pnTelecomTypeKey	= @pnTelecomTypeKey
	
End

Return @nErrorCode
GO

Grant execute on dbo.naw_ListMainTelecom to public
GO