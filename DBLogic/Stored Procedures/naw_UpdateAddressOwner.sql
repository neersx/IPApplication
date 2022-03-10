-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_UpdateAddressOwner
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_UpdateAddressOwner]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_UpdateAddressOwner.'
	Drop procedure [dbo].[naw_UpdateAddressOwner]
End
Print '**** Creating Stored Procedure dbo.naw_UpdateAddressOwner...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.naw_UpdateAddressOwner
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnAddressKey		int,		-- Mandatory
	@pnNewOwnerKey		int,		-- Mandatory
	@pnOldOwnerKey		int		-- Mandatory	
)
as
-- PROCEDURE:	naw_UpdateAddressOwner
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update the owner of the address

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 11 Feb 2008	LP	RFC3497	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

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
		    Update NAMEADDRESS
		    Set OWNEDBY = 0
		    Where ADDRESSCODE = @pnAddressKey
		    and NAMENO = @pnOldOwnerKey
	    "
	    exec @nErrorCode = sp_executesql @sSQLString,
		    N'@pnAddressKey		int,
			    @pnOldOwnerKey	int',
			    @pnAddressKey	= @pnAddressKey,
			    @pnOldOwnerKey	= @pnOldOwnerKey
            	
    End

    -- Then set the new owner
    If @nErrorCode = 0 
    Begin
	    Set @sSQLString = "
		    Update NAMEADDRESS
		    Set OWNEDBY = 1
		    Where ADDRESSCODE = @pnAddressKey
		    and NAMENO = @pnNewOwnerKey
	    "
            	
	    exec @nErrorCode = sp_executesql @sSQLString,
	    N'@pnAddressKey		int,
		    @pnNewOwnerKey	int',
		    @pnAddressKey	= @pnAddressKey,
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

Grant execute on dbo.naw_UpdateAddressOwner to public
GO