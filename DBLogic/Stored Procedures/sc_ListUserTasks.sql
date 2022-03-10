-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sc_ListUserTasks
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sc_ListUserTasks]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.sc_ListUserTasks.'
	Drop procedure [dbo].[sc_ListUserTasks]
End
Print '**** Creating Stored Procedure dbo.sc_ListUserTasks...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.sc_ListUserTasks
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnIdentityKey 		int		= null,	-- the key of the user who's permissions are required
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	sc_ListUserTasks
-- VERSION:	7
-- DESCRIPTION:	Returns the list of tasks that the current user has been granted access to. 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Jun 2004	TM	RFC1085	1	Procedure created
-- 19 Aug 2004	TM	RFC1500	2	Add the task Description column.
-- 16 Sep 2004	JEK	RFC886	3	Implement translation.
-- 14 Oct 2004	TM	RFC1898	4	Only return those rows where any one of the following is true:
--					CanInsert, CanUpdate, CanDelete, CanExecute
-- 29 Oct 2004	TM	RFC1903	5	Modify translation of the Task.Description as required for a Short Column.
-- 15 May 2005	JEK	RFC2508	6	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 13 Jul 2006	SW	RFC3828	7	Pass getdate() to fn_Permission..

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
		T.TASKID		as 'TaskKey',
		"+dbo.fn_SqlTranslatedColumn('TASK','TASKNAME',null,'T',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'TaskName',
		"+dbo.fn_SqlTranslatedColumn('TASK','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'Description',
		P.CanInsert		as 'CanInsert',
		P.CanUpdate		as 'CanUpdate',
		P.CanDelete		as 'CanDelete',
		P.CanExecute		as 'CanExecute'
	from TASK T
	join dbo.fn_PermissionsGranted(@pnIdentityKey, 'TASK', null, null, @dtToday) P
			on (P.ObjectIntegerKey = T.TASKID
			and (P.CanInsert = 1
			 or  P.CanUpdate = 1
			 or  P.CanDelete = 1
			 or  P.CanExecute = 1))
	order by 3"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @dtToday		datetime',
					  @pnIdentityKey	= @pnIdentityKey,
					  @dtToday		= @dtToday
	Set @pnRowCount = @@ROWCOUNT

End



	


Return @nErrorCode
GO

Grant execute on dbo.sc_ListUserTasks to public
GO
