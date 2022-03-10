-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceGetActions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceGetActions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceGetActions.'
	drop procedure dbo.ip_PoliceGetActions
end
print '**** Creating procedure dbo.ip_PoliceGetActions...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceGetActions 
			@pnRowCount		int	OUTPUT,
			@pnDebugFlag		tinyint,
			@pdtDateOfAct		datetime    =NULL,
			@psAction		nvarchar(2)  =NULL,
			@pnEventNo		int	    =NULL,
			@pnExcludeAction	decimal(1,0)=NULL,
			@pnCriteriaFlag		decimal(1,0)=NULL,
			@pnDueDateFlag		decimal(1,0)=NULL,
			@pnCalcReminderFlag	decimal(1,0)=NULL


as
-- PROCEDURE :	ip_PoliceGetActions
-- VERSION :	17
-- DESCRIPTION:	Get all of the Actions from the OpenAction table for the CaseEvents Cases being policed.

-- MODIFICATION
-- Date		Who	SQA	Version
-- ====         ===	=== 	=======
-- 06/07/2001	MF			Procedure created
-- 19/09/2001	MF	7062		Return Actions for calculation if Reminders are being recalculated
-- 13/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 28 Jul 2003	MF	8673	10	Get the OFFICE associated with the Case so it can be used to determine the
--					best CriteriaNo for an Action.
-- 08 Mar 2005	MF	11122	11	Initialise the USERID and IDENTITYID in #TEMPOPENACTION from the #TEMPCASES row.
-- 07 Jun 2006	MF	12417	12	Change order of columns returned in debug mode to make it easier to review
-- 31 May 2007	MF	14812	13	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	14	Reserve word [STATE]
-- 21 Aug 2012	MF	S20824	15	Revisit of RFC11808. If the due date calculations exist for a different Action that has been closed then
--					do not trigger these to calculate. This means that we require closed actions to be included into #TEMPOPENACTION.
--					This change removes the previous restriction that only loaded OpenActions where POLICEEVENTS=1.
-- 03 Nov 2015	MF	R54331	16	Actions that are marked as closed should not be flagged to recalculate.  They should however be returned into #TEMPOPENACTION.
-- 14 Nov 2018  AV  75198/DR-45358	17   Date conversion errors when creating cases and opening names in Chinese DB

set nocount on

DECLARE		@ErrorCode		int,
		@sSQLString		nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode   = 0

-- Load #TEMPOPENACTION with the details of the Actions to be processed. 

