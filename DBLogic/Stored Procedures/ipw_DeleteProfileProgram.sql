-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteProfileProgram
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteProfileProgram]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteProfileProgram.'
	Drop procedure [dbo].[ipw_DeleteProfileProgram]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteProfileProgram...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_DeleteProfileProgram
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnOldProfileKey	int,		-- Mandatory
	@psOldProgramKey	nvarchar(8)	-- Mandatory
	
)
as
-- PROCEDURE:	ipw_DeleteProfileProgram
-- VERSION:	1
-- DESCRIPTION:	Remove the association between a Profile and a Program

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 16 Dec 2009	LP	RFC8450	1	Procedure created


SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

declare	@nErrorCode		int
declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 		= 0

-- Delete
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	delete 	PROFILEPROGRAM
	where	PROFILEID 	= @pnOldProfileKey
	and	PROGRAMID	= @psOldProgramKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnOldProfileKey	int,
					  @psOldProgramKey	nvarchar(8)',
					  @pnOldProfileKey	= @pnOldProfileKey,
					  @psOldProgramKey	= @psOldProgramKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteProfileProgram to public
GO
