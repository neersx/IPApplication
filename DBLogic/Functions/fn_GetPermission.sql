-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetPermission 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetPermission ') and xtype='TF')
Begin
	Print '**** Drop Function dbo.fn_GetPermission '
	Drop function [dbo].[fn_GetPermission ]
End
Print '**** Creating Function dbo.fn_GetPermission ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetPermission 
(	
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
RETURNS @tbPermissions TABLE
   (
        GrantPermission	tinyint		NOT NULL,
	DenyPermission	tinyint		NOT NULL
   )
-- Function :	fn_GetPermission 
-- VERSION :	2
-- DESCRIPTION:	This function assembles grand and deny permissions from the supplied 
--		parameters and object's applicable permissions. 	
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Jun 2004	TM	RFC1500	1	Function created
-- 29 Jun 2004	TM	RFC1500	2	Correct the Description.
AS
BEGIN
	Declare @nGrantPermission	tinyint
	Declare @nDenyPermission	tinyint	
	Declare @nApplicablePermission	tinyint	-- is used to extract applicable permissions
	
	
	-- Prepare bitwise flags for permission values. 	
	-- 1) Prepare DenyPermission
	--    Create a single bitwise field from the XxxPermission values = 2.
	
	Set @nDenyPermission =  
	CASE WHEN @pnSelectPermission    = 2 	THEN 1 	ELSE 0 END |
	CASE WHEN @pnMandatoryPermission = 2 	THEN 64	ELSE 0 END |
	CASE WHEN @pnInsertPermission    = 2	THEN 8 	ELSE 0 END |
	CASE WHEN @pnUpdatePermission    = 2	THEN 2	ELSE 0 END |
	CASE WHEN @pnDeletePermission    = 2	THEN 16	ELSE 0 END |
	CASE WHEN @pnExecutePermission   = 2	THEN 32	ELSE 0 END	

	-- If Select is denied, ensure that mandatory is also denied.
	
	Set @nDenyPermission = 	CASE WHEN ((@nDenyPermission&1=1) and (@nDenyPermission&64<>64))
				     THEN (@nDenyPermission | 64)
				     ELSE  @nDenyPermission 
				END 	

	-- Get permissions that are not applicable for this objects.
	
	Select @nApplicablePermission = isnull(PRULE.GRANTPERMISSION, PDFLT.GRANTPERMISSION)
	from PERMISSIONS P	
	left join PERMISSIONS PRULE 	on  (PRULE.OBJECTTABLE = P.OBJECTTABLE
					and (PRULE.OBJECTINTEGERKEY = P.OBJECTINTEGERKEY
					 or  PRULE.OBJECTSTRINGKEY  = P.OBJECTSTRINGKEY)
					and  PRULE.LEVELTABLE is null
					and  PRULE.LEVELKEY is null)
	left join PERMISSIONS PDFLT	on  (PDFLT.OBJECTTABLE = P.OBJECTTABLE
					and  PDFLT.OBJECTINTEGERKEY is null
					and  PDFLT.OBJECTSTRINGKEY is null
					and  PDFLT.LEVELTABLE is null
					and  PDFLT.LEVELKEY is null)
	where P.OBJECTTABLE      = @psObjectTable 
	and  (P.OBJECTINTEGERKEY = @pnObjectIntegerKey or P.OBJECTINTEGERKEY is null)
	and  (P.OBJECTSTRINGKEY  = @psObjectStringKey  or P.OBJECTSTRINGKEY is null)  	

		
	-- Ensure that all bits that are not applicable are set to 0.
		
	Set @nDenyPermission = @nDenyPermission&@nApplicablePermission	
	
	-- 2) Prepare GrantPermission
	
	-- Create a single bitwise field from the XxxPermission values = 0/1.
	-- If Select is denied, ensure that mandatory is also denied.
	
	Set @nGrantPermission = 
	CASE WHEN @pnSelectPermission    = 1 THEN 1 	ELSE 0 END |
	CASE WHEN @pnMandatoryPermission = 1 THEN 64	ELSE 0 END |
	CASE WHEN @pnInsertPermission    = 1 THEN 8  	ELSE 0 END |
	CASE WHEN @pnUpdatePermission    = 1 THEN 2	ELSE 0 END |
	CASE WHEN @pnDeletePermission    = 1 THEN 16 	ELSE 0 END |
	CASE WHEN @pnExecutePermission   = 1 THEN 32 	ELSE 0 END	

	-- If Select is revoked, ensure that Mandatory is also revoked.
	
	Set @nGrantPermission = 	CASE WHEN ((@nGrantPermission&1=0) and (@nGrantPermission&64=64))
					     THEN (@nGrantPermission&(~64))
					     ELSE  @nGrantPermission 
					END 	

	-- Ensure that all bits that are not applicable are set to 0.
	-- This applies for preparation of DenyPermission as well as
	-- Grantpermission. 	
	
	Set @nGrantPermission = @nGrantPermission&@nApplicablePermission	

	-- Insert calculated GrantPermission and DenyPermission into the table variable.
	Insert into @tbPermissions (GrantPermission, DenyPermission)
	values     (@nGrantPermission, @nDenyPermission)
	
	Return
End
GO

Grant REFERENCES, SELECT on dbo.fn_GetPermission  to public
GO
