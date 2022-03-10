-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseWorkFlowData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseWorkFlowData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseWorkFlowData.'
	Drop procedure [dbo].[csw_ListCaseWorkFlowData]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseWorkFlowData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseWorkFlowData
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnCaseKey			int,		-- Mandatory	
	@psActionKey			nvarchar(2),
	@pnActionCycle			int,
	@pnCriteriaKey			int,		-- Mandatory
	@pnEntryNumber			int,		-- Mandatory
	@pnControllingEventKey		int		= null,
	@pnControllingEventCycle	int		= null,
	@pbUseNextCycle			bit		= 0
)
as
-- PROCEDURE:	csw_ListCaseWorkFlowData
-- VERSION:	21
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List the events and letters applicable for the current criteria entry session.
--		Controlling Event Key is the first event (min(displaysequence)) in the detail control
--		If @pbUseNextCycle is true, prepare the event using the next cycle.
--		If @pbUseNextCycle is false, use @pnControllingEventCycle which is the user selected cycle to edit.  

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 OCT 2008	SF	RFC3392	1	Procedure created
-- 16 JUN 2010	KR	RFC8512 2	added EventNotesPreview column to CaseEntryEvent table.
-- 14 OCT 2010	SF	RFC9835	3	EventNotesPreview caused an issue when LEN is used on the ntext column
-- 19 JAN 2011	DV	R10126  4	Fixed issue where Period code rather than description was being displayed 
-- 18 APR 2011	KR	R10487	5	Fixed issue with cyclic actions and events by returning the correct event cycle
-- 06 SEP 2011	LP	R11257	6	Non-cyclic events belonging to the same entry should not use controlling event cycle
--					if it is greater than 1; These case event rows should only be updated, not inserted.
-- 24 Oct 2011	ASH	R11460	7	Cast integer columns as nvarchar(11) data type.
-- 03 Feb 2012	DV	R11674	8	IsNew and Cycle was not taking into account the condition where multiple events could be at different 
--					cycles. 
-- 08 Apr 2014	MS	R31303	9	Added LogDateTimeStamp of CASEEVENT 
-- 29 Dec 2014	MS	R41730	10	Fix IsNew logic for condition where case event doesnot exist
-- 02 Mar 2015	MS	R43203	11	Return event text from EVENTTEXT table
-- 16 Sep 2015	MF	50955	12	Previously satisfied due date is becoming due against incorrectly.  This is because the Satisfied manually 
--					entered due date is being displayed in the Workflow Wizard when it should be hidden.
-- 28 Sep 2016	MF	69013	13	When extracting the Events associated with the selected EntryNumber, a new CaseEvent should check if it can
--					default the EventText from another Event or cycle.
-- 14 Oct 2016	MF	69013	14	Need to cater for the possibility that an Event could potentially have multiple Event Notes of the same Note Type. This can occur when
--					an Event that has its own notes as become a member of a NoteGroup where Notes existed for other Events in that NoteGroup. To decide which Note
--					to return, the system will give preference to a Note that has been shared followed by the latest note edited.
-- 09 Nov 2016	MF	69788	15	A duplicate row was being returned for the Events. Introducing DISTINCT keyword.
-- 10 Jul 2017	MF	71920	15	The sharing of Event Notes that have an Event Note Type need to check if the Event Note Type is allowed to be shared (SHARINGALLOWED=1).
-- 05 Oct 2017	DV	72489	16	Fixed issue where event notes were null when there are event note with event note type added.
-- 29 Nov 2017	MF	73026	17	Typo correction.
-- 04 Jan 2018	MF	73220	18	Event Notes not being returned when the EVENTTEXT row is missing a LOGDATETIMESTAMP value. Resolved by defaulting to 1900-01-01.
-- 07 Sep 2018	AV	74738	19	Set isolation level to read uncommited.
-- 31 Oct 2018	LP	DR45009 20	Return Letter Document Type and WebGeneratedOnly flag
-- 13 Mar 2019	DV	DR26323	21	Fixed issue where DueDateResp field was not visible even when configured


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare	@nErrorCode		int
declare @sSQLString		nvarchar(max)
declare @sSQLFromWhere		nvarchar(max)
declare @sLookupCulture		nvarchar(10)
declare @nMaxCycle		int
declare @bIsActionCyclic	bit
declare @nDefaultEventNoteType	smallint

-- Initialise variables
Set    @nErrorCode 	      = 0
Set    @sLookupCulture 	      = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Select @nDefaultEventNoteType = dbo.fn_GetDefaultEventNoteType(@pnUserIdentityId)

