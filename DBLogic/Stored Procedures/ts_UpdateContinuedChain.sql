-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_UpdateContinuedChain]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_UpdateContinuedChain.'
	Drop procedure [dbo].[ts_UpdateContinuedChain]
End
Print '**** Creating Stored Procedure dbo.ts_UpdateContinuedChain...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.ts_UpdateContinuedChain
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnStaffKey		int,		-- Mandatory. @pnStaffKey and @pnStartEntryNo identify the starting point in the chain.	
	@pnStartEntryNo		int,		-- Mandatory.
	@pnNameKey		int		= null,
	@pnCaseKey		int		= null,
	@psActivityKey		nvarchar(6)	= null,
	@pnNarrativeKey		smallint	= null,
	@ptNarrative		ntext		= null,
	@pnProductKey		int		= null,
	@pdtEntryDate		datetime	= null

)
-- PROCEDURE:	ts_UpdateContinuedChain
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION: This procedure ensures that all the rows in a continued chain contain the same 
--		basic details; e.g. case and activity.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 21 Jun 2005  TM	RFC1100	1	Procedure created. 
-- 30 Oct 2006	LP	RFC4592	2	Add new @pdtEntryDate parameter.
--					Update Date portion of StartDateTime and FinishDateTime

AS

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON


Declare @nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @bLongFlag	bit
Declare @nEntryNo	int

-- Initialise variables
Set @nErrorCode 	= 0

-- Is the Narrative long text?
If (datalength(@ptNarrative) <= 508)
or datalength(@ptNarrative) is null
Begin
	Set @bLongFlag = 0
End
Else
Begin
	Set @bLongFlag = 1
End

-- Repeat Update Data step with @pnStartEntryNo set to Diary.ParentEntryNo until there are no more parent rows.
While @pnStartEntryNo is not null
and   @nErrorCode = 0
Begin
	
	-- Only perform processing if the data in the chain differs from that supplied.
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "	
		Update  DIARY 
		Set	ACTIVITY	= @psActivityKey,
			CASEID		= @pnCaseKey,
			NAMENO		= CASE WHEN @pnCaseKey is null THEN @pnNameKey ELSE NULL END,
			NARRATIVENO	= @pnNarrativeKey,
			SHORTNARRATIVE	= CASE WHEN @bLongFlag = 1 THEN NULL ELSE CAST(@ptNarrative as nvarchar(254)) END,
			LONGNARRATIVE	= CASE WHEN @bLongFlag = 1 THEN @ptNarrative ELSE NULL END,
			PRODUCTCODE	= @pnProductKey"+char(10)
		
		If (@pdtEntryDate is not null)
		Begin
		Set @sSQLString = @sSQLString + ",
			STARTTIME	= DATEADD(day, DATEDIFF(day,STARTTIME,@pdtEntryDate), STARTTIME),
			FINISHTIME	= DATEADD(day, DATEDIFF(day,FINISHTIME,@pdtEntryDate), FINISHTIME)"
		End
		
		Set @sSQLString = @sSQLString + "
		where   EMPLOYEENO	= @pnStaffKey
		and     ENTRYNO		= @pnStartEntryNo"		
	
		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnStaffKey		int,
						  @pnStartEntryNo	int,
						  @psActivityKey	nvarchar(6),
						  @pnCaseKey		int,
						  @pnNameKey		int,
						  @bLongFlag		bit,
						  @pnNarrativeKey	smallint,
						  @ptNarrative		ntext,
						  @pnProductKey		int,
						  @pdtEntryDate		datetime',					  
						  @pnStaffKey		= @pnStaffKey,
						  @pnStartEntryNo	= @pnStartEntryNo,
						  @psActivityKey	= @psActivityKey,
						  @pnCaseKey		= @pnCaseKey,
						  @pnNameKey		= @pnNameKey,
						  @bLongFlag		= @bLongFlag,
						  @pnNarrativeKey	= @pnNarrativeKey,
						  @ptNarrative		= @ptNarrative,
						  @pnProductKey		= @pnProductKey,				 
						  @pdtEntryDate		= @pdtEntryDate
	End

	-- Get the next entry of the chain if there are any:
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @pnStartEntryNo = PARENTENTRYNO
		from   DIARY
		where  EMPLOYEENO	= @pnStaffKey
		and    ENTRYNO		= @pnStartEntryNo"

		exec @nErrorCode=sp_executesql @sSQLString,
						N'@pnStartEntryNo	int			output,
						  @pnStaffKey		int',
						  @pnStartEntryNo	= @pnStartEntryNo	output,
						  @pnStaffKey		= @pnStaffKey
	End
End


Return @nErrorCode
GO

Grant execute on dbo.ts_UpdateContinuedChain to public
GO

