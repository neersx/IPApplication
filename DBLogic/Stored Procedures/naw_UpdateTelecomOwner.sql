-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateTelecomOwner									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateTelecomOwner]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateTelecomOwner.'
	Drop procedure [dbo].[naw_UpdateTelecomOwner]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateTelecomOwner...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_UpdateTelecomOwner
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pntelecomKey		int,		-- Mandatory
	@pnNewOwnerKey		int,		-- Mandatory
	@pnOldOwnerKey		int		-- Mandatory	
)
as
-- PROCEDURE:	naw_UpdateTelecomOwner
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Provide the list of all names which are associated with the telecom.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 05 Oct 2010	ASH	RFC9510	1	Procedure created


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF


Declare @nErrorCode		int
Declare @nRowCount		int
Declare @nTranCountStart		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount = 0

Select @nTranCountStart = @@TranCount
BEGIN TRANSACTION

    -- First remove the current owner
    If @nErrorCode = 0 
    Begin
	    Set @sSQLString = "
		    Update NAMETELECOM
		    Set OWNEDBY = 0
		    Where TELECODE = @pntelecomKey
		    and NAMENO = @pnOldOwnerKey
	    "
	    exec @nErrorCode = sp_executesql @sSQLString,
		    N'@pntelecomKey		int,
			    @pnOldOwnerKey	int',
			    @pntelecomKey	= @pntelecomKey,
			    @pnOldOwnerKey	= @pnOldOwnerKey
            	
    End

    -- Then set the new owner
    If @nErrorCode = 0 
    Begin
	    Set @sSQLString = "
		    Update NAMETELECOM
		    Set OWNEDBY = 1
		    Where TELECODE = @pntelecomKey
		    and NAMENO = @pnNewOwnerKey
	    "
            	
	    exec @nErrorCode = sp_executesql @sSQLString,
	    N'@pntelecomKey		int,
		    @pnNewOwnerKey	int',
		    @pntelecomKey	= @pntelecomKey,
		    @pnNewOwnerKey	= @pnNewOwnerKey

    End

If @@TranCount > @nTranCountStart
Begin
	If @nErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

Return @nErrorCode
GO

Grant execute on dbo.naw_UpdateTelecomOwner to public
GO
