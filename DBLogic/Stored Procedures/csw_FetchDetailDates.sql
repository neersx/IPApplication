-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchDetailDates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchDetailDates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchDetailDates.'
	Drop procedure [dbo].[csw_FetchDetailDates]
End
Print '**** Creating Stored Procedure dbo.csw_FetchDetailDates...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_FetchDetailDates
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
-- PROCEDURE:	csw_FetchDetailDates
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List the events applicable for the current criteria entry session.
--		Controlling Event Key is the first event (min(displaysequence)) in the detail control
--		If @pbUseNextCycle is true, prepare the event using the next cycle.
--		If @pbUseNextCycle is false, use @pnControllingEventCycle which is the user selected cycle to edit.  

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 MAR 2012	SF	R11460	1	Procedure created (Moved logic from ipw_ListWorkflowData


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
declare @sSQLFromWhere nvarchar(4000)
declare @sLookupCulture	nvarchar(10)
declare @nMaxCycle int
declare @bIsActionCyclic bit

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
and @pnControllingEventKey is null
Begin
	-- find controlling event
	Set @sSQLString = "
		Select	top 1 @pnControllingEventKey = EVENTNO								
		from	DETAILDATES DD  		
		where 	DD.CRITERIANO = @pnCriteriaKey  
		and	DD.ENTRYNUMBER = @pnEntryNumber
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
		Select	cast(DD.ENTRYNUMBER as nvarchar(15)) + '^' + 
			cast(DD.EVENTNO as nvarchar(15)) + '^' + 
			cast(CE.CYCLE as nvarchar(15))				as RowKey,
			@pnCaseKey						as CaseKey,
			DD.CRITERIANO						as CriteriaKey,
			DD.ENTRYNUMBER						as EntryNumber,
			@psActionKey						as ActionKey,
			DD.EVENTNO						as EventKey, 				
			ISNULL(
			"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)			
							+",
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)			
							+")			as EventDescription,    							
			cast (case 
				when @nMaxCycle is null then 1
				when @nMaxCycle = EC.NUMCYCLESALLOWED then @nMaxCycle
				when @nMaxCycle > EC.NUMCYCLESALLOWED then ISNULL(EC.NUMCYCLESALLOWED,1)
				else @nMaxCycle + 1
			end as smallint)					as EventCycle,
			CE.EVENTDATE						as EventDate,
			CE.EVENTDUEDATE						as EventDueDate,
			CASE 	WHEN (CE.LONGFLAG = 1)
				THEN CE.EVENTLONGTEXT
				ELSE "+dbo.fn_SqlTranslatedColumn('CASEEVENT','EVENTTEXT',null,'CE',@sLookupCulture,@pbCalledFromCentura)+"
			END
										as EventText,
			"+dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E',@sLookupCulture,@pbCalledFromCentura)			
							+"			as EventDefinition,    																	
			isnull(CE.CREATEDBYACTION,@psActionKey)			as CreatedByActionKey,
			isnull(CE.CREATEDBYCRITERIA,@pnCriteriaKey)		as CreatedByCriteriaKey,
			isnull(cast(CE.OCCURREDFLAG as bit),0)			as IsStopPolice,
			CE.ENTEREDDEADLINE					as PeriodDuration,
			CE.PERIODTYPE						as PeriodTypeKey,
			"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
							+"			as PeriodTypeDescription,
			cast(CE.DATEDUESAVED as bit)				as IsDateDueSaved,
			EVENTATTRIBUTE						as EventAttribute, 
			DUEATTRIBUTE						as DueAttribute, 
			OVREVENTATTRIBUTE					as OverrideEventAttribute, 
			OVRDUEATTRIBUTE						as OverrideDueAttribute, 
			PERIODATTRIBUTE						as PeriodAttribute,
			POLICINGATTRIBUTE					as PolicingAttribute,			
			DD.DISPLAYSEQUENCE					as DisplaySequence,
			cast(case when @nMaxCycle + 1 > ISNULL(EC.NUMCYCLESALLOWED,1) and CE.CASEID IS NOT NULL then 0 else 1 END as bit)
										as IsNew,
			CE.LOGDATETIMESTAMP					as LastModifiedDate
		from	DETAILDATES DD
		join	DETAILCONTROL DC		on (	DD.ENTRYNUMBER = DC.ENTRYNUMBER)
		join	EVENTCONTROL EC			on (	DD.EVENTNO = EC.EVENTNO
							and	DD.CRITERIANO = EC.CRITERIANO)
		join	EVENTS	E			on (	E.EVENTNO = EC.EVENTNO)		
		left	join CASEEVENT CE		on (	CE.EVENTNO = DD.EVENTNO
							and	CE.CASEID = @pnCaseKey
							and	CE.CYCLE = 
								case 
									when @nMaxCycle is null then 1
									when @nMaxCycle = EC.NUMCYCLESALLOWED then @nMaxCycle
									when @nMaxCycle > EC.NUMCYCLESALLOWED then ISNULL(EC.NUMCYCLESALLOWED,1)
									else @nMaxCycle + 1
								end					
							)

		left	join TABLECODES TC		on (	TC.TABLETYPE = 127  
							and	CE.PERIODTYPE = TC.USERCODE)
		where	DC.CRITERIANO = DD.CRITERIANO  
		and		DD.CRITERIANO = @pnCriteriaKey   		
		and		DC.ENTRYNUMBER = @pnEntryNumber
		order by DisplaySequence"
	
	exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnCaseKey				int,		
						@pnCriteriaKey			int,
						@pnEntryNumber			int,
						@nMaxCycle				int,
						@psActionKey			nvarchar(2)',
						@pnCaseKey			= @pnCaseKey,
						@pnCriteriaKey		= @pnCriteriaKey,
						@pnEntryNumber		= @pnEntryNumber,
						@nMaxCycle			= @nMaxCycle,
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
			Select	cast(DD.ENTRYNUMBER as nvarchar(15)) + '^' + 
				cast(DD.EVENTNO as nvarchar(15)) + '^' + 
				cast(Case When(isnull(EC.NUMCYCLESALLOWED, E.NUMCYCLESALLOWED))=1
				Then 1
				Else	Case When(@bIsActionCyclic=1)
						Then isnull(@pnControllingEventCycle, @pnActionCycle)
						Else  isnull(@pnControllingEventCycle, isnull(@nMaxCycle,1))
						End
				End 
				as nvarchar(15))				as RowKey,
				@pnCaseKey					as CaseKey,
				DD.CRITERIANO					as CriteriaKey,
				DD.ENTRYNUMBER					as EntryNumber,
				@psActionKey					as ActionKey,
				DD.EVENTNO					as EventKey, 				
				ISNULL(
				"+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)			
								+",
				"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)			
								+")		as EventDescription, "   							
	Set @sSQLString = @sSQLString +  "cast (Case When(isnull(EC.NUMCYCLESALLOWED, E.NUMCYCLESALLOWED))=1
										Then 1
										Else Case When(@bIsActionCyclic=1)
											 Then isnull(@pnControllingEventCycle, @pnActionCycle)
											 Else  isnull(@pnControllingEventCycle, isnull(@nMaxCycle,1))
											 End
										End " +	"
				as smallint)					as EventCycle,
				CE.EVENTDATE					as EventDate,
				CE.EVENTDUEDATE					as EventDueDate,
				CASE 	WHEN (CE.LONGFLAG = 1)
					THEN CE.EVENTLONGTEXT
					ELSE "+dbo.fn_SqlTranslatedColumn('CASEEVENT','EVENTTEXT',null,'CE',@sLookupCulture,@pbCalledFromCentura)+"
				END
										as EventText,
				"+dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E',@sLookupCulture,@pbCalledFromCentura)			
							+"			as EventDefinition,
				isnull(CE.CREATEDBYACTION,@psActionKey)		as CreatedByActionKey,
				isnull(CE.CREATEDBYCRITERIA,@pnCriteriaKey)	as CreatedByCriteriaKey,
				isnull(cast(CE.OCCURREDFLAG as bit),0)		as IsStopPolice,
				CE.ENTEREDDEADLINE				as PeriodDuration,
				CE.PERIODTYPE					as PeriodTypeKey,
				"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TC',@sLookupCulture,@pbCalledFromCentura)
								+"		as PeriodTypeDescription,
				cast(CE.DATEDUESAVED as bit)			as IsDateDueSaved,
				EVENTATTRIBUTE					as EventAttribute, 
				DUEATTRIBUTE					as DueAttribute, 
				OVREVENTATTRIBUTE				as OverrideEventAttribute, 
				OVRDUEATTRIBUTE					as OverrideDueAttribute, 
				PERIODATTRIBUTE					as PeriodAttribute,
				POLICINGATTRIBUTE				as PolicingAttribute,			
				DD.DISPLAYSEQUENCE				as DisplaySequence,
				cast(case when CE.EVENTNO is null then 1 else 0 end as bit)
										as IsNew,
				CE.LOGDATETIMESTAMP				as LastModifiedDate
			from	DETAILDATES DD
			join	EVENTS E			on (E.EVENTNO = DD.EVENTNO)
			join	CASES C				on (C.CASEID= @pnCaseKey)
			join	OPENACTION O			on (O.CASEID=C.CASEID
								and O.CRITERIANO = DD.CRITERIANO)
			join	ACTIONS		A		on (A.ACTION = O.ACTION)
			left join EVENTCONTROL EC		on (EC.CRITERIANO = DD.CRITERIANO
								and EC.EVENTNO = DD.EVENTNO)
			left join CASEEVENT CE			on (CE.CASEID=C.CASEID
								and CE.EVENTNO=DD.EVENTNO
								and CE.CYCLE=CASE(isnull(EC.NUMCYCLESALLOWED,E.NUMCYCLESALLOWED))
								when 1 
									then 1 
									else "
			Set @sSQLString = @sSQLString + case when @bIsActionCyclic = 1 then "
									isnull(@pnControllingEventCycle, @pnActionCycle)"
								else "
									isnull(@pnControllingEventCycle, isnull(@nMaxCycle,1))"
								end +																
				"											end)
				left	join TABLECODES TC	on (	TC.TABLETYPE = 127  
								and CE.PERIODTYPE = TC.USERCODE)
				where	DD.CRITERIANO = @pnCriteriaKey
				and		DD.ENTRYNUMBER = @pnEntryNumber
				and		O.CYCLE = @pnActionCycle
				order by DisplaySequence, EventKey, EventCycle"			
	
		exec @nErrorCode = sp_executesql @sSQLString ,
						  N'@pnCaseKey					int,		
							@pnCriteriaKey				int,
							@pnEntryNumber				int,
							@psActionKey				nvarchar(2),
							@pnActionCycle				int,
							@pnControllingEventCycle	int,
							@nMaxCycle					int,
							@bIsActionCyclic			bit',
							@pnCaseKey					= @pnCaseKey,
							@pnCriteriaKey				= @pnCriteriaKey,
							@pnEntryNumber				= @pnEntryNumber,
							@psActionKey				= @psActionKey,
							@pnActionCycle				= @pnActionCycle,
							@pnControllingEventCycle	= @pnControllingEventCycle,
							@nMaxCycle					= @nMaxCycle,
							@bIsActionCyclic			= @bIsActionCyclic
	End
End

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchDetailDates to public
GO
