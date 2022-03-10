-----------------------------------------------------------------------------------------------------------------------------
-- Creation of rmw_ListReminderComments
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rmw_ListReminderComments]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rmw_ListReminderComments.'
	Drop procedure [dbo].[rmw_ListReminderComments]
End
Print '**** Creating Stored Procedure dbo.rmw_ListReminderComments...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.rmw_ListReminderComments
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnReminderForKey		int,
	@pdtReminderDateCreated datetime,
	@pnCaseKey				int	= null,
	@psReference			nvarchar(20) = null,
	@pnEventKey				int = null,
	@pnCycle				smallint = null,
	@psShortMessage			nvarchar(256) = null
)
as
-- PROCEDURE:	rmw_ListReminderComments
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This stored procedure list comments for Reminders application in the WorkBenches.
--

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	--------------------------------------- 
-- 09 FEB 2009	SF	RFC5803	1	Procedure created
-- 24 SEP 2009	SF	RFC5803 2	Continuation
-- 11 Feb 2010	SF	RFC9284	3	Return LogDateTimeStamp rather than checksum
-- 02 Nov 2015	vql	R53910	4	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @sLookupCulture nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 	ER.MESSAGESEQ as DateCreated,
			ER.EMPLOYEENO as StaffNameKey,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as StaffDisplayName,
			N.NAMECODE as StaffNameCode,
		"+dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','COMMENTS',null,'ER',@sLookupCulture,@pbCalledFromCentura)
				+ " as Comments,
			cast(case when @pnReminderForKey = ER.EMPLOYEENO then 1 else 0 end as bit) as IsRecipientComment,
			ER.LOGDATETIMESTAMP as LogDateTimeStamp 
	from	EMPLOYEEREMINDER ER  
	join	NAME N on (N.NAMENO = ER.EMPLOYEENO)  
	where	ER.COMMENTS IS NOT NULL"+char(10)+
	case when @pnCaseKey is not null then
			"and	ER.CASEID = @pnCaseKey" 
			else 
			"and	ER.REFERENCE = @psReference"
		end +char(10)+
	case when @pnEventKey is null and @pnCycle is null then 
			"and	ER.SHORTMESSAGE = @psShortMessage"
			else 
			"and	ER.EVENTNO = @pnEventKey  
			 and	ER.CYCLENO = @pnCycle" 
			end+char(10)+
	"union
	 Select 	ER.MESSAGESEQ as DateCreated,
			ER.EMPLOYEENO as StaffNameKey,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as StaffDisplayName,
			N.NAMECODE as StaffNameCode,
		"+dbo.fn_SqlTranslatedColumn('EMPLOYEEREMINDER','COMMENTS',null,'ER',@sLookupCulture,@pbCalledFromCentura)
				+ " as Comments,
			cast(case when @pnReminderForKey = ER.EMPLOYEENO then 1 else 0 end as bit) as IsRecipientComment,
			ER.LOGDATETIMESTAMP as LogDateTimeStamp
	from	EMPLOYEEREMINDER ER  
	join	NAME N on (N.NAMENO = ER.EMPLOYEENO)  
	where	ER.MESSAGESEQ = @pdtReminderDateCreated
	and		ER.EMPLOYEENO = @pnReminderForKey
	order by 2"

	exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnReminderForKey int,
				@pdtReminderDateCreated datetime,
				@pnCaseKey	int,
				@psReference nvarchar(20),
				@pnEventKey int,
				@pnCycle	smallint,
				@psShortMessage nvarchar(256)',
			@pnReminderForKey = @pnReminderForKey,
			@pdtReminderDateCreated = @pdtReminderDateCreated,
			@pnCaseKey		= @pnCaseKey,
			@psReference	= @psReference,
			@pnEventKey		= @pnEventKey,
			@pnCycle		= @pnCycle,
			@psShortMessage = @psShortMessage
End

Return @nErrorCode
GO

Grant execute on dbo.rmw_ListReminderComments to public
GO
