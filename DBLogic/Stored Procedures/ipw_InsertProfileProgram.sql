-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertProfileProgram
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertProfileProgram]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertProfileProgram.'
	Drop procedure [dbo].[ipw_InsertProfileProgram]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertProfileProgram...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InsertProfileProgram
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnProfileKey		int,		-- Mandatory
	@psProgramKey		nvarchar(8)	-- Mandatory
)
as
-- PROCEDURE:	ipw_InsertProfileProgram
-- VERSION:	1
-- DESCRIPTION:	Create an assocation between a Profile and Program

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

-- Insert
If @nErrorCode = 0
Begin

	Set @sSQLString = " 
	insert 	into PROFILEPROGRAM (PROFILEID, PROGRAMID)
	values	(@pnProfileKey, @psProgramKey)"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnProfileKey	int,
					  @psProgramKey	nvarchar(8)',
					  @pnProfileKey	= @pnProfileKey,
					  @psProgramKey	= @psProgramKey
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertProfileProgram to public
GO
