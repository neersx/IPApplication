-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_CascadeGroupUpdate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_CascadeGroupUpdate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_CascadeGroupUpdate.'
	Drop procedure [dbo].[naw_CascadeGroupUpdate]
End
Print '**** Creating Stored Procedure dbo.naw_CascadeGroupUpdate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_CascadeGroupUpdate
(
	@pnRowCount		int		= null	OUTPUT,
	@pnUserIdentityId	int,		-- Mandatory
	@pnNameKey		int,		-- Mandatory. The key of the name at the root of the tree to be processed.
	@pnGroupKey		smallint	-- Mandatory. The key of the new group to be applied. Maybe null.

)
as
-- PROCEDURE:	naw_CascadeGroupUpdate
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Propagate change of group down a tree

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 31 May 2006	SW	RFC3880	1	Procedure created
-- 16 Jun 2006	SW	RFC3880	2	Bug fix that not to update the root but only children

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @nMoreChildren	int
Declare @sSQLString	nvarchar(4000)

-- temporary table to store all children of @pnNameKey
Create table #CHILDREN (
	NAMENO		int,
	STATUS		int	-- 0 - just inserted to table
				-- 1 - ready to check for children
				-- 2 - already checked for children, so will not check again
)

-- Initialise variables
Set @nErrorCode		= 0
Set @nMoreChildren	= 1 -- enter initial while loop

-- insert @pnNameKey into #CHILDREN as the first key to look for children
Set @sSQLString = '
	Insert	#CHILDREN (NAMENO, STATUS)
	values	(@pnNameKey, 0)'

Exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnNameKey		int',
		  @pnNameKey		= @pnNameKey

-- Find out all the children from #CHILDREN and put in #CHILDREN
While (@nMoreChildren > 0 and @nErrorCode = 0)
Begin

	-- move up the status after each execution
	Set @sSQLString = '
		Update	#CHILDREN
		set	STATUS = STATUS + 1
		where	STATUS < 2'

	Exec @nErrorCode = sp_executesql @sSQLString

	If @nErrorCode = 0
	Begin
		Set @sSQLString = '
			Insert	#CHILDREN (NAMENO, STATUS) 
			select	O.NAMENO, 0
			from	ORGANISATION O
			join	#CHILDREN C on (C.NAMENO = O.PARENT
						and C.STATUS = 1)
			where	O.NAMENO not in(
				Select	NAMENO
				from	#CHILDREN)'
		
		Exec @nErrorCode = sp_executesql @sSQLString
	
		Set @nMoreChildren = @@ROWCOUNT
	End
End 

If @nErrorCode = 0
Begin
	-- Apply changes to all the children but root key
	Set @sSQLString = '
		Update	[NAME]
		set	FAMILYNO = @pnGroupKey
		from	[NAME] N
		join	#CHILDREN C on (C.NAMENO = N.NAMENO and C.NAMENO <> @pnNameKey)'
	
	Exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnGroupKey		int,
		  @pnNameKey		int',
		  @pnGroupKey		= @pnGroupKey,
		  @pnNameKey		= @pnNameKey

	-- Only set rowcount if @nErrorCode = 0
	Set @pnRowCount = CASE	WHEN @nErrorCode = 0
				THEN @@ROWCOUNT
                          END
End

-- clean up
Drop table #CHILDREN

Return @nErrorCode
GO

Grant execute on dbo.naw_CascadeGroupUpdate to public
GO
