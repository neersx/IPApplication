-----------------------------------------------------------------------------------------------------------------------------
-- Creation of rmw_GetCaseEventNotes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[rmw_GetCaseEventNotes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.rmw_GetCaseEventNotes.'
	Drop procedure [dbo].[rmw_GetCaseEventNotes]
End
Print '**** Creating Stored Procedure dbo.rmw_GetCaseEventNotes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.rmw_GetCaseEventNotes
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit				= 0,
	@pnCaseKey				int		= null,
	@pnEventKey				int		= null,
	@pnCycle				smallint	= null
)
as
-- PROCEDURE:	rmw_GetCaseEventNotes
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This stored procedure retrieves event notes for Reminders application in the WorkBenches.
--

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 AUG 2009	SF	RFC5803	1	Procedure created
-- 02 MAR 2015	MS	R43203	2	Get event text from EVENTEXT table
-- 27 Oct 2016	MF	64289	3	Return Event Text of the default EventNoteType preference of the user, 
--					however if that does not exist then return the most recently modified text.
-- 28 Nov 2017	MF	72968	4	Revisit of 64289.  Event Notes with no Event Note Type will be returned in preference.  If none exists then the user's preference will be shown or finally the most recently modified text.
-- 04 Jan 2018	MF	73214	5	Revisit 72968. We were previously returning Event Notes that were shared between Events, even though there was not a physical connection between the Event and the Note (no CASEEVENTTEXT row). This could
--					occur if the rules around how Events sharing have changed after notes had been entered.  This solution however only works well when looking at the details of a single Case, whereas a list of Cases such
--					as returned by the Due Date List (ipw_ListDueDate) would result in an unacceptable performance overhead. To ensure consistency of behaviour only notes directly linked to a CASEEVENT will be shown here.
-- 04 Jan 2018	MF	73220	6	Event Notes not being returned when the EVENTTEXT row is missing a LOGDATETIMESTAMP value. Resolved by defaulting to 1900-01-01.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @sSQLString		nvarchar(max)
declare @sLookupCulture		nvarchar(10)
declare	@nDefaultEventNoteType	int

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture        = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nDefaultEventNoteType = dbo.fn_GetDefaultEventNoteType(@pnUserIdentityId)

If @nErrorCode = 0
Begin

	Set @sSQLString = "
	With	CTE_EventText (EVENTNO, CYCLE, EVENTTEXTID, LASTENTERED, DEFAULTTEXTTYPE)
			as (	select  CT.EVENTNO, CT.CYCLE, ET.EVENTTEXTID, isnull(ET.LOGDATETIMESTAMP,'1900-01-01'),
					CASE WHEN(ET.EVENTTEXTTYPEID is null)
						THEN '2'
						WHEN(ET.EVENTTEXTTYPEID=@nDefaultEventNoteType)
						THEN '1'
						ELSE '0'
					END
				from CASEEVENTTEXT CT
				join EVENTTEXT ET on (ET.EVENTTEXTID=CT.EVENTTEXTID)
				Where CT.CASEID=@pnCaseKey
			)
	SELECT 
	C.CASEID as CaseKey,
	C.EVENTNO as EventKey,
	C.CYCLE as Cycle,
	"+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ET',@sLookupCulture,@pbCalledFromCentura)+"				
												as EventText
	FROM CASEEVENT C
	join EVENTS E on (E.EVENTNO=C.EVENTNO)

	-------------------------------------------
	-- The Event Note to return is based on the
	-- following hierarchy:
	-- 1 - No TextType
	-- 2 - Users default Text Type
	-- 3 - Most recently modified text
	-------------------------------------------
	left join CTE_EventText CTE	on (CTE.EVENTNO  =C.EVENTNO
					and CTE.CYCLE    =C.CYCLE
					and CTE.EVENTTEXTID = Cast
							(substring
							((select max(CTE1.DEFAULTTEXTTYPE + convert(nchar(23),CTE1.LASTENTERED,121) + convert(nchar(11),CTE1.EVENTTEXTID))
							from CTE_EventText CTE1
							where CTE1.EVENTNO  =CTE.EVENTNO
							and   CTE1.CYCLE    =CTE.CYCLE ),25,11) as int)
						)
	left join EVENTTEXT ET		on (ET.EVENTTEXTID = CTE.EVENTTEXTID)
	WHERE	C.CASEID  = @pnCaseKey 
	AND	C.CYCLE   = @pnCycle 
	AND	C.EVENTNO = @pnEventKey"

	exec @nErrorCode=sp_executesql @sSQLString,
		   N'	@pnCaseKey		int,
			@pnEventKey		int,
			@pnCycle		smallint,
			@nDefaultEventNoteType	int',
			@pnCaseKey		= @pnCaseKey,
			@pnEventKey		= @pnEventKey,
			@pnCycle		= @pnCycle,
			@nDefaultEventNoteType	= @nDefaultEventNoteType
End

Return @nErrorCode
GO

Grant execute on dbo.rmw_GetCaseEventNotes to public
GO
