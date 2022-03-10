-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_UpdateEventText
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_UpdateEventText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_UpdateEventText.'
	Drop procedure [dbo].[csw_UpdateEventText]
End
Print '**** Creating Stored Procedure dbo.csw_UpdateEventText...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created. 
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_UpdateEventText
(
	@nRowCount		int		= 0 output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,
	@pnEventKey		int,		
	@pnEventCycle		smallint,
	@pnEventTextType	smallint	= null,
	@ptEventText		nvarchar(max)	= null	
)
as
-- PROCEDURE:	csw_UpdateEventText
-- VERSION:	9
-- DESCRIPTION:	Writes to the input information to the EVENTTEXT table and manages
--		the relationship between CASEEVENT and EVENTTEXT by writing to the
--		CASEEEVENTTEXT table.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Jul 2004	TM	RFC1545	1	Procedure created
-- 19 Jul 2004	TM	RFC1545	2	Correct the Description.
-- 23 Sep 2004	TM	RFC1545	3	Fix the concurrency logic for short @ptOldEventText by using '='
--					instead of the 'like' and casting the @ptOldEventText as nvarchar(254).
-- 17 Jan 2005	TM	RFC2217	4	Convert the @ptEventText to nvarchar(254) to avoide an SQL error on 
--					the singe-byte database.
-- 26 Dec 2013  MS      R29466  5       Update check for old event text to handle long text and set LongFlag as 1 always
-- 02 Mar 2015	MS	R43203	6	Update event text into EVENTTEXT and CASEEVENTTEXT table
-- 01 Apr 2015  SW      R45377  7       Refactored update and delete sql statements to use join instead of subquery
--                                      and used delete from caseventtext instead of eventtext in delete sql statement
-- 29 Sep 2016	MF	69013	8	Need to take into consideration if EventText is being shared with other CASEEVENT rows.
-- 03 Mar 2017  MS      R70715  9       Use Scope_Identity instead of Ident_Current for getting EventText Identity

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(MAX)

-- Initialise variables
Set @nErrorCode = 0


--------------------------------------------------
-- Determine if the EVENTTEXT associated with the
-- current CASEEVENT row has been referenced by 
-- more than one CASEEVENT.
--------------------------------------------------
Set @sSQLString="Select @nRowCount=count(*)
		 from CASEEVENTTEXT CET
		 join EVENTTEXT ET       on (ET.EVENTTEXTID  =CET.EVENTTEXTID)
		 join CASEEVENTTEXT CET1 on (CET1.EVENTTEXTID=CET.EVENTTEXTID)
		 where CET.CASEID  = @pnCaseKey
		 and   CET.EVENTNO = @pnEventKey
		 and   CET.CYCLE   = @pnEventCycle
		 and ( ET.EVENTTEXTTYPEID = @pnEventTextType or (ET.EVENTTEXTTYPEID is null and @pnEventTextType is null))"

exec @nErrorCode=sp_executesql @sSQLString,
	      N'@nRowCount		int		OUTPUT,
	        @pnCaseKey		int,
		@pnEventKey		int,
		@pnEventCycle		smallint,
		@pnEventTextType	smallint',
		@nRowCount		= @nRowCount	OUTPUT,
		@pnCaseKey		= @pnCaseKey,
		@pnEventKey		= @pnEventKey,
		@pnEventCycle		= @pnEventCycle,
		@pnEventTextType	= @pnEventTextType