If @nErrorCode = 0
Begin
	/* Populate the primary keys for this entry session */

	Set @sSQLString = "
		Select					
		cast(@pnCriteriaKey as nvarchar(15)) + '^' + 
		cast(DC.ENTRYNUMBER as nvarchar(15)) 
							as RowKey,
		@pnCaseKey				as CaseKey,
		DC.ENTRYNUMBER				as EntryNumber, 
		"+dbo.fn_SqlTranslatedColumn('DETAILCONTROL','ENTRYDESC',null,'DC',@sLookupCulture,@pbCalledFromCentura)			
						+"	as EntryDescription, 
		@pnCriteriaKey				as CriteriaKey,
		case when ATLEAST1FLAG = 1 then 1 else 0 end as IsRequireAtleast1Entry,
		"+dbo.fn_SqlTranslatedColumn('DETAILCONTROL','USERINSTRUCTION',null,'DC',@sLookupCulture,@pbCalledFromCentura)			
						+"	as UserInstructions, 
		DC.STATUSCODE				as CaseStatusKey,
		DC.RENEWALSTATUS			as RenewalStatusKey,
		Cast(isnull(S.CONFIRMATIONREQ,0) as bit)
							as IsStatusConfirmationRequired,
		DC.FILELOCATION				as FileLocationKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'FLD',@sLookupCulture,@pbCalledFromCentura)			
						+"	as FileLocationDescription,
		DC.NUMBERTYPE				as NumberTypeKey,
		"+dbo.fn_SqlTranslatedColumn('NUMBERTYPES','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)			
						+"	as NumberTypeDescription,
		case when DC.POLICINGIMMEDIATE=1 then 1 else 0 end as IsPoliceImmediately
		from	DETAILCONTROL DC  
		left join NUMBERTYPES NT on (NT.NUMBERTYPE = DC.NUMBERTYPE)	
		left join TABLECODES FLD on (FLD.TABLECODE = DC.FILELOCATION)		
		left join STATUS S on (S.STATUSCODE = DC.STATUSCODE)
		where 	DC.CRITERIANO = @pnCriteriaKey  
		and		DC.ENTRYNUMBER = @pnEntryNumber"	

	exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnCaseKey		int,		
					@pnCriteriaKey		int,
					@pnEntryNumber		int',
					@pnCaseKey		= @pnCaseKey,
					@pnCriteriaKey		= @pnCriteriaKey,
					@pnEntryNumber		= @pnEntryNumber
End

If @nErrorCode = 0
Begin
	/* get some existing case properties */

	Set @sSQLString = "
		Select					
		cast(@pnCriteriaKey as nvarchar(15)) + '^' + 
		cast(DC.ENTRYNUMBER as nvarchar(15)) 
							as RowKey,
		@pnCaseKey				as CaseKey,
		@pnEntryNumber				as EntryNumber, 
		C.STATUSCODE				as CaseStatusKey,
		CL.FILELOCATION				as FileLocationKey,
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'FLD',@sLookupCulture,@pbCalledFromCentura)			
						+"	as FileLocationDescription,
		DC.NUMBERTYPE				as NumberTypeKey,
		ISNULL(O.OFFICIALNUMBER, O1.OFFICIALNUMBER) as OfficialNumber				
		from	CASES C  
		left join DETAILCONTROL DC on (DC.CRITERIANO = @pnCriteriaKey  
					   and DC.ENTRYNUMBER = @pnEntryNumber)"+char(10)+
		-- find the OFFICIAL NUMBER that is marked as current for the number type specified by the detail control.
		-- if none of the official numbers are current, find the one which is the most recent.
		"		
		left join (	select top 1 OFFICIALNUMBER, NUMBERTYPE, CASEID
					from OFFICIALNUMBERS OMAX
					where OMAX.ISCURRENT= 0 or OMAX.ISCURRENT is null					
					order by DATEENTERED desc) O1 on (O1.CASEID = C.CASEID
													and O1.NUMBERTYPE = DC.NUMBERTYPE) 
		left join OFFICIALNUMBERS O on (C.CASEID = O.CASEID 
										and O.NUMBERTYPE = DC.NUMBERTYPE 
										and O.ISCURRENT = 1)"+char(10)+
		-- find the most recent CASE LOCATION for the current case.
		"		
		left join (	select	CASEID, 
					MAX( convert(nvarchar(24),WHENMOVED, 21)+cast(CASEID as nvarchar(11)) ) as [DATE]
					from CASELOCATION CLMAX
					group by CASEID	
					) LASTMODIFIED	on (LASTMODIFIED.CASEID = @pnCaseKey)
		left join	CASELOCATION CL		on (CL.CASEID = @pnCaseKey
										and ( (convert(nvarchar(24),CL.WHENMOVED, 21)+cast(CL.CASEID as nvarchar(11))) = LASTMODIFIED.[DATE]
															or LASTMODIFIED.[DATE] is null ))
		left join	TABLECODES FLD on (FLD.TABLECODE = CL.FILELOCATION)
		where 	C.CASEID = @pnCaseKey"	

	exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnCaseKey				int,		
						@pnCriteriaKey			int,
						@pnEntryNumber			int',
						@pnCaseKey			= @pnCaseKey,
						@pnCriteriaKey		= @pnCriteriaKey,
						@pnEntryNumber		= @pnEntryNumber
End

If @nErrorCode = 0
and @pnControllingEventKey is null
Begin
	-- find controlling event
	Set @sSQLString = "
		Select	top 1 @pnControllingEventKey = EVENTNO								
		from	DETAILDATES DD  		
		where 	DD.CRITERIANO = @pnCriteriaKey  
		and		DD.ENTRYNUMBER = @pnEntryNumber
		order by DISPLAYSEQUENCE
		"	

	exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnControllingEventKey		int output,
						@pnCriteriaKey				int,
						@pnEntryNumber				int',
						@pnControllingEventKey		= @pnControllingEventKey output,
						@pnCriteriaKey				= @pnCriteriaKey,
						@pnEntryNumber				= @pnEntryNumber
