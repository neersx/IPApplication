---------------------------------------------------------------------------------------------
-- Creation of dbo.qr_ListQueryGroups
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_ListQueryGroups]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_ListQueryGroups.'
	drop procedure [dbo].[qr_ListQueryGroups]
	Print '**** Creating Stored Procedure dbo.qr_ListQueryGroups...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.qr_ListQueryGroups
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnContextKey	int	= null
)
AS
-- PROCEDURE:	qr_ListQueryGroups
-- VERSION:	4
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of Query Groups.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 20 Apr 2004  TM	RFC919	1	Procedure created
-- 15 Sep 2004	JEK	RFC886	2	Implement translation.
-- 15 May 2005	JEK	RFC2508	3	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 16 Feb 2010	PA	RFC100149 4	@pnContextKey input parameter is added to filter the QUERYGROUP by CONTEXTID

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	G.CONTEXTID 	as 'ContextKey',
		G.GROUPID		as 'GroupKey',
		"+dbo.fn_SqlTranslatedColumn('QUERYGROUP','GROUPNAME',null,'G',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'GroupName' 
	from QUERYGROUP G
	Where G.CONTEXTID = @pnContextKey
	order by G.CONTEXTID, G.DISPLAYSEQUENCE" 
	
	exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnContextKey int',
						@pnContextKey = @pnContextKey
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant exec on dbo.qr_ListQueryGroups to public
GO