If  @nRowCount>0
and @nErrorCode=0
Begin
	-----------------------------------------------------
	-- There is already EVENTTEXT linked to the CASEEVENT
	-----------------------------------------------------
	If @ptEventText is not null
	Begin
		If @nRowCount=1
		Begin
			-----------------------------------------------
			-- The text is to be modified.
			-- NOTE: The text may be shared across multiple 
			--       CASEEVENT rows so any change here will
			--	 also be reflected on those CASEEVENTS.
			-----------------------------------------------
			Set @sSQLString = "
				Update ET 
				Set ET.EVENTTEXT = @ptEventText
				from EVENTTEXT ET
				join CASEEVENTTEXT CET on (CET.EVENTTEXTID = ET.EVENTTEXTID) 
				where CET.CASEID  = @pnCaseKey
				and   CET.EVENTNO = @pnEventKey
				and   CET.CYCLE   = @pnEventCycle
				and ( ET.EVENTTEXTTYPEID = @pnEventTextType or (ET.EVENTTEXTTYPEID is null and @pnEventTextType is null))
				and   ET.EVENTTEXT<>@ptEventText"
		End
		Else Begin
			------------------------------------------------
			-- The text is to be modified.
			-- As the text is being referenced by multiple 
			-- CASEEVENTs, only change the text if it has
			-- not already been updated in this transaction.
			------------------------------------------------
			Set @sSQLString = "
				Update ET 
				Set ET.EVENTTEXT = @ptEventText
				from EVENTTEXT ET
				join CASEEVENTTEXT CET on (CET.EVENTTEXTID = ET.EVENTTEXTID) 
				left join master.dbo.sysprocesses P on (P.spid=@@SPID
								    and ET.LOGTRANSACTIONNO=CASE WHEN(substring(P.context_info,5,4) <>0x0000000) THEN cast(substring(P.context_info,5,4)  as int) END
								    and ET.LOGIDENTITYID   =CASE WHEN(substring(P.context_info,1,4) <>0x0000000) THEN cast(substring(P.context_info,1,4)  as int) END)
				where CET.CASEID  = @pnCaseKey
				and   CET.EVENTNO = @pnEventKey
				and   CET.CYCLE   = @pnEventCycle
				and ( ET.EVENTTEXTTYPEID = @pnEventTextType or (ET.EVENTTEXTTYPEID is null and @pnEventTextType is null))
				and   ET.EVENTTEXT<>@ptEventText
				and    P.spid is null	-- indicating that the LogTransactionNo and LogIdentityId does not match the current transaction so the row CAN BE changed."
		End
		
		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@pnCaseKey			int,
				@pnEventKey			int,
				@pnEventCycle			smallint,
				@ptEventText			nvarchar(max),
				@pnEventTextType		smallint',
				@pnCaseKey			= @pnCaseKey,
				@pnEventKey			= @pnEventKey,
				@pnEventCycle			= @pnEventCycle,
				@ptEventText			= @ptEventText,
				@pnEventTextType		= @pnEventTextType

		Set @nRowCount = @@RowCount
	End
	
	
	--------------------------------------------------
	-- @ptEventText is NULL which might indicate that
	-- the text is to be cleared out.
	--------------------------------------------------
	Else If @nRowCount=1
	Begin
		--------------------------------------------------
		-- Only one CASEEVENT is pointing to the EVENTTEXT
		-- so it can be deleted because there is no text
		-- supplied.
		--------------------------------------------------
		Set @sSQLString = "
			DELETE CET 
			FROM CASEEVENTTEXT CET
			join EVENTTEXT ET on (CET.EVENTTEXTID = ET.EVENTTEXTID) 
			where CET.CASEID  = @pnCaseKey
			and   CET.EVENTNO = @pnEventKey
			and   CET.CYCLE   = @pnEventCycle
			and ( ET.EVENTTEXTTYPEID = @pnEventTextType or (ET.EVENTTEXTTYPEID is null and @pnEventTextType is null))"

		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@pnCaseKey			int,
				@pnEventKey			int,
				@pnEventCycle			smallint,
				@pnEventTextType		smallint',
				@pnCaseKey			= @pnCaseKey,
				@pnEventKey			= @pnEventKey,
				@pnEventCycle			= @pnEventCycle,
				@pnEventTextType		= @pnEventTextType

		Set @nRowCount = @@RowCount
	End
	
	Else If @nRowCount>1
	Begin
		----------------------------------------------------
		-- Multiple CASEEVENTs are pointing to the EVENTTEXT
		-- so we can only delete the CASEEVENTTEXT if we 
		-- know that the CASEEVENTTEXT was not just inserted
		-- in the current transaciton for this SPID.
		----------------------------------------------------
		Set @sSQLString = "
			DELETE CET 
			FROM CASEEVENTTEXT CET
			join EVENTTEXT ET on (CET.EVENTTEXTID = ET.EVENTTEXTID)
			left join master.dbo.sysprocesses P on (P.spid=@@SPID
							    and CET.LOGTRANSACTIONNO=CASE WHEN(substring(P.context_info,5,4) <>0x0000000) THEN cast(substring(P.context_info,5,4)  as int) END
							   and  CET.LOGIDENTITYID   =CASE WHEN(substring(P.context_info,1,4) <>0x0000000) THEN cast(substring(P.context_info,1,4)  as int) END)
			where CET.CASEID  = @pnCaseKey
			and   CET.EVENTNO = @pnEventKey
			and   CET.CYCLE   = @pnEventCycle
			and ( ET.EVENTTEXTTYPEID = @pnEventTextType or (ET.EVENTTEXTTYPEID is null and @pnEventTextType is null))
			and     P.spid is null	-- indicating that the LogTransactionNo and LogIdentityId does not match the current transaction so the row CAN BE deleted."

		exec @nErrorCode=sp_executesql @sSQLString,
			      N'@pnCaseKey			int,
				@pnEventKey			int,
				@pnEventCycle			smallint,
				@pnEventTextType		smallint',
				@pnCaseKey			= @pnCaseKey,
				@pnEventKey			= @pnEventKey,
				@pnEventCycle			= @pnEventCycle,
				@pnEventTextType		= @pnEventTextType

		Set @nRowCount = @@RowCount
	End
