-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sc_UpdatePermission
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sc_UpdatePermission]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.sc_UpdatePermission.'
	Drop procedure [dbo].[sc_UpdatePermission]
End
Print '**** Creating Stored Procedure dbo.sc_UpdatePermission...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.sc_UpdatePermission
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
	@pnExecutePermission	tinyint		= null,
	@pnOldSelectPermission	tinyint		= null,
	@pnOldMandatoryPermission tinyint	= null,
	@pnOldInsertPermission	tinyint		= null,
	@pnOldUpdatePermission	tinyint		= null,
	@pnOldDeletePermission	tinyint		= null,
	@pnOldExecutePermission	tinyint		= null
)
as
-- PROCEDURE:	sc_UpdatePermission
-- VERSION:	4
-- DESCRIPTION:	Update a permission if the underlying values are as expected.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Jun 2004	TM	RFC1500	1	Procedure created
-- 29 Jun 2004	TM	RFC1500	2	Implement the fn_GetPermission function to calculate permissions.
-- 29 Jun 2004	TM	RFC1500	3	Always return the new permissions (whether they were 0 or not) and test 
--					for 0 Grant/Deny permissions.
-- 13 Oct 2004	TM	RFC1898	4	Correct the update logic.

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

Declare	@nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

Declare @nGrantPermission	tinyint
Declare @nDenyPermission	tinyint

Declare @nOldGrantPermission	tinyint
Declare @nOldDenyPermission	tinyint

-- Initialise variables
Set @nErrorCode = 0

-- Get old and new permissions.
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  @nGrantPermission 	= FPNew.GrantPermission,
		@nDenyPermission  	= FPNew.DenyPermission,
		@nOldGrantPermission	= FPOld.GrantPermission,
		@nOldDenyPermission	= FPOld.DenyPermission
	from dbo.fn_GetPermission(@psLevelTable, 
				  @pnLevelKey, 
				  @psObjectTable, 
				  @pnObjectIntegerKey, 
				  @psObjectStringKey,
				  @pnOldSelectPermission, 
				  @pnOldMandatoryPermission, 
				  @pnOldInsertPermission,
				  @pnOldUpdatePermission, 
				  @pnOldDeletePermission, 
				  @pnOldExecutePermission) FPOld		
	left join dbo.fn_GetPermission(@psLevelTable, 
				  @pnLevelKey, 
				  @psObjectTable, 
				  @pnObjectIntegerKey, 
				  @psObjectStringKey,
				  @pnSelectPermission, 
				  @pnMandatoryPermission, 
				  @pnInsertPermission,
				  @pnUpdatePermission, 
				  @pnDeletePermission, 
				  @pnExecutePermission) FPNew
				on (1=1)"				  
	
	

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psObjectTable		nvarchar(30),
					  @pnObjectIntegerKey		int,
					  @psObjectStringKey		nvarchar(30),					 
					  @psLevelTable			nvarchar(30),
					  @pnLevelKey			int,
					  @pnSelectPermission		tinyint,
					  @pnMandatoryPermission 	tinyint,
					  @pnInsertPermission 		tinyint,
					  @pnUpdatePermission 		tinyint,
					  @pnDeletePermission		tinyint,
					  @pnExecutePermission		tinyint,
					  @pnOldSelectPermission 	tinyint,
					  @pnOldMandatoryPermission 	tinyint,
					  @pnOldInsertPermission 	tinyint,
					  @pnOldUpdatePermission 	tinyint,
					  @pnOldDeletePermission 	tinyint,
					  @pnOldExecutePermission	tinyint,
					  @nGrantPermission		tinyint			OUTPUT,
					  @nDenyPermission		tinyint			OUTPUT,
					  @nOldGrantPermission		tinyint			OUTPUT,
					  @nOldDenyPermission		tinyint			OUTPUT',
					  @psObjectTable		= @psObjectTable,
					  @pnObjectIntegerKey		= @pnObjectIntegerKey,
					  @psObjectStringKey		= @psObjectStringKey,					 
					  @psLevelTable			= @psLevelTable,
					  @pnLevelKey			= @pnLevelKey,
					  @pnSelectPermission		= @pnSelectPermission,
					  @pnMandatoryPermission 	= @pnMandatoryPermission,
				 	  @pnInsertPermission		= @pnInsertPermission,
					  @pnUpdatePermission		= @pnUpdatePermission,
					  @pnDeletePermission		= @pnDeletePermission,
					  @pnExecutePermission		= @pnExecutePermission,
					  @pnOldSelectPermission	= @pnOldSelectPermission,
					  @pnOldMandatoryPermission 	= @pnOldMandatoryPermission,
				 	  @pnOldInsertPermission	= @pnOldInsertPermission,
					  @pnOldUpdatePermission	= @pnOldUpdatePermission,
					  @pnOldDeletePermission	= @pnOldDeletePermission,
					  @pnOldExecutePermission	= @pnOldExecutePermission,
					  @nGrantPermission		= @nGrantPermission	OUTPUT,
					  @nDenyPermission		= @nDenyPermission	OUTPUT,
					  @nOldGrantPermission		= @nOldGrantPermission	OUTPUT,
					  @nOldDenyPermission		= @nOldDenyPermission	OUTPUT
					  