End

If @nErrorCode = 0
Begin
	-- find largest cycle of the event in the case.
	Set @sSQLString = "
		Select	@nMaxCycle = max(CE.CYCLE)								
		from	CASEEVENT CE 
		where	CE.EVENTNO = @pnControllingEventKey 
		and		CE.CASEID = @pnCaseKey"	

	exec @nErrorCode = sp_executesql @sSQLString,
				      N'@nMaxCycle					int output,
						@pnCaseKey					int,		
						@pnControllingEventKey		int',
						@nMaxCycle					= @nMaxCycle output,
						@pnCaseKey					= @pnCaseKey,
						@pnControllingEventKey		= @pnControllingEventKey

End

If @nErrorCode = 0
and @pbUseNextCycle = 1
Begin

/* Case Entry Events +  meta data */
/* when using next cycle, make sure the event hasn't exceeded the maximum cycle allowable.
   prepare the event row as though it will be added as a new case event if cycle falls within allowable cycle range
   prepare the event row for update if it is the maximum cycle */

	Set @sSQLString = "
		With 
		CTE_EventText (NOTEGROUP, CYCLE, EVENTTEXTID, LASTENTERED, SHARINGALLOWED)
			as (	select distinct E.NOTEGROUP, CT.CYCLE, ET.EVENTTEXTID,isnull(ET.LOGDATETIMESTAMP,'1900-01-01'), ETT.SHARINGALLOWED
				from CASEEVENTTEXT CT
				join EVENTS E     on (E.EVENTNO=CT.EVENTNO)
				join EVENTTEXT ET on (ET.EVENTTEXTID=CT.EVENTTEXTID)
				left join EVENTTEXTTYPE ETT on (ETT.EVENTTEXTTYPEID=ET.EVENTTEXTTYPEID)
				Where CT.CASEID=@pnCaseKey
				and (ET.EVENTTEXTTYPEID=@nDefaultEventNoteType or (ET.EVENTTEXTTYPEID is null and @nDefaultEventNoteType is null))
				and (ET.EVENTTEXTTYPEID is null OR ETT.SHARINGALLOWED=1) -- Event Text that have a TextType can only be returned if note sharing for that type is allowed
				and  E.NOTEGROUP is not null
			),"
			--------------------------------------------------
			-- Count how often the EventTextId has been used
			-- as we will take the one with the highest number
			-- in preference
			--------------------------------------------------
	Set @sSQLString=@sSQLString+"			
		CTE_TextCount (EVENTTEXTID, TEXTCOUNT)
			as (	select ET.EVENTTEXTID, count(*)
				from CTE_EventText ET
				join CASEEVENTTEXT CT on (CT.EVENTTEXTID=ET.EVENTTEXTID)
				group by ET.EVENTTEXTID
			),
		CTE_MaxCycle (EVENTNO, MAXCYCLE)
			as (	select EVENTNO, max(CYCLE)
				from CASEEVENT
				where CASEID=@pnCaseKey
				group by EVENTNO
			)
		Select	distinct
			cast(DD.ENTRYNUMBER as nvarchar(15)) + '^' + 
			cast(DD.EVENTNO as nvarchar(15)) + '^' + 
			cast(CE.CYCLE as nvarchar(15))			as RowKey,
			@pnCaseKey					as CaseKey,
			DD.ENTRYNUMBER					as EntryNumber,
			DD.EVENTNO					as EventKey, 				
			ISNULL(
			"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)			
							+",
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)			
							+")		as EventDescription,   
		        CASE   WHEN(CASE 
					WHEN @nMaxCycle is null			THEN 1
				        WHEN @nMaxCycle = EC.NUMCYCLESALLOWED	THEN @nMaxCycle
				        WHEN @nMaxCycle > EC.NUMCYCLESALLOWED	THEN ISNULL(EC.NUMCYCLESALLOWED,1)
										ELSE @nMaxCycle + 1
				     END) >= isnull((	SELECT MAXCYCLE 
							FROM CTE_MaxCycle C1 
							WHERE C1.EVENTNO = DD.EVENTNO),1)
				THEN(CASE 
					WHEN @nMaxCycle is null			THEN 1
					WHEN @nMaxCycle = EC.NUMCYCLESALLOWED	THEN @nMaxCycle
					WHEN @nMaxCycle > EC.NUMCYCLESALLOWED	THEN ISNULL(EC.NUMCYCLESALLOWED,1)
										ELSE @nMaxCycle + 1
				     END)
				     
				ELSE isnull((	SELECT MAXCYCLE 
						FROM CTE_MaxCycle C1 
						WHERE C1.EVENTNO = DD.EVENTNO),1)
			END
			 						as EventCycle,
			CE.EVENTDATE					as EventDate,
			CASE WHEN(CE.OCCURREDFLAG=9) THEN NULL ELSE CE.EVENTDUEDATE END	as EventDueDate,	-- RFC50955
			CASE WHEN(CE.OCCURREDFLAG=9) THEN NULL								-- RFC50955
			ELSE "+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ET',@sLookupCulture,@pbCalledFromCentura)+"	
			END	as EventText,
			CASE	WHEN (datalength("+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ET',@sLookupCulture,@pbCalledFromCentura)+")>1000) 
				THEN cast("+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ET',@sLookupCulture,@pbCalledFromCentura)+" as nvarchar(1000))
				ELSE "+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ET',@sLookupCulture,@pbCalledFromCentura)+"
			END						as EventNotesPreview,
			@nDefaultEventNoteType				as EventTextType,
			"+dbo.fn_SqlTranslatedColumn('EVENTTEXTTYPE','DESCRIPTION',null,'ETT',@sLookupCulture,@pbCalledFromCentura)+"				
									as EventTextTypeDescription,
			isnull(CE.CREATEDBYACTION,@psActionKey)	as CreatedByActionCode,
			isnull(CE.CREATEDBYCRITERIA,@pnCriteriaKey) as CreatedByCriteriaKey,
			isnull(cast(CE.OCCURREDFLAG as bit),0)	as IsStopPolice,
			CE.ENTEREDDEADLINE	as PeriodDuration,
			CE.PERIODTYPE		as PeriodTypeKey,
			"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
							+"
						as PeriodTypeDescription,
			CE.DATEDUESAVED		as DateDueSaved,
			EVENTATTRIBUTE		as EventAttribute, 
			DUEATTRIBUTE		as DueAttribute, 
			OVREVENTATTRIBUTE	as OverrideEventAttribute, 
			OVRDUEATTRIBUTE		as OverrideDueAttribute, 
			PERIODATTRIBUTE		as PeriodAttribute,
			POLICINGATTRIBUTE	as PolicingAttribute,			
			DD.DISPLAYSEQUENCE	as DisplaySequence,
			CE.LOGDATETIMESTAMP	as LastModifiedDate,
			CE.EMPLOYEENO as DueDateRespKey,
			DUEDATERESPATTRIBUTE as DueDateRespAttribute,
			case 
			        when @nMaxCycle + 1 > ISNULL(EC.NUMCYCLESALLOWED,1) and CE.CASEID IS NOT NULL 
			then 0 
			else 
			        case  
		                        when    (case 
		                                        when @nMaxCycle is null then 1
		                                        when @nMaxCycle = EC.NUMCYCLESALLOWED then @nMaxCycle
		                                        else @nMaxCycle + 1
	                                         end) > isnull((SELECT MAXCYCLE 
								FROM CTE_MaxCycle C1 
								WHERE C1.EVENTNO = DD.EVENTNO),1)
			                then 	1
			                else    0
			        end 
			 end			as IsNew"
	Set @sSQLString=@sSQLString+"			
		from	DETAILDATES DD
		join	DETAILCONTROL DC	on (	DD.ENTRYNUMBER = DC.ENTRYNUMBER)
		join	EVENTCONTROL EC		on (	DD.EVENTNO = EC.EVENTNO
						and	DD.CRITERIANO = EC.CRITERIANO)
		join	EVENTS	E		on (	E.EVENTNO = EC.EVENTNO)			
		left	join CASEEVENT CE	on (	CE.EVENTNO = DD.EVENTNO
						and	CE.CASEID = @pnCaseKey
						and	CE.CYCLE = 
								CASE	WHEN (CASE 
										WHEN @nMaxCycle is null               THEN 1
										WHEN @nMaxCycle = EC.NUMCYCLESALLOWED THEN @nMaxCycle
										WHEN @nMaxCycle > EC.NUMCYCLESALLOWED THEN ISNULL(EC.NUMCYCLESALLOWED,1)
														      ELSE @nMaxCycle + 1
									      END) >=  isnull((	SELECT MAXCYCLE 
												FROM CTE_MaxCycle C1 
												WHERE C1.EVENTNO = DD.EVENTNO),1)	
									THEN (CASE 
										WHEN @nMaxCycle is null               THEN 1
										WHEN @nMaxCycle = EC.NUMCYCLESALLOWED THEN @nMaxCycle
										WHEN @nMaxCycle > EC.NUMCYCLESALLOWED THEN ISNULL(EC.NUMCYCLESALLOWED,1)
														      ELSE @nMaxCycle + 1
									      END)
									ELSE isnull((	SELECT MAXCYCLE 
											FROM CTE_MaxCycle C1 
											WHERE C1.EVENTNO = DD.EVENTNO),1)
								END				
							)"
		-----------------------------------------
		-- Check if Event Notes are shared across
		-- Events in the one NOTEGROUP.
		-----------------------------------------
	Set @sSQLString=@sSQLString+"			
		left	join CTE_EventText CTE on (CTE.NOTEGROUP=E.NOTEGROUP
					       and CTE.CYCLE    =CASE WHEN(E.NOTESSHAREDACROSSCYCLES=1)
									THEN (select MAX(CTE1.CYCLE)
									      from CTE_EventText CTE1
									      where CTE1.NOTEGROUP=E.NOTEGROUP)
									      
									ELSE CASE WHEN(	CASE	WHEN @nMaxCycle is null               THEN 1
												WHEN @nMaxCycle = EC.NUMCYCLESALLOWED THEN @nMaxCycle
												WHEN @nMaxCycle > EC.NUMCYCLESALLOWED THEN ISNULL(EC.NUMCYCLESALLOWED,1)
																      ELSE @nMaxCycle + 1
											END) >=  isnull((	SELECT MAXCYCLE 
														FROM CTE_MaxCycle C1 
														WHERE C1.EVENTNO = DD.EVENTNO),1)	
											         
										THEN (CASE	WHEN @nMaxCycle is null               THEN 1
												WHEN @nMaxCycle = EC.NUMCYCLESALLOWED THEN @nMaxCycle
												WHEN @nMaxCycle > EC.NUMCYCLESALLOWED THEN ISNULL(EC.NUMCYCLESALLOWED,1)
																      ELSE @nMaxCycle + 1
										      END)
										ELSE isnull((	SELECT MAXCYCLE 
												FROM CTE_MaxCycle C1 
												WHERE C1.EVENTNO = DD.EVENTNO),1)
									END
								 END
					       and CTE.EVENTTEXTID = Cast
								     (substring
								      ((select max(convert(nchar(11), TC.TEXTCOUNT) + convert(nchar(23),CTE1.LASTENTERED,121) + convert(nchar(11),CTE1.EVENTTEXTID))
									from CTE_EventText CTE1
									join CTE_TextCount TC on (TC.EVENTTEXTID=CTE1.EVENTTEXTID)
									where CTE1.NOTEGROUP=CTE.NOTEGROUP
									and   CTE1.CYCLE    =CTE.CYCLE ),35,11) as int)
					       )"
		-----------------------------------------
		-- Check if Event Notes are held for this
		-- Event either for the same cycle or if
		-- allowed another cycle
		-----------------------------------------
	Set @sSQLString=@sSQLString+"			
		left	join 
			(Select ET.EVENTTEXTID, CET.CASEID, CET.EVENTNO, CET.CYCLE
			 from EVENTTEXT ET
			 Join CASEEVENTTEXT CET	on (CET.EVENTTEXTID = ET.EVENTTEXTID)
			 where ET.EVENTTEXTTYPEID = @nDefaultEventNoteType or (ET.EVENTTEXTTYPEID is null and @nDefaultEventNoteType is null))
					as ETF on (CTE.NOTEGROUP is null	-- Only required if text for the NoteGroup has not been returned.
					       and ETF.CASEID  = @pnCaseKey
					       and ETF.EVENTNO = DD.EVENTNO 
					       and ETF.CYCLE   = CASE WHEN(CE.CYCLE is not null)        THEN CE.CYCLE
					                              WHEN(E.NOTESSHAREDACROSSCYCLES=1) THEN (select MAX(CET1.CYCLE) 
													      from CASEEVENTTEXT CET1
													      where CET1.CASEID=@pnCaseKey
													      and   CET1.EVENTNO=DD.EVENTNO)
								 END
						and ETF.EVENTTEXTID = Cast
								     (substring
								      ((select max(CASE WHEN(ET1.EVENTTEXTTYPEID=@nDefaultEventNoteType OR (ET1.EVENTTEXTTYPEID is null and @nDefaultEventNoteType is NULL)) THEN '1' ELSE '0' END
										 + convert(nchar(23),isnull(ET1.LOGDATETIMESTAMP,'1900-01-01'),121) + convert(nchar(11),CET1.EVENTTEXTID))
									from CASEEVENTTEXT CET1
									join EVENTTEXT ET1 on (ET1.EVENTTEXTID=CET1.EVENTTEXTID)
									where CET1.CASEID=@pnCaseKey
									and   CET1.EVENTNO=DD.EVENTNO
									and   CET1.CYCLE  =ETF.CYCLE ),25,11) as int)
					       )
		                         
		left	join EVENTTEXT ET	on (ET.EVENTTEXTID=ISNULL(CTE.EVENTTEXTID,ETF.EVENTTEXTID))
				
		left	join EVENTTEXTTYPE ETT	on (ETT.EVENTTEXTTYPEID = @nDefaultEventNoteType)
		
		left	join TABLECODES TC	on (TC.TABLETYPE = 127  
						and CE.PERIODTYPE = TC.USERCODE)
		where	DC.CRITERIANO  = DD.CRITERIANO  
		and	DD.CRITERIANO  = @pnCriteriaKey   		
		and	DC.ENTRYNUMBER = @pnEntryNumber
		order by DisplaySequence"

	exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnCaseKey		int,		
					@pnCriteriaKey		int,
					@pnEntryNumber		int,
					@nMaxCycle		int,
					@nDefaultEventNoteType	smallint,
					@psActionKey		nvarchar(2)',
					@pnCaseKey		= @pnCaseKey,
					@pnCriteriaKey		= @pnCriteriaKey,
					@pnEntryNumber		= @pnEntryNumber,
					@nMaxCycle		= @nMaxCycle,
					@nDefaultEventNoteType	= @nDefaultEventNoteType,
					@psActionKey		= @psActionKey
