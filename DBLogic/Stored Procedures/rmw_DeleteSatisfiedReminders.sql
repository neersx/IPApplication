-----------------------------------------------------------------------------------------------------------------------------
-- Creation of rmw_DeleteSatisfiedReminders
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rmw_DeleteSatisfiedReminders]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rmw_DeleteSatisfiedReminders.'
	Drop procedure [dbo].[rmw_DeleteSatisfiedReminders]
End
Print '**** Creating Stored Procedure dbo.rmw_DeleteSatisfiedReminders...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.rmw_DeleteSatisfiedReminders
(
	@pnUserIdentityId		int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey				int	= null,
	@pnNameKey				int = null
)
as
-- PROCEDURE:	rmw_DeleteSatisfiedReminders
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This stored procedure deletes all satisfied reminders that the 
--				current user is permitted to delete. 
--				The logic for defining Satisfied reminders can be found in rem_GetSatisfiedReminders.sql
--

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 07 OCT 2009	SF		RFC5803	1		Procedure created
-- 02 NOV 2009	SF		RFC5803	2		Fix issues

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @nNameKey int
declare @bExternalUser bit
declare @sSatisfiedReminderTable nvarchar(60)

-- Initialise variables
Set @nErrorCode = 0

Set @nNameKey = @pnNameKey

If @nErrorCode = 0
and @pnCaseKey is null
and @pnNameKey is null
Begin

	Set @sSQLString = N'
		Select  @nNameKey = U.NAMENO,
				@bExternalUser = U.ISEXTERNALUSER
		from USERIDENTITY U
		join NAME N on (N.NAMENO = U.NAMENO)
		where IDENTITYID = @pnUserIdentityId'
	
	exec @nErrorCode = sp_executesql @sSQLString,
		N'
		@nNameKey			int output,
		@bExternalUser		bit output,
		@pnUserIdentityId	int',
		@nNameKey			= @nNameKey output,
		@bExternalUser		= @bExternalUser output,
		@pnUserIdentityId	= @pnUserIdentityId
End

If @nErrorCode = 0
Begin

	Set @sSatisfiedReminderTable = N'##DELETESATISFIEDREMINDER_' + Cast(@@SPID as varchar(10))
		
	If @nErrorCode=0
	and exists(select * from tempdb.dbo.sysobjects where name = @sSatisfiedReminderTable)
	Begin
		/***
			This may occur if it wasn't cleaned up properly over the last execution
		*/
		Set @sSQLString = N'drop table ' + @sSatisfiedReminderTable
		exec @nErrorCode = sp_executesql @sSQLString
	End
	If @nErrorCode = 0
	Begin
		Set @sSQLString = N'
			Create table ' + @sSatisfiedReminderTable + N'(
				EMPLOYEENO	int		not null,
				MESSAGESEQ	datetime	not null
			)'
		
		exec @nErrorCode = sp_executesql @sSQLString
	End
	
	/******
		Retrieve satisfied reminders by calling rem_GetSatisfiedReminders
	*/
	If @nErrorCode = 0
	Begin

		exec @nErrorCode = rem_GetSatisfiedReminders
								@pnUserIdentityId = @pnUserIdentityId,
								@pnNameNo = @nNameKey,
								@pnCaseId = @pnCaseKey,
								@pbExternalUser = @bExternalUser,
								@pbCalledFromCentura = @pbCalledFromCentura,
								@psParentProcTableName = @sSatisfiedReminderTable
	End


	/******
		Delete the satisfied EMPLOYEEREMINDERS now.
	*/
	If @nErrorCode = 0
	Begin
		Set @sSQLString = N'
			Delete from EMPLOYEEREMINDER
			from EMPLOYEEREMINDER as ER 
			join ' + @sSatisfiedReminderTable + 
			' R on (ER.MESSAGESEQ = R.MESSAGESEQ and ER.EMPLOYEENO = R.EMPLOYEENO)'
		
		exec @nErrorCode = sp_executesql @sSQLString	
	End
End

/** should clean up always */
If exists(select * from tempdb.dbo.sysobjects where name = @sSatisfiedReminderTable)
Begin
	/***
		Drop the temporary table on completing this procedure
	*/
	Set @sSQLString = N'drop table ' + @sSatisfiedReminderTable
	
	exec @nErrorCode = sp_executesql @sSQLString
End


Return @nErrorCode
GO

Grant execute on dbo.rmw_DeleteSatisfiedReminders to public
GO