End

-- Delete unused Permission.
If @nErrorCode = 0
and @nGrantPermission = 0
and @nDenyPermission = 0
Begin
	Set @sSQLString = " 
	Delete
	from PERMISSIONS
	where GRANTPERMISSION = @nOldGrantPermission   
	and   DENYPERMISSION  = @nOldDenyPermission  
	and   OBJECTTABLE     = @psObjectTable
	and   OBJECTINTEGERKEY= @pnObjectIntegerKey
	and   OBJECTSTRINGKEY = @psObjectStringKey
	and   LEVELTABLE      = @psLevelTable
	and   LEVELKEY	      = @pnLevelKey" 

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psObjectTable	nvarchar(30),
					  @pnObjectIntegerKey	int,
					  @psObjectStringKey	nvarchar(30),					 
					  @psLevelTable		nvarchar(30),
					  @pnLevelKey		int,
					  @nOldGrantPermission	tinyint,
					  @nOldDenyPermission	tinyint',
					  @psObjectTable	= @psObjectTable,
					  @pnObjectIntegerKey	= @pnObjectIntegerKey,
					  @psObjectStringKey	= @psObjectStringKey,					 
					  @psLevelTable		= @psLevelTable,
					  @pnLevelKey		= @pnLevelKey,
					  @nOldGrantPermission	= @nOldGrantPermission,
					  @nOldDenyPermission 	= @nOldDenyPermission
End
 
-- Update Permission.
If @nErrorCode = 0
and (@nGrantPermission <> 0
 or @nDenyPermission <> 0)
Begin
	Set @sSQLString = " 
	Update 	 PERMISSIONS
	set      GRANTPERMISSION = @nGrantPermission,
		 DENYPERMISSION  = @nDenyPermission
	where    GRANTPERMISSION = @nOldGrantPermission   
	and 	 DENYPERMISSION  = @nOldDenyPermission  
	and      OBJECTTABLE     = @psObjectTable
	and 	 OBJECTINTEGERKEY= @pnObjectIntegerKey
	and 	 OBJECTSTRINGKEY = @psObjectStringKey
	and   	 LEVELTABLE	 = @psLevelTable
	and  	 LEVELKEY	 = @pnLevelKey"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@psObjectTable	nvarchar(30),
					  @pnObjectIntegerKey	int,
					  @psObjectStringKey	nvarchar(30),					 
					  @psLevelTable		nvarchar(30),
					  @pnLevelKey		int,
					  @nGrantPermission	tinyint,
					  @nDenyPermission	tinyint,
					  @nOldGrantPermission	tinyint,
					  @nOldDenyPermission	tinyint',
					  @psObjectTable	= @psObjectTable,
					  @pnObjectIntegerKey	= @pnObjectIntegerKey,
					  @psObjectStringKey	= @psObjectStringKey,					 
					  @psLevelTable		= @psLevelTable,
					  @pnLevelKey		= @pnLevelKey,
					  @nGrantPermission	= @nGrantPermission,
					  @nDenyPermission 	= @nDenyPermission,
					  @nOldGrantPermission	= @nOldGrantPermission,
					  @nOldDenyPermission 	= @nOldDenyPermission

End

Return @nErrorCode
GO

Grant execute on dbo.sc_UpdatePermission to public
GO