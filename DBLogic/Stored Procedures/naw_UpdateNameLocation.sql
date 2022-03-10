-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateNameLocation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateNameLocation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateNameLocation.'
	Drop procedure [dbo].[naw_UpdateNameLocation]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateNameLocation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_UpdateNameLocation
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pnNameKey			int,            -- Mandatory
	@pnFileLocationKey		int,		-- Mandatory
	@pbIsCurrent    		bit		= null,
	@pbIsDefault		        bit	        = null,
	@pdtLastModifiedDate            datetime        = null
)
as
-- PROCEDURE:	naw_UpdateNameLocation
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update Staff Location.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 28 Jul 2011	MS	R100503	1	Procedure created   

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "UPDATE NAMELOCATION
			SET     ISCURRENTLOCATION = @pbIsCurrent,			
			        ISDEFAULTLOCATION = @pbIsDefault
			WHERE NAMENO = @pnNameKey
		        and FILELOCATION = @pnFileLocationKey
		        and (LOGDATETIMESTAMP = @pdtLastModifiedDate or 
		            (LOGDATETIMESTAMP is null and @pdtLastModifiedDate is null))"

	exec @nErrorCode=sp_executesql @sSQLString,
		      	N'
			@pnNameKey			int,
			@pnFileLocationKey		int,
			@pbIsCurrent		        bit,
			@pbIsDefault                    bit,
			@pdtLastModifiedDate	        datetime',
			@pnNameKey		        = @pnNameKey,
			@pnFileLocationKey		= @pnFileLocationKey,
			@pbIsCurrent	                = @pbIsCurrent,
			@pbIsDefault		        = @pbIsDefault,
			@pdtLastModifiedDate	        = @pdtLastModifiedDate	
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateNameLocation to public
GO