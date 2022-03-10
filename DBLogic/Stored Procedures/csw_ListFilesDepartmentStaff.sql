-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListFilesDepartmentStaff
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListFilesDepartmentStaff]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListFilesDepartmentStaff.'
	Drop procedure [dbo].[csw_ListFilesDepartmentStaff]
End
Print '**** Creating Stored Procedure dbo.csw_ListFilesDepartmentStaff...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListFilesDepartmentStaff
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	csw_ListFilesDepartmentStaff
-- VERSION:	2
-- DESCRIPTION:	Returns the employees who have been assigned rights to Files Department Staff task.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Nov 2011	MS	R11208	1	Procedure created
-- 10 Nov 2015	KR	R53910	2	Adjust formatted names logic (DR-15543) 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString             nvarchar(4000)
		
-- Initialise variables
Set @nErrorCode                 = 0

If   @nErrorCode=0
Begin
        Set @sSQLString = "Select distinct 
                U.NAMENO                as NameKey,
                N.NAMECODE              as NameCode,
                dbo.fn_FormatNameUsingNameNo(N.NAMENO, N.NAMESTYLE) 
	                                as Name 
                from USERIDENTITY U
                join fn_PermissionsGrantedAll('TASK',193, null, GETDATE()) as P on (P.IdentityKey = U.IDENTITYID)
                join NAME N on (N.NAMENO = U.NAMENO)
                order by Name"
        
        exec @nErrorCode = sp_ExecuteSql @sSQLString
        
End
Return @nErrorCode
GO

Grant execute on dbo.csw_ListFilesDepartmentStaff to public
GO