End

If @nErrorCode = 0
and @pbUseNextCycle = 0
Begin

	If @pnControllingEventCycle is null
	Begin
		-- user is not using the Next cycle, so find the out if action is cyclic.
		-- if action is cyclic use @pnActionCycle
		-- if action is not cyclic use @nMaxCycle
		Set @sSQLString = "
			Select	@bIsActionCyclic = CASE WHEN A.NUMCYCLESALLOWED > 1 THEN 1 else 0 END		
			from	ACTIONS A
			where	A.ACTION = @psActionKey"	

		exec @nErrorCode = sp_executesql @sSQLString,
						  N'@bIsActionCyclic				bit output,
							@psActionKey					nvarchar(2)',
							@bIsActionCyclic				= @bIsActionCyclic output,
							@psActionKey					= @psActionKey

	End

	If @nErrorCode = 0
	Begin 
		/* Case Entry Events +  meta data */
		Set @sSQLString = "
		With 
		CTE_EventText (NOTEGROUP, CYCLE, EVENTTEXTID, LASTENTERED, SHARINGALLOWED)
			as (	select distinct E.NOTEGROUP, CT.CYCLE, ET.EVENTTEXTID, isnull(ET.LOGDATETIMESTAMP,'1900-01-01'), ETT.SHARINGALLOWED
				from CASEEVENTTEXT CT
				join EVENTS E     on (E.EVENTNO=CT.EVENTNO)
				join EVENTTEXT ET on (ET.EVENTTEXTID=CT.EVENTTEXTID)
				left join EVENTTEXTTYPE ETT on (ETT.EVENTTEXTTYPEID=ET.EVENTTEXTTYPEID)
				Where CT.CASEID=@pnCaseKey
				and (ET.EVENTTEXTTYPEID=@nDefaultEventNoteType or (ET.EVENTTEXTTYPEID is null and @nDefaultEventNoteType is null))
				and (ET.EVENTTEXTTYPEID is null OR ETT.SHARINGALLOWED=1) -- Event Text that have a TextType can only be returned if note sharing for that type is allowed
				and  E.NOTEGROUP is not null
			),"
			--------------------------------------------------
			-- Count how often the EventTextId has bee used
			-- as we will take the one with the highest number
			-- in preference
			--------------------------------------------------
		Set @sSQLString=@sSQLString+"			
		CTE_TextCount (EVENTTEXTID, TEXTCOUNT)
			as (	select ET.EVENTTEXTID, count(*)
				from CTE_EventText ET
				join CASEEVENTTEXT CT on (CT.EVENTTEXTID=ET.EVENTTEXTID)
				group by ET.EVENTTEXTID
			),
		CTE_MaxCycle (EVENTNO, MAXCYCLE)
			as (	select EVENTNO, max(CYCLE)
				from CASEEVENT
				where CASEID=@pnCaseKey
				group by EVENTNO
			)
		Select	distinct
			cast(DD.ENTRYNUMBER as nvarchar(15)) + '^' + 
			cast(DD.EVENTNO as nvarchar(15)) + '^' + 
			cast(	CASE When(isnull(EC.NUMCYCLESALLOWED, E.NUMCYCLESALLOWED))=1
					THEN 1
					ELSE	CASE When(@bIsActionCyclic=1)
							THEN coalesce(@pnControllingEventCycle, @pnActionCycle)
							ELSE coalesce(@pnControllingEventCycle,(SELECT MAXCYCLE 
												FROM CTE_MaxCycle C1 
												WHERE C1.EVENTNO = DD.EVENTNO), 1)
						END
				END 
				as nvarchar(15))	as RowKey,
			@pnCaseKey			as CaseKey,
			DD.ENTRYNUMBER			as EntryNumber,
			DD.EVENTNO			as EventKey, 				
			ISNULL(
			"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)			
							+",
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)			
							+")	as EventDescription,    	
														
			CASE WHEN(isnull(EC.NUMCYCLESALLOWED, E.NUMCYCLESALLOWED))=1
				THEN 1
				ELSE CASE WHEN(@bIsActionCyclic=1)
					THEN coalesce(@pnControllingEventCycle, @pnActionCycle)
					ELSE coalesce(@pnControllingEventCycle,(SELECT MAXCYCLE 
										FROM CTE_MaxCycle C1 
										WHERE C1.EVENTNO = DD.EVENTNO), 1)
				     END
			END								as EventCycle,
			CE.EVENTDATE							as EventDate,
			CASE WHEN(CE.OCCURREDFLAG=9) THEN NULL ELSE CE.EVENTDUEDATE END	as EventDueDate,	-- RFC50955
			CASE WHEN(CE.OCCURREDFLAG=9) THEN NULL								-- RFC50955
			ELSE "+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ET',@sLookupCulture,@pbCalledFromCentura)+"	
			END	as EventText,
			CASE	WHEN (datalength("+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ET',@sLookupCulture,@pbCalledFromCentura)+")>1000) 
				THEN cast("+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ET',@sLookupCulture,@pbCalledFromCentura)+" as nvarchar(1000))
				ELSE "+dbo.fn_SqlTranslatedColumn('EVENTTEXT','EVENTTEXT',null,'ET',@sLookupCulture,@pbCalledFromCentura)+"
			END								as EventNotesPreview,
			@nDefaultEventNoteType						as EventTextType,
			"+dbo.fn_SqlTranslatedColumn('EVENTTEXTTYPE','DESCRIPTION',null,'ETT',@sLookupCulture,@pbCalledFromCentura)+"				
											as EventTextTypeDescription,
			isnull(CE.CREATEDBYACTION,@psActionKey)				as CreatedByActionCode,
			isnull(CE.CREATEDBYCRITERIA,@pnCriteriaKey)			as CreatedByCriteriaKey,
			isnull(cast(CE.OCCURREDFLAG as bit),0)				as IsStopPolice,
			CE.ENTEREDDEADLINE						as PeriodDuration,
			CE.PERIODTYPE							as PeriodTypeKey,
			"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
							+"				as PeriodTypeDescription,
			CE.DATEDUESAVED							as DateDueSaved,
			EVENTATTRIBUTE							as EventAttribute, 
			DUEATTRIBUTE							as DueAttribute, 
			OVREVENTATTRIBUTE						as OverrideEventAttribute, 
			OVRDUEATTRIBUTE							as OverrideDueAttribute, 
			PERIODATTRIBUTE							as PeriodAttribute,
			POLICINGATTRIBUTE						as PolicingAttribute,			
			DD.DISPLAYSEQUENCE						as DisplaySequence,
			CE.LOGDATETIMESTAMP						as LastModifiedDate,
			CE.EMPLOYEENO							as DueDateRespKey,
			DUEDATERESPATTRIBUTE					as DueDateRespAttribute,
			CASE WHEN CE.EVENTNO is null THEN 1 ELSE 0 END			as IsNew"
			
			Set @sSQLString=@sSQLString+"			
			from	DETAILDATES DD
			join	EVENTS E		on (E.EVENTNO = DD.EVENTNO)
			join	CASES C			on (C.CASEID= @pnCaseKey)
			join	OPENACTION O		on (O.CASEID=C.CASEID
							and O.CRITERIANO = DD.CRITERIANO)
			join	ACTIONS A		on (A.ACTION = O.ACTION)
			left join EVENTCONTROL EC	on (EC.CRITERIANO = DD.CRITERIANO
							and EC.EVENTNO = DD.EVENTNO)
			left join CASEEVENT CE		on (CE.CASEID=C.CASEID
							and CE.EVENTNO=DD.EVENTNO
							and CE.CYCLE=CASE WHEN(isnull(EC.NUMCYCLESALLOWED,E.NUMCYCLESALLOWED)=1)
									THEN 1 
									ELSE CASE WHEN @bIsActionCyclic = 1 
											THEN coalesce(@pnControllingEventCycle, @pnActionCycle)
											ELSE coalesce(@pnControllingEventCycle, (SELECT MAXCYCLE FROM CTE_MaxCycle C1 WHERE C1.EVENTNO = DD.EVENTNO), 1)
									     END 				
							             END)"
			-------------------------------------------
			-- Check if Event Notes are held on another
			-- Event that shares the same NOTEGROUP.
			-------------------------------------------
			Set @sSQLString=@sSQLString+"	
			left	join CTE_EventText CTE on (CTE.NOTEGROUP=E.NOTEGROUP
						       and CTE.CYCLE=CASE WHEN(isnull(EC.NUMCYCLESALLOWED,E.NUMCYCLESALLOWED)=1)
									THEN 1 
									ELSE CASE WHEN @bIsActionCyclic = 1 
											THEN coalesce(@pnControllingEventCycle, @pnActionCycle)
											ELSE coalesce(@pnControllingEventCycle, (SELECT MAXCYCLE FROM CTE_MaxCycle C1 WHERE C1.EVENTNO = DD.EVENTNO), 1)
									     END				
							             END
							and CTE.EVENTTEXTID = Cast
								     (substring
								      ((select max(convert(nchar(11), TC.TEXTCOUNT) + convert(nchar(23),CTE1.LASTENTERED,121) + convert(nchar(11),CTE1.EVENTTEXTID))
									from CTE_EventText CTE1
									join CTE_TextCount TC on (TC.EVENTTEXTID=CTE1.EVENTTEXTID)
									where CTE1.NOTEGROUP=CTE.NOTEGROUP
									and   CTE1.CYCLE    =CTE.CYCLE ),35,11) as int)
								)"
			-----------------------------------------
			-- Check if Event Notes are held for this
			-- Event either for the same cycle or if
			-- allowed another cycle
			-----------------------------------------
			Set @sSQLString=@sSQLString+"	
			left	join 
				(Select ET.EVENTTEXTID, CET.CASEID, CET.EVENTNO, CET.CYCLE
				 from EVENTTEXT ET
				 Join CASEEVENTTEXT CET	on (CET.EVENTTEXTID = ET.EVENTTEXTID)
				 where ET.EVENTTEXTTYPEID = @nDefaultEventNoteType or (ET.EVENTTEXTTYPEID is null and @nDefaultEventNoteType is null))
						as ETF on (CTE.NOTEGROUP is null	-- Only required if no text against NoteGroup
						       and ETF.CASEID  = @pnCaseKey
						       and ETF.EVENTNO = DD.EVENTNO 
						       and ETF.CYCLE   = CASE WHEN(CE.CYCLE is not null)        THEN CE.CYCLE
									      WHEN(E.NOTESSHAREDACROSSCYCLES=1) THEN (select MAX(CET1.CYCLE) 
														      from CASEEVENTTEXT CET1
														      where CET1.CASEID=@pnCaseKey
														      and   CET1.EVENTNO=DD.EVENTNO)
									 END
							and ETF.EVENTTEXTID = Cast
									     (substring
									      ((select max(CASE WHEN(ET1.EVENTTEXTTYPEID=@nDefaultEventNoteType OR (ET1.EVENTTEXTTYPEID is null and @nDefaultEventNoteType is NULL)) THEN '1' ELSE '0' END
										 + convert(nchar(23),isnull(ET1.LOGDATETIMESTAMP,'1900-01-01'),121) + convert(nchar(11),CET1.EVENTTEXTID))
										from CASEEVENTTEXT CET1
										join EVENTTEXT ET1 on (ET1.EVENTTEXTID=CET1.EVENTTEXTID)
										where CET1.CASEID=@pnCaseKey
										and   CET1.EVENTNO=DD.EVENTNO
										and   CET1.CYCLE  =ETF.CYCLE ),25,11) as int)
						       )
					                         
			left	join EVENTTEXT ET	on (ET.EVENTTEXTID=ISNULL(CTE.EVENTTEXTID, ETF.EVENTTEXTID))
					
			left	join EVENTTEXTTYPE ETT	on (ETT.EVENTTEXTTYPEID = @nDefaultEventNoteType)
			
			left	join TABLECODES TC	on (TC.TABLETYPE  = 127  
							and CE.PERIODTYPE = TC.USERCODE)
			where	DD.CRITERIANO  = @pnCriteriaKey
			and	DD.ENTRYNUMBER = @pnEntryNumber
			and	O.CYCLE        = @pnActionCycle
			order by DisplaySequence, EventKey, EventCycle"			
	
		exec @nErrorCode = sp_executesql @sSQLString ,
						N'@pnCaseKey			int,		
						  @pnCriteriaKey		int,
						  @pnEntryNumber		int,
						  @psActionKey			nvarchar(2),
						  @pnActionCycle		int,
						  @pnControllingEventCycle	int,
						  @nMaxCycle			int,
						  @nDefaultEventNoteType	smallint,
						  @bIsActionCyclic		bit',
						  @pnCaseKey			= @pnCaseKey,
						  @pnCriteriaKey		= @pnCriteriaKey,
						  @pnEntryNumber		= @pnEntryNumber,
						  @psActionKey			= @psActionKey,
						  @pnActionCycle		= @pnActionCycle,
						  @pnControllingEventCycle	= @pnControllingEventCycle,
						  @nMaxCycle			= @nMaxCycle,
						  @nDefaultEventNoteType	= @nDefaultEventNoteType,
						  @bIsActionCyclic		= @bIsActionCyclic
	End
