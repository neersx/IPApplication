-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_InsertNameLocation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_InsertNameLocation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_InsertNameLocation.'
	Drop procedure [dbo].[naw_InsertNameLocation]
End
Print '**** Creating Stored Procedure dbo.naw_InsertNameLocation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.naw_InsertNameLocation
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pnNameKey			int,            -- Mandatory
	@pnFileLocationKey		int,		-- Mandatory
	@pbIsCurrent    		bit		= null,
	@pbIsDefault		        bit	        = null
)
as
-- PROCEDURE:	naw_InsertNameLocation
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert Staff Location.

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
	Set @sSQLString = "Insert into NAMELOCATION
			(NAMENO,
			FILELOCATION,
			ISCURRENTLOCATION,
			ISDEFAULTLOCATION)
		values (@pnNameKey,
			@pnFileLocationKey,
			@pbIsCurrent,
			@pbIsDefault)"

	exec @nErrorCode=sp_executesql @sSQLString,
		      	N'
			@pnNameKey			int,
			@pnFileLocationKey		int,
			@pbIsCurrent		        bit,
			@pbIsDefault                    bit',
			@pnNameKey		        = @pnNameKey,
			@pnFileLocationKey		= @pnFileLocationKey,
			@pbIsCurrent	                = @pbIsCurrent,
			@pbIsDefault		        = @pbIsDefault	
End

Return @nErrorCode
GO

Grant execute on dbo.naw_InsertNameLocation to public
GO