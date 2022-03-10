-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sc_DeletePermission
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sc_DeletePermission]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.sc_DeletePermission.'
	Drop procedure [dbo].[sc_DeletePermission]
End
Print '**** Creating Stored Procedure dbo.sc_DeletePermission...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.sc_DeletePermission
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psLevelTable		nvarchar(30),	-- Mandatory	
	@pnLevelKey		int,		-- Mandatory
	@psObjectTable		nvarchar(30),	-- Mandatory
	@pnObjectIntegerKey	int,		-- Mandatory
	@psObjectStringKey	nvarchar(30),	-- Mandatory
	@pnOldSelectPermission	tinyint		= null,
	@pnOldMandatoryPermission tinyint		= null,
	@pnOldInsertPermission	tinyint		= null,
	@pnOldUpdatePermission	tinyint		= null,
	@pnOldDeletePermission	tinyint		= null,
	@pnOldExecutePermission	tinyint		= null
)
as
-- PROCEDURE:	sc_DeletePermission
-- VERSION:	2
-- DESCRIPTION:	Delete a permission if the underlying values are as expected.

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

-- Delete unused Permission.
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Delete PERMISSIONS
	from PERMISSIONS
	join dbo.fn_GetPermission    (	@psLevelTable, 
				      	@pnLevelKey, 
				      	@psObjectTable, 
				      	@pnObjectIntegerKey, 
				      	@psObjectStringKey,
				      	@pnOldSelectPermission, 
				      	@pnOldMandatoryPermission, 
				      	@pnOldInsertPermission,
				      	@pnOldUpdatePermission, 
				      	@pnOldDeletePermission, 
				      	@pnOldExecutePermission) P 
				   on  (P.GrantPermission = PERMISSIONS.GRANTPERMISSION
				   and 	P.DenyPermission  = PERMISSIONS.DENYPERMISSION)
	where    OBJECTTABLE     	= @psObjectTable
	and 	 OBJECTINTEGERKEY	= @pnObjectIntegerKey
	and 	 OBJECTSTRINGKEY 	= @psObjectStringKey
	and   	 LEVELTABLE	 	= @psLevelTable
	and  	 LEVELKEY	 	= @pnLevelKey" 

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psObjectTable		nvarchar(30),
					  @pnObjectIntegerKey		int,
					  @psObjectStringKey		nvarchar(30),					 
					  @psLevelTable			nvarchar(30),
					  @pnLevelKey			int,
					  @pnOldSelectPermission 	tinyint,
					  @pnOldMandatoryPermission 	tinyint,
					  @pnOldInsertPermission 	tinyint,
					  @pnOldUpdatePermission 	tinyint,
					  @pnOldDeletePermission 	tinyint,
					  @pnOldExecutePermission	tinyint',
					  @psObjectTable		= @psObjectTable,
					  @pnObjectIntegerKey		= @pnObjectIntegerKey,
					  @psObjectStringKey		= @psObjectStringKey,					 
					  @psLevelTable			= @psLevelTable,
					  @pnLevelKey			= @pnLevelKey,
					  @pnOldSelectPermission	= @pnOldSelectPermission,
					  @pnOldMandatoryPermission 	= @pnOldMandatoryPermission,
				 	  @pnOldInsertPermission	= @pnOldInsertPermission,
					  @pnOldUpdatePermission	= @pnOldUpdatePermission,
					  @pnOldDeletePermission	= @pnOldDeletePermission,
					  @pnOldExecutePermission	= @pnOldExecutePermission
End

Return @nErrorCode
GO

Grant execute on dbo.sc_DeletePermission to public
GO