If @ErrorCode=0
Begin
	set @sSQLString="
	insert #TEMPOPENACTION 
		(CASEID, ACTION, CYCLE, LASTEVENT, CRITERIANO, DATEFORACT, NEXTDUEDATE, POLICEEVENTS,
		 STATUSCODE, STATUSDESC, DATEENTERED, DATEUPDATED, CASETYPE, PROPERTYTYPE, COUNTRYCODE,
		 CASECATEGORY, SUBTYPE, BASIS, REGISTEREDUSERS, LOCALCLIENTFLAG, EXAMTYPE, RENEWALTYPE,
		 CASEOFFICEID,NEWCRITERIANO,USERID,IDENTITYID,[STATE])
	select	OA.CASEID,
		OA.ACTION,
		OA.CYCLE,
		OA.LASTEVENT,
		OA.CRITERIANO,
		OA.DATEFORACT,
		OA.NEXTDUEDATE,
		OA.POLICEEVENTS,
		OA.STATUSCODE,
		OA.STATUSDESC,
		OA.DATEENTERED,
		OA.DATEUPDATED,
		C.CASETYPE,
		C.PROPERTYTYPE,
		C.COUNTRYCODE,
		C.CASECATEGORY,
		C.SUBTYPE,
		P.BASIS,
		P.REGISTEREDUSERS,
		C.LOCALCLIENTFLAG,
		P.EXAMTYPE,
		P.RENEWALTYPE,
		C.OFFICEID,
		OA.CRITERIANO,
		T.USERID,
		T.IDENTITYID,
				/* if the Event is being recalculated then flag the openaction	*/
				/* so none will be recalcualted.				*/
		CASE WHEN (@pnEventNo is not NULL)
			THEN 'C1'
				/* Return all of the eligible Open Action rows for the selected	*/
				/* cases however only flag those rows that match the criteria	*/
				/* for recalculation.						*/
			ELSE CASE
				WHEN (OA.POLICEEVENTS=0)
				    THEN 'C1' 
				WHEN (@pnCriteriaFlag=1 OR @pnDueDateFlag=1 OR @pnCalcReminderFlag=1)
				    THEN 	
					CASE WHEN (@pnExcludeAction is null OR @pnExcludeAction=0)
						THEN
							CASE WHEN (@psAction     is null     and @pdtDateOfAct is null)		Then 'C'
							     WHEN (@psAction     is not null and @psAction=OA.ACTION
							       and @pdtDateOfAct is not null and @pdtDateOfAct=OA.DATEFORACT)	Then 'C'
							     WHEN (@psAction     is not null and @psAction=OA.ACTION
							       and @pdtDateOfAct is null)					Then 'C'
							     WHEN (@pdtDateOfAct is not null and @pdtDateOfAct=OA.DATEFORACT
							       and @psAction     is null)					Then 'C'
																Else 'C1'
							End
						ELSE
							CASE WHEN (@psAction     is null     and @pdtDateOfAct is null)		Then 'C'
							     WHEN (@psAction     is not null and @psAction=OA.ACTION)		Then 'C1'
							     WHEN (@pdtDateOfAct is not null and @pdtDateOfAct=OA.DATEFORACT)	Then 'C1'
																Else 'C'
							End
					End
				    ELSE 'C1'
			End
		End
	from	#TEMPCASES T
	join    OPENACTION OA on (OA.CASEID    =T.CASEID)
	join 	ACTIONS    A  on (A.ACTION     =OA.ACTION)
	join	CASES	   C  on (C.CASEID     =T.CASEID)
	left join PROPERTY P  on (P.CASEID     =T.CASEID)
	left join STATUS   S  on (S.STATUSCODE =T.STATUSCODE)
	left join STATUS   S1 on (S1.STATUSCODE=T.RENEWALSTATUS)
	left join #TEMPOPENACTION TOA	on (TOA.CASEID=OA.CASEID
					and TOA.ACTION=OA.ACTION
					and TOA.CYCLE =OA.CYCLE)
	where	TOA.CASEID is null
	and    ((A.ACTIONTYPEFLAG  =0 and (S.POLICEOTHERACTIONS=1 or S.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =2 and (S.POLICEEXAM        =1 or S.STATUSCODE  is null))
	 or     (A.ACTIONTYPEFLAG  =1 and (S.POLICERENEWALS    =1 or S.STATUSCODE  is null) 
	                              and (S1.POLICERENEWALS   =1 or S1.STATUSCODE is null)))"

	Execute @ErrorCode = sp_executesql @sSQLString, 
				N'@pdtDateOfAct		datetime,
				 @psAction		nvarchar(2),
				 @pnEventNo		int,
				 @pnExcludeAction	decimal(1,0),
				 @pnCriteriaFlag	decimal(1,0),
				 @pnDueDateFlag		decimal(1,0),
				 @pnCalcReminderFlag	decimal(1,0)',
				@pdtDateOfAct,
				 @psAction,
				 @pnEventNo,
				 @pnExcludeAction,
				 @pnCriteriaFlag,
				 @pnDueDateFlag,
				 @pnCalcReminderFlag

	Set @pnRowCount=@@Rowcount
End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceGetActions',0,1,@sTimeStamp ) with NOWAIT

	If @pnDebugFlag>2
	Begin
		set @sSQLString="
		Select T.[STATE], *, @pnRowCount as 'RowCount' from #TEMPOPENACTION T
		order by T.[STATE], T.CASEID, T.ACTION, T.CYCLE"

		exec @ErrorCode= sp_executesql @sSQLString,
						N'@pnRowCount	int',
						  @pnRowCount
	End
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceGetActions  to public
go
