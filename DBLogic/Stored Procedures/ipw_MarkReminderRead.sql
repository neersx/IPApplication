-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_MarkReminderRead ]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_MarkReminderRead .'
	Drop procedure [dbo].[ipw_MarkReminderRead ]
End
Print '**** Creating Stored Procedure dbo.ipw_MarkReminderRead ...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_MarkReminderRead 
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnEmployeeKey		int,
	@pdtReminderDateCreated	datetime,
	@pdtLogDateTimeStamp	datetime output,
	@pbIsRead 		bit		
)
-- PROCEDURE:	ipw_MarkReminderRead 
-- VERSION:	5
-- SCOPE:	WorkBench
-- DESCRIPTION:	Update the reminder row with the provided @pbIsRead flag if the CheckSum matches.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21 Jan 2005  TM	RFC1319	1	Procedure created. 
-- 22 Feb 2005	TM	RFC1319	2	Increase the size of the @sSQLString to nvarchar(4000)
-- 02 Mar 2005	TM	RFC2409	3	Set NOCOUNT OFF.
-- 24 Sep 2009	SF	RFC5803 4	Return checksum as part of update
-- 11 Feb 2010	SF	RFC9284	5	Return LogDateTimeStamp rather than checksum
as

-- Row counts required by the data adapter
SET NOCOUNT OFF
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode 			int
Declare @sSQLString  			nvarchar(4000)
Declare @dtLogDateTimeStampValue	datetime

Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = '
	Update EMPLOYEEREMINDER 
	set    READFLAG 	= @pbIsRead
	where  EMPLOYEENO 	= @pnEmployeeKey
	and    MESSAGESEQ 	= @pdtReminderDateCreated
	and    LOGDATETIMESTAMP = @pdtLogDateTimeStamp'

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnEmployeeKey	  int,
				  @pdtReminderDateCreated datetime,
				  @pdtLogDateTimeStamp	  datetime,
				  @pbIsRead		  bit',
				  @pnEmployeeKey	  = @pnEmployeeKey,
				  @pdtReminderDateCreated = @pdtReminderDateCreated,
				  @pdtLogDateTimeStamp	  = @pdtLogDateTimeStamp,
				  @pbIsRead		  = @pbIsRead
				  
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

Grant execute on dbo.ipw_MarkReminderRead  to public
GO