End

If @nErrorCode = 0
Begin

	/* Case Letters */
	Set @sSQLString = "
		Select	cast(DL.ENTRYNUMBER as nvarchar(15)) + '^' + 
				cast(DL.LETTERNO as nvarchar(15))		as RowKey,
				@pnCaseKey								as CaseKey,
				@psActionKey							as ActionKey,
				@pnActionCycle							as ActionCycle,
				DL.ENTRYNUMBER							as EntryNumber,
				DL.LETTERNO								as LetterKey, 				
				"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'L',@sLookupCulture,@pbCalledFromCentura)			
								+"						as LetterName,    							
				L.DOCUMENTCODE							as LetterCode,
				L.COVERINGLETTER						as CoveringLetterKey,
				"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'COV',@sLookupCulture,@pbCalledFromCentura)			
								+"						as CoveringLetterName,    							
				L.ENVELOPE								as EnvelopeKey,
				"+dbo.fn_SqlTranslatedColumn('LETTER','LETTERNAME',null,'ENV',@sLookupCulture,@pbCalledFromCentura)			
								+"						as EnvelopeName,    							
				cast(DL.MANDATORYFLAG as bit)				as IsMandatory,
				L.DOCUMENTTYPE						as DocumentType,
				case when L.USEDBY & 1024 = 1024 then 1 else 0 end	as IsWebGeneratedOnly
		from	DETAILLETTERS DL
		join	LETTER L				on (	DL.LETTERNO = L.LETTERNO)
		left	join LETTER COV 			on (	L.COVERINGLETTER = COV.LETTERNO)
		left	join LETTER ENV 			on (	L.COVERINGLETTER = ENV.LETTERNO)
		where	DL.CRITERIANO = @pnCriteriaKey   		
		and		DL.ENTRYNUMBER = @pnEntryNumber"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnCaseKey				int,		
						@pnCriteriaKey			int,
						@psActionKey			nvarchar(2),
						@pnActionCycle			int,
						@pnEntryNumber			int',
						@pnCaseKey			= @pnCaseKey,
						@pnCriteriaKey		= @pnCriteriaKey,
						@psActionKey		= @psActionKey,
						@pnActionCycle		= @pnActionCycle,
						@pnEntryNumber		= @pnEntryNumber
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseWorkFlowData to public
GO
