-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sc_ListUserModules
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sc_ListUserModules]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.sc_ListUserModules.'
	Drop procedure [dbo].[sc_ListUserModules]
End
Print '**** Creating Stored Procedure dbo.sc_ListUserModules...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.sc_ListUserModules
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey 		int		= null,	-- the key of the user who's permissions are required
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	sc_ListUserModules
-- VERSION:	6
-- DESCRIPTION:	Returns the list of web parts that the current user has been granted access to.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Jul 2004	TM	RFC916	1	Procedure created
-- 20 Jul 2004	TM	RFC916	2	Add Description column.
-- 16 Sep 2004	JEK	RFC886	3	Implement translation.
-- 14 Oct 2004	TM	RFC1898	4	Modify calls to the fn_PermissionsGranted to include 'CanSelect = 1' 
--					as a 'join' or 'where' condition. 
-- 15 May 2005	JEK	RFC2508	35	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 13 Jul 2006	SW	RFC3828	6	Pass getdate() to fn_Permission..

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

Declare @sLookupCulture		nvarchar(10)
Declare @dtToday		datetime

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

-- Initialise variables
Set @nErrorCode = 0

-- If the @pnIdentityKey was not supplied then find out tasks 
-- for the current user (@pnUserIdentityId)
Set @pnIdentityKey = ISNULL(@pnIdentityKey, @pnUserIdentityId)

-- Populating Role result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  @pnIdentityKey		as 'IdentityKey',
		M.MODULEID		as 'ModuleKey',
		"+dbo.fn_SqlTranslatedColumn('MODULE','TITLE',null,'M',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ModuleTitle',
		"+dbo.fn_SqlTranslatedColumn('MODULE','DESCRIPTION',null,'M',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Description', 
		P.CanSelect		as 'CanSelect',
		P.IsMandatory		as 'IsMandatory'
	from MODULE M
	join dbo.fn_PermissionsGranted(@pnIdentityKey, 'MODULE', null, null, @dtToday) P
					on (P.ObjectIntegerKey = M.MODULEID
					and P.CanSelect = 1)
	order by ModuleTitle"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @dtToday		datetime',
					  @pnIdentityKey	= @pnIdentityKey,
					  @dtToday		= @dtToday
	Set @pnRowCount = @@ROWCOUNT
End

Return @nErrorCode
GO

Grant execute on dbo.sc_ListUserModules to public
GO
