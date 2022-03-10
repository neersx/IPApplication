-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchCaseEvent									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchCaseEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchCaseEvent.'
	Drop procedure [dbo].[csw_FetchCaseEvent]
End
Print '**** Creating Stored Procedure dbo.csw_FetchCaseEvent...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_FetchCaseEvent
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int,		-- Mandatory
	@pbNewRow		bit		= 0,
	@pnEventKey		int		= null,
	@pnCycleKey		smallint	= 1,
	@psActionKey		nvarchar(2)	= null
)
as
-- PROCEDURE:	csw_FetchCaseEvent
-- VERSION:	13
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the CaseEvent business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 10 May 2006	AU	RFC3866	1	Procedure created
-- 02 Sep 2009	KR	RFC6950 2	Modified to enable new event creation
-- 08 Sep 2009	KR	RFC6950	3	Added Responsible Name Type and Responsible Name to the select list
-- 21 Sep 2009  LP      RFC8047 4       Pass ProfileKey parameter to fn_GetCriteriaNo
-- 05 Sep 2011	LP	R11257	5	Return IsCyclic flag
-- 24 Oct 2011	ASH	R11460  6	Cast integer columns as nvarchar(11) data type.
-- 19 May 2014  MS      R34423  7       Added LastModifiedDate in resultset
-- 23 Dec 2014	MF	R41842	8	Cater for the possibility of an Event not being configured for the CREATEDBYCRITERIA. This means
--					there would be no EVENTCONTROL row found for the criteria, so fall back to the EVENTS table row.
-- 02 Mar 2015	MS	R43203	9	Return Event Text from EVENTTEXT table
-- 04 Nov 2015	KR	R53910	10	Adjust formatted names logic (DR-15543)
-- 26 Oct 2016	LP	R69658	11	Use DISTINCT keyword to prevent duplicate rows from being returned when there are multiple shared notes.
-- 27 Oct 2016	MF	64289	12	Return Event Text of the default EventNoteType preference of the user, however if that does not exist then return the most recently modified text.
-- 28 Nov 2017	MF	72968	13	Revisit of 64289.  Event Notes with no Event Note Type will be returned in preference.  If none exists then the user's preference will be shown or finally the most recently modified text.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)
Declare @nProfileKey		int
Declare	@nDefaultEventNoteType	int

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture        = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nDefaultEventNoteType = dbo.fn_GetDefaultEventNoteType(@pnUserIdentityId)

