-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rmw_MaintainComments ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rmw_MaintainComments .'
	Drop procedure [dbo].[rmw_MaintainComments ]
End
Print '**** Creating Stored Procedure dbo.rmw_MaintainComments ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.rmw_MaintainComments 
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnEmployeeKey		int,
	@pdtReminderDateCreated	datetime,
	@pdtLogDateTimeStamp	datetime output,
	@psComments 		nvarchar(max) = null
)
-- PROCEDURE:	rmw_MaintainComments 
-- VERSION:	2
-- SCOPE:	WorkBench
-- DESCRIPTION:	Add a comment to the reminder

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 24 Sep 2009	SF	RFC5803 1	Procedure created
-- 02 Sep 2016	MF	36786	36	Expand EMPLOYEEREMINDER.COMMENTS to nvarchar(max).

as

-- Row counts required by the data adapter
SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode 				int
Declare @sSQLString  				nvarchar(4000)
Declare @dtLogDateTimeStampValue	datetime

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = '
	Update EMPLOYEEREMINDER 
	set    COMMENTS	= @psComments
	where  EMPLOYEENO 	= @pnEmployeeKey
	and    MESSAGESEQ 	= @pdtReminderDateCreated
	and    LOGDATETIMESTAMP = @pdtLogDateTimeStamp'

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnEmployeeKey	  int,
				  @pdtReminderDateCreated datetime,
				  @pdtLogDateTimeStamp	  datetime,
				  @psComments		  nvarchar(max)',
				  @pnEmployeeKey	  = @pnEmployeeKey,
				  @pdtReminderDateCreated = @pdtReminderDateCreated,
				  @pdtLogDateTimeStamp	  = @pdtLogDateTimeStamp,
				  @psComments		  = @psComments
				  
	If @nErrorCode = 0
	and @@ROWCOUNT > 0
	Begin
		Set @sSQLString = '
			Select	@dtLogDateTimeStampValue = LOGDATETIMESTAMP 
			from	EMPLOYEEREMINDER
			where	EMPLOYEENO 	= @pnEmployeeKey
			and		MESSAGESEQ 	= @pdtReminderDateCreated
			'
		exec @nErrorCode = sp_executesql @sSQLString,
				N'@dtLogDateTimeStampValue datetime output,
				  @pnEmployeeKey	  int,
				  @pdtReminderDateCreated datetime',
				  @dtLogDateTimeStampValue = @dtLogDateTimeStampValue output,
				  @pnEmployeeKey	  = @pnEmployeeKey,
				  @pdtReminderDateCreated = @pdtReminderDateCreated
	End			  

	If @nErrorCode = 0
	and @dtLogDateTimeStampValue is not null
	Begin
		Select @pdtLogDateTimeStamp = @dtLogDateTimeStampValue
	End
End

Return @nErrorCode
GO

Grant execute on dbo.rmw_MaintainComments  to public
GO