End
Else If @ptEventText is not null
     and @nErrorCode=0
Begin
	------------------------------------------------------
	-- If the CaseEvent is not currently associated with 
	-- some EventText and the user has entered some text
	-- then it is to be inserted into the EVENTTEXT table
	-- and then linked to the CASEEVENT via CASEEVENTTEXT.
	------------------------------------------------------
	Declare @nIdentEventText int

	Set @sSQLString = "INSERT INTO EVENTTEXT (EVENTTEXT, EVENTTEXTTYPEID)
			Select @ptEventText, @pnEventTextType"

        Set @sSQLString = @sSQLString + CHAR(10)
			+ "Set @nIdentEventText = SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@nIdentEventText              int     output,
                        @ptEventText			nvarchar(max),
			@pnEventTextType		smallint',
                        @nIdentEventText                = @nIdentEventText      output,
			@ptEventText			= @ptEventText,
			@pnEventTextType		= @pnEventTextType

	If @nErrorCode = 0
	Begin
		--------------------------------------------------
		-- Now link the just inserted EVENTTEXT row to the
		-- the CASEEVENT.
		-- Note that if the text is to be shared with
		-- other CASEEVENT rows then this will be done via
		-- the insert trigger on CASEEVENTTEXT.
		--------------------------------------------------
		Set @sSQLString = "INSERT INTO CASEEVENTTEXT(CASEID, EVENTNO, CYCLE, EVENTTEXTID)
				SELECT  @pnCaseKey, @pnEventKey, @pnEventCycle, @nIdentEventText"
				
		exec @nErrorCode=sp_executesql @sSQLString,
		      N'@pnCaseKey			int,
			@pnEventKey			int,
			@pnEventCycle			smallint,
			@nIdentEventText		int',
			@pnCaseKey			= @pnCaseKey,
			@pnEventKey			= @pnEventKey,
			@pnEventCycle			= @pnEventCycle,
			@nIdentEventText		= @nIdentEventText
	End
	
	Set @nRowCount = @@RowCount			
End

Return @nErrorCode
GO

Grant execute on dbo.csw_UpdateEventText to public
GO