If @nErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId
        
        Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	if @pbNewRow = 0
		Begin
			Set @sSQLString = "
			With	CTE_EventText (NOTEGROUP, CYCLE, EVENTTEXTID, LASTENTERED, DEFAULTTEXTTYPE)
					as (	select distinct E.NOTEGROUP, CT.CYCLE, ET.EVENTTEXTID, ET.LOGDATETIMESTAMP,
								CASE WHEN(ET.EVENTTEXTTYPEID is null)
									THEN '2'
								     WHEN(ET.EVENTTEXTTYPEID=@nDefaultEventNoteType)
									THEN '1'
									ELSE '0'
								END
						from CASEEVENTTEXT CT
						join EVENTS E     on (E.EVENTNO=CT.EVENTNO)
						join EVENTTEXT ET on (ET.EVENTTEXTID=CT.EVENTTEXTID)
						Where CT.CASEID=@pnCaseKey
						and E.NOTEGROUP is not null
					),			
				CTE_TextCount (EVENTTEXTID, TEXTCOUNT)
					as (	select ET.EVENTTEXTID, count(*)
						from CTE_EventText ET
						join CASEEVENTTEXT CT on (CT.EVENTTEXTID=ET.EVENTTEXTID)
						group by ET.EVENTTEXTID
					)
			Select
			DISTINCT
			CAST(C.CASEID as nvarchar(11))+'^'+CAST(C.EVENTNO as nvarchar(11))+'^'+CAST(C.CYCLE as nvarchar(10))
						as RowKey,
			C.CASEID		as CaseKey,
			C.EVENTNO		as EventKey,
			C.CYCLE			as EventCycle,
			COALESCE(	"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+",
					"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+")
						as EventDescription,
			C.EVENTDATE		as EventDate,
			C.EVENTDUEDATE		as EventDueDate,
			"+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ET',@sLookupCulture,@pbCalledFromCentura)+"				
						as EventText,
			C.CREATEDBYACTION	as CreatedByActionCode,
			A.ACTIONNAME as CreatedByAction,
			C.CREATEDBYCRITERIA	as CreatedByCriteriaKey,
			C.DATEREMIND		as NextPoliceDate,
			C.FROMCASEID		as FromCaseKey,
			CS.IRN			as FromCase,
			C.DUEDATERESPNAMETYPE	as ResponsibleNameTypeKey,
			NTR.DESCRIPTION		as ResponsibleNameType,
			C.EMPLOYEENO		as ResponsibleNameKey, 
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
						as ResponsibleName,
			CASE WHEN COALESCE(EC.NUMCYCLESALLOWED,E.NUMCYCLESALLOWED,0) = 1 THEN cast(0 as bit) ELSE cast(1 as bit) END as IsCyclic,
			C.LOGDATETIMESTAMP	as LastModifiedDate	
			from CASEEVENT C
			left join EVENTCONTROL EC on (EC.EVENTNO = C.EVENTNO and EC.CRITERIANO = C.CREATEDBYCRITERIA)
			left join EVENTS E	  on (E.EVENTNO = C.EVENTNO)
			left join NAMETYPE NTR	  on (NTR.NAMETYPE = C.DUEDATERESPNAMETYPE)
			left join NAME N	  on (N.NAMENO = C.EMPLOYEENO)
			left join ACTIONS A	  on (A.ACTION = C.CREATEDBYACTION)
			left join CASES CS	  on (CS.CASEID = C.FROMCASEID)
			-------------------------------------------
			-- Check if Event Notes are shared between
			-- Event with the same NOTEGROUP.
			-------------------------------------------
			left join CTE_EventText CTE	on (CTE.NOTEGROUP=E.NOTEGROUP
							and CTE.CYCLE    =C.CYCLE
							and CTE.EVENTTEXTID = Cast
								     (substring
								      ((select max(CTE1.DEFAULTTEXTTYPE + convert(nchar(11), TC.TEXTCOUNT) + convert(nchar(23),CTE1.LASTENTERED,121) + convert(nchar(11),CTE1.EVENTTEXTID))
									from CTE_EventText CTE1
									join CTE_TextCount TC on (TC.EVENTTEXTID=CTE1.EVENTTEXTID)
									where CTE1.NOTEGROUP=CTE.NOTEGROUP
									and   CTE1.CYCLE    =CTE.CYCLE ),36,11) as int)
								)
			left join CASEEVENTTEXT CET	on (CTE.NOTEGROUP is null
							and CET.CASEID  = C.CASEID 
							and CET.EVENTNO = C.EVENTNO 
							and CET.CYCLE   = C.CYCLE
							and CET.EVENTTEXTID = Cast
								     (substring
								      ((select max(CASE WHEN(ET1.EVENTTEXTTYPEID is null)                THEN '2'
											WHEN(ET1.EVENTTEXTTYPEID=@nDefaultEventNoteType) THEN '1' ELSE '0'
										   END
										 + convert(nchar(23),ET1.LOGDATETIMESTAMP,121) + convert(nchar(11),CET1.EVENTTEXTID))
									from CASEEVENTTEXT CET1
									join EVENTTEXT ET1 on (ET1.EVENTTEXTID=CET1.EVENTTEXTID)
									where CET1.CASEID =CET.CASEID
									and   CET1.EVENTNO=CET.EVENTNO
									and   CET1.CYCLE  =CET.CYCLE ),25,11) as int)
							)
			left join EVENTTEXT ET		on (ET.EVENTTEXTID = isnull(CTE.EVENTTEXTID,CET.EVENTTEXTID))
			where C.CASEID = @pnCaseKey

			order by CaseKey, EventDescription, EventKey, EventCycle"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey			int,
					  @nDefaultEventNoteType	int',
					  @pnCaseKey		= @pnCaseKey,
					  @nDefaultEventNoteType= @nDefaultEventNoteType
		End
	Else
		Begin
			Set @sSQLString = "Select

			'NewKey'
					as RowKey,
			@pnCaseKey	as CaseKey,
			@pnEventKey	as EventKey,
			@pnCycleKey	as EventCycle,
			"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura) +"
					as EventDescription,
			null		as EventDate,
			null		as EventDueDate,
			null		as EventText,
			null		as CreatedByActionCode,
			null		as CreatedByCriteriaKey,
			null		as NextPoliceDate,
			null		as FromCaseKey,
			null		as ResponsibleNameTypeKey,
			null		as ResponsibleNameType,
			null		as ResponsibleNameKey,
			CASE WHEN ISNULL(EC.NUMCYCLESALLOWED,0) = 1 THEN cast(0 as bit) ELSE cast(1 as bit) END as IsCyclic,
			null            as LastModifiedDate	
			from EVENTCONTROL EC
			where EC.EVENTNO = @pnEventKey
			and EC.CRITERIANO = "+ cast(dbo.fn_GetCriteriaNo(@pnCaseKey, 'E', @psActionKey, getdate(), @nProfileKey) as nvarchar(11))

			exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey			int,
					  @pnEventKey			int,
					  @pnCycleKey			smallint,
					  @psActionKey			nvarchar(2),
					  @nProfileKey			int',
					  @pnCaseKey			= @pnCaseKey,
					  @pnEventKey			= @pnEventKey,
					  @pnCycleKey			= @pnCycleKey,
					  @psActionKey			= @psActionKey,
					  @nProfileKey			= @nProfileKey	
			
		End	

End

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchCaseEvent to public
GO