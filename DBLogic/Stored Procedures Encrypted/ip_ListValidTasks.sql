-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListValidTasks
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListValidTasks]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListValidTasks.'
	Drop procedure [dbo].[ip_ListValidTasks]
End
Print '**** Creating Stored Procedure dbo.ip_ListValidTasks...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_ListValidTasks
(
	@pnUserIdentityId	int,			-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pbIsImpersonated	bit		= 0
)
With encryption
as
-- PROCEDURE:	ip_ListValidTasks
-- VERSION:	4
-- DESCRIPTION:	Returns the list of tasks that the current user has been granted access to. 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Nov 2004	TM	RFC869	1	Procedure created
-- 15 May 2005	JEK	RFC2508	2	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 13 Jul 2006	SW	RFC3828	3	Pass getdate() to fn_Permission..
-- 01 Mar 2007	PG	RFC4788	4	Add @pbIsImpersonated

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
declare @dtToday	datetime

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
set @dtToday = getdate()

-- Initialise variables
Set @nErrorCode = 0

-- Populating Role result set
If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  @pnUserIdentityId	as 'IdentityKey',
		T.TASKID		as 'TaskKey',
		"+dbo.fn_SqlTranslatedColumn('TASK','TASKNAME',null,'T',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'TaskName',
		P.CanInsert		as 'CanInsert',
		P.CanUpdate		as 'CanUpdate',
		P.CanDelete		as 'CanDelete',
		P.CanExecute		as 'CanExecute'
	from TASK T
	join dbo.fn_PermissionsGranted(@pnUserIdentityId, 'TASK', null, null, @dtToday) P
			on (P.ObjectIntegerKey = T.TASKID
			and (P.CanInsert = 1
			 or  P.CanUpdate = 1
			 or  P.CanDelete = 1
			 or  P.CanExecute = 1))"
	
	if @pbIsImpersonated = 1
	Begin
		Set @sSQLString = @sSQLString +" where T.CANIMPERSONATE=1 "
	End

	Set @sSQLString = @sSQLString +" order by TASKNAME"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @dtToday		datetime',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @dtToday		= @dtToday

End



	


Return @nErrorCode
GO

Grant execute on dbo.ip_ListValidTasks to public
GO
