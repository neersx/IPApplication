-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sc_InsertPermission
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sc_InsertPermission]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.sc_InsertPermission.'
	Drop procedure [dbo].[sc_InsertPermission]
End
Print '**** Creating Stored Procedure dbo.sc_InsertPermission...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.sc_InsertPermission
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psLevelTable		nvarchar(30),	-- Mandatory	
	@pnLevelKey		int,		-- Mandatory
	@psObjectTable		nvarchar(30),	-- Mandatory
	@pnObjectIntegerKey	int,		-- Mandatory
	@psObjectStringKey	nvarchar(30),	-- Mandatory
	@pnSelectPermission	tinyint		= null,
	@pnMandatoryPermission	tinyint		= null,
	@pnInsertPermission	tinyint		= null,
	@pnUpdatePermission	tinyint		= null,
	@pnDeletePermission	tinyint		= null,
	@pnExecutePermission	tinyint		= null
)
as
-- PROCEDURE:	sc_InsertPermission
-- VERSION:	2
-- DESCRIPTION:	Insert a new Permission, returning the generated Role key.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Jun 2004	TM	RFC1500	1	Procedure created
-- 29 Jun 2004	TM	RFC1500	2	Implement the fn_GetPermission function to calculate permissions.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	insert 	into PERMISSIONS
		(OBJECTTABLE, 
		 OBJECTINTEGERKEY, 		 
		 OBJECTSTRINGKEY,
		 LEVELTABLE,
		 LEVELKEY,
		 GRANTPERMISSION,
		 DENYPERMISSION)
	select	 @psObjectTable,
		 @pnObjectIntegerKey, 		
		 @psObjectStringKey,
		 @psLevelTable,
		 @pnLevelKey,
		 P.GrantPermission,
		 P.DenyPermission
		 from
		 dbo.fn_GetPermission(@psLevelTable, 
				      @pnLevelKey, 
				      @psObjectTable, 
				      @pnObjectIntegerKey, 
				      @psObjectStringKey,
				      @pnSelectPermission, 
				      @pnMandatoryPermission, 
				      @pnInsertPermission,
				      @pnUpdatePermission, 
				      @pnDeletePermission, 
				      @pnExecutePermission) P"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psObjectTable	nvarchar(30),
					  @pnObjectIntegerKey	int,
					  @psObjectStringKey	nvarchar(30),					 
					  @psLevelTable		nvarchar(30),
					  @pnLevelKey		int,
					  @pnSelectPermission	tinyint,
					  @pnMandatoryPermission tinyint,
					  @pnInsertPermission	tinyint,
					  @pnUpdatePermission	tinyint,
					  @pnDeletePermission	tinyint,
					  @pnExecutePermission	tinyint',
					  @psObjectTable	= @psObjectTable,
					  @pnObjectIntegerKey	= @pnObjectIntegerKey,
					  @psObjectStringKey	= @psObjectStringKey,					 
					  @psLevelTable		= @psLevelTable,
					  @pnLevelKey		= @pnLevelKey,
					  @pnSelectPermission   = @pnSelectPermission,
					  @pnMandatoryPermission = @pnMandatoryPermission,
					  @pnInsertPermission 	= @pnInsertPermission,
					  @pnUpdatePermission	= @pnUpdatePermission,
					  @pnDeletePermission	= @pnDeletePermission,
					  @pnExecutePermission	= @pnExecutePermission
					  
End

Return @nErrorCode
GO

Grant execute on dbo.sc_InsertPermission to public
